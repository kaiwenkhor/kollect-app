//
//  PhotocardCollectionViewCell.swift
//  Kollect-App
//
//  Created by Daryl Khor on 26/04/2024.
//

import UIKit

class PhotocardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photocardImageView: UIImageView!
    
    func setup(with photocard: Photocard) {
        photocardImageView.image = UIImage(named: photocard.image!)
    }
}
