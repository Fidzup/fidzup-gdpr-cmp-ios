//
//  CMPConsentString.swift
//  FidzupCMP
//
//  Created by Loïc GIRON DIT METAZ on 24/04/2018.
//  Copyright © 2018 Smart AdServer.
//
//  This software is distributed under the Creative Commons Legal Code, Attribution 3.0 Unported license.
//  Check the LICENSE file for more information.
//

import Foundation

/**
 Representation of an Global consent string (you can also grab a subset to get the IAB Consent String)
 */
@objc
public class CMPConsentString: NSObject, NSCopying {
    
    /// The type of encoding of the consent string.
    internal enum ConsentEncoding {
        
        /// Bitfield or range encoding, depending of the most efficient solution.
        case automatic
        
        /// Bitfield encoding.
        case bitfield
        
        /// Range encoding.
        case range
    }
    
    /// The consent string version.
    @objc
    public let version: Int
    
    /// The consent string version configuration.
    private let versionConfig: CMPVersionConfig
    
    /// The date of the first consent string creation.
    @objc
    public let created: Date
    
    /// The date of the last consent string update.
    @objc
    public let lastUpdated: Date
    
    /// The id of the last Consent Manager Provider that updated the consent string.
    @objc
    public let cmpId: Int
    
    /// The version of the Consent Manager Provider.
    @objc
    public let cmpVersion: Int
    
    /// The screen number in the CMP where the consent was given.
    @objc
    public let consentScreen: Int
    
    /// The language that the CMP asked for consent in.
    @objc
    public let consentLanguage: CMPLanguage
    
    /// The version of the editor used in the most recent consent string update.
    @objc
    public let editorVersion: Int

    /// The version of the vendor list used in the most recent consent string update.
    @objc
    public let vendorListVersion: Int
    
    /// The maximum vendor id that can be found in the current vendor list.
    @objc
    public let maxVendorId: Int
    
    /// An array of editor purposes id.
    @objc
    public let editorPurposes: IndexSet

    /// An array of allowed purposes id.
    @objc
    public let allowedPurposes: IndexSet
    
    /// An array of allowed vendors id.
    @objc
    public let allowedVendors: IndexSet
    
    /// The base64 representation of the consent string.
    @objc
    public let consentString: String
    
    /// The base64 representation of the iab consent string.
    @objc
    public let iabConsentString: String
    
    /// The 'parsed editor purpose consents' string that can be stored in the GlobalConsent_ParsedEditorPurposeConsents key.
    @objc
    public var parsedEditorPurposeConsents: String {
        return (1...versionConfig.editorPurposesBitSize).map { editorPurposes.contains($0) ? "1" : "0" }.joined()
    }

    /// The 'parsed purpose consents' string that can be stored in the IABConsent_ParsedPurposeConsents key.
    @objc
    public var parsedPurposeConsents: String {
        return (1...versionConfig.allowedPurposesBitSize).map { allowedPurposes.contains($0) ? "1" : "0" }.joined()
    }

    /// The 'parsed vendor consents' string that can be stored in the IABConsent_ParsedVendorConsents key.
    @objc
    public var parsedVendorConsents: String {
        return (1...maxVendorId).map { allowedVendors.contains($0) ? "1" : "0" }.joined()
    }
    
    /**
     Initialize a new instance of CMPConsentString from a vendor list and an editor.
     
     - Parameters:
         - version: The consent string version.
         - created: The date of the first consent string creation.
         - lastUpdated: The date of the last consent string update.
         - cmpId: The id of the last Consent Manager Provider that updated the consent string.
         - cmpVersion: The version of the Consent Manager Provider.
         - consentScreen: The screen number in the CMP where the consent was given.
         - consentLanguage: The language that the CMP asked for consent in.
         - editorPurposes: An array of editor purposes id.
         - allowedPurposes: An array of allowed purposes id.
         - allowedVendors: An array of allowed vendors id.
         - editor: The editor corresponding to the consent string.
         - vendorList: The vendor list corresponding to the consent string.
     - Returns: A new instance of CMPConsentString if version is valid, nil otherwise.
     */
    @objc
    public convenience init?(version: Int,
                             created: Date,
                             lastUpdated: Date,
                             cmpId: Int,
                             cmpVersion: Int,
                             consentScreen: Int,
                             consentLanguage: CMPLanguage,
                             editorPurposes: IndexSet,
                             allowedPurposes: IndexSet,
                             allowedVendors: IndexSet,
                             editor: CMPEditor,
                             vendorList: CMPVendorList) {
        
        if let versionConfig = CMPVersionConfig(version: version) {
            self.init(versionConfig: versionConfig,
                      created: created,
                      lastUpdated: lastUpdated,
                      cmpId: cmpId,
                      cmpVersion: cmpVersion,
                      consentScreen: consentScreen,
                      consentLanguage: consentLanguage,
                      editorVersion: editor.editorVersion,
                      vendorListVersion: vendorList.vendorListVersion,
                      maxVendorId: vendorList.maxVendorId,
                      editorPurposes: editorPurposes,
                      allowedPurposes: allowedPurposes,
                      allowedVendors: allowedVendors,
                      vendorListEncoding: .automatic)
        } else {
            return nil
        }
        
    }
    
    /**
     Initialize a new instance of CMPConsentString using a vendor list and an editor version,  and a max vendor id.
     
     - Parameters:
         - version: The consent string version.
         - created: The date of the first consent string creation.
         - lastUpdated: The date of the last consent string update.
         - cmpId: The id of the last Consent Manager Provider that updated the consent string.
         - cmpVersion: The version of the Consent Manager Provider.
         - consentScreen: The screen number in the CMP where the consent was given.
         - consentLanguage: The language that the CMP asked for consent in.
         - vendorListVersion: The version of the vendor list used in the most recent consent string update.
         - editorVersion: The version of the editor used in the most recent consent string update.
         - maxVendorId: The maximum vendor id that can be found in the current vendor list.
         - editorPurposes: An array of editor purposes id.
         - allowedPurposes: An array of allowed purposes id.
         - allowedVendors: An array of allowed vendors id.
     - Returns: A new instance of CMPConsentString if version is valid, nil otherwise.
     */
    @objc
    public convenience init?(version: Int,
                             created: Date,
                             lastUpdated: Date,
                             cmpId: Int,
                             cmpVersion: Int,
                             consentScreen: Int,
                             consentLanguage: CMPLanguage,
                             editorVersion: Int,
                             vendorListVersion: Int,
                             maxVendorId: Int,
                             editorPurposes: IndexSet,
                             allowedPurposes: IndexSet,
                             allowedVendors: IndexSet) {
        
        if let versionConfig = CMPVersionConfig(version: version) {
            self.init(versionConfig: versionConfig,
                      created: created,
                      lastUpdated: lastUpdated,
                      cmpId: cmpId,
                      cmpVersion: cmpVersion,
                      consentScreen: consentScreen,
                      consentLanguage: consentLanguage,
                      editorVersion: editorVersion,
                      vendorListVersion: vendorListVersion,
                      maxVendorId: maxVendorId,
                      editorPurposes: editorPurposes,
                      allowedPurposes: allowedPurposes,
                      allowedVendors: allowedVendors,
                      vendorListEncoding: .automatic)
        } else {
            return nil
        }
        
    }
    
    /**
     Initialize a new instance of CMPConsentString from a vendor list and an editor.
     
     - Parameters:
         - versionConfig: The consent string version configuration.
         - created: The date of the first consent string creation.
         - lastUpdated: The date of the last consent string update.
         - cmpId: The id of the last Consent Manager Provider that updated the consent string.
         - cmpVersion: The version of the Consent Manager Provider.
         - consentScreen: The screen number in the CMP where the consent was given.
         - consentLanguage: The language that the CMP asked for consent in.
         - allowedPurposes: An array of allowed purposes id.
         - allowedVendors: An array of allowed vendors id.
         - editor: The editor corresponding to the consent string.
         - vendorList: The vendor list corresponding to the consent string.
     */
    @objc
    public convenience init(versionConfig: CMPVersionConfig,
                            created: Date,
                            lastUpdated: Date,
                            cmpId: Int,
                            cmpVersion: Int,
                            consentScreen: Int,
                            consentLanguage: CMPLanguage,
                            editorPurposes: IndexSet,
                            allowedPurposes: IndexSet,
                            allowedVendors: IndexSet,
                            editor: CMPEditor,
                            vendorList: CMPVendorList) {
        
        self.init(versionConfig: versionConfig,
                  created: created,
                  lastUpdated: lastUpdated,
                  cmpId: cmpId,
                  cmpVersion: cmpVersion,
                  consentScreen: consentScreen,
                  consentLanguage: consentLanguage,
                  editorVersion: editor.editorVersion,
                  vendorListVersion: vendorList.vendorListVersion,
                  maxVendorId: vendorList.maxVendorId,
                  editorPurposes: editorPurposes,
                  allowedPurposes: allowedPurposes,
                  allowedVendors: allowedVendors,
                  vendorListEncoding: .automatic)
        
    }
    
    /**
     Initialize a new instance of CMPConsentString using a vendor list version and a max vendor id.
     
     - Parameters:
         - versionConfig: The consent string version configuration.
         - created: The date of the first consent string creation.
         - lastUpdated: The date of the last consent string update.
         - cmpId: The id of the last Consent Manager Provider that updated the consent string.
         - cmpVersion: The version of the Consent Manager Provider.
         - consentScreen: The screen number in the CMP where the consent was given.
         - consentLanguage: The language that the CMP asked for consent in.
         - vendorListVersion: The version of the vendor list used in the most recent consent string update.
         - maxVendorId: The maximum vendor id that can be found in the current vendor list.
         - allowedPurposes: An array of allowed purposes id.
         - allowedVendors: An array of allowed vendors id.
     */
    @objc
    public convenience init(versionConfig: CMPVersionConfig, // no
                            created: Date, // no
                            lastUpdated: Date, // no
                            cmpId: Int, // no
                            cmpVersion: Int, // no
                            consentScreen: Int, // yes
                            consentLanguage: CMPLanguage, // yes
                            editorVersion: Int, // editor
                            vendorListVersion: Int, // vendorList
                            maxVendorId: Int, // vendorList
                            editorPurposes: IndexSet, // no
                            allowedPurposes: IndexSet, // no
                            allowedVendors: IndexSet) { // no
        
        self.init(versionConfig: versionConfig,
                  created: created,
                  lastUpdated: lastUpdated,
                  cmpId: cmpId,
                  cmpVersion: cmpVersion,
                  consentScreen: consentScreen,
                  consentLanguage: consentLanguage,
                  editorVersion: editorVersion,
                  vendorListVersion: vendorListVersion,
                  maxVendorId: maxVendorId,
                  editorPurposes:editorPurposes,
                  allowedPurposes: allowedPurposes,
                  allowedVendors: allowedVendors,
                  vendorListEncoding: .automatic)
        
    }
    
    /**
     Initialize a new instance of CMPConsentString using a vendor list version and a max vendor id.
     
     - Parameters:
     - versionConfig: The consent string version configuration.
     - created: The date of the first consent string creation.
     - lastUpdated: The date of the last consent string update.
     - cmpId: The id of the last Consent Manager Provider that updated the consent string.
     - cmpVersion: The version of the Consent Manager Provider.
     - consentScreen: The screen number in the CMP where the consent was given.
     - consentLanguage: The language that the CMP asked for consent in.
     - vendorListVersion: The version of the vendor list used in the most recent consent string update.
     - maxVendorId: The maximum vendor id that can be found in the current vendor list.
     - allowedPurposes: An array of allowed purposes id.
     - allowedVendors: An array of allowed vendors id.
     */
    @objc
    public convenience init(versionConfig: CMPVersionConfig,
        created: Date,
        lastUpdated: Date,
        cmpId: Int,
        cmpVersion: Int,
        consentScreen: Int,
        consentLanguage: CMPLanguage,
        editorVersion: Int,
        editorPurposes: IndexSet,
        allowedPurposes: IndexSet,
        allowedVendors: IndexSet,
        vendorList: CMPVendorList) {
        
        self.init(versionConfig: versionConfig,
                  created: created,
                  lastUpdated: lastUpdated,
                  cmpId: cmpId,
                  cmpVersion: cmpVersion,
                  consentScreen: consentScreen,
                  consentLanguage: consentLanguage,
                  editorVersion: editorVersion,
                  vendorListVersion: vendorList.vendorListVersion,
                  maxVendorId: vendorList.maxVendorId,
                  editorPurposes: editorPurposes,
                  allowedPurposes: allowedPurposes,
                  allowedVendors: allowedVendors,
                  vendorListEncoding: .automatic)
        
    }
    
    /**
     Initialize a new instance of CMPConsentString using a vendor list version and a max vendor id.
     
     - Parameters:
     - versionConfig: The consent string version configuration.
     - created: The date of the first consent string creation.
     - lastUpdated: The date of the last consent string update.
     - cmpId: The id of the last Consent Manager Provider that updated the consent string.
     - cmpVersion: The version of the Consent Manager Provider.
     - consentScreen: The screen number in the CMP where the consent was given.
     - consentLanguage: The language that the CMP asked for consent in.
     - vendorListVersion: The version of the vendor list used in the most recent consent string update.
     - maxVendorId: The maximum vendor id that can be found in the current vendor list.
     - allowedPurposes: An array of allowed purposes id.
     - allowedVendors: An array of allowed vendors id.
     */
    @objc
    public convenience init(versionConfig: CMPVersionConfig,
                            created: Date,
                            lastUpdated: Date,
                            cmpId: Int,
                            cmpVersion: Int,
                            consentScreen: Int,
                            consentLanguage: CMPLanguage,
                            vendorListVersion: Int,
                            maxVendorId: Int,
                            editorPurposes: IndexSet,
                            allowedPurposes: IndexSet,
                            allowedVendors: IndexSet,
                            editor: CMPEditor) {
        
        self.init(versionConfig: versionConfig,
                  created: created,
                  lastUpdated: lastUpdated,
                  cmpId: cmpId,
                  cmpVersion: cmpVersion,
                  consentScreen: consentScreen,
                  consentLanguage: consentLanguage,
                  editorVersion: editor.editorVersion,
                  vendorListVersion: vendorListVersion,
                  maxVendorId: maxVendorId,
                  editorPurposes: editorPurposes,
                  allowedPurposes: allowedPurposes,
                  allowedVendors: allowedVendors,
                  vendorListEncoding: .automatic)
        
    }
    
    /**
     Initialize a new instance of CMPConsentString.
     
     - Parameters:
         - versionConfig: The consent string version configuration.
         - created: The date of the first consent string creation.
         - lastUpdated: The date of the last consent string update.
         - cmpId: The id of the last Consent Manager Provider that updated the consent string.
         - cmpVersion: The version of the Consent Manager Provider.
         - consentScreen: The screen number in the CMP where the consent was given.
         - consentLanguage: The language that the CMP asked for consent in.
         - vendorListVersion: The version of the vendor list used in the most recent consent string update.
         - maxVendorId: The maximum vendor id that can be found in the current vendor list.
         - allowedPurposes: An array of allowed purposes id.
         - allowedVendors: An array of allowed vendors id.
         - vendorListEncoding: The type of vendors encoding that should be used to generate the base64 consent string.
     */
    internal init(versionConfig: CMPVersionConfig,
                  created: Date,
                  lastUpdated: Date,
                  cmpId: Int,
                  cmpVersion: Int,
                  consentScreen: Int,
                  consentLanguage: CMPLanguage,
                  editorVersion: Int,
                  vendorListVersion: Int,
                  maxVendorId: Int,
                  editorPurposes: IndexSet,
                  allowedPurposes: IndexSet,
                  allowedVendors: IndexSet,
                  vendorListEncoding: ConsentEncoding) {
        
        self.version = versionConfig.version
        self.versionConfig = versionConfig
        self.created = created
        self.lastUpdated = lastUpdated
        self.cmpId = cmpId
        self.cmpVersion = cmpVersion
        self.consentScreen = consentScreen
        self.consentLanguage = consentLanguage
        self.editorVersion = editorVersion
        self.vendorListVersion = vendorListVersion
        self.maxVendorId = maxVendorId
        self.editorPurposes = editorPurposes
        self.allowedPurposes = allowedPurposes
        self.allowedVendors = allowedVendors
        
        self.consentString = CMPBitsString(bitsString: CMPConsentString.encodeToBits(versionConfig: versionConfig,
                                                                                     created: created,
                                                                                     lastUpdated: lastUpdated,
                                                                                     cmpId: cmpId,
                                                                                     cmpVersion: cmpVersion,
                                                                                     consentScreen: consentScreen,
                                                                                     consentLanguage: consentLanguage,
                                                                                     editorVersion: editorVersion,
                                                                                     vendorListVersion: vendorListVersion,
                                                                                     maxVendorId: maxVendorId,
                                                                                     editorPurposes: editorPurposes,
                                                                                     allowedPurposes: allowedPurposes,
                                                                                     allowedVendors: allowedVendors,
                                                                                     vendorListEncoding: vendorListEncoding))!.stringValue
        
        self.iabConsentString = CMPBitsString(bitsString: CMPConsentString.iabEncodeToBits(versionConfig: versionConfig,
                                                                                     created: created,
                                                                                     lastUpdated: lastUpdated,
                                                                                     cmpId: cmpId,
                                                                                     cmpVersion: cmpVersion,
                                                                                     consentScreen: consentScreen,
                                                                                     consentLanguage: consentLanguage,
                                                                                     vendorListVersion: vendorListVersion,
                                                                                     maxVendorId: maxVendorId,
                                                                                     allowedPurposes: allowedPurposes,
                                                                                     allowedVendors: allowedVendors,
                                                                                     vendorListEncoding: vendorListEncoding))!.stringValue
        
        // Note: CMPBitsString() is unwrapped using the forced operator because CMPConsentString.encodeToBits() will always return a valid bits string.
    }
    
    /**
     Check if a purpose is allowed by the consent string.
     
     - Parameter purposeId: The purpose id which should be checked.
     - Returns: true if the purpose is allowed, false otherwise.
     */
    @objc
    public func isPurposeAllowed(purposeId: Int) -> Bool {
        return allowedPurposes.contains(purposeId)
    }
    
    /**
     Check if an editor purpose is allowed by the consent string.
     
     - Parameter purposeId: The purpose id which should be checked.
     - Returns: true if the purpose is allowed, false otherwise.
     */
    @objc
    public func isEditorPurposeAllowed(purposeId: Int) -> Bool {
        return editorPurposes.contains(purposeId)
    }

    /**
     Check if a vendor is allowed by the consent string.
     
     - Parameter vendorId: The vendor id which should be checked.
     - Returns: true if the vendor is allowed, false otherwise.
     */
    @objc
    public func isVendorAllowed(vendorId: Int) -> Bool {
        return allowedVendors.contains(vendorId)
    }
    
    /**
     Returns a new instance of CMPConsentString from a base64 string.
     
     - Parameter base64String: The base64 consent string.
     - Returns: A new instance of CMPConsentString if the string is valid, nil otherwise.
     */
    @objc
    public static func from(base64 base64String: String) -> CMPConsentString? {
        if let bits = CMPBitsString(string: base64String)?.bitsValue {
            return CMPConsentString.decodeFromBits(bits: bits)
        } else {
            return nil
        }
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        if let object = object as? CMPConsentString {
            return self == object
        } else {
            return false
        }
    }
    
    public static func == (lhs: CMPConsentString, rhs: CMPConsentString) -> Bool {
        return lhs.version == rhs.version
            && lhs.created == rhs.created
            && lhs.lastUpdated == rhs.lastUpdated
            && lhs.cmpId == rhs.cmpId
            && lhs.cmpVersion == rhs.cmpVersion
            && lhs.consentScreen == rhs.consentScreen
            && lhs.consentLanguage == rhs.consentLanguage
            && lhs.editorVersion == rhs.editorVersion
            && lhs.vendorListVersion == rhs.vendorListVersion
            && lhs.maxVendorId == rhs.maxVendorId
            && lhs.editorPurposes == rhs.editorPurposes
            && lhs.allowedPurposes == rhs.allowedPurposes
            && lhs.allowedVendors == rhs.allowedVendors
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return CMPConsentString.from(base64: self.consentString)!
        
        // Note: CMPConsentString.from() is unwrapped using the forced operator because we already know that
        // the base64url consent string is valid since it has been generated by our encoder.
    }
    
}
