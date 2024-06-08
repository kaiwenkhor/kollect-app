//
//  ListingDetailsTableViewCell.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/06/2024.
//

import UIKit

class ListingDetailsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var idolLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
