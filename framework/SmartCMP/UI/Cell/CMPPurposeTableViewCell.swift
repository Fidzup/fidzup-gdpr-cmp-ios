//
//  CMPPurposeTableViewCell.swift
//  FidzupCMP
//
//  Created by Christophe on 29/08/2018.
//

import UIKit

internal class CMPPurposeTableViewCell: UITableViewCell {
    
    var purposeActiveSwitchCallback: ((_ switch: UISwitch) -> Void)?
    var purposeIsActive: Bool =  true
    var fullHeight: Int = 0
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var purposeSwitch: UISwitch!
    @IBOutlet weak var purposeDesc: UITextView!
    
    func computeDescHeight() -> CGFloat {
        return self.purposeDesc.frame.size.height + self.purposeDesc.frame.origin.y
    }
    
    func setPurposeActive(consent: Bool) {
        self.purposeIsActive = consent
        self.purposeSwitch.isOn = consent
    }
    
    @IBAction func purposeSwitchValueChanged(_ sender: UISwitch) {
        self.setPurposeActive(consent: sender.isOn)
        purposeActiveSwitchCallback?(sender)
    }
}
