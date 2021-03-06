//
//  CMPConsentManager.swift
//  FidzupCMP
//
//  Created by Thomas Geley on 24/04/2018.
//  Copyright © 2018 Smart AdServer.
//
//  This software is distributed under the Creative Commons Legal Code, Attribution 3.0 Unported license.
//  Check the LICENSE file for more information.
//

import UIKit
import AdSupport

/**
 A class to manage the CMP.
 */
@objc
public class CMPConsentManager: NSObject, CMPVendorListManagerDelegate, CMPEditorManagerDelegate, CMPConsentToolManagerDelegate {

    // MARK: - Global singleton
    
    /// Returns the shared CMPConsentManager object.
    @objc(sharedInstance)
    public static let shared = CMPConsentManager()
    
    // MARK: - Public fields
    
    /// CMPConsentManager delegate.
    @objc
    public weak var delegate: CMPConsentManagerDelegate?
    
    /// Must be set as soon as the publisher knows whether or not the user is subject to GDPR law, for example after looking up the user's location, or if the publisher himself is subject to this regulation.
    @objc
    public var subjectToGDPR: Bool = false { didSet { gdrpStatusChanged() } }
    
    /// The consent string.
    private var consentString: CMPConsentString? { didSet { consentStringChanged() } }
    
    /// Most up-to-date vendor list retrieved by the consent manager, or nil if no vendor list is available yet.
    @objc
    public var vendorList: CMPVendorList?
    
    /// Most up-to-date editor retrieved by the consent manager, or nil if no editor is available yet.
    @objc
    public var editor: CMPEditor?

    // MARK: - Private fields
    
    /// Whether or not the CMPConsentManager has been configured by the publisher.
    private var configured: Bool = false
    
    /// The current device language in a format usable by the CMP.
    private var language: CMPLanguage = CMPLanguage.DEFAULT_LANGUAGE
    
    /// Instance of CMPVendorListManager that is responsible for fetching, parsing and creating a model of CMPVendorList.
    private var vendorListManager: CMPVendorListManager?
    
    /// Instance of CMPEditorManager that is responsible for fetching, parsing and creating a model of CMPEditor.
    private var editorManager: CMPEditorManager?

    /// Whether or not the consent tool should show if user has limited ad tracking in the device settings.
    /// If false and LAT is On, no consent will be given for any purpose or vendors.
    private var showConsentToolIfLAT: Bool = true
    
    /// Consent tool configuration instance.
    private var consentToolConfiguration: CMPConsentToolConfiguration?
    
    /// Consent tool manager instance.
    private var consentToolManager: CMPConsentToolManager?
    
    /// Whether or not the consent tool is presented.
    private var consentToolIsShown: Bool = false
    
    /// A state object used to store persistent data.
    private let managerState: CMPConsentManagerState
    
    /// The minimum interval between two consent tool presentation.
    private var presentationInterval: TimeInterval = DEFAULT_VENDORLIST_PRESENTATION_INTERVAL
    
    /// The editor that has been used to generate the current consent string if available (and if there is a consent string), nil otherwise.
    public var previousEditor: CMPEditor?
    
    /// The vendor list that has been used to generate the current consent string if available (and if there is a consent string), nil otherwise.
    public var previousVendorList: CMPVendorList?

    /// true if the constent tool's presentation interval is elapsed, false otherwise.
    private var isPresentationIntervalElapsed: Bool {
        let lastPresentationDate = managerState.lastPresentationDate() ?? Date(timeIntervalSince1970: 0)
        return Date().timeIntervalSince1970 - lastPresentationDate.timeIntervalSince1970 > presentationInterval
    }
    
    // MARK: - Constants
    
    /// The default minimum interval between two presentation of the consent tool (or between to call to the delegate).
    @objc
    public static let DEFAULT_VENDORLIST_PRESENTATION_INTERVAL = 7.0 * 24.0 * 60.0 * 60.0;  // 1 week
    
    /// The default refresh interval for the editor.
    @objc
    public static let DEFAULT_EDITOR_REFRESH_INTERVAL = 60.0 * 60.0; // 1 hour
    
    /// The default refresh interval for the vendor list.
    @objc
    public static let DEFAULT_VENDORLIST_REFRESH_INTERVAL = 60.0 * 60.0; // 1 hour

    /// The behavior if LAT (Limited Ad Tracking) is enabled.
    @objc
    public static let DEFAULT_LAT_VALUE = true
    
    /**
     Consent manager deinitializer.
     */
    deinit {
        unregisterApplicationLifecycleNotifications()
    }
    
    /**
     Initialize a consent manager instance.
     
     Note: this initializer should only be used to construct the shared instance.
     */
    private override init() {
        self.managerState = CMPConsentManagerState()
    }
    
    /**
     Initialize a consent manager instance with a custom state manager.
     
     Note: this initializer should only be used for unit testing. For other use cases, use the shared instance.
     
     - Parameter managerState: A state object used to store persistent data.
     */
    internal init(managerState: CMPConsentManagerState) {
        self.managerState = managerState
    }
    
    // MARK: - Public methods
    
    /**
     Configure the CMPConsentManager. This method must be called only once per session.
     
     - Parameters:
        - language: an instance of CMPLanguage reflecting the device's current language.
        - consentToolConfiguration: an instance of CMPConsentToolConfiguration to configure of the consent tool UI.
     */
    @objc
    public func configureWithLanguage(_ language: CMPLanguage,
                                      consentToolConfiguration: CMPConsentToolConfiguration) {
        self.configure(
            presentationInterval: CMPConsentManager.DEFAULT_VENDORLIST_PRESENTATION_INTERVAL,
            language: language,
            consentToolConfiguration: consentToolConfiguration,
            showConsentToolWhenLimitedAdTracking: CMPConsentManager.DEFAULT_LAT_VALUE
        )
    }
    
    /**
     Configure the CMPConsentManager. This method must be called only once per session.
     
     Note: if you set 'showConsentToolWhenLimitedAdTracking' to true, you will be able to ask for user consent even if 'Limited Ad
     Tracking' has been enabled on the device. In this case, remember that you still have to comply to Apple's App Store Terms and
     Conditions regarding 'Limited Ad Tracking'.
     
     - Parameters:
        - vendorListURL: The URL from where to fetch the vendor list (vendors.json). If you enter your own URL, your custom list MUST BE compatible with IAB specifications and respect vendorId and purposeId distributed by the IAB.
        - presentationInterval: The minimum interval between two presentation of the consent tool (or between to call to the delegate).
        - language: an instance of CMPLanguage reflecting the device's current language.
        - consentToolConfiguration: an instance of CMPConsentToolConfiguration to configure of the consent tool UI.
        - showConsentToolWhenLimitedAdTracking: Whether or not the consent tool UI should be shown if the user has enabled 'Limit Ad Tracking' in his device's preferences. If false, the consent tool will never be shown if user has enabled 'Limit Ad Tracking' and the consent string will be formatted has 'user does not give consent'. Note that if you have provided a delegate, it will not be called either.
     */
    @objc
    public func configure(presentationInterval: TimeInterval = CMPConsentManager.DEFAULT_VENDORLIST_PRESENTATION_INTERVAL,
                          language: CMPLanguage,
                          consentToolConfiguration: CMPConsentToolConfiguration,
                          showConsentToolWhenLimitedAdTracking: Bool = CMPConsentManager.DEFAULT_LAT_VALUE) {
        // Check that we did not already configure, log error and stop if already configured
        if self.configured {
            logErrorMessage("CMPConsentManager is already configured for this session. You cannot reconfigure.")
            return;
        }
        
        // Change configuration status
        self.configured = true
        
        // Language
        self.language = language
        
        // Presentation interval
        self.presentationInterval = presentationInterval
        
        // Consent Tool
        self.consentToolConfiguration = consentToolConfiguration
        self.showConsentToolIfLAT = showConsentToolWhenLimitedAdTracking
        
        // Instantiate CPMVendorsManager with URL and RefreshTime and delegate
        self.vendorListManager = CMPVendorListManager(url: CMPVendorListURL(language: language), refreshInterval: CMPConsentManager.DEFAULT_VENDORLIST_REFRESH_INTERVAL, delegate: self)
        
        // Instantiate CPMEditorManager with URL and RefreshTime and delegate
        self.editorManager = CMPEditorManager(url: CMPEditorURL(language: language), refreshInterval: CMPConsentManager.DEFAULT_EDITOR_REFRESH_INTERVAL, delegate: self)

        // Check for already existing consent string in NSUserDefaults
        if let storedConsentString = managerState.consentString() {
            self.consentString = CMPConsentString.from(base64: storedConsentString)
        }
        
        // Registering for application lifecycle events to allow the CMP to stop automatic monitoring when the app goes in background
        registerApplicationLifecycleNotifications()
        
        // Starting the automatic vendor list monitoring by default
        startVendorListMonitoring()
        
        // Starting the automatic editor monitoring by default
        startEditorMonitoring()
    }

    /**
     Forces an immediate refresh of the vendors list.
     */
    @objc
    public func refreshVendorsList() {
        // Log error and stop if configuration is not made
        if !configured {
            logErrorMessage("CMPConsentManager is not configured for this session. Please call CMPConsentManager.shared.configure() first.")
            return;
        }
        
        // Refresh vendor list
        vendorListManager?.refresh(forceRefresh: true);
    }

    /**
     Forces an immediate refresh of the editor.
     */
    @objc
    public func refreshEditor() {
        // Log error and stop if configuration is not made
        if !configured {
            logErrorMessage("CMPConsentManager is not configured for this session. Please call CMPConsentManager.shared.configure() first.")
            return;
        }
        
        // Refresh vendor list
        editorManager?.refresh(forceRefresh: true);
    }

    /**
     Present the consent tool UI modally.
     
     Note: the consent tool will not be displayed if
     
     - you haven't called the configure() method first
     - the consent tool is already displayed
     - the vendor list has not been retrieved yet (or can't be retrieved for the moment).
     
     If you want to check if the consent tool will be displayed without issue before actually displaying
     it, you can use the method canShowConsentTool().
     
     - Parameter controller: The UIViewController instance which should present the consent tool UI.
     - Returns: true if the consent tool has been displayed properly, false if it can't be displayed.
     */
    @objc
    public func showConsentTool(fromController controller: UIViewController) -> Bool {
        // Log error and stop if configuration is not made
        guard self.configured else {
            logErrorMessage("CMPConsentManager is not configured for this session. Please call CMPConsentManager.shared.configure() first.")
            return false;
        }
        
        guard !self.consentToolIsShown else {
            logErrorMessage("CMPConsentManager is already showing the consent tool view controller.")
            return false;
        }
        
        guard let lastVendorList = self.vendorList else {
            logErrorMessage("CMPConsentManager cannot show consent tool as no vendor list is available. Please wait.")
            return false;
        }
        
        guard let lastEditor = self.editor else {
            logErrorMessage("CMPConsentManager cannot show consent tool as no editor is available. Please wait.")
            return false;
        }
        
        // If there is a previous consent string & a previous vendor list, this consent string must be migrated
        // before displaying the consent tool so the new vendors/purposes are initialized properly
        migrateConsentStringIfNeeded()
        
        // If there is a previous consent string & a previous editor, this consent string must be migrated
        // before displaying the consent tool so the new editor/purposes are initialized properly
        migrateConsentStringEditorIfNeeded()

        // Consider consent tool as shown
        self.consentToolIsShown = true
        
        // Instantiate consent tool manager from vendor list and current consent
        let manager = CMPConsentToolManager(delegate: self, language: self.language, consentString: self.consentString, editor: lastEditor, vendorList: lastVendorList, configuration: self.consentToolConfiguration!)
        self.consentToolManager = manager
        manager.showConsentTool(fromController: controller)
        
        return true
    }
    
    /**
     Check if the consent tool can be presented.
     
     Note: the consent tool cannot be displayed if
     
     - you haven't called the configure() method first
     - the consent tool is already displayed
     - the vendor list has not been retrieved yet (or can't be retrieved for the moment).
     
     - Returns: true if presenting the consent tool with the showConsentTool() method will be successful, false if it will fail.
     */
    @objc
    public func canShowConsentTool() -> Bool {
        return self.configured && !self.consentToolIsShown && self.vendorList != nil && self.editor != nil;
    }
    
    /**
     Add all purposes consents for the current consent string if it is already defined, create a new consent string with full consent otherwise.
     
     - Returns: true if the modification has been done successfully, false otherwise.
     */
    @objc
    public func allowAllPurposes() -> Bool {
        return modifyAllPurposes { previousConsentString, lastEditor, lastVendorList in
            if let consentString = previousConsentString {
                return CMPConsentString.consentStringWithAllPurposesConsent(fromConsentString: consentString, consentScreen: 0, consentLanguage: language, editor: lastEditor, vendorList: lastVendorList)
            } else {
                return CMPConsentString.consentStringWithFullConsent(consentScreen: 0, consentLanguage: language, editor: lastEditor, vendorList: lastVendorList)
            }
        }
    }
    
    /**
     Remove all purposes consents for the current consent string if it is already defined, create a new consent string with full vendors consent and no purposes consent otherwise.
     
     - Returns: true if the modification has been done successfully, false otherwise.
     */
    @objc
    public func revokeAllPurposes() -> Bool {
        return modifyAllPurposes { previousConsentString, lastEditor, lastVendorList in
            if let consentString = previousConsentString {
                return CMPConsentString.consentStringWithNoPurposesConsent(fromConsentString: consentString, consentScreen: 0, consentLanguage: language, editor: lastEditor, vendorList: lastVendorList)
            } else {
                let newConsentString = CMPConsentString.consentStringWithFullConsent(consentScreen: 0, consentLanguage: language, editor: lastEditor, vendorList: lastVendorList)
                return CMPConsentString.consentStringWithNoPurposesConsent(fromConsentString: newConsentString, consentScreen: 0, consentLanguage: language, editor: lastEditor, vendorList: lastVendorList)
            }
        }
    }
    
    /**
     Modify all purposes consents for the current consent string if it is already defined, create a new consent string with full consent otherwise.
     
     - Parameter modificationHandler: A function that will returned the modified consent string.
     - Returns: true if the modification has been done successfully, false otherwise.
     */
    internal func modifyAllPurposes(modificationHandler: ((CMPConsentString?, CMPEditor, CMPVendorList) -> CMPConsentString?)) -> Bool {
        // Log error and stop if configuration is not made
        guard self.configured else {
            logErrorMessage("CMPConsentManager is not configured for this session. Please call CMPConsentManager.shared.configure() first.")
            return false;
        }
        
        guard let lastVendorList = self.vendorList else {
            logErrorMessage("Purposes can't be modified because the vendor list is not available or up-to-date.")
            return false;
        }
        
        guard let lastEditor = self.editor else {
            logErrorMessage("Purposes can't be modified because the editor is not available or up-to-date.")
            return false;
        }
        
        guard let newConsentString = modificationHandler(consentString, lastEditor, lastVendorList) else {
            logErrorMessage("Purposes can't be modified because the vendor list and/or editor is not available or up-to-date.")
            return false
        }
        
        self.consentString = newConsentString
        return true
    }
    
    // MARK: - Automatic vendor list monitoring management
    
    /**
     Start the vendor list monitoring.
     */
    internal func startVendorListMonitoring() {
        vendorListManager?.startRefreshTimer()
    }
    
    /**
     Stop the vendor list monitoring.
     */
    internal func stopVendorListMonitoring() {
        vendorListManager?.stopRefreshTimer()
    }
    
    // MARK: - Automatic editor monitoring management
    
    /**
     Start the editor monitoring.
     */
    internal func startEditorMonitoring() {
        editorManager?.startRefreshTimer()
    }
    
    /**
     Stop the editor monitoring.
     */
    internal func stopEditorMonitoring() {
        editorManager?.stopRefreshTimer()
    }
    
    // MARK: - Application lifecycle notifications
    
    /**
     Register the consent manager has an observer for application lifecycle notifications.
     */
    internal func registerApplicationLifecycleNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground(notification:)),
                                               name: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: UIApplication.shared)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground(notification:)),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: UIApplication.shared)
    }
    
    /**
     Unregister the consent manager has an observer for application lifecycle notifications.
     */
    internal func unregisterApplicationLifecycleNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: UIApplication.shared)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: UIApplication.shared)
    }
    
    /**
     Method called when the application will enter foreground state.
     
     - Parameter notification: The 'application will enter foreground' notification emitted by iOS.
     */
    @objc
    func applicationWillEnterForeground(notification: Notification) {
        startVendorListMonitoring()
        startEditorMonitoring()
    }
    
    /**
     Method called when the application did enter background state.
     
     - Parameter notification: The 'application did enter background' notification emitted by iOS.
     */
    @objc
    func applicationDidEnterBackground(notification: Notification) {
        stopVendorListMonitoring()
        stopEditorMonitoring()
    }
    
    // MARK: - CMPVendorListManagerDelegate
    
    func vendorListManager(_ vendorListManager: CMPVendorListManager, didFailWithError error: Error) {
        logErrorMessage("CMPConsentManager cannot retrieve vendors list because of an error \"\(error.localizedDescription)\" a new attempt will be made later.")
        return;
    }
    
    func vendorListManager(_ vendorListManager: CMPVendorListManager, didFetchVendorList vendorList: CMPVendorList) {
        self.vendorList = vendorList
        
        // Consent string exist
        if let storedConsentString = self.consentString {
            // Consent string has a different version than vendor list, ask for consent tool display
            if storedConsentString.vendorListVersion != vendorList.vendorListVersion {
                // Fetching the old vendor list to migrate the consent string:
                // Old purposes & vendors must keep their values, new one will be considered as accepted by default
                vendorListManager.refresh(vendorListURL: CMPVendorListURL(version: storedConsentString.vendorListVersion)) { previousVendorList, error in
                    if let error = error {
                        self.logErrorMessage("CMPConsentManager cannot retrieve previous vendors list because of an error \"\(error.localizedDescription)\"")
                    } else if let previousVendorList = previousVendorList {
                        // The previous vendor list is stored
                        self.previousVendorList = previousVendorList
                        
                        // Don't display the consent tool immediately if the presentation interval isn't elapsed
                        guard self.isPresentationIntervalElapsed else {
                            return;
                        }
                        
                        DispatchQueue.main.async {
                            // Display consent tool
                            self.handleVendorListChanged(vendorList)
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                // Consent string does not exist, ask for consent tool display
                self.handleVendorListChanged(vendorList)
            }
        }
    }
    
    
    // MARK: - CMPEditorManagerDelegate
    
    func editorManager(_ editorManager: CMPEditorManager, didFailWithError error: Error) {
        logErrorMessage("CMPConsentManager cannot retrieve editor because of an error \"\(error.localizedDescription)\" a new attempt will be made later.")
        return;
    }
    
    func editorManager(_ editorManager: CMPEditorManager, didFetchEditor editor: CMPEditor) {
        self.editor = editor
        
        // Consent string exist
        if let storedConsentString = self.consentString {
            // Consent string has a different version than editor, ask for consent tool display
            if storedConsentString.editorVersion != editor.editorVersion {
                // Fetching the old vendor list to migrate the consent string:
                // Old purposes & vendors must keep their values, new one will be considered as accepted by default
                editorManager.refresh(editorURL: CMPEditorURL(version: storedConsentString.editorVersion)) { previousEditor, error in
                    if let error = error {
                        self.logErrorMessage("CMPConsentManager cannot retrieve previous editor because of an error \"\(error.localizedDescription)\"")
                    } else if let previousEditor = previousEditor {
                        // The previous editor is stored
                        self.previousEditor = previousEditor
                        
                        // Don't display the consent tool immediately if the presentation interval isn't elapsed
                        guard self.isPresentationIntervalElapsed else {
                            return;
                        }
                        
                        DispatchQueue.main.async {
                            // Display consent tool
                            self.handleEditorChanged(editor)
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                // Consent string does not exist, ask for consent tool display
                self.handleEditorChanged(editor)
            }
        }
    }
    
    // MARK: - CMPConsentToolManagerDelegate
    
    func consentToolManager(_ consentToolManager: CMPConsentToolManager, didFinishWithConsentString consentString: CMPConsentString) {
        self.consentToolIsShown = false
        if self.consentString != consentString {
            self.consentString = consentString
        }
    }
    
    // MARK: - Trigger Consent Tool Display
    
    /**
     Handle the reception of a new vendor list. Calling this method will either:
     
     - show the consent tool manager (if we don't have any delegate),
     - call the delegate with the new vendor list,
     - generate an consent string without any consent if 'limited ad tracking' is enabled and the CMP is configured to handle it itself.
     
     - Parameter vendorList: The newly retrieved vendor list.
     */
    private func handleVendorListChanged(_ vendorList: CMPVendorList) {
        // Checking the 'Limited Ad Tracking' status of the device
        let isTrackingAllowed = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        
        // If the 'Limited Ad Tracking' is disabled on the device, or if the 'Limited Ad Tracking' is enabled but the publisher
        // wants to handle this option himself…
        if isTrackingAllowed || self.showConsentToolIfLAT {
            // If there is a previous consent string & a previous vendor list, this consent string must be migrated
            // before displaying the consent tool so the new vendors/purposes are initialized properly
            migrateConsentStringIfNeeded()
            
            if let delegate = self.delegate {
                // The delegate is called so the publisher can ask for user's consent
                delegate.consentManagerRequestsToShowConsentTool(self, forVendorList: vendorList)
            } else {
                // There is no delegate so the CMP will ask for user's consent automatically
                if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                    let _ = showConsentTool(fromController: viewController)
                }
            }
            
            // Persistent save of the last presentation date to avoid spamming the user with the consent tool
            managerState.saveLastPresentationDate(Date())
        } else {
            // If 'Limited Ad Tracking' is enabled and the publisher don't want to handle it himself, a consent string with no
            // consent (for all vendors / purposes) is generated and stored.
            self.consentString = CMPConsentString.consentStringWithNoConsent(consentScreen: 0, consentLanguage: self.language, editor: self.editor!, vendorList: vendorList, date: Date())
        }
    }
    
    /**
     Handle the reception of a new editor. Calling this method will either:
     
     - show the consent tool manager (if we don't have any delegate),
     - call the delegate with the new editor,
     - generate an consent string without any consent if 'limited ad tracking' is enabled and the CMP is configured to handle it itself.
     
     - Parameter editor: The newly retrieved editor.
     */
    private func handleEditorChanged(_ editor: CMPEditor) {
        // Checking the 'Limited Ad Tracking' status of the device
        let isTrackingAllowed = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        
        // If the 'Limited Ad Tracking' is disabled on the device, or if the 'Limited Ad Tracking' is enabled but the publisher
        // wants to handle this option himself…
        if isTrackingAllowed || self.showConsentToolIfLAT {
            // If there is a previous consent string & a previous editor, this consent string must be migrated
            // before displaying the consent tool so the new editor/purposes are initialized properly
            migrateConsentStringEditorIfNeeded()
            
            if let delegate = self.delegate {
                // The delegate is called so the publisher can ask for user's consent
                delegate.consentManagerRequestsEditorToShowConsentTool(self, forEditor: editor)
            } else {
                // There is no delegate so the CMP will ask for user's consent automatically
                if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                    let _ = showConsentTool(fromController: viewController)
                }
            }
            
            // Persistent save of the last presentation date to avoid spamming the user with the consent tool
            managerState.saveLastPresentationDate(Date())
        } else {
            // If 'Limited Ad Tracking' is enabled and the publisher don't want to handle it himself, a consent string with no
            // consent (for all vendors / purposes) is generated and stored.
            self.consentString = CMPConsentString.consentStringWithNoConsent(consentScreen: 0, consentLanguage: self.language, editor: editor, vendorList: self.vendorList!, date: Date())
        }
    }

    /**
     Migrate the current consent string to the current vendor list.
     
     This method is useful when the current consent string used by the manager has been generated using a previousVendorList
     but when a new vendorList is available. In this case, we want to upgrade the consent string version and add the new purposes
     and vendors into the string.
     
     If the consent string is migrated, the previousVendorList will be set to nil to indicates that no more migration are required.
     
     Note: this method will always check that the migration is actually needed so it can called without issue from anywhere.
     */
    private func migrateConsentStringIfNeeded() {
        if let storedConsentString = self.consentString,
            let previousVendorList = self.previousVendorList,
            let vendorList = self.vendorList,
            storedConsentString.vendorListVersion != vendorList.vendorListVersion
                && storedConsentString.vendorListVersion == previousVendorList.vendorListVersion {

            // Generate the updated consent string
            self.consentString = CMPConsentString.consentString(fromUpdatedVendorList: vendorList,
                                                                previousVendorList: previousVendorList,
                                                                previousConsentString: storedConsentString,
                                                                consentLanguage: self.language)
        }

        // Since the consent string has been updated, the previous vendor list is not needed anymore
        self.previousVendorList = nil
    }
    
    /**
     Migrate the current consent string to the current editor.
     
     This method is useful when the current consent string used by the manager has been generated using a previousEditor
     but when a new editor is available. In this case, we want to upgrade the consent string version and add the new purposes
      into the string.
     
     If the consent string is migrated, the previousEditor will be set to nil to indicates that no more migration are required.
     
     Note: this method will always check that the migration is actually needed so it can called without issue from anywhere.
     */
    private func migrateConsentStringEditorIfNeeded() {
        if let storedConsentString = self.consentString,
            let previousEditor = self.previousEditor,
            let editor = self.editor,
            storedConsentString.editorVersion != editor.editorVersion
                && storedConsentString.editorVersion == previousEditor.editorVersion {
            
            // Generate the updated consent string
            self.consentString = CMPConsentString.consentString(fromUpdatedEditor: editor,
                                                                previousEditor: previousEditor,
                                                                previousConsentString: storedConsentString,
                                                                consentLanguage: self.language)
        }
        
        // Since the consent string has been updated, the previous editor is not needed anymore
        self.previousEditor = nil
    }

    // MARK: - Variables changes
    
    /**
     Method called when the GDPR status variable has changed.
     */
    private func gdrpStatusChanged() {
        managerState.saveGDPRStatus(self.subjectToGDPR)
    }
    
    /**
     Method called when the consent string has changed.
     */
    private func consentStringChanged() {
        guard let newConsentString = consentString else {
            return;
        }
        
        managerState.saveConsentString(newConsentString.consentString)
        managerState.saveIABConsentString(newConsentString.iabConsentString)
        managerState.saveVendorConsentString(newConsentString.parsedVendorConsents)
        managerState.savePurposeConsentString(newConsentString.parsedPurposeConsents)
        managerState.saveAdvertisingConsentStatus(forConsentString: newConsentString)
    }
        
    // MARK: - Utils - Error Display
    
    /**
     Log an error message in Xcode console.
 
     - Parameter message: The message that will be logged.
     */
    private func logErrorMessage(_ message: String) {
        NSLog("[ERROR] FidzupCMP: \(message)")
    }
    
}
