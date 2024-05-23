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
    
    var listenerType: ListenerType = .listing
    weak var databaseController: DatabaseProtocol?
    
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sell", primaryAction: UIAction { action in
            // Go to sell page where user can fill in listing details and post listing.
        })
        
        // Setup photocard and photocard details
        backgroundView.layer.cornerRadius = 20
        photocardImageView.image = UIImage(named: photocard.image ?? "Default_Photocard_Image")
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photocardListingDetailsSegue" {
            let destination = segue.destination as! PhotocardListingDetailsViewController
//            destination.listing = selectedListing
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
        print(listings)
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
        print(filteredListings)
    }

}

// MARK: - UITableViewDataSource

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
//        cell.photocardImageView.image = listing.images.first!
        cell.photocardImageView.image = .defaultPhotocard
        // Format Price
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.formatterBehavior = .default
        cell.priceLabel.text = numberFormatter.string(from: listing.price! as NSNumber)
        // Format Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        if let stringToDate = dateFormatter.date(from: "2024-05-22 02:01:43 +0000") {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateToString = dateFormatter.string(from: stringToDate)
            cell.dateLabel.text = dateToString
        }
//        cell.dateLabel.text = dateFormatter.string(from: listing.listDate)
//        cell.userImageView.image = listing.seller?.image
        cell.userImageView.image = .defaultProfile
        cell.userImageView.layer.cornerRadius = cell.userImageView.frame.width / 2
//        cell.userLabel.text = listing.seller?.name
        cell.userLabel.text = "john_doe"
        
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
