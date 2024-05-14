//
//  DetailsViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 27/04/2024.
//

import UIKit

class DetailsViewController: UIViewController, DatabaseListener {
    
    @IBOutlet weak var favouritesButton: UIButton!
    @IBOutlet weak var wishlistButton: UIButton!
    @IBOutlet weak var findInMarketButton: UIButton!
    
    @IBOutlet weak var photocardImageView: UIImageView!
    @IBOutlet weak var idolLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    var photocard = Photocard()
    var currentUser = User()
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    let DEFAULT_IMAGE = "Default_Photocard_Image"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        if let currentUser = databaseController?.currentUser {
            self.currentUser = currentUser
        }
        
        // Setup photocard details
        photocardImageView.image = UIImage(named: photocard.image ?? DEFAULT_IMAGE)
        photocardImageView.layer.cornerRadius = 18
        idolLabel.text = photocard.idol?.name
        albumLabel.text = photocard.album?.name
        artistLabel.text = photocard.artist?.name
        
        // Check if is favourite/wishlist
        if currentUser.favourites.contains(photocard) {
            favouritesButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        }
        if currentUser.wishlist.contains(photocard) {
            wishlistButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    @IBAction func addToFavourites(_ sender: Any) {
        if favouritesButton.currentImage == UIImage(systemName: "heart.fill") {
            // Remove from favourites
            databaseController?.removePhotocardFromFavourites(photocard: photocard, user: currentUser)
            favouritesButton.setImage(UIImage(systemName: "heart"), for: .normal)
        } else {
            // Add to favourites
            let result = databaseController?.addPhotocardToFavourites(photocard: photocard, user: currentUser)
            if result == true {
                favouritesButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            }
        }
    }
    
    @IBAction func addToWishlist(_ sender: Any) {
        if wishlistButton.currentImage == UIImage(systemName: "star.fill") {
            // Remove from wishlist
            databaseController?.removePhotocardFromWishlist(photocard: photocard, user: currentUser)
            wishlistButton.setImage(UIImage(systemName: "star"), for: .normal)
        } else {
            // Add to wishlist
            let result = databaseController?.addPhotocardToWishlist(photocard: photocard, user: currentUser)
            if result == true {
                wishlistButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
            }
        }
    }
    
    @IBAction func findInMarket(_ sender: Any) {
        // Find in market
        // Go to photocard in market and show listings for that photocard.
    }
    
    @IBAction func sharePhotocard(_ sender: Any) {
        // Create a link to the current page
        // Deep linking
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - DatabaseListener
    
    func onAllIdolsChange(change: DatabaseChange, idols: [Idol]) {
        //
    }
    
    func onAllArtistsChange(change: DatabaseChange, artists: [Artist]) {
        //
    }
    
    func onAllAlbumsChange(change: DatabaseChange, albums: [Album]) {
        //
    }
    
    func onAllPhotocardsChange(change: DatabaseChange, photocards: [Photocard]) {
        //
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        currentUser = user
    }
    
}
