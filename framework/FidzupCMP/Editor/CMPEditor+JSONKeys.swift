//
//  CMPEditor+JSONKeys.swift
//  FidzupCMP
//
//  Created by Nicolas Blanc on 31/08/2018.
//  Copyright © 2018 Fidzup. All rights reserved.
//

import Foundation
/*
 CMPEditor extension used to store all JSON keys.
 */
internal extension CMPEditor {
    
    /**
     Class storing all JSON keys used to parse the vendors list.
     */
    class JsonKey {
        
        static let EDITOR_VERSION = "editorVersion"
        static let LAST_UPDATED = "lastUpdated"
        static let EDITOR_ID = "id"
        static let EDITOR_NAME = "name"
        class Purposes {
            static let PURPOSES = "purposes"
            static let ID = "id"
            static let NAME = "name"
            static let DESCRIPTION = "description"
        }
        
        class Features {
            static let FEATURES = "features"
            static let ID = "id"
            static let NAME = "name"
            static let DESCRIPTION = "description"
        }
        
    }
    
}
