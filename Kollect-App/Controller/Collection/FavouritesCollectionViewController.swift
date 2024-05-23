//
//  FavouritesCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 08/05/2024.
//

import UIKit

class FavouritesCollectionViewController: UICollectionViewController, UISearchResultsUpdating, DatabaseListener {

    let CELL_PHOTOCARD = "photocardCell"
    var filteredPhotocards = [Photocard]()
    var favouritePhotocards = [Photocard]()
    var selectedPhotocard = Photocard()
    var selectedPhotocards = [Photocard]()
    var isEditingMode = false
    weak var databaseController: DatabaseProtocol?
    var currentUser = User()
    var listenerType = ListenerType.user
    let DEFAULT_IMAGE = "Default_Photocard_Image"
    
    @IBOutlet weak var editFavouritesBarButton: UIBarButtonItem!
    
    @IBAction func editFavourites(_ sender: Any) {
        if editFavouritesBarButton.title == "Select" && !isEditingMode {
            // Edit
            editFavouritesBarButton.title = "Cancel"
            isEditingMode = true
            collectionView.allowsMultipleSelection = true
            
            // Show tool bar
            let spaceItem = UIBarButtonItem(systemItem: .flexibleSpace)
            
            let favouriteItem = UIBarButtonItem(image: UIImage(systemName: "heart.slash"), primaryAction: UIAction { action in
                // Remove selected photocards from favourite
                for photocard in self.selectedPhotocards {
                    self.databaseController?.removePhotocardFromFavourites(photocard: photocard, user: self.currentUser)
                }
                
                self.selectedPhotocards.removeAll()
                self.editFavouritesBarButton.title = "Select"
                self.isEditingMode = false
                self.collectionView.allowsMultipleSelection = false
                
                self.navigationController?.isToolbarHidden = true
            })
            favouriteItem.isEnabled = false
            
            let removeItem = UIBarButtonItem(systemItem: .trash, primaryAction: UIAction { action in
                let isPluralText = self.selectedPhotocards.count == 1 ? "" : "s"
                let actionSheet = UIAlertController(title: nil, message: "Remove photocard" + isPluralText + " from collection?", preferredStyle: .actionSheet)
                
                let removeAction = UIAlertAction(title: "Remove \(self.selectedPhotocards.count) photocard" + isPluralText, style: .destructive) { action in
                    for photocard in self.selectedPhotocards {
                        self.databaseController?.removePhotocardFromCollection(photocard: photocard, user: self.currentUser)
                    }
                    
                    // After delete from collection, clear selectedPhotocards and reload collection
                    self.selectedPhotocards.removeAll()
                    self.editFavouritesBarButton.title = "Select"
                    self.isEditingMode = false
                    self.collectionView.allowsMultipleSelection = false
                    
                    self.navigationController?.isToolbarHidden = true
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                actionSheet.addAction(removeAction)
                actionSheet.addAction(cancelAction)
                
                self.present(actionSheet, animated: true, completion: nil)
            })
            removeItem.isEnabled = false
            
            let labelItem = UIBarButtonItem(title: "Select Photocards", style: .plain, target: nil, action: nil)
            labelItem.isEnabled = false
            labelItem.setTitleTextAttributes([.foregroundColor: UIColor.label, .font: UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .disabled)
            
            toolbarItems = [favouriteItem, spaceItem, labelItem, spaceItem, removeItem]
            navigationController?.setToolbarItems(toolbarItems, animated: true)
            navigationController?.isToolbarHidden = false
            
        } else {
            // Cancel
            editFavouritesBarButton.title = "Select"
            isEditingMode = false
            selectedPhotocards.removeAll()
            collectionView.allowsMultipleSelection = false
            collectionView.reloadData()
            
            navigationController?.isToolbarHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "My Favourites"
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredPhotocards = favouritePhotocards
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Favourite Photocards"
        navigationItem.searchController = searchController
        
        // This view controller decides how the search controller is presented.
        definesPresentationContext = true
        
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        
        navigationController?.isToolbarHidden = true
        
        collectionView.keyboardDismissMode = .onDrag
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        /*
         * Tiled layout
         * - Group is three photocards, side-by-side
         * - Group width is 1 x screen width, and height is 17/33 screen width (photocard height)
         * - Poster width is 1/3 x group width, with height as 1 x group width
         * - This makes item dimensions 5.5:8.5
         * - contentInsets puts a 2 pixel margin around each photocard
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
        if segue.identifier == "photocardDetailsFromFavouritesSegue" {
            let destination = segue.destination as! DetailsViewController
            // Pass selected photocard to view details
            destination.photocard = selectedPhotocard
            destination.isWishlist = false
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredPhotocards.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! FavouritesCollectionViewCell
    
        let photocard = filteredPhotocards[indexPath.row]
        cell.photocardImageView.image = UIImage(named: photocard.image ?? DEFAULT_IMAGE)
        
        if favouritePhotocards.contains(photocard) {
            cell.favouriteImageView.isHidden = false
        } else {
            cell.favouriteImageView.isHidden = true
        }
        cell.favouriteImageView.layer.shadowColor = UIColor.black.cgColor
        cell.favouriteImageView.layer.shadowOffset = CGSize(width: -2, height: 2)
        cell.favouriteImageView.layer.shadowOpacity = 1.0
        cell.favouriteImageView.layer.shadowRadius = 12.0
        cell.favouriteImageView.clipsToBounds = false
        
        cell.layer.cornerRadius = 10
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photocard = filteredPhotocards[indexPath.row]
        print("PHOTOCARD \(photocard.image ?? DEFAULT_IMAGE) SELECTED")
        
        if isEditingMode {
            // Show cell as selected
            collectionView.cellForItem(at: indexPath)?.layer.opacity = 0.5
            // Add to selection
            selectedPhotocards.append(photocard)
            // Enable the buttons if a cell is selected
            if selectedPhotocards.count > 0 {
                toolbarItems?.first?.isEnabled = true
                toolbarItems?.last?.isEnabled = true
                // Update display text
                if selectedPhotocards.count == 1 {
                    toolbarItems?[2].title = "\(selectedPhotocards.count) Photocard Selected"
                } else {
                    toolbarItems?[2].title = "\(selectedPhotocards.count) Photocards Selected"
                }
            } else {
                toolbarItems?.first?.isEnabled = false
                toolbarItems?.last?.isEnabled = false
                toolbarItems?[2].title = "Select Photocards"
            }
        } else {
            selectedPhotocard = photocard
            performSegue(withIdentifier: "photocardDetailsFromFavouritesSegue", sender: self)
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.alpha = 1
        let photocard = filteredPhotocards[indexPath.row]
        print("PHOTOCARD \(photocard.image ?? DEFAULT_IMAGE) DESELECTED")
        
        // Remove from selection
        selectedPhotocards.removeAll { selectedPhotocard in
            return selectedPhotocard == photocard
        }
        // Disable buttons if no cells selected
        if selectedPhotocards.count == 0 {
            toolbarItems?.first?.isEnabled = false
            toolbarItems?.last?.isEnabled = false
            // Update display text
            toolbarItems?[2].title = "Select Photocards"
        } else {
            toolbarItems?.first?.isEnabled = true
            toolbarItems?.last?.isEnabled = true
            // Update display text
            if selectedPhotocards.count == 1 {
                toolbarItems?[2].title = "\(selectedPhotocards.count) Photocard Selected"
            } else {
                toolbarItems?[2].title = "\(selectedPhotocards.count) Photocards Selected"
            }
        }
    }

    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            filteredPhotocards = favouritePhotocards.filter({ (photocard: Photocard) -> Bool in
                let searchArtist = photocard.artist?.name?.lowercased().contains(searchText) ?? false
                let searchIdol = photocard.idol?.name?.lowercased().contains(searchText) ?? false
                let searchAlbum = photocard.album?.name?.lowercased().contains(searchText) ?? false
                return searchArtist || searchIdol || searchAlbum
            })
        } else {
            filteredPhotocards = favouritePhotocards
        }
        
        collectionView.reloadData()
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
        favouritePhotocards = user.favourites
        currentUser = user
        
        filteredPhotocards = favouritePhotocards
        collectionView.reloadData()
    }
    
}
