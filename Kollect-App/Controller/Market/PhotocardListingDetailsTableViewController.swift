//
//  PhotocardListingDetailsTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/06/2024.
//

import UIKit

class PhotocardListingDetailsTableViewController: UITableViewController {
    
    let numOfRows: Int = 5
    let CELL_IMAGE = "imageCell"
    let CELL_DETAILS = "detailsCell"
    let CELL_INFO = "infoCell"
    
    var listing: Listing?
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numOfRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // UIScrollView
        if indexPath.row == 0 {
            let imageCell = tableView.dequeueReusableCell(withIdentifier: CELL_IMAGE, for: indexPath) as! ListingImagesTableViewCell
            
            if let frontImage = databaseController?.getImage(imageData: listing!.images.first!) {
                imageCell.frontImageView.image = frontImage
            }
            if let backImage = databaseController?.getImage(imageData: listing!.images.last!) {
                imageCell.backImageView.image = backImage
            }
            
            return imageCell
            
        } else if indexPath.row == 1 {
            let detailsCell = tableView.dequeueReusableCell(withIdentifier: CELL_DETAILS, for: indexPath) as! ListingDetailsTableViewCell
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = Locale(identifier: "en_AU")
            numberFormatter.formatterBehavior = .default
            detailsCell.priceLabel.text = numberFormatter.string(for: listing?.price)
            
            detailsCell.artistLabel.text = listing?.photocard?.artist?.name
            detailsCell.idolLabel.text = listing?.photocard?.idol?.name
            detailsCell.albumLabel.text = listing?.photocard?.album?.name
            
            return detailsCell
            
        } else {
            let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath) as! ListingInfoTableViewCell
            
            // Description
            if indexPath.row == 2 {
                infoCell.titleLabel.text = "Description"
                infoCell.contentLabel.text = listing?.descriptionText
            }
            
            // Posted by
            else if indexPath.row == 3 {
                infoCell.titleLabel.text = "Posted by"
                infoCell.contentLabel.text = listing?.seller?.name
            }
            
            // Date posted
            else if indexPath.row == 4 {
                infoCell.titleLabel.text = "Date posted"
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                if let listDate = listing?.listDate, let stringToDate = dateFormatter.date(from: listDate) {
                    dateFormatter.timeZone = TimeZone(abbreviation: TimeZone.current.abbreviation()!)
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateToString = dateFormatter.string(from: stringToDate)
                    infoCell.contentLabel.text = dateToString
                }
            }
            
            return infoCell
        }
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Chat segue
        // Pass seller info
    }

}
