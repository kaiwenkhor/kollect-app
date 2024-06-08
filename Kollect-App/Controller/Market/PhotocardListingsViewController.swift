//
//  PhotocardListingsViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 22/05/2024.
//

import UIKit

class PhotocardListingsViewController: UIViewController, DatabaseListener {
    
    let CELL_LISTING = "listingCell"
    
    var photocard = Photocard()
    var allListings = [Listing]()
    var filteredListings = [Listing]()
    var selectedListing = Listing()
    
    var currentUser = User()
    
    var listenerType: ListenerType = .listing
    weak var databaseController: DatabaseProtocol?
    
    var wishlistBarButton: UIBarButtonItem!
    var sellBarButton: UIBarButtonItem!
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var photocardImageView: UIImageView!
    @IBOutlet weak var idolLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    
    @IBOutlet weak var listingsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        navigationItem.title = "Photocard"
        
        currentUser = databaseController!.currentUser
        
        // Setup navigation bar buttons
        wishlistBarButton = UIBarButtonItem(image: UIImage(systemName: "star"), primaryAction: UIAction { action in
            if self.currentUser.isAnonymous == true {
                self.performSegue(withIdentifier: "logInFromPhotocardListingsSegue", sender: self)
                return
            }
            if self.wishlistBarButton.image == UIImage(systemName: "star.fill") {
                // Remove from wishlist
                self.databaseController?.removePhotocardFromWishlist(photocard: self.photocard, user: self.currentUser)
                self.wishlistBarButton.image = UIImage(systemName: "star")
            } else {
                // Add to wishlist
                let result = self.databaseController?.addPhotocardToWishlist(photocard: self.photocard, user: self.currentUser)
                if result == true {
                    self.wishlistBarButton.image = UIImage(systemName: "star.fill")
                }
            }
        })
        
        sellBarButton = UIBarButtonItem(title: "Sell", primaryAction: UIAction { action in
            if self.currentUser.isAnonymous == true {
                self.performSegue(withIdentifier: "logInFromPhotocardListingsSegue", sender: self)
                return
            }
            // Create listing -> go to create listing screen
            self.performSegue(withIdentifier: "addListingSegue", sender: self)
        })
        
        navigationItem.rightBarButtonItems = [sellBarButton, wishlistBarButton]
        
        // Setup photocard and photocard details
        backgroundView.layer.cornerRadius = 20
        if let image = databaseController?.getImage(imageData: photocard.image!) {
            photocardImageView.image = image
        }
        photocardImageView.layer.cornerRadius = 8
        idolLabel.text = photocard.idol?.name
        artistLabel.text = photocard.artist?.name
        albumLabel.text = photocard.album?.name
        
        filteredListings = allListings
        
        listingsTableView.dataSource = self
        listingsTableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        currentUser = databaseController!.currentUser
        // Setup bar button items
        if currentUser.wishlist.contains(photocard) {
            wishlistBarButton.image = UIImage(systemName: "star.fill")
        } else {
            wishlistBarButton.image = UIImage(systemName: "star")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photocardListingDetailsSegue" {
            let destination = segue.destination as! PhotocardListingDetailsTableViewController
            destination.listing = selectedListing
        } else if segue.identifier == "addListingSegue" {
            let destination = segue.destination as! AddListingViewController
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
        allListings = listings
        getPhotocardListings()
        listingsTableView.reloadData()
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        //
    }
    
    // MARK: - Exclusive Methods
    
    func getPhotocardListings() {
        filteredListings = allListings.filter({ (listing: Listing) -> Bool in
            let matchingListing = (listing.photocard == self.photocard)
            return matchingListing
        })
    }

}

// MARK: - UITableViewDataSource
// FIXME: Something wrong with the constraints in cell
extension PhotocardListingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredListings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_LISTING, for: indexPath) as! PhotocardListingsTableViewCell
        
        let listing = filteredListings[indexPath.row]
        
        // Load image
        if let firstImage = listing.images.first {
            if let image = databaseController?.getImage(imageData: firstImage) {
                cell.photocardImageView.image = image
            }
        } else {
            print("Image not found")
        }
        
        // Format Price
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: "en_AU")
        numberFormatter.formatterBehavior = .default
        cell.priceLabel.text = numberFormatter.string(for: listing.price)
        
        // Format Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        if let listDate = listing.listDate, let stringToDate = dateFormatter.date(from: listDate) {
            dateFormatter.timeZone = TimeZone(abbreviation: TimeZone.current.abbreviation()!)
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateToString = dateFormatter.string(from: stringToDate)
            cell.dateLabel.text = dateToString
        }
        
        if let image = databaseController?.getImage(imageData: listing.seller!.image!) {
            cell.userImageView.image = image
        }
        cell.userImageView.layer.cornerRadius = cell.userImageView.frame.width / 2
        
        cell.userLabel.text = listing.seller?.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(filteredListings.count) Listings"
    }
}

// MARK: - UITableViewDelegate

extension PhotocardListingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedListing = filteredListings[indexPath.row]
        performSegue(withIdentifier: "photocardListingDetailsSegue", sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
