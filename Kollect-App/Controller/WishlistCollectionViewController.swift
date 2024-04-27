//
//  WishlistCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 26/04/2024.
//

import UIKit

private let reuseIdentifier = "PhotocardCollectionViewCell"

class WishlistCollectionViewController: UICollectionViewController, DatabaseListener {
    
    var wishList = [Photocard]()
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
        return wishList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photocardCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotocardCollectionViewCell
        
        photocardCell.setup(with: wishList[indexPath.row])
        
        return photocardCell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        photocard = wishList[indexPath.row]
        performSegue(withIdentifier: "photocardDetailsFromWishlistSegue", sender: self)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: DatabaseListener
    
    func onAllArtistsChange(change: DatabaseChange, artists: [Artist]) {
        // Do nothing
    }
    
    func onAllGroupsChange(change: DatabaseChange, groups: [Group]) {
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
