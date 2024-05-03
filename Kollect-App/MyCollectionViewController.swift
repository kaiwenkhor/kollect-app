//
//  MyCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 01/05/2024.
//

import UIKit

class MyCollectionViewController: UIViewController, DatabaseListener {

    let SECTION_ALL = 0
    let SECTION_FAVOURITES = 1
    let SECTION_WISHLIST = 2
    let CELL_PHOTOCARD = "photocardCell"
    
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    
    var allList = [Photocard]()
    var favouritesList = [Photocard]()
    var wishList = [Photocard]()
    
    var numOfArtists: Int?
    var numOfPhotocards: Int?
    var favArtist: Artist?
    var favIdol: Idol?
    
    var photocard = Photocard()
    
    @IBOutlet weak var myCollectionsCollectionView: UICollectionView!
    
    @IBOutlet weak var totalPhotocardsButton: UIButton!
    @IBOutlet weak var totalArtistsButton: UIButton!
    @IBOutlet weak var favouriteIdolButton: UIButton!
    @IBOutlet weak var favouriteArtistButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Set collection view data source and delegate
        myCollectionsCollectionView.dataSource = self
        myCollectionsCollectionView.delegate = self
        
        // Set layout
        myCollectionsCollectionView.setCollectionViewLayout(generateLayout(), animated: false)
        
        // Set overview data
        setupOverviewData(photocards: allList)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
        navigationController?.navigationBar.isHidden = false
    }
    
    // Get data from the user's collection
    func setupOverviewData(photocards: [Photocard]) {
        // Get data
        // Total photocards
        let totalPhotocards = photocards.count
        
        // Total artists
        var uniqueArtists = Set<Artist>()
        for photocard in photocards {
            if let artist = photocard.artist {
                uniqueArtists.insert(artist)
            }
        }
        let totalArtists = uniqueArtists.count
        
        // Favourite idol and artist
        var idolsCount = [Idol: Int]()
        var artistsCount = [Artist: Int]()
        for photocard in photocards {
            if let idol = photocard.idol {
                idolsCount[idol, default: 0] += 1
            }
            if let artist = photocard.artist {
                artistsCount[artist, default: 0] += 1
            }
        }
        
        // Sort dictionary in case of same values, get the first alphabetically
        let sortedIdolsCount = idolsCount.sorted(by: { $0.0.name! < $1.0.name! })
        let sortedArtistsCount = artistsCount.sorted(by: { $0.0.name! < $1.0.name! })
        
        // Get idol and artist with most count
        var favouriteIdol = Idol()
        var favouriteArtist = Artist()
        var maxIdolCount = 0
        var maxArtistCount = 0
        for (idol, count) in sortedIdolsCount {
            if count > maxIdolCount {
                favouriteIdol = idol
                maxIdolCount = count
            }
        }
        for (artist, count) in sortedArtistsCount {
            if count > maxArtistCount {
                favouriteArtist = artist
                maxArtistCount = count
            }
        }
        
        // Set labels
        totalPhotocardsButton.titleLabel?.text = "Total photocards"
        totalPhotocardsButton.subtitleLabel?.text = String(totalPhotocards)
        
        totalArtistsButton.titleLabel?.text = "Total artists"
        totalArtistsButton.subtitleLabel?.text = String(totalArtists)
        
        favouriteIdolButton.titleLabel?.text = "Favourite idol"
        favouriteIdolButton.subtitleLabel?.text = favouriteIdol.name
        
        favouriteArtistButton.titleLabel?.text = "Favourite artist"
        favouriteArtistButton.subtitleLabel?.text = favouriteArtist.name
    }
    
    // MARK: UICollectionViewCompositionalLayout
    
    func generateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(2/7), heightDimension: .fractionalWidth(34/77))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        
        // Section header
//        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        //        let headerLayout =
        //        section.boundarySupplementaryItems = [headerLayout]
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photocardDetailsFromCollectionSegue" {
            let destination = segue.destination as! DetailsViewController
            // Pass selected photocard to view details
            destination.photocard = photocard
        }
    }
    
    // MARK: DatabaseListener
    
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
    
    func onUserChange(change: DatabaseChange, user: User) {
        // Update collection
        allList = user.all
        favouritesList = user.favourites
        wishList = user.wishlist
        
        setupOverviewData(photocards: allList)
        myCollectionsCollectionView.reloadData()
    }

}

// MARK: UICollectionViewDataSource

extension MyCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
            case SECTION_ALL:
                return allList.count
            case SECTION_FAVOURITES:
                return favouritesList.count
            case SECTION_WISHLIST:
                return wishList.count
            default:
                return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == SECTION_ALL {
            let allCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! MyCollectionCollectionViewCell
            
            if let imageName = allList[indexPath.row].image {
                allCell.photocardImageView.image = UIImage(named: imageName)
            }
            // Set header as ALL
            
            return allCell
            
        } else if indexPath.section == SECTION_FAVOURITES {
            let favouriteCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! MyCollectionCollectionViewCell
            
            if let imageName = favouritesList[indexPath.row].image {
                favouriteCell.photocardImageView.image = UIImage(named: imageName)
            }
            // Set header as FAVOURITES
            
            return favouriteCell
            
        } else {
            let wishlistCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! MyCollectionCollectionViewCell
            
            if let imageName = wishList[indexPath.row].image {
                wishlistCell.photocardImageView.image = UIImage(named: imageName)
            }
            // Set header as WISHLIST
            
            return wishlistCell
        }
    }
}

// MARK: UICollectionViewDelegate

extension MyCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == SECTION_ALL {
            let allPhotocard = allList[indexPath.row]
            photocard = allPhotocard
            
        } else if indexPath.section == SECTION_FAVOURITES {
            let favouritePhotocard = favouritesList[indexPath.row]
            photocard = favouritePhotocard
            
        } else {
            let wishlistPhotocard = wishList[indexPath.row]
            photocard = wishlistPhotocard
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

