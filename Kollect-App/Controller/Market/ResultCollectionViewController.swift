//
//  ResultCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 22/05/2024.
//

import UIKit

class ResultCollectionViewController: UICollectionViewController, UISearchBarDelegate {
    
    let CELL_PHOTOCARD = "photocardCell"
    var filteredPhotocards = [Photocard]()
    var allPhotocards = [Photocard]()
    var selectedPhotocard = Photocard()
    
    let searchBar = UISearchBar()
    var keyword: String?
    
    weak var databaseController: DatabaseProtocol?
    
    // TODO: Add Search History as Core Data

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredPhotocards = allPhotocards
        
        // Setup search bar
        searchBar.delegate = self
        searchBar.sizeToFit()
        searchBar.searchBarStyle = .minimal
        searchBar.text = keyword
        navigationItem.titleView = searchBar
        
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        
        collectionView.keyboardDismissMode = .onDrag
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchFromResultSegue" {
            let destination = segue.destination as! MarketResultsTableViewController
            destination.keyword = self.keyword
        } else if segue.identifier == "photocardListingsSegue" {
            let destination = segue.destination as! PhotocardListingsViewController
            destination.photocard = selectedPhotocard
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! ResultCollectionViewCell
    
        let photocard = filteredPhotocards[indexPath.row]
        
        cell.photocardImageView.image = UIImage(named: photocard.image!)
        cell.photocardImageView.layer.cornerRadius = 10
        
        cell.idolLabel.text = photocard.idol?.name
        cell.artistLabel.text = photocard.artist?.name
        cell.albumLabel.text = photocard.album?.name
    
        return cell
    }

    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.alpha = 0.5
        
        selectedPhotocard = filteredPhotocards[indexPath.row]
        performSegue(withIdentifier: "photocardListingsSegue", sender: self)
        
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.cellForItem(at: indexPath)?.alpha = 1.0
    }

    // MARK: - UICollectionViewCompositionalLayout
    
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
        sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 12, bottom: 20, trailing: 12)
        
        return UICollectionViewCompositionalLayout(section: sectionLayout)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        performSegue(withIdentifier: "searchFromResultSegue", sender: self)
        return false
    }
    
}
