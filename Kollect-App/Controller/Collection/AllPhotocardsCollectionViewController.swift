//
//  AllPhotocardsCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/05/2024.
//

import UIKit

class AllPhotocardsCollectionViewController: UICollectionViewController, UISearchResultsUpdating {
    
    let CELL_PHOTOCARD = "photocardCell"
    var allPhotocards = [Photocard]()
    var filteredPhotocards = [Photocard]()
    var selectedPhotocards = [Photocard]()
    weak var databaseController: DatabaseProtocol?
    let DEFAULT_IMAGE = "Default_Photocard_Image"
    
    @IBOutlet weak var addPhotocardsBarButton: UIBarButtonItem!
    
    @IBAction func addPhotocards(_ sender: Any) {
        let isPluralText = self.selectedPhotocards.count == 1 ? "" : "s"
        
        let actionSheet = UIAlertController(title: nil, message: "Add photocard" + isPluralText + " to collection?", preferredStyle: .actionSheet)
        
        let addAction = UIAlertAction(title: "Add \(self.selectedPhotocards.count) photocard" + isPluralText, style: .default) { action in
            for photocard in self.selectedPhotocards {
                let photocardAdded = self.databaseController?.addPhotocardToCollection(photocard: photocard, user: self.databaseController!.currentUser) ?? false
                if !photocardAdded {
                    self.displayMessage(title: "Error", message: "Error adding photocards. Please try again.")
                    return
                }
            }
            
            // After delete from collection, clear selectedPhotocards and reload collection
            self.selectedPhotocards.removeAll()
            self.addPhotocardsBarButton.isEnabled = false
            self.navigationController?.isToolbarHidden = true
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(addAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "All Photocards"
        
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
        collectionView.allowsMultipleSelection = true
        
        addPhotocardsBarButton.isEnabled = false
        
        // Show tool bar
        let spaceItem = UIBarButtonItem(systemItem: .flexibleSpace)
        let labelItem = UIBarButtonItem(title: "Select Photocards", style: .plain, target: nil, action: nil)
        labelItem.isEnabled = false
        labelItem.setTitleTextAttributes([.foregroundColor: UIColor.label, .font: UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .disabled)
        
        toolbarItems = [spaceItem, labelItem, spaceItem]
        navigationController?.setToolbarItems(toolbarItems, animated: true)
        navigationController?.isToolbarHidden = false
        
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
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredPhotocards.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! AllPhotocardsCollectionViewCell
    
        let photocard = filteredPhotocards[indexPath.row]
        if let image = databaseController?.getImage(imageData: photocard.image!) {
            cell.photocardImageView.image = image
        }
        cell.layer.cornerRadius = 10
        
        if databaseController?.currentUser.all.contains(photocard) == true {
            cell.isUserInteractionEnabled = false
            cell.coverView.backgroundColor = .label
            cell.titleLabel.text = "Owned"
            cell.titleLabel.textColor = .systemBackground
            cell.coverView.layer.opacity = 0.5
        } else {
            cell.isUserInteractionEnabled = true
            cell.coverView.layer.opacity = 0
        }
    
        return cell
    }

    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photocard = filteredPhotocards[indexPath.row]
        
        // Display as selected
        collectionView.cellForItem(at: indexPath)?.layer.opacity = 0.5
        // Add to selection
        selectedPhotocards.append(photocard)
        // Enable button
        addPhotocardsBarButton.isEnabled = true
        // Update display text
        let isPluralText = self.selectedPhotocards.count == 1 ? "" : "s"
        toolbarItems?[1].title = "\(selectedPhotocards.count) Photocard" + isPluralText + " Selected"
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let photocard = filteredPhotocards[indexPath.row]
        
        // Display as deselected
        collectionView.cellForItem(at: indexPath)?.layer.opacity = 1
        // Remove from selection
        selectedPhotocards.removeAll { selectedPhotocard in
            return selectedPhotocard == photocard
        }
        // Disable buttons if no cells selected
        if selectedPhotocards.count == 0 {
            // Disable button
            addPhotocardsBarButton.isEnabled = false
            // Update display text
            toolbarItems?[1].title = "Select Photocards"
        } else {
            // Update display text
            let isPluralText = self.selectedPhotocards.count == 1 ? "" : "s"
            toolbarItems?[1].title = "\(selectedPhotocards.count) Photocard" + isPluralText + " Selected"
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
