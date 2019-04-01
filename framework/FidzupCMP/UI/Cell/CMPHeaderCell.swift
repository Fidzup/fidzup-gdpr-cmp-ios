//
//  CMPHeaderCell.swift
//  FidzupCMP
//
//  Created by Christophe on 29/03/2019.
//  Copyright © 2019 Fidzup. All rights reserved.
//

import UIKit

internal class CMPHeaderCell: UITableViewCell {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var disclaimerTextView: UITextView!
    @IBOutlet weak var vendorButton: UIButton!
    
    func configure(logo: UIImage, title: String, disclaimer: String, vendorText: String) {
        logoImageView.image = logo
        titleLabel.text = title
        disclaimerTextView.text = disclaimer
        vendorButton.setTitle(vendorText, for: .normal)
        
    }
}
