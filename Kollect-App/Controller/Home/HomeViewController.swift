//
//  HomeViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 10/05/2024.
//

import UIKit

class HomeViewController: UIViewController, DatabaseListener {
    
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    
    var allList = [Photocard]()
    
    var numOfPhotocards: Int = 0
    var numOfArtists: Int = 0
    var favIdol = Idol()
    var favArtist = Artist()
    
    var photocard = Photocard()
    
    @IBOutlet weak var totalPhotocardsButton: UIButton!
    @IBOutlet weak var totalArtistsButton: UIButton!
    @IBOutlet weak var favouriteIdolButton: UIButton!
    @IBOutlet weak var favouriteArtistButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Set overview data
        setupOverviewData(photocards: allList)
        
        // Navigation bar
        navigationItem.title = "Overview"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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
        
        setupOverviewData(photocards: allList)
//        myCollectionsCollectionView.reloadData()
    }
    
}
