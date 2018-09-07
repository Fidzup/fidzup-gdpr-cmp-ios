//
//  CMPConstants.swift
//  FidzupCMP
//
//  Created by Thomas Geley on 25/04/2018.
//  Copyright © 2018 Smart AdServer.
//
//  This software is distributed under the Creative Commons Legal Code, Attribution 3.0 Unported license.
//  Check the LICENSE file for more information.
//

import Foundation

/**
 General constants for FidzupCMP.
 */
internal struct CMPConstants {
    
    /// Generic information on the CMP framework.
    struct CMPInfos {
        static let VERSION                          = 3
        
        // WARNING: '190' IS THE OFFICIAL CMP ID FOR FidzupCMP.
        // You can use this ID as long as you don't change the source code of this project.
        // If you don't use it exactly as distributed in the official Fidzup repository,
        // you must get your own CMP ID by registering here: https://register.consensu.org/CMP
        static let ID                               = 190
    }
    
    /// IAB Keys for NSUserDefaults storage.
    struct IABConsentKeys {
        static let CMPPresent                       = "IABConsent_CMPPresent"
        static let SubjectToGDPR                    = "IABConsent_SubjectToGDPR"
        static let ConsentString                    = "IABConsent_ConsentString"
        static let ParsedPurposeConsent             = "IABConsent_ParsedPurposeConsents"
        static let ParsedVendorConsent              = "IABConsent_ParsedVendorConsents"
    }
    
    /// The AdvertisingConsentStatus NSUserDefaults key contains the current user consent for the advertising
    /// purpose of the current vendor list.
    ///
    /// This status is only based on the answer of the user for the advertising purpose and does not take
    /// vendors status into account. It should only be used for third party advertisement SDK that are not
    /// IAB TCF compliant.
    ///
    /// Note: this key is not part of the IAB TCF specification.
    struct FidzupCMPConsentKeys {
        static let PurposeId                        = 3 
        static let Key                              = "FidzupCMP_advertisingConsentStatus"
        static let ConsentString                    = "GlobalConsent_ConsentString"
        static let ParsedEditorPurposeConsent       = "GlobalConsent_ParsedEditorPurposeConsents"
    }
    
    // Miscellanous NSUSerDefaults keys
    struct MiscKeys {
        static let LastPresentationDate             = "FIdzupCMP_lastPresentationDate"
    }
    
    /// Editor configuration
    struct Editor {
        static let DefaultEndPoint                  = "https://www.fidzup.com/editor/editor.json"
        static let DefaultLocalizedEndPoint         = "https://www.fidzup.com/editor/editor-{language}.json"
    }
 
    /// Vendor list configuration.
    struct VendorList {
        static let DefaultEndPoint                  = "https://vendorlist.consensu.org/vendorlist.json"
        static let VersionedEndPoint                = "https://vendorlist.consensu.org/v-{version}/vendorlist.json"
        
        static let DefaultLocalizedEndPoint         = "https://vendorlist.consensu.org/purposes-{language}.json"
        static let VersionedLocalizedEndPoint       = "https://vendorlist.consensu.org/purposes-{language}-{version}.json"
    }
    
}
