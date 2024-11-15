//
//  DetailsViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 27/04/2024.
//

import UIKit

class DetailsViewController: UIViewController, DatabaseListener {
    
    @IBOutlet weak var addToBarButton: UIBarButtonItem!
    @IBOutlet weak var findInMarketButton: UIButton!
    
    @IBOutlet weak var photocardImageView: UIImageView!
    @IBOutlet weak var idolLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    var isWishlist = false
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
        if let image = databaseController?.getImage(imageData: photocard.image!) {
            photocardImageView.image = image
        }
        photocardImageView.layer.cornerRadius = 18
        idolLabel.text = photocard.idol?.name
        albumLabel.text = photocard.album?.name
        artistLabel.text = photocard.artist?.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        
        // Check if is favourite/wishlist
        if isWishlist {
            if currentUser.wishlist.contains(photocard) {
                addToBarButton.image = UIImage(systemName: "star.fill")
            } else {
                addToBarButton.image = UIImage(systemName: "star")
            }
        } else {
            if currentUser.favourites.contains(photocard) {
                addToBarButton.image = UIImage(systemName: "heart.fill")
            } else {
                addToBarButton.image = UIImage(systemName: "heart")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    @IBAction func addToFavouritesOrWishlist(_ sender: Any) {
        if isWishlist {
            if addToBarButton.image == UIImage(systemName: "star.fill") {
                // Remove from wishlist
                databaseController?.removePhotocardFromWishlist(photocard: photocard, user: currentUser)
                addToBarButton.image = UIImage(systemName: "star")
            } else {
                // Add to wishlist
                let result = databaseController?.addPhotocardToWishlist(photocard: photocard, user: currentUser)
                if result == true {
                    addToBarButton.image = UIImage(systemName: "star.fill")
                }
            }
        } else {
            if addToBarButton.image == UIImage(systemName: "heart.fill") {
                // Remove from favourites
                databaseController?.removePhotocardFromFavourites(photocard: photocard, user: currentUser)
                addToBarButton.image = UIImage(systemName: "heart")
            } else {
                // Add to favourites
                let result = databaseController?.addPhotocardToFavourites(photocard: photocard, user: currentUser)
                if result == true {
                    addToBarButton.image = UIImage(systemName: "heart.fill")
                }
            }
        }
    }
    
    @IBAction func findInMarket(_ sender: Any) {
        // Find in market
        // Go to photocard in market and show listings for that photocard.
        performSegue(withIdentifier: "photocardListingsFromPhotocardDetailsSegue", sender: self)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photocardListingsFromPhotocardDetailsSegue" {
            let destination = segue.destination as! PhotocardListingsViewController
            destination.photocard = self.photocard
        }
    }

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
    
    func onAllListingsChange(change: DatabaseChange, listings: [Listing]) {
        // Do nothing
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        currentUser = user
    }
    
}
