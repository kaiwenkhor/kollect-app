//
//  AllArtistsTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 02/05/2024.
//

import UIKit

class AllArtistsTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {
    
    let CELL_ARTIST = "artistCell"
    var allArtists = [Artist]()
    var filteredArtists = [Artist]()
    var listenerType = ListenerType.artist
    weak var databaseController: DatabaseProtocol?
    weak var artistDelegate: SelectArtistDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredArtists = allArtists
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search All Artists"
        navigationItem.searchController = searchController
        
        // This view controller decides how the search controller is presented.
        definesPresentationContext = true
        
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredArtists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure and return an artist cell
        let artistCell = tableView.dequeueReusableCell(withIdentifier: CELL_ARTIST, for: indexPath)
        
        var content = artistCell.defaultContentConfiguration()
        let artist = filteredArtists[indexPath.row]
        content.text = artist.name
        artistCell.contentConfiguration = content
        
        return artistCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let artistDelegate = artistDelegate {
            if artistDelegate.selectArtist(filteredArtists[indexPath.row]) {
                navigationController?.popViewController(animated: true)
                return
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            filteredArtists = allArtists.filter({ (artist: Artist) -> Bool in
                return (artist.name?.lowercased().contains(searchText) ?? false)
            })
        } else {
            filteredArtists = allArtists
        }
        
        tableView.reloadData()
    }
    
    // MARK: - DatabaseListener
    
    func onAllIdolsChange(change: DatabaseChange, idols: [Idol]) {
        // Do nothing
    }
    
    func onAllArtistsChange(change: DatabaseChange, artists: [Artist]) {
        allArtists = artists
        updateSearchResults(for: navigationItem.searchController!)
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
        // Do nothing
    }

}
