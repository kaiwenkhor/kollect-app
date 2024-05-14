//
//  HeaderCollectionReusableView.swift
//  Kollect-App
//
//  Created by Daryl Khor on 05/05/2024.
//

import UIKit

class HeaderCollectionReusableView: UICollectionReusableView {
    var section: Int?
    weak var headerButtonDelegate: SetHeaderButtonActionDelegate?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var showAllButton: UIButton!
    @IBAction func showPhotocards(_ sender: Any) {
        headerButtonDelegate?.showPhotocards(section: section!)
    }
}
