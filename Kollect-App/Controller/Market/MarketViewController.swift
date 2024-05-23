//
//  MarketViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/05/2024.
//

import UIKit

class MarketViewController: UIViewController, UISearchBarDelegate, DatabaseListener {
    
    var allPhotocards = [Photocard]()
    
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .photocard
    
    @IBOutlet weak var cartBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Setup search bar
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.sizeToFit()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search Market"
        navigationItem.titleView = searchBar
        
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        performSegue(withIdentifier: "marketResultsSegue", sender: self)
//        searchBar.setShowsCancelButton(false, animated: true)
        return false
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // pass search text to collection view
//        if segue.identifier == "marketResultsSegue" {
//            let destination = segue.destination as! MarketResultsTableViewController
//            destination.allPhotocards = allPhotocards
//        }
    }
    
    @IBAction func showCart(_ sender: Any) {
        // segue to cart screen
//        performSegue(withIdentifier: "cartSegue", sender: self)
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
        allPhotocards = photocards
    }
    
    func onAllListingsChange(change: DatabaseChange, listings: [Listing]) {
        //
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        //
    }
    
}
