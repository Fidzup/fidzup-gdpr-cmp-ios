//
//  CMPEditorManagerDelegate.swift
//  FidzupCMP
//
//  Created by Nicolas Blanc on 03/09/2018.
//  Copyright © 2018 Fidzup. All rights reserved.
//

import Foundation

/**
 Delegate of CMPEditorManager.
 */
internal protocol CMPEditorManagerDelegate {
    
    /**
     Method called when the editor manager did fetch an editor successfully.
     
     - Parameters:
     - editorManager: The editor manager that fetched an editor.
     - editor: The editor that has been fetched.
     */
    func editorManager(_ editorManager: CMPEditorManager, didFetchEditor editor: CMPEditor)
    
    /**
     Method called when the vendor list manager did fail to fetch a vendor list.
     
     - Parameters:
     - editorManager: The editor manager that failed to fetch an editor.
     - error: The error that has been triggered when trying to fetch the vendor list.
     */
    func editorManager(_ editorManager: CMPEditorManager, didFailWithError error: Error)
    
}
