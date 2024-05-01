//
//  DetailsViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 27/04/2024.
//

import UIKit

class DetailsViewController: UIViewController {
    
    @IBOutlet weak var wishlistBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var findInMarketButton: UIButton!
    @IBOutlet weak var findInTradeButton: UIButton!
    
    @IBOutlet weak var photocardImageView: UIImageView!
    @IBOutlet weak var idolLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    var photocard = Photocard()
    var currentUser = User()
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    
    @IBAction func addToWishlist(_ sender: Any) {
        if wishlistBarButtonItem.image == UIImage(systemName: "heart.fill") {
            // Remove from wishlist
            databaseController?.removePhotocardFromWishlist(photocard: photocard, user: currentUser)
            wishlistBarButtonItem.image = UIImage(systemName: "heart")
        } else {
            // Add to wishlist
            let result = databaseController?.addPhotocardToWishlist(photocard: photocard, user: currentUser)
            if result == true {
                wishlistBarButtonItem.image = UIImage(systemName: "heart.fill")
            }
        }
    }
    
    @IBAction func sharePhotocard(_ sender: Any) {
    }
    
    @IBAction func findInMarket(_ sender: Any) {
    }
    
    @IBAction func findInTrade(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        if let user = databaseController?.currentUser {
            currentUser = user
        }
        
        // Setup photocard details
        photocardImageView.image = UIImage(named: photocard.image!)
        idolLabel.text = photocard.idol?.name
        albumLabel.text = photocard.album?.name
        artistLabel.text = photocard.artist?.name
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
