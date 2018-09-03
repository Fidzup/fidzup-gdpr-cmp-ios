//
//  CMPEditorManager.swift
//  FidzupCMP
//
//  Created by Nicolas Blanc on 03/09/2018.
//  Copyright © 2018 Fidzup. All rights reserved.
//

import Foundation
/**
 Retrieves and parse an editor from internet.
 */
internal class CMPEditorManager {
    
    /// Represents an error happening during vendor list refresh.
    enum RefreshError : Error {
        
        /// The vendor list refresh fails because of a network error.
        case networkError
        
        /// The vendor list refresh fails because the JSON received is invalid.
        case parsingError
        
    }
    
    /// The default polling timer interval.
    ///
    /// This timer is polling every minutes because we want to be able to retry quickly in case of
    /// issues when retrieving the vendor list.
    /// If the refresh is successful, the 'refreshInterval' will be honored by the timer.
    internal static let DEFAULT_TIMER_POLL_INTERVAL: TimeInterval = 60.0
    
    /// The URL of the vendor list.
    let editorURL: CMPEditorURL
    
    /// The interval between each refresh.
    let refreshInterval: TimeInterval
    
    /// The current polling timer interval.
    let pollInterval: TimeInterval
    
    /// The delegate that should be warned when an editor is available or in case of errors.
    let delegate: CMPEditorManagerDelegate
    
    /// The URL session used for network connection.
    ///
    /// This should always use the shared URL session except for unit testing.
    internal let urlSession: CMPURLSession
    
    /// A handler that will be called before any refresh.
    ///
    /// This should only be implemented by unit tests.
    internal var refreshHandler: ((Date?) -> ())?
    
    /// The polling timer.
    private var timer: Timer? = nil
    
    /// The date of the last vendor list successful refresh, or nil if no success yet.
    private var lastRefreshDate: Date? = nil
    
    /**
     Initialize a new instance of CMPEditorManager.
     
     - Parameters:
     - url: The URL of the vendor list that will be fetched.
     - refreshInterval: The interval between each refresh.
     - delegate: The delegate that should be warned when a vendor list is available or in case of errors.
     */
    public convenience init(url: CMPEditorURL, refreshInterval: TimeInterval, delegate: CMPEditorManagerDelegate) {
        self.init(
            url: url,
            refreshInterval: refreshInterval,
            delegate: delegate,
            pollInterval: CMPEditorManager.DEFAULT_TIMER_POLL_INTERVAL,
            urlSession: CMPURLSession.shared
        )
    }
    
    /**
     Initialize a new instance of CMPEditorManager.
     
     Note: this initializer should only be used by unit tests.
     
     - Parameters:
     - url: The URL of the vendor list that will be fetched.
     - refreshInterval: The interval between each refresh.
     - delegate: The delegate that should be warned when a vendor list is available or in case of errors.
     - pollInterval: A custom polling timer interval.
     - urlSession: A custom URL session used for network connection.
     */
    public init(url: CMPEditorURL,
                refreshInterval:TimeInterval,
                delegate: CMPEditorManagerDelegate,
                pollInterval: TimeInterval,
                urlSession: CMPURLSession) {
        
        self.editorURL = url
        self.refreshInterval = refreshInterval
        self.delegate = delegate
        self.pollInterval = pollInterval
        self.urlSession = urlSession
        
    }
    
    /**
     Start the automatic refresh timer.
     
     Note: starting the refresh timer will trigger a refresh immediately no matter when the
     last refresh happen.
     */
    public func startRefreshTimer() {
        if timer == nil {
            // Refresh is called automatically when the refresh timer is started
            refresh(forceRefresh: false)
            
            // Then the timer is started…
            timer = Timer.scheduledTimer(
                timeInterval: pollInterval,
                target: self,
                selector: #selector(timerFired(timer:)),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    /**
     Stop the automatic refresh timer.
     */
    public func stopRefreshTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /**
     Called when the polling timer is fired.
     
     - Parameter timer: The timer that has been fired.
     */
    @objc
    func timerFired(timer: Timer) {
        refresh(forceRefresh: false)
    }
    
    /**
     Refresh the editor from network.
     
     - Parameter forceRefresh: true if the refresh should happen no matter what, false if it should check the 'last refresh date'.
     */
    public func refresh(forceRefresh: Bool) {
        if forceRefresh || isRefreshNeeded() {
            refresh(editorURL: editorURL)
        }
    }
    
    /**
     Check if an editor refresh is needed.
     
     - Returns: true if an editor refresh is needed, false otherwise.
     */
    internal func isRefreshNeeded() -> Bool {
        switch lastRefreshDate {
        case .some(let date) where Date().timeIntervalSince1970 - date.timeIntervalSince1970 > refreshInterval:
            return true
        case .none:
            return true
        default:
            return false
        }
    }
    
    /**
     Refresh the editor from network.
     
     Note: a successful refresh will update the last refresh date, preventing the auto refresh to happen for some times,
     a failed refresh will invalidate the last refresh date: an auto refresh will be triggered at the next timer fired
     event.
     
     - Parameters
     - editorURL: The url of the editor that must be fetched.
     - responseHandler: Optional callback that will be used INSTEAD of the delegate if provided.
     */
    public func refresh(editorURL: CMPEditorURL, responseHandler: ((CMPEditor?, Error?) -> ())? = nil) {
        refreshHandler?(lastRefreshDate) // calling handler when refreshing for unit testing purposes only
        
        fetchEditor(editorURL: editorURL) { (editorData, editorError, localizedEditorData, localizedEditorError) in
            if let editorData = editorData, editorError == nil {
                if let editor = CMPEditor(jsonData: editorData, localizedJsonData: localizedEditorData) {
                    self.lastRefreshDate = Date()
                    
                    // Fetching successful
                    self.callRefreshCallback(editor: editor, error: nil, responseHandler: responseHandler)
                } else {
                    self.lastRefreshDate = nil
                    
                    // Parsing error
                    self.callRefreshCallback(editor: nil, error: RefreshError.parsingError, responseHandler: responseHandler)
                }
            } else {
                self.lastRefreshDate = nil
                
                // Network error
                self.callRefreshCallback(editor: nil, error: RefreshError.networkError, responseHandler: responseHandler)
            }
        }
    }
    
    /**
     Fetch an editor and its localized version if it exists in parallel.
     
     - Parameters:
     - editorURL: The editor URL.
     - responseHandler: The callback called when the vendor list retrieval is finished. The first two parameters corresponds to
     the main editor, the last two corresponds to the localized editor if it exists (if not, both Data & Error will be nil).
     */
    private func fetchEditor(editorURL: CMPEditorURL, responseHandler: @escaping (Data?, Error?, Data?, Error?) -> ()) {
        let dispatchGroup = DispatchGroup()
        
        // Requesting for main vendor list JSON
        var editorData: Data? = nil
        var editorError: Error? = nil
        fetchEditor(withDispatchGroup: dispatchGroup, url: editorURL.url) { (data, error) in
            editorData = data
            editorError = error
        }
        
        // Requesting for localized vendor list JSON if necessary
        var localizedEditorData: Data? = nil
        var localizedEditorError: Error? = nil
        if let localizedURL = editorURL.localizedUrl {
            fetchEditor(withDispatchGroup: dispatchGroup, url: localizedURL) { (data, error) in
                localizedEditorData = data
                localizedEditorError = error
            }
        }
        
        // Waiting for both requests to complete
        dispatchGroup.notify(queue: .main) {
            responseHandler(editorData, editorError, localizedEditorData, localizedEditorError)
        }
    }
    
    /**
     Fetch an editor from a raw URL using a dispatch group for synchronization.
     
     - Parameters:
     - dispatchGroup: The dispatch group that is going to be locked during the request.
     - url: The raw URL that need to be fetched
     - responseHandler: The callback that will be called when the request finished.
     */
    private func fetchEditor(withDispatchGroup dispatchGroup: DispatchGroup, url: URL, responseHandler: @escaping (Data?, Error?) -> ()) {
        dispatchGroup.enter()
        urlSession.dataRequest(url: url) { (data, response, error) in
            responseHandler(data, error)
            dispatchGroup.leave()
        }
    }
    
    /**
     Call the relevant CMPEditorManager delegate or callback.
     
     Called after a refresh attempt, this method will call a callback if provided when refresh() was invoked, otherwise
     the standard delegate will be called.
     
     - Parameters:
     - editor: An optional editor.
     - error: An optional error.
     - responseHandler: An optional response handler.
     */
    private func callRefreshCallback(editor: CMPEditor?, error: Error?, responseHandler: ((CMPEditor?, Error?) -> ())?) {
        if let handler = responseHandler {
            handler(editor, error)
        } else {
            if let editor = editor {
                self.delegate.editorManager(self, didFetchEditor: editor)
            } else if let error = error {
                self.delegate.editorManager(self, didFailWithError: error)
            }
        }
    }
    
}
