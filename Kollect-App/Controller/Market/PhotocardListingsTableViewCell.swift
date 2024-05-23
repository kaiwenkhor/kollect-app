//
//  PhotocardListingsTableViewCell.swift
//  Kollect-App
//
//  Created by Daryl Khor on 22/05/2024.
//

import UIKit

class PhotocardListingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var photocardImageView: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
