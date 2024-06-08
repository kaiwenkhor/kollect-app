//
//  ListingImagesTableViewCell.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/06/2024.
//

import UIKit

class ListingImagesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var frontImageView: UIImageView!
    @IBOutlet weak var backImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
