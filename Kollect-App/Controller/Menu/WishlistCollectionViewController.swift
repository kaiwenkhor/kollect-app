//
//  WishlistCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 26/04/2024.
//

import UIKit

class WishlistCollectionViewController: UICollectionViewController, UISearchResultsUpdating, DatabaseListener {
    
    let CELL_PHOTOCARD = "photocardCell"
    var filteredPhotocards = [Photocard]()
    var wishlistPhotocards = [Photocard]()
    var selectedPhotocard = Photocard()
    var selectedPhotocards = [Photocard]()
    var isEditingMode = false
    weak var databaseController: DatabaseProtocol?
    var currentUser = User()
    var listenerType = ListenerType.user
    let DEFAULT_IMAGE = "Default_Photocard_Image"
    
    @IBOutlet weak var editWishlistBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Wishlist"
        
        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredPhotocards = wishlistPhotocards
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Wishlist Photocards"
        navigationItem.searchController = searchController
        
        // This view controller decides how the search controller is presented
        definesPresentationContext = true
        
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        
        navigationController?.isToolbarHidden = true
        
        collectionView.keyboardDismissMode = .onDrag
    }
    
    @IBAction func editWishlist(_ sender: Any) {
        if editWishlistBarButton.title == "Select" && !isEditingMode {
            // Edit
            editWishlistBarButton.title = "Cancel"
            isEditingMode = true
            collectionView.allowsMultipleSelection = true
            
            // Show tool bar
            let spaceItem = UIBarButtonItem(systemItem: .flexibleSpace)
            
            let wishlistItem = UIBarButtonItem(image: UIImage(systemName: "star.slash"), primaryAction: UIAction { action in
                // Remove selected photocards from wishlist
                for photocard in self.selectedPhotocards {
                    self.databaseController?.removePhotocardFromWishlist(photocard: photocard, user: self.currentUser)
                }
                
                self.selectedPhotocards.removeAll()
                self.editWishlistBarButton.title = "Select"
                self.isEditingMode = false
                self.collectionView.allowsMultipleSelection = false
                
                self.navigationController?.isToolbarHidden = true
            })
            wishlistItem.isEnabled = false
            
            let labelItem = UIBarButtonItem(title: "Select Photocards", style: .plain, target: nil, action: nil)
            labelItem.isEnabled = false
            labelItem.setTitleTextAttributes([.foregroundColor: UIColor.label, .font: UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .disabled)
            
            toolbarItems = [wishlistItem, spaceItem, labelItem, spaceItem]
            navigationController?.setToolbarItems(toolbarItems, animated: true)
            navigationController?.isToolbarHidden = false
            
        } else {
            // Cancel
            editWishlistBarButton.title = "Select"
            isEditingMode = false
            selectedPhotocards.removeAll()
            collectionView.allowsMultipleSelection = false
            collectionView.reloadData()
            
            navigationController?.isToolbarHidden = true
        }
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
        if segue.identifier == "photocardDetailsFromWishlistSegue" {
            let destination = segue.destination as! DetailsViewController
            // Pass selected photocard to view details
            destination.photocard = selectedPhotocard
            destination.isWishlist = true
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredPhotocards.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! WishlistCollectionViewCell
    
        let photocard = filteredPhotocards[indexPath.row]
        if let image = databaseController?.getImage(imageData: photocard.image!) {
            cell.photocardImageView.image = image
        }
        cell.layer.cornerRadius = 10
    
        return cell
    }

    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photocard = filteredPhotocards[indexPath.row]
        
        if isEditingMode {
            // Show cell as selected
            collectionView.cellForItem(at: indexPath)?.layer.opacity = 0.5
            // Add to selection
            selectedPhotocards.append(photocard)
            // Enable the buttons if a cell is selected
            toolbarItems?.first?.isEnabled = true
            // Update display text
            let isPluralText = self.selectedPhotocards.count == 1 ? "" : "s"
            toolbarItems?[2].title = "\(selectedPhotocards.count) Photocard" + isPluralText + " Selected"
            
        } else {
            selectedPhotocard = photocard
            performSegue(withIdentifier: "photocardDetailsFromWishlistSegue", sender: self)
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let photocard = filteredPhotocards[indexPath.row]
        
        // Display as deselected
        collectionView.cellForItem(at: indexPath)?.alpha = 1
        // Remove from selection
        selectedPhotocards.removeAll { selectedPhotocard in
            return selectedPhotocard == photocard
        }
        // Disable buttons if no cells selected
        if selectedPhotocards.count == 0 {
            toolbarItems?.first?.isEnabled = false
            // Update display text
            toolbarItems?[2].title = "Select Photocards"
        } else {
            // Update display text
            let isPluralText = self.selectedPhotocards.count == 1 ? "" : "s"
            toolbarItems?[2].title = "\(selectedPhotocards.count) Photocard" + isPluralText + " Selected"
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            filteredPhotocards = wishlistPhotocards.filter({ (photocard: Photocard) -> Bool in
                let searchArtist = photocard.artist?.name?.lowercased().contains(searchText) ?? false
                let searchIdol = photocard.idol?.name?.lowercased().contains(searchText) ?? false
                let searchAlbum =  photocard.album?.name?.lowercased().contains(searchText) ?? false
                return searchArtist || searchIdol || searchAlbum
            })
        } else {
            filteredPhotocards = wishlistPhotocards
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
    
    func onAllListingsChange(change: DatabaseChange, listings: [Listing]) {
        // Do nothing
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        wishlistPhotocards = user.wishlist
        currentUser = user
        
        filteredPhotocards = wishlistPhotocards
        collectionView.reloadData()
    }

}
