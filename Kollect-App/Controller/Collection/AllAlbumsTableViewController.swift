//
//  AllAlbumsTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/05/2024.
//

import UIKit

class AllAlbumsTableViewController: UITableViewController, UISearchResultsUpdating {
    
    let CELL_ALBUM = "albumCell"
    var allAlbums = [Album]()
    var filteredAlbums = [Album]()
    weak var databaseController: DatabaseProtocol?
    weak var albumDelegate: SelectAlbumDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredAlbums = allAlbums
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search All Albums"
        navigationItem.searchController = searchController
        
        // This view controller decides how the search controller is presented.
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAlbums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure and return an album cell
        let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
        
        var content = albumCell.defaultContentConfiguration()
        let album = filteredAlbums[indexPath.row]
        content.text = album.name
        albumCell.contentConfiguration = content
        
        return albumCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let albumDelegate = albumDelegate {
            if albumDelegate.selectAlbum(filteredAlbums[indexPath.row]) {
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
            filteredAlbums = allAlbums.filter({ (album: Album) -> Bool in
                return (album.name?.lowercased().contains(searchText) ?? false)
            })
        } else {
            filteredAlbums = allAlbums
        }
        
        tableView.reloadData()
    }

}
