//
//  MyCollectionViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 01/05/2024.
//

import UIKit

class MyCollectionViewController: UIViewController, DatabaseListener, SetHeaderButtonActionDelegate {

    let SECTION_ALL = 0
    let SECTION_FAVOURITES = 1
    let CELL_PHOTOCARD = "photocardCell"
    let CELL_ADD = "addCell"
    let PLACEHOLDER_IMAGE = "Photocard_Placeholder"
    
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    
    var allList = [Photocard]()
    var favouritesList = [Photocard]()
    var wishList = [Photocard]()
    
    var numOfPhotocards: Int = 0
    var numOfArtists: Int = 0
    var favIdol = Idol()
    var favArtist = Artist()
    
    var photocard = Photocard()
    
    @IBOutlet weak var myCollectionsCollectionView: UICollectionView!
    
    @IBOutlet weak var totalPhotocardsButton: UIButton!
    @IBOutlet weak var totalArtistsButton: UIButton!
    @IBOutlet weak var favouriteIdolButton: UIButton!
    @IBOutlet weak var favouriteArtistButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Set collection view data source and delegate
        myCollectionsCollectionView.dataSource = self
        myCollectionsCollectionView.delegate = self
        
        myCollectionsCollectionView.isScrollEnabled = false
        
        // Set layout
        myCollectionsCollectionView.setCollectionViewLayout(createLayout(), animated: false)
        
        // Set overview data
        setupOverviewData(photocards: allList)
        
        // Navigation bar
        navigationItem.title = "My Collection"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // Get data from the user's collection
    func setupOverviewData(photocards: [Photocard]) {
        // Get data
        // Total photocards
        numOfPhotocards = photocards.count
        
        // Total artists
        var uniqueArtists = Set<Artist>()
        for photocard in photocards {
            if let artist = photocard.artist {
                uniqueArtists.insert(artist)
            }
        }
        numOfArtists = uniqueArtists.count
        
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
        var maxIdolCount = 0
        var maxArtistCount = 0
        for (idol, count) in sortedIdolsCount {
            if count > maxIdolCount {
                favIdol = idol
                maxIdolCount = count
            }
        }
        for (artist, count) in sortedArtistsCount {
            if count > maxArtistCount {
                favArtist = artist
                maxArtistCount = count
            }
        }
        
        // Set labels
        var totalPhotocardsContent = AttributedString(String(numOfPhotocards))
        totalPhotocardsContent.font = .systemFont(ofSize: 20.0)
        totalPhotocardsButton.configuration?.attributedSubtitle = totalPhotocardsContent
        
        var totalArtistsContent = AttributedString(String(numOfArtists))
        totalArtistsContent.font = .systemFont(ofSize: 20.0)
        totalArtistsButton.configuration?.attributedSubtitle = totalArtistsContent
        
        var favouriteIdolContent = AttributedString(favIdol.name ?? "Unavailable")
        favouriteIdolContent.font = .systemFont(ofSize: 20.0)
        favouriteIdolButton.configuration?.attributedSubtitle = favouriteIdolContent
        
        var favouriteArtistContent = AttributedString(favArtist.name ?? "Unavailable")
        favouriteArtistContent.font = .systemFont(ofSize: 20.0)
        favouriteArtistButton.configuration?.attributedSubtitle = favouriteArtistContent
    }
    
    // MARK: UICollectionViewCompositionalLayout
    
    func createHeaderLayout() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
        let headerLayout = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        return headerLayout
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        // Horizontal side-scrolling layout.
        //  * Group is 3 photocards side-by-side.
        //  * Group is 6/7 x screen width, and height is 34/77 x screen width.
        //  * Photocard width is 1/3 x group width, with height as 1 x group width
        //  * This makes item dimensions 5.5:8.5
        //  * contentInsets puts a 1 pixel margin around each poster.
        //  * orthogonalScrollingBehavior property allows side-scrolling.
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1))
        let itemLayout = NSCollectionLayoutItem(layoutSize: itemSize)
        itemLayout.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(6/7), heightDimension: .fractionalWidth(34/77))
        let groupLayout = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [itemLayout])
        
        let sectionLayout = NSCollectionLayoutSection(group: groupLayout)
        sectionLayout.orthogonalScrollingBehavior = .groupPaging
        sectionLayout.boundarySupplementaryItems = [createHeaderLayout()]
        sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        
        return UICollectionViewCompositionalLayout(section: sectionLayout)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photocardDetailsFromCollectionSegue" {
            let destination = segue.destination as! DetailsViewController
            // Pass selected photocard to view details
            destination.photocard = photocard
        } else if segue.identifier == "allCollectionsSegue" {
            let destination = segue.destination as! AllCollectionsCollectionViewController
            destination.allPhotocards = allList
            destination.favouritePhotocards = favouritesList
        } else if segue.identifier == "favouritesSegue" {
            let destination = segue.destination as! FavouritesCollectionViewController
            destination.favouritePhotocards = favouritesList
        }
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
    
    func onUserChange(change: DatabaseChange, user: User) {
        // Update collection
        allList = user.all
        favouritesList = user.favourites
        wishList = user.wishlist
        
        setupOverviewData(photocards: allList)
        myCollectionsCollectionView.reloadData()
    }
    
    // MARK: - SetHeaderButtonActionDelegate
    
    func showPhotocards(section: Int) {
        if section == SECTION_ALL {
            performSegue(withIdentifier: "allCollectionsSegue", sender: self)
        } else if section == SECTION_FAVOURITES {
            performSegue(withIdentifier: "favouritesSegue", sender: self)
        }
    }
    
}

// MARK: - UICollectionViewDataSource

extension MyCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
            case SECTION_ALL:
                return allList.count + 1
            case SECTION_FAVOURITES:
                return favouritesList.count
            default:
                return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == SECTION_ALL {
            if indexPath.row == 0 {
                let addCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ADD, for: indexPath)
                addCell.layer.cornerRadius = 10
                return addCell
            }
                
            let allCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! MyCollectionCollectionViewCell
            var reversedList = allList
            reversedList.reverse()
            
            if let imageName = reversedList[indexPath.row - 1].image {
                allCell.photocardImageView.image = UIImage(named: imageName)
            }
            allCell.layer.cornerRadius = 10
            return allCell
            
        } else {
            let favouriteCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! MyCollectionCollectionViewCell
            var reversedList = favouritesList
            reversedList.reverse()
            
            if let imageName = reversedList[indexPath.row].image {
                favouriteCell.photocardImageView.image = UIImage(named: imageName)
            }
            favouriteCell.layer.cornerRadius = 10
            return favouriteCell
        }
    }
}

// MARK: UICollectionViewDelegate

extension MyCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == SECTION_ALL {
            collectionView.cellForItem(at: indexPath)?.alpha = 0.5
            if indexPath.row == 0 {
                performSegue(withIdentifier: "addPhotocardSegue", sender: self)
                return
            }
            let allPhotocard = allList[allList.count - 1 - (indexPath.row - 1)]
            photocard = allPhotocard
            
        } else {
            collectionView.cellForItem(at: indexPath)?.alpha = 0.5
            let favouritePhotocard = favouritesList[favouritesList.count - 1 - indexPath.row]
            photocard = favouritePhotocard
        }
        
        performSegue(withIdentifier: "photocardDetailsFromCollectionSegue", sender: self)
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerView", for: indexPath) as? HeaderCollectionReusableView {
            sectionHeader.headerButtonDelegate = self
            sectionHeader.section = indexPath.section
            
            if indexPath.section == SECTION_ALL {
                sectionHeader.headerLabel.text = "Recently added"
            } else if indexPath.section == SECTION_FAVOURITES {
                sectionHeader.headerLabel.text = "Favourites"
            }
            sectionHeader.headerLabel.font = .systemFont(ofSize: 28, weight: .semibold)
            
            return sectionHeader
        }
        
        return UICollectionReusableView()
    }
    
}

