//
//  CMPConsentToolManager.swift
//  FidzupCMP
//
//  Created by Thomas Geley on 26/04/2018.
//  Copyright © 2018 Smart AdServer.
//
//  This software is distributed under the Creative Commons Legal Code, Attribution 3.0 Unported license.
//  Check the LICENSE file for more information.
//

import Foundation

/**
 UI manager to ask for user consent.
 */
internal class CMPConsentToolManager {
    
    // MARK: - Private fields
    
    /// CMPConsentToolManager delegate.
    private weak var delegate: CMPConsentToolManagerDelegate?
    
    /// Language.
    private let language: CMPLanguage
    
    /// Initial consent string.
    private let initialConsentString: CMPConsentString
    
    /// Generated consent string.
    private var generatedConsentString: CMPConsentString 
    
    /// Editor.
    private let editor: CMPEditor
    
    /// Vendor list.
    private let vendorList: CMPVendorList

    /// Current view controller.
    private var presentingViewController: UIViewController?
    
    /// Consent tool configuration.
    internal let configuration: CMPConsentToolConfiguration
    
    // MARK: - Initialization
    
    /**
     Initialize a new instance of CMPConsentToolManager.
     
     - Parameters:
        - delegate: An instance of CMPConsentToolManagerDelegate.
        - language: The language in which the consent will be given.
        - consentString: The previous consent string if any.
        - editor: The editor.
        - vendorList: The vendor list.
        - configuration: The consent tool configuration.
     */
    public init(delegate: CMPConsentToolManagerDelegate,
                language: CMPLanguage,
                consentString: CMPConsentString?,
                editor: CMPEditor,
                vendorList: CMPVendorList,
                configuration: CMPConsentToolConfiguration) {
        
        self.delegate = delegate
        self.language = language
        self.editor = editor
        self.vendorList = vendorList
        self.configuration = configuration
        
        if let consentString = consentString {
            self.initialConsentString = consentString
            self.generatedConsentString = consentString.copy() as! CMPConsentString
        } else {
            self.initialConsentString = CMPConsentString.consentStringWithFullConsent(consentScreen: 1, consentLanguage: self.language, editor: self.editor, vendorList: self.vendorList)
            self.generatedConsentString = self.initialConsentString.copy() as! CMPConsentString
        }
    }
    
    // MARK: - Show / Hide UI
    
    /**
     Show the consent tool.
     
     - Parameter controller: The UIViewController instance which should present the consent tool UI.
     */
    func showConsentTool(fromController controller: UIViewController) {
        guard self.presentingViewController == nil else {
            return;
        }
        
        // Instantiate consent tool UI
        let storyboard = UIStoryboard(name: "CMPConsentTool", bundle: Bundle(for: type(of: self)))
        let consentToolController: CMPConsentToolPreferencesViewController = storyboard.instantiateViewController(withIdentifier: "CMPConsentToolPreferencesViewController") as! CMPConsentToolPreferencesViewController
        consentToolController.consentToolManager = self
        
        let navController: UINavigationController = UINavigationController(rootViewController: consentToolController)
        
        // Present Consent Tool VC
        self.presentingViewController = controller
        controller.present(navController, animated: true, completion: nil)
    }
    
    /**
     Dismiss the consent tool. The current consent string will be saved or discarded depending of the 'save' parameter.
     
     - Parameter save: true if the current consent string must be saved, false if it needs to be discarded.
     */
    func dismissConsentTool(save: Bool) {
        guard let viewController = self.presentingViewController else {
            return;
        }
        
        viewController.dismiss(animated: true) {
            self.delegate?.consentToolManager(self, didFinishWithConsentString: save ? self.generatedConsentString : self.initialConsentString)
        }
    }
    
    /**
     Dismiss the consent tool after accepting all purposes.
     */
    func acceptAllPurposesAndCloseConsentTool() {
        guard let viewController = self.presentingViewController else {
            return;
        }
        self.generatedConsentString = CMPConsentString.consentStringWithFullConsent(consentScreen: self.initialConsentString.consentScreen,
                                                                                    consentLanguage: self.initialConsentString.consentLanguage,
                                                                                    editor: editor,
                                                                                    vendorList: vendorList)
    
        viewController.dismiss(animated: true) {
            self.delegate?.consentToolManager(self, didFinishWithConsentString: self.generatedConsentString)
        }
    }
    
    /**
     Dismiss the consent tool after revoking all purposes.
     */
    func revokeAllPurposesAndCloseConsentTool() {
        guard let viewController = self.presentingViewController else {
            return;
        }
    
        self.generatedConsentString = CMPConsentString.consentStringWithNoConsent(consentScreen: self.initialConsentString.consentScreen,
                                                                                    consentLanguage: self.initialConsentString.consentLanguage,
                                                                                    editor: editor,
                                                                                    vendorList: vendorList)
        viewController.dismiss(animated: true) {
            self.delegate?.consentToolManager(self, didFinishWithConsentString: self.generatedConsentString)
        }
    }
    
    /**
     Reset the generated consent string to the initial consent string without saving.
     */
    func reset() {
        self.generatedConsentString = self.initialConsentString.copy() as! CMPConsentString
    }
    
    
    // MARK: - TableView DataSource
    
    /// The number of activated (ie not deleted) vendors.
    var activatedVendorCount: Int {
        return self.vendorList.activatedVendorCount;
    }
    
    /// The activated vendors.
    var activatedVendors: [CMPVendor] {
        return self.vendorList.activatedVendors;
    }
    
    /// The number of allowed vendors among activated ones.
    var allowedVendorCount: Int {
        var count = 0
        for vendor in self.vendorList.activatedVendors {
            if generatedConsentString.isVendorAllowed(vendorId: vendor.id) {
                count = count + 1
            }
        }
        return count
    }
    
    /**
     Check if a vendor is allowed.
     
     - Parameter vendor: The vendor to be checked.
     - Returns: true if the vendor is allowed, false otherwise.
     */
    func isVendorAllowed(_ vendor: CMPVendor) -> Bool {
        return generatedConsentString.isVendorAllowed(vendorId: vendor.id)
    }
    
    /// The number of purposes.
    var purposesCount: Int {
        return self.vendorList.purposes.count
    }
    
    /// The number of editor purposes.
    var editorPurposesCount: Int {
        return self.editor.purposes.count
    }

    /**
     Return the purpose by index.
     
     - Parameter index: The index.
     - Returns: The purpose if any, nil otherwise.
     */
    func purposeAtIndex(_ index: Int) -> CMPPurpose? {
        guard index < purposesCount else {
            return nil
        }
        
        return self.vendorList.purposes[index]
    }

    /**
     Return the editor purpose by index.
     
     - Parameter index: The index.
     - Returns: The purpose if any, nil otherwise.
     */
    func editorPurposeAtIndex(_ index: Int) -> CMPPurpose? {
        guard index < editorPurposesCount else {
            return nil
        }
        
        return self.editor.purposes[index]
    }

    /**
     Check if a purpose is allowed.
     
     - Parameter purpose: The purpose to be checked.
     - Returns: true if the purpose is allowed, false otherwise.
     */
    func isPurposeAllowed(_ purpose: CMPPurpose) -> Bool {
        return generatedConsentString.isPurposeAllowed(purposeId: purpose.id)
    }

    /**
     Check if an editor purpose is allowed.
     
     - Parameter purpose: The purpose to be checked.
     - Returns: true if the purpose is allowed, false otherwise.
     */
    func isEditorPurposeAllowed(_ purpose: CMPPurpose) -> Bool {
        return generatedConsentString.isEditorPurposeAllowed(purposeId: purpose.id)
    }

    // MARK: - Manipulate purpose and vendors
    
    /**
     Change the purpose consent by index.
     
     - Parameters:
        - index: The index of the purpose to be changed.
        - consent: true if consent must be added for the purpose, false to remove the consent.
     */
    func changePurposeConsent(index: Int, consent: Bool) {
        guard let purpose = purposeAtIndex(index) else {
            return
        }
        
        if consent {
            addConsentForPurpose(id: purpose.id)
        } else {
            removeConsentForPurpose(id: purpose.id)
        }
    }
    
    /**
     Change the purpose consent.
     
     - Parameters:
        - purpose: The purpose to be changed.
        - consent: true if consent must be added for the purpose, false to remove the consent.
     */
    func changePurposeConsent(_ purpose: CMPPurpose, consent: Bool) {
        if consent {
            addConsentForPurpose(id: purpose.id)
        } else {
            removeConsentForPurpose(id: purpose.id)
        }
    }    
    
    /**
     Change the editor purpose consent by index.
     
     - Parameters:
     - index: The index of the purpose to be changed.
     - consent: true if consent must be added for the purpose, false to remove the consent.
     */
    func changeEditorPurposeConsent(index: Int, consent: Bool) {
        guard let purpose = editorPurposeAtIndex(index) else {
            return
        }
        
        if consent {
            addConsentForEditorPurpose(id: purpose.id)
        } else {
            removeConsentForEditorPurpose(id: purpose.id)
        }
    }
    
    /**
     Change the editor purpose consent.
     
     - Parameters:
     - purpose: The purpose to be changed.
     - consent: true if consent must be added for the purpose, false to remove the consent.
     */
    func changeEditorPurposeConsent(_ purpose: CMPPurpose, consent: Bool) {
        if consent {
            addConsentForEditorPurpose(id: purpose.id)
        } else {
            removeConsentForEditorPurpose(id: purpose.id)
        }
    }

    /**
     Change the vendor consent.
     
     - Parameters:
        - vendor: The the vendor to be changed.
        - consent: true if consent must be added for the vendor, false to remove the consent.
     */
    func changeVendorConsent(_ vendor: CMPVendor, consent: Bool) {
        if consent {
            addConsentForVendor(id: vendor.id)
        } else {
            removeConsentForVendor(id: vendor.id)
        }
    }
    
    /**
     Give consent for a purpose by id.
     
     - Parameter id: The purpose id.
     */
    func addConsentForPurpose(id: Int) {
        guard !generatedConsentString.isPurposeAllowed(purposeId: id) else {
            return
        }
        
        // Generate new consent string
        self.generatedConsentString = CMPConsentString.consentStringByAddingConsent(forPurposeId: id, consentString: self.generatedConsentString, consentLanguage: language, lastUpdated: Date())
    }
    
    /**
     Remove consent for a purpose by id.
     
     - Parameter id: The purpose id.
     */
    func removeConsentForPurpose(id: Int) {
        guard generatedConsentString.isPurposeAllowed(purposeId: id) else {
            return
        }
        
        // Generate new consent string
        self.generatedConsentString = CMPConsentString.consentStringByRemovingConsent(forPurposeId: id, consentString: self.generatedConsentString, consentLanguage: language, lastUpdated: Date())
        
    }
    
    /**
     Give consent for an editor purpose by id.
     
     - Parameter id: The purpose id.
     */
    func addConsentForEditorPurpose(id: Int) {
        guard !generatedConsentString.isEditorPurposeAllowed(purposeId: id) else {
            return
        }
        
        // Generate new consent string
        self.generatedConsentString = CMPConsentString.consentStringByAddingConsent(forEditorPurposeId: id, consentString: self.generatedConsentString, consentLanguage: language, lastUpdated: Date())
    }
    
    /**
     Remove consent for an editor purpose by id.
     
     - Parameter id: The purpose id.
     */
    func removeConsentForEditorPurpose(id: Int) {
        guard generatedConsentString.isEditorPurposeAllowed(purposeId: id) else {
            return
        }
        
        // Generate new consent string
        self.generatedConsentString = CMPConsentString.consentStringByRemovingConsent(forEditorPurposeId: id, consentString: self.generatedConsentString, consentLanguage: language, lastUpdated: Date())
        
    }

    /**
     Give consent for a vendor by id.
     
     - Parameter id: The vendor id.
     */
    func addConsentForVendor(id: Int) {
        guard !generatedConsentString.isVendorAllowed(vendorId: id) else {
            return
        }

        // Generate new consent string
        self.generatedConsentString = CMPConsentString.consentStringByAddingConsent(forVendorId: id, consentString: self.generatedConsentString, consentLanguage: language, lastUpdated: Date())
        
    }
    
    /**
     Remove consent for a vendor by id.
     
     - Parameter id: The vendor id.
     */
    func removeConsentForVendor(id: Int) {
        guard generatedConsentString.isVendorAllowed(vendorId: id) else {
            return
        }
        
        // Generate new consent string
        self.generatedConsentString = CMPConsentString.consentStringByRemovingConsent(forVendorId: id, consentString: self.generatedConsentString, consentLanguage: language, lastUpdated: Date())
    }
    
    // MARK: - Utils
    
    /**
     Retrieve the purpose name from id.
     
     - Parameter id: The purpose id.
     - Returns: The purpose name if the id is valid, nil otherwise.
     */
    func purposeName(forId id: Int) -> String? {
        return vendorList.purposeName(forId: id)
    }
    
    /**
     Retrieve the feature name from id.
     
     - Parameter id: The feature id.
     - Returns: The feature name if the id is valid, nil otherwise.
     */
    func featureName(forId id: Int) -> String? {
        return vendorList.featureName(forId: id)
    }
    
    /**
     Retrieve the vendor name from id.
     
     - Parameter id: The vendor id.
     - Returns: The vendor name if the id is valid, nil otherwise.
     */
    func vendorName(forId id: Int) -> String? {
        return vendorList.vendorName(forId: id)
    }
    
}
