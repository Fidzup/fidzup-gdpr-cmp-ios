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
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var purposeSwitch: UISwitch!
    @IBOutlet weak var purposeDesc: UITextView!
    @IBOutlet weak var expandIcon: UIImageView!
    
    func computeDescHeight() -> CGFloat {
        return self.purposeDesc.frame.size.height + self.purposeDesc.frame.origin.y
    }
    
    func expanded(exp: Bool) {
        self.expandIcon.image = UIImage(named: (exp ? "minus.png" : "plus.png"), in: Bundle(for: type(of: self)), compatibleWith: nil)
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
