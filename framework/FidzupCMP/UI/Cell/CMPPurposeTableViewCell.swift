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
    @IBOutlet weak var purposeDesc: UILabel!
    @IBOutlet weak var expandIcon: UIImageView!
    @IBOutlet weak var toogleConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainView: UIView!
    
    func computeDescHeight() -> CGFloat {
        return self.purposeDesc.frame.size.height + self.purposeDesc.frame.origin.y
    }
    
    func expanded(exp: Bool) {
        self.expandIcon.image = UIImage(named: (exp ? "arrow_up" : "arrow_down"), in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        // remove current constraint
        if let constraint = toogleConstraint {
            constraint.isActive = false
        }
        
        var newConstraint: NSLayoutConstraint
        
        if exp {
            newConstraint = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem:purposeDesc , attribute: .bottom, multiplier: 1.0, constant: 10)
        }
        else {
            newConstraint = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: mainView, attribute: .bottom, multiplier: 1.0, constant: 0)
        }
        newConstraint.priority = UILayoutPriority(250)
        newConstraint.isActive = true
        self.toogleConstraint = newConstraint
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
