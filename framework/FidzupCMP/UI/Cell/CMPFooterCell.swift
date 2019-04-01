//
//  CMPFooterCell.swift
//  FidzupCMP
//
//  Created by Christophe on 29/03/2019.
//  Copyright © 2019 Fidzup. All rights reserved.
//

import UIKit

internal class CMPFooterCell: UITableViewCell {
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var customizeButton: UIButton!
    @IBOutlet weak var refuseButton: UIButton!
    
    func enableCustomizeButton(enable: Bool) {
        customizeButton.isEnabled = enable
    }
    
    func configure(acceptText: String, customizeText: String, refuseText: String, customizeEnabled: Bool) {
        acceptButton.setTitle(acceptText, for: .normal)
        customizeButton.setTitle(customizeText, for: .normal)
        refuseButton.setTitle(refuseText, for: .normal)
        enableCustomizeButton(enable: customizeEnabled)
    }
}
