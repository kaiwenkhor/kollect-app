//
//  AddToWishlistCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 08/05/2024.
//

import UIKit

class AddToWishlistCollectionViewController: UICollectionViewController, UISearchResultsUpdating {

    let CELL_PHOTOCARD = "photocardCell"
    var allPhotocards = [Photocard]()
    var filteredPhotocards = [Photocard]()
    var wishlistPhotocards = [Photocard]()
    weak var databaseController: DatabaseProtocol?
    let DEFAULT_IMAGE = "Default_Photocard_Image"
    
    var selectedPhotocards = [Photocard]()
    
    @IBAction func addToWishlist(_ sender: Any) {
        // Add to wishlist for photocard in photocards
        for photocard in selectedPhotocards {
            let photocardAdded = databaseController?.addPhotocardToWishlist(photocard: photocard, user: databaseController!.currentUser) ?? false
            if !photocardAdded {
                displayMessage(title: "Error Adding Photocard", message: "Unable to add photocard, please try again")
                return
            }
        }
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Select Photocards"
        navigationItem.backButtonTitle = "Back"
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredPhotocards = allPhotocards
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search All Photocards"
        navigationItem.searchController = searchController
        
        // This view controller decides how the search controller is presented.
        definesPresentationContext = true
        
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        
        // Allow multi select to add multiple photocards at once
        collectionView.allowsMultipleSelection = true
        
        collectionView.keyboardDismissMode = .onDrag
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        /*
         * Tiled layout
         * - Group is three photocards, side-by-side
         * - Group width is 1 x screen width, and height is 17/33 screen width (photocard height)
         * - Poster width is 1/3 x group width, with height as 1 x group width
         * - This makes item dimensions 5.5:8.5
         * - contentInsets puts a 1 pixel margin around each photocard
         */
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1))
        let itemLayout = NSCollectionLayoutItem(layoutSize: itemSize)
        itemLayout.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(17/33))
        let groupLayout = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [itemLayout])
        
        let sectionLayout = NSCollectionLayoutSection(group: groupLayout)
        
        return UICollectionViewCompositionalLayout(section: sectionLayout)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredPhotocards.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! AddToWishlistCollectionViewCell
    
        let photocard = filteredPhotocards[indexPath.row]
        if let image = databaseController?.getImage(imageData: photocard.image!) {
            cell.photocardImageView.image = image
        }
        cell.layer.cornerRadius = 10
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.alpha = 0.5
        let photocard = filteredPhotocards[indexPath.row]
        selectedPhotocards.append(photocard)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.alpha = 1
        let photocard = filteredPhotocards[indexPath.row]
        selectedPhotocards.removeAll { selectedPhotocard in
            return selectedPhotocard == photocard
        }
    }

    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            filteredPhotocards = allPhotocards.filter({ (photocard: Photocard) -> Bool in
                let searchArtist = photocard.artist?.name?.lowercased().contains(searchText) ?? false
                let searchIdol = photocard.idol?.name?.lowercased().contains(searchText) ?? false
                let searchAlbum =  photocard.album?.name?.lowercased().contains(searchText) ?? false
                return searchArtist || searchIdol || searchAlbum
            })
        } else {
            filteredPhotocards = allPhotocards
        }
        
        collectionView.reloadData()
    }

}
