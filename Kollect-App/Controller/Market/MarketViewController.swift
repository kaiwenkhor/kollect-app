//
//  MarketViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/05/2024.
//

import UIKit

class MarketViewController: UIViewController, UISearchBarDelegate, DatabaseListener {
    
    let CELL_PHOTOCARD = "photocardCell"
    let VIEW_HEADER = "headerView"
    
    var allPhotocards = [Photocard]()
    var selectedPhotocard = Photocard()
    
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .photocard
    
    @IBOutlet weak var photocardsCollectionView: UICollectionView!
    
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
        
        photocardsCollectionView.dataSource = self
        photocardsCollectionView.delegate = self
        photocardsCollectionView.setCollectionViewLayout(createLayout(), animated: false)
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
        if segue.identifier == "photocardDetailsFromMarketSegue" {
            let destination = segue.destination as! DetailsViewController
            // Pass selected photocard to view details
            destination.photocard = selectedPhotocard
            destination.isWishlist = true
        }
    }
    
    // MARK: - UICollectionViewCompositionalLayout
    
    func createHeaderLayout() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let headerLayout = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        return headerLayout
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        /*
         * Tiled layout
         * - Group is three photocards, side-by-side
         * - Group width is 1 x screen width, and height is 1/2 screen width (photocard height)
         * - Poster width is 1/3 x group width, with height as 1 x group height
         * - This makes item dimensions 5.5:8.5
         * - contentInsets puts a 2 pixel margin around each photocard
         */
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1))
        let itemLayout = NSCollectionLayoutItem(layoutSize: itemSize)
        itemLayout.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(72/100))
        let groupLayout = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [itemLayout])
        groupLayout.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
        
        let sectionLayout = NSCollectionLayoutSection(group: groupLayout)
        sectionLayout.boundarySupplementaryItems = [createHeaderLayout()]
        sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 12, bottom: 20, trailing: 12)
        
        return UICollectionViewCompositionalLayout(section: sectionLayout)
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
        photocardsCollectionView.reloadData()
    }
    
    func onAllListingsChange(change: DatabaseChange, listings: [Listing]) {
        //
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        //
    }
    
}

extension MarketViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allPhotocards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! MarketPhotocardsCollectionViewCell
        
        let photocard = allPhotocards[indexPath.row]
        
        if let photocardImage = photocard.image {
            if let image = databaseController?.getImage(imageData: photocardImage) {
                cell.photocardImageView.image = image
            }
        }
        cell.photocardImageView.layer.cornerRadius = 10
        
        cell.idolLabel.text = photocard.idol?.name
        cell.artistLabel.text = photocard.artist?.name
        cell.albumLabel.text = photocard.album?.name
        
        return cell
    }
}

extension MarketViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPhotocard = allPhotocards[indexPath.row]
        performSegue(withIdentifier: "photocardDetailsFromMarketSegue", sender: self)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: VIEW_HEADER, for: indexPath) as? MarketPhotocardsHeaderCollectionReusableView {
            sectionHeader.headerLabel.text = "All Photocards"
            sectionHeader.headerLabel.font = .systemFont(ofSize: 28, weight: .semibold)
            
            return sectionHeader
        }
        
        return UICollectionReusableView()
    }
}
