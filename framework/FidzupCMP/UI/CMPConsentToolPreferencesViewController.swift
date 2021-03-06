//
//  CMPConsentToolPurposeViewController.swift
//  FidzupCMP
//
//  Created by Thomas Geley on 25/04/2018.
//  Copyright © 2018 Smart AdServer.
//
//  This software is distributed under the Creative Commons Legal Code, Attribution 3.0 Unported license.
//  Check the LICENSE file for more information.
//

import UIKit

/**
 Consent tool preferences view controller.
 */
internal class CMPConsentToolPreferencesViewController: CMPConsentToolBaseViewController {
    
    // MARK: - UI Elements
    
    static let EditorPurposeSection = 0
    static let PurposeSection = 1
    static let VendorSection = 2
    static let EditorPurposeCellIdentifier = "editorPurposeCell"
    static let PurposeCellIdentifier = "purposeCell"
    static let VendorsCellIdentifier = "vendorsCell"

    static let EditorPurposeControllerSegue = "editorPurposeControllerSegue"
    static let PurposeControllerSegue = "purposeControllerSegue"
    static let VendorsControllerSegue = "vendorsControllerSegue"
    
    var editorPurposeHeights: [CGFloat] = []
    var purposeHeights: [CGFloat] = []

    // MARK: - Consent Tool Manager
    
    weak var consentToolManager: CMPConsentToolManager?
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        
        var purposesCount = consentToolManager?.purposesCount ?? 1
        while purposesCount > 0 {
            purposesCount -= 1
            purposeHeights.append(44)
        }
        var editorPurposesCount = consentToolManager?.editorPurposesCount ?? 1
        while editorPurposesCount > 0 {
            editorPurposesCount -= 1
            editorPurposeHeights.append(44)
        }
        super.viewDidLoad()
        
        self.title = consentToolManager?.configuration.consentManagementScreenTitle
        
        // Cancel button
        let btnBack = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        btnBack.setTitle(consentToolManager?.configuration.consentManagementCancelButtonTitle, for: .normal)
        btnBack.titleLabel?.textAlignment = .left
        btnBack.addTarget(self, action: #selector(cancelButtonTapped(sender:)), for: .touchUpInside)
        btnBack.setTitleColor(navigationButtonTintColor, for: .normal)
        btnBack.setTitleColor(navigationButtonTintColor, for: .highlighted)
        let leftBarButton = UIBarButtonItem()
        leftBarButton.customView = btnBack
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        // Save button
        let btnSave = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        btnSave.setTitle(consentToolManager?.configuration.consentManagementSaveButtonTitle, for: .normal)
        btnSave.titleLabel?.textAlignment = .right
        btnSave.addTarget(self, action: #selector(saveButtonTapped(sender:)), for: .touchUpInside)
        btnSave.setTitleColor(navigationButtonTintColor, for: .normal)
        btnSave.setTitleColor(navigationButtonTintColor, for: .highlighted)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = btnSave
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        // Footer
        self.tableView.tableFooterView = UIView()
        self.view.backgroundColor = UIColor.groupTableViewBackground
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }

    // MARK: - Actions
    
    @objc func cancelButtonTapped(sender: Any) {
        self.consentToolManager?.reset()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func saveButtonTapped(sender: Any) {
        consentToolManager?.dismissConsentTool(save: true)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == CMPConsentToolPreferencesViewController.EditorPurposeSection {
            return consentToolManager?.editorPurposesCount ?? 1
        } else if section == CMPConsentToolPreferencesViewController.PurposeSection {
            return consentToolManager?.purposesCount ?? 1
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == CMPConsentToolPreferencesViewController.EditorPurposeSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: CMPConsentToolPreferencesViewController.PurposeCellIdentifier) as! CMPPurposeTableViewCell
            
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                cell.expanded(exp: selectedIndexPaths.contains(indexPath))
            }
            else {
                cell.expanded(exp: false)
            }
            
            if let purpose = consentToolManager?.editorPurposeAtIndex(indexPath.row) {
                cell.nameLabel.text = purpose.name
                cell.setPurposeActive(consent: consentToolManager!.isEditorPurposeAllowed(purpose))
                cell.purposeDesc.text = purpose.purposeDescription
                cell.purposeActiveSwitchCallback =  { (switch) -> Void in
                    self.consentToolManager?.changeEditorPurposeConsent(purpose, consent: cell.purposeIsActive)
                }
            }
            //cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator;
            
            return cell
            
        } else if indexPath.section == CMPConsentToolPreferencesViewController.PurposeSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: CMPConsentToolPreferencesViewController.PurposeCellIdentifier) as! CMPPurposeTableViewCell
            
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                cell.expanded(exp: selectedIndexPaths.contains(indexPath))
            }
            else {
                cell.expanded(exp: false)
            }

            if let purpose = consentToolManager?.purposeAtIndex(indexPath.row) {
                cell.nameLabel.text = purpose.name
                cell.setPurposeActive(consent: consentToolManager!.isPurposeAllowed(purpose))
                cell.purposeDesc.text = purpose.purposeDescription
                cell.purposeActiveSwitchCallback =  { (switch) -> Void in
                    self.consentToolManager?.changePurposeConsent(purpose, consent: cell.purposeIsActive)
                }
            }
            //cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator;
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CMPConsentToolPreferencesViewController.VendorsCellIdentifier) as! CMPPreferenceTableViewCell
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator;
            cell.nameLabel.text = consentToolManager?.configuration.consentManagementVendorsControllerAccessText
            if let consentToolManager = self.consentToolManager {
                cell.statusLabel.text = String(consentToolManager.allowedVendorCount) + " / " + String(consentToolManager.activatedVendorCount)
                //cell.statusLabel.sizeToFit()
            }
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator;
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case CMPConsentToolPreferencesViewController.EditorPurposeSection:
            return consentToolManager?.configuration.consentManagementScreenEditorPurposesSectionHeaderText
        case CMPConsentToolPreferencesViewController.PurposeSection:
            return consentToolManager?.configuration.consentManagementScreenPurposesSectionHeaderText
        default:
            return consentToolManager?.configuration.consentManagementScreenVendorsSectionHeaderText
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32.0
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        view.tintColor = UIColor.groupTableViewBackground
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont.systemFont(ofSize: 15.0)
        header.textLabel?.textColor = UIColor.darkGray
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CMPConsentToolPreferencesViewController.VendorsControllerSegue {
            let vendorsController:CMPConsentToolVendorsViewController = segue.destination as! CMPConsentToolVendorsViewController
            vendorsController.consentToolManager = self.consentToolManager
        } else if segue.identifier == CMPConsentToolPreferencesViewController.PurposeControllerSegue {
            let purposeController:CMPConsentToolPurposeViewController = segue.destination as! CMPConsentToolPurposeViewController
            purposeController.consentToolManager = self.consentToolManager
            if let selectedRow = self.tableView.indexPathForSelectedRow?.row {
                purposeController.purpose = self.consentToolManager?.purposeAtIndex(selectedRow)
            }
        } else if segue.identifier == CMPConsentToolPreferencesViewController.EditorPurposeControllerSegue {
            let editorPurposeController:CMPConsentToolPurposeViewController = segue.destination as! CMPConsentToolPurposeViewController
            editorPurposeController.consentToolManager = self.consentToolManager
            if let selectedRow = self.tableView.indexPathForSelectedRow?.row {
                editorPurposeController.purpose = self.consentToolManager?.editorPurposeAtIndex(selectedRow)
            }
        }
    }
 
    
    ////////
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == CMPConsentToolPreferencesViewController.EditorPurposeSection ||
            indexPath.section == CMPConsentToolPreferencesViewController.PurposeSection {
            if let cell = tableView.cellForRow(at: indexPath) as! CMPPurposeTableViewCell? {
                cell.expanded(exp: true)
            }
        }
        
        updateTableView()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if indexPath.section == CMPConsentToolPreferencesViewController.EditorPurposeSection ||
            indexPath.section == CMPConsentToolPreferencesViewController.PurposeSection {
            if let cell = tableView.cellForRow(at: indexPath) as! CMPPurposeTableViewCell? {
                cell.expanded(exp: false)
            }
        }
        
        updateTableView()
    }
    
    private func updateTableView() {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    /////////
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == CMPConsentToolPreferencesViewController.EditorPurposeSection {
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows, selectedIndexPaths.contains(indexPath) {
                if let cell = tableView.cellForRow(at: indexPath) as! CMPPurposeTableViewCell? {
                    let height = cell.computeDescHeight()
                    editorPurposeHeights[indexPath.row] = height // remember for later
                    return height // Expanded height
                }
                return editorPurposeHeights[indexPath.row] // cell is outside the screen, i.e. unavailable : use cache
            }
        } else if indexPath.section == CMPConsentToolPreferencesViewController.PurposeSection {
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows, selectedIndexPaths.contains(indexPath) {
                if let cell = tableView.cellForRow(at: indexPath) as! CMPPurposeTableViewCell? {
                    let height = cell.computeDescHeight()
                    purposeHeights[indexPath.row] = height // remember for later
                    return height // Expanded height
                }
                return purposeHeights[indexPath.row] // cell is outside the screen, i.e. unavailable : use cache
            }
        }
        
        return 44.0 // Normal height
    }

}
