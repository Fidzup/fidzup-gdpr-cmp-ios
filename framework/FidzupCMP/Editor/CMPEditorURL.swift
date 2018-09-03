//
//  CMPEditorURL.swift
//  FidzupCMP
//
//  Created by Nicolas Blanc on 03/09/2018.
//  Copyright © 2018 Fidzup. All rights reserved.
//

import Foundation
/**
 Represents the URL to a vendor list.
 */
internal class CMPEditorURL {
    
    /// The actual url of the vendor list.
    let url: URL
    
    /// The actual localized url of the vendor list if any.
    let localizedUrl: URL?
    
    /**
     Initialize a CMPEditorURL object that represents the latest editor.
     
     - Parameter language: The language of the user if a localized url has to be used.
     */
    init(language: CMPLanguage? = nil) {
        url = URL(string: CMPConstants.Editor.DefaultEndPoint)!
        
        localizedUrl = {
            if let language = language {
                let urlString = CMPConstants.Editor.DefaultLocalizedEndPoint
                    .replacingOccurrences(of: "{language}", with: language.string)
                return URL(string: urlString)
            }
            return nil
        }()
    }
    
    /**
     Initialize a CMPEditorURL object that represents the editor for a given version.
     
     - Parameters:
     - version: The editor version that should be fetched.
     - language: The language of the user if a localized url has to be used.
     */
    init(version: Int, language: CMPLanguage? = nil) {
        precondition(version >= 0, "Version number must be a positive number!")
        
        let urlString = CMPConstants.Editor.DefaultEndPoint
            .replacingOccurrences(of: "{version}", with: String(version))
        url = URL(string: urlString)!
        
        localizedUrl = {
            if let language = language {
                let urlString = CMPConstants.Editor.DefaultLocalizedEndPoint
                    .replacingOccurrences(of: "{language}", with: language.string)
                    .replacingOccurrences(of: "{version}", with: String(version))
                return URL(string: urlString)
            }
            return nil
        }()
    }
    
}
