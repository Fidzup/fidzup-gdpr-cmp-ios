//
//  CMPConsentString+Utils.swift
//  FidzupCMP
//
//  Created by Loïc GIRON DIT METAZ on 26/04/2018.
//  Copyright © 2018 Smart AdServer.
//
//  This software is distributed under the Creative Commons Legal Code, Attribution 3.0 Unported license.
//  Check the LICENSE file for more information.
//

import Foundation

/**
 Utils consent string extension that contains static methods used to initialize new consent
 strings more easily.
 */
internal extension CMPConsentString {
    
    /**
     Return a new consent string with no consent given for any purposes & vendors.
     
     - Parameters:
        - consentScreen: The screen number in the CMP where the consent was given.
        - consentLanguage: The language that the CMP asked for consent in.
        - vendorList: The vendor list corresponding to the consent string.
        - date: The date that will be used as creation date & last updated date (optional, it will use the current date by default).
     - Returns: A new consent string with no consent given.
     */
    static func consentStringWithNoConsent(consentScreen: Int,
                                           consentLanguage: CMPLanguage,
                                           editor: CMPEditor,
                                           vendorList: CMPVendorList,
                                           date: Date = Date()) -> CMPConsentString {
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: date,
            lastUpdated: date,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentScreen,
            consentLanguage: consentLanguage,
            editorPurposes: [],
            allowedPurposes: [],
            allowedVendors: [],
            editor: editor,
            vendorList: vendorList
        )
        
    }
    
    /**
     Return a new consent string with every consent given for every purposes & vendors.
     
     - Parameters:
        - consentScreen: The screen number in the CMP where the consent was given.
        - consentLanguage: The language that the CMP asked for consent in.
        - editor: The editor corresponding to the consent string.
        - vendorList: The vendor list corresponding to the consent string.
        - date: The date that will be used as creation date & last updated date (optional, it will use the current date by default).
     - Returns: A new consent string with every consent given.
     */
    static func consentStringWithFullConsent(consentScreen: Int,
                                             consentLanguage: CMPLanguage,
                                             editor: CMPEditor,
                                             vendorList: CMPVendorList,
                                             date: Date = Date()) -> CMPConsentString {
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: date,
            lastUpdated: date,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentScreen,
            consentLanguage: consentLanguage,
            editorPurposes: editor.getPurposesIndexSet(),
            allowedPurposes: IndexSet(vendorList.purposes.map({ $0.id })),
            allowedVendors: IndexSet(vendorList.vendors.map({ $0.id })),
            editor: editor,
            vendorList: vendorList
        )
        
    }
    
    /**
     Return a new consent string which keeps info from a previous one (generated with a previous vendor list)
     but give consent one new items (purposes & vendors).
     
     - Parameters:
        - updatedVendorList: The updated vendor list.
        - previousVendorList: The previous consent string that has been used to generated the previous consent string.
        - previousConsentString: The previous consent string.
        - consentLanguage: The language that the CMP asked for consent in.
        - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: The new consent string.
     */
    static func consentString(fromUpdatedVendorList updatedVendorList: CMPVendorList,
                              previousVendorList: CMPVendorList,
                              previousConsentString: CMPConsentString,
                              consentLanguage: CMPLanguage,
                              lastUpdated: Date = Date()) -> CMPConsentString {
        
        let updatedAllowedPurposes = IndexSet((1...updatedVendorList.purposes.count).compactMap { index in
            if index <= previousVendorList.purposes.count {
                return previousConsentString.allowedPurposes.contains(index) ? index : nil
            } else {
                return index
            }
        })
        
        let updatedAllowedVendors = IndexSet((1...updatedVendorList.maxVendorId).compactMap { index in
            if index <= previousVendorList.maxVendorId {
                return previousConsentString.allowedVendors.contains(index) ? index : nil
            } else {
                return index
            }
        })
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: previousConsentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: previousConsentString.consentScreen,
            consentLanguage: consentLanguage,
            editorVersion: previousConsentString.editorVersion,
            editorPurposes: previousConsentString.editorPurposes,
            allowedPurposes: updatedAllowedPurposes,
            allowedVendors: updatedAllowedVendors,
            vendorList: updatedVendorList
        )
    }
    
    /**
     Return a new consent string which keeps info from a previous one (generated with a previous editor)
     but give consent one new items (editor purposes).
     
     - Parameters:
     - updatedEditor: The updated editor.
     - previousEditor: The previous consent string that has been used to generated the previous consent string.
     - previousConsentString: The previous consent string.
     - consentLanguage: The language that the CMP asked for consent in.
     - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: The new consent string.
     */
    static func consentString(fromUpdatedEditor updatedEditor: CMPEditor,
                              previousEditor: CMPEditor,
                              previousConsentString: CMPConsentString,
                              consentLanguage: CMPLanguage,
                              lastUpdated: Date = Date()) -> CMPConsentString {
        
        let updatedEditorPurposes = IndexSet((1...updatedEditor.purposes.count).compactMap { index in
            if index <= previousEditor.purposes.count {
                return previousConsentString.editorPurposes.contains(index) ? index : nil
            } else {
                return index
            }
        })
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: previousConsentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: previousConsentString.consentScreen,
            consentLanguage: consentLanguage,
            vendorListVersion: previousConsentString.vendorListVersion,
            maxVendorId: previousConsentString.maxVendorId,
            editorPurposes: updatedEditorPurposes,
            allowedPurposes: previousConsentString.allowedPurposes,
            allowedVendors: previousConsentString.allowedVendors,
            editor: updatedEditor
        )
    }
    
    /**
     Return a new consent string identical to the one provided in parameters, with a consent given for a particular purpose.
     
     Note: this method will update the version config and the last updated date.
     
     - Parameters:
        - purposeId: The purpose id which should be added to the consent list.
        - consentString: The consent string which should be copied.
        - consentLanguage: The language that the CMP asked for consent in.
        - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: A new consent string with a consent given for a particular purpose.
     */
    static func consentStringByAddingConsent(forPurposeId purposeId: Int,
                                             consentString: CMPConsentString,
                                             consentLanguage: CMPLanguage,
                                             lastUpdated: Date = Date()) -> CMPConsentString {
        
        let updatedAllowedPurposes = !consentString.allowedPurposes.contains(purposeId) ?
            IndexSet(consentString.allowedPurposes + [purposeId]) : consentString.allowedPurposes
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: consentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentString.consentScreen,
            consentLanguage: consentLanguage,
            editorVersion: consentString.editorVersion,
            vendorListVersion: consentString.vendorListVersion,
            maxVendorId: consentString.maxVendorId,
            editorPurposes: consentString.editorPurposes,
            allowedPurposes: updatedAllowedPurposes,
            allowedVendors: consentString.allowedVendors
        )
    }
    
    /**
     Return a new consent string identical to the one provided in parameters, with a consent given for a particular purpose.
     
     Note: this method will update the version config and the last updated date.
     
     - Parameters:
     - purposeId: The purpose id which should be added to the consent list.
     - consentString: The consent string which should be copied.
     - consentLanguage: The language that the CMP asked for consent in.
     - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: A new consent string with a consent given for a particular purpose.
     */
    static func consentStringByAddingConsent(forEditorPurposeId purposeId: Int,
                                             consentString: CMPConsentString,
                                             consentLanguage: CMPLanguage,
                                             lastUpdated: Date = Date()) -> CMPConsentString {
        
        let updatedEditorPurposes = !consentString.editorPurposes.contains(purposeId) ?
            IndexSet(consentString.editorPurposes + [purposeId]) : consentString.editorPurposes
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: consentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentString.consentScreen,
            consentLanguage: consentLanguage,
            editorVersion: consentString.editorVersion,
            vendorListVersion: consentString.vendorListVersion,
            maxVendorId: consentString.maxVendorId,
            editorPurposes: updatedEditorPurposes,
            allowedPurposes: consentString.allowedPurposes,
            allowedVendors: consentString.allowedVendors
        )
    }

    /**
     Return a new consent string identical to the one provided in parameters, with a consent removed for a particular purpose.
     
     Note: this method will update the version config and the last updated date.
     
     - Parameters:
        - purposeId: The purpose id which should be removed from the consent list.
        - consentString: The consent string which should be copied.
        - consentLanguage: The language that the CMP asked for consent in.
        - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: A new consent string with a consent removed for a particular purpose.
     */
    static func consentStringByRemovingConsent(forPurposeId purposeId: Int,
                                               consentString: CMPConsentString,
                                               consentLanguage: CMPLanguage,
                                               lastUpdated: Date = Date()) -> CMPConsentString {
        
        let updatedAllowedPurposes = consentString.allowedPurposes.filteredIndexSet(includeInteger: { $0 != purposeId })
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: consentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentString.consentScreen,
            consentLanguage: consentLanguage,
            editorVersion: consentString.editorVersion,
            vendorListVersion: consentString.vendorListVersion,
            maxVendorId: consentString.maxVendorId,
            editorPurposes: consentString.editorPurposes,
            allowedPurposes: updatedAllowedPurposes,
            allowedVendors: consentString.allowedVendors
        )
    }
    
    /**
     Return a new consent string identical to the one provided in parameters, with a consent removed for a particular purpose.
     
     Note: this method will update the version config and the last updated date.
     
     - Parameters:
     - purposeId: The purpose id which should be removed from the consent list.
     - consentString: The consent string which should be copied.
     - consentLanguage: The language that the CMP asked for consent in.
     - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: A new consent string with a consent removed for a particular purpose.
     */
    static func consentStringByRemovingConsent(forEditorPurposeId purposeId: Int,
                                               consentString: CMPConsentString,
                                               consentLanguage: CMPLanguage,
                                               lastUpdated: Date = Date()) -> CMPConsentString {
        
        let updatedEditorPurposes = consentString.editorPurposes.filteredIndexSet(includeInteger: { $0 != purposeId })
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: consentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentString.consentScreen,
            consentLanguage: consentLanguage,
            editorVersion: consentString.editorVersion,
            vendorListVersion: consentString.vendorListVersion,
            maxVendorId: consentString.maxVendorId,
            editorPurposes: updatedEditorPurposes,
            allowedPurposes: consentString.allowedPurposes,
            allowedVendors: consentString.allowedVendors
        )
    }
    
    /**
     Return a new consent string identical to the one provided in parameters, with a consent given for a particular vendor.
     
     Note: this method will update the version config and the last updated date.
     
     - Parameters:
        - vendorId: The vendor id which should be added to the consent list.
        - consentString: The consent string which should be copied.
        - consentLanguage: The language that the CMP asked for consent in.
        - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: A new consent string with a consent given for a particular vendor.
     */
    static func consentStringByAddingConsent(forVendorId vendorId: Int,
                                             consentString: CMPConsentString,
                                             consentLanguage: CMPLanguage,
                                             lastUpdated: Date = Date()) -> CMPConsentString {
        
        let updatedAllowedVendors = !consentString.allowedVendors.contains(vendorId) ?
            IndexSet(consentString.allowedVendors + [vendorId]) : consentString.allowedVendors
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: consentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentString.consentScreen,
            consentLanguage: consentLanguage,
            editorVersion: consentString.editorVersion,
            vendorListVersion: consentString.vendorListVersion,
            maxVendorId: consentString.maxVendorId,
            editorPurposes: consentString.editorPurposes,
            allowedPurposes: consentString.allowedPurposes,
            allowedVendors: updatedAllowedVendors
        )
    }
    
    /**
     Return a new consent string identical to the one provided in parameters, with a consent removed for a particular vendor.
     
     Note: this method will update the version config and the last updated date.
     
     - Parameters:
        - vendorId: The vendor id which should be removed from the consent list.
        - consentString: The consent string which should be copied.
        - consentLanguage: The language that the CMP asked for consent in.
        - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: A new consent string with a consent removed for a particular vendor.
     */
    static func consentStringByRemovingConsent(forVendorId vendorId: Int,
                                               consentString: CMPConsentString,
                                               consentLanguage: CMPLanguage,
                                               lastUpdated: Date = Date()) -> CMPConsentString {
        
        let updatedAllowedVendors = consentString.allowedVendors.filteredIndexSet(includeInteger: { $0 != vendorId })
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: consentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentString.consentScreen,
            consentLanguage: consentLanguage,
            editorVersion: consentString.editorVersion,
            vendorListVersion: consentString.vendorListVersion,
            maxVendorId: consentString.maxVendorId,
            editorPurposes: consentString.editorPurposes,
            allowedPurposes: consentString.allowedPurposes,
            allowedVendors: updatedAllowedVendors
        )
    }
    
    /**
     Return a new consent string identical to the one provided in parameters, with all purposes disallowed.
     
     Note: the vendor list provided must match the one used to generate the previous consent string, otherwise
     this method will return nil.
     
     - Parameters:
        - previousConsentString: The previous consent string.
        - consentScreen: The screen number in the CMP where the consent was given.
        - consentLanguage: The language that the CMP asked for consent in.
        - vendorList: The vendor list corresponding to the consent string.
        - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: A new consent string identical to the one provided in parameters with all purposes disallowed if possible, nil otherwise.
     */
    static func consentStringWithNoPurposesConsent(fromConsentString previousConsentString: CMPConsentString,
                                                   consentScreen: Int,
                                                   consentLanguage: CMPLanguage,
                                                   editor: CMPEditor,
                                                   vendorList: CMPVendorList,
                                                   lastUpdated: Date = Date()) -> CMPConsentString? {
        
        guard previousConsentString.vendorListVersion == vendorList.vendorListVersion else {
            return nil
        }
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: previousConsentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentScreen,
            consentLanguage: consentLanguage,
            editorPurposes: [], // No purpose allowed
            allowedPurposes: [], // No purpose allowed
            allowedVendors: previousConsentString.allowedVendors,
            editor: editor,
            vendorList: vendorList
        )
    }
    
    /**
     Return a new consent string identical to the one provided in parameters, with all purposes allowed.
     
     Note: the vendor list provided must match the one used to generate the previous consent string, otherwise
     this method will return nil.
     
     - Parameters:
        - previousConsentString: The previous consent string.
        - consentScreen: The screen number in the CMP where the consent was given.
        - consentLanguage: The language that the CMP asked for consent in.
        - vendorList: The vendor list corresponding to the consent string.
        - lastUpdated: The date that will be used as last updated date (optional, it will use the current date by default).
     - Returns: A new consent string identical to the one provided in parameters with all purposes allowed if possible, nil otherwise.
     */
    static func consentStringWithAllPurposesConsent(fromConsentString previousConsentString: CMPConsentString,
                                                    consentScreen: Int,
                                                    consentLanguage: CMPLanguage,
                                                    editor: CMPEditor,
                                                    vendorList: CMPVendorList,
                                                    lastUpdated: Date = Date()) -> CMPConsentString? {
        
        guard previousConsentString.vendorListVersion == vendorList.vendorListVersion else {
            return nil
        }
        
        let allowedPurposes = IndexSet(vendorList.purposes.map { $0.id })
        
        return CMPConsentString(
            versionConfig: CMPVersionConfig.LATEST,
            created: previousConsentString.created,
            lastUpdated: lastUpdated,
            cmpId: CMPConstants.CMPInfos.ID,
            cmpVersion: CMPConstants.CMPInfos.VERSION,
            consentScreen: consentScreen,
            consentLanguage: consentLanguage,
            editorPurposes: editor.getPurposesIndexSet(),
            allowedPurposes: allowedPurposes,
            allowedVendors: previousConsentString.allowedVendors,
            editor: editor,
            vendorList: vendorList
        )
    }
    
}
