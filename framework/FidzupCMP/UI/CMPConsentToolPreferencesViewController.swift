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
    
    static let headerCellIdentifier = "headerCell"
    static let footerCellIdentifier = "footerCell"
    static let PurposeCellIdentifier = "purposeCell"

    static let VendorsControllerSegue = "vendorsControllerSegue"

    // MARK: - Consent Tool Manager
    
    weak var consentToolManager: CMPConsentToolManager?
    var customEnabled: Bool = true
    var footerCell: CMPFooterCell?
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = consentToolManager?.configuration.consentManagementScreenTitle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        var i:Int = 0
        var counter:Int = 0
        
        if let ctm = consentToolManager {
            while i < ctm.purposesCount {
                if let p = ctm.purposeAtIndex(i) {
                    if ctm.isPurposeAllowed(p) {
                        counter += 1
                    }
                }
                i += 1
            }
            
            i=0
            while i < ctm.activatedVendorCount {
                let v = ctm.activatedVendors[i]
                if (ctm.isVendorAllowed(v)) {
                    counter += 1
                }
                i += 1
            }
            
            customEnabled = (counter != ctm.purposesCount + ctm.activatedVendorCount) && (counter != 0)
        }
        
        
        self.tableView.reloadData()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CMPConsentToolPreferencesViewController.VendorsControllerSegue {
            let vendorsController:CMPConsentToolVendorsViewController = segue.destination as! CMPConsentToolVendorsViewController
            vendorsController.consentToolManager = self.consentToolManager
        }
    }

    // MARK: - Actions
    /*
    @objc func cancelButtonTapped(sender: Any) {
        self.consentToolManager?.reset()
        self.dismiss(animated: true, completion: nil)
    }
    */
    @IBAction func saveButtonTapped(sender: Any) {
        consentToolManager?.dismissConsentTool(save: true)
    }
    
    @IBAction func closeConsentButtonTapped(_ sender: Any) {
        consentToolManager?.acceptAllPurposesAndCloseConsentTool()
    }
    
    @IBAction func closeRefuseConsentButtonTapped(_ sender: Any) {
        consentToolManager?.revokeAllPurposesAndCloseConsentTool()
    }
 
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 || section == 2 {
            return 1
        }
        else {
            return consentToolManager?.purposesCount ?? 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CMPConsentToolPreferencesViewController.headerCellIdentifier) as! CMPHeaderCell
            
            if let config = self.consentToolManager?.configuration {
                cell.configure(logo: config.homeScreenLogo, title: config.homeScreenManageConsentButtonTitle, disclaimer: config.homeScreenText, vendorText: config.consentManagementVendorsControllerAccessText)
            }
            
            return cell
        }
        else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CMPConsentToolPreferencesViewController.footerCellIdentifier) as! CMPFooterCell
            
            if let config = self.consentToolManager?.configuration {
                cell.configure(acceptText: config.homeScreenCloseButtonTitle, customizeText: config.consentManagementScreenTitle, refuseText: config.homeScreenCloseRefuseButtonTitle, customizeEnabled: customEnabled)
            }
            
            footerCell = cell
            
            return cell
        }
        else {
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
                    self.customEnabled = true
                    if let footer = self.footerCell {
                        footer.enableCustomizeButton(enable: self.customEnabled)
                    }
                }
            }
            
            return cell
        }
    }
 
    ////////
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            if let cell = tableView.cellForRow(at: indexPath) as! CMPPurposeTableViewCell? {
                cell.expanded(exp: true)
            }
        }
        updateTableView()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
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
    
    private func updateButton()
    {
        
    }
}
