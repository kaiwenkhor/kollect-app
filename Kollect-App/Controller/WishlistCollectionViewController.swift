//
//  WishlistCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 26/04/2024.
//

import UIKit

private let reuseIdentifier = "PhotocardCollectionViewCell"

class WishlistCollectionViewController: UICollectionViewController, UISearchResultsUpdating, DatabaseListener {
    
    var wishList = [Photocard]()
    var filteredList = [Photocard]()
    var photocard = Photocard()
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredList = wishList
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Wishlist"
        navigationItem.searchController = searchController
        
        // This view controller decides how the search controller is presented
        definesPresentationContext = true
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photocardDetailsFromWishlistSegue" {
            let destination = segue.destination as! DetailsViewController
            // Pass selected photocard to view details
            destination.photocard = photocard
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return filteredList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photocardCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotocardCollectionViewCell
        
        photocardCell.setup(with: filteredList[indexPath.row])
        
        return photocardCell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        photocard = filteredList[indexPath.row]
        performSegue(withIdentifier: "photocardDetailsFromWishlistSegue", sender: self)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            filteredList = wishList.filter({ (photocard: Photocard) -> Bool in
                let searchArtist = photocard.artist?.name?.lowercased().contains(searchText) ?? false
                let searchIdol = photocard.idol?.name?.lowercased().contains(searchText) ?? false
                let searchAlbum =  photocard.album?.name?.lowercased().contains(searchText) ?? false
                return searchArtist || searchIdol || searchAlbum
            })
        } else {
            filteredList = wishList
        }
        
        collectionView.reloadData()
    }
    
    // MARK: DatabaseListener
    
    func onAllIdolsChange(change: DatabaseChange, idols: [Idol]) {
        // Do nothing
    }
    
    func onAllArtistsChange(change: DatabaseChange, artists: [Artist]) {
        // Do nothing
    }
    
    func onAllAlbumsChange(change: DatabaseChange, albums: [Album]) {
        // Do nothing
    }
    
    func onAllPhotocardsChange(change: DatabaseChange, photocards: [Photocard]) {
        // Do nothing
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        wishList = user.wishlist
        collectionView.reloadData()
    }

}
