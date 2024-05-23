//
//  MarketResultsTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/05/2024.
//

import UIKit
import CoreData

class MarketResultsTableViewController: UITableViewController, UISearchBarDelegate, DatabaseListener {
    
    let SECTION_RECENT = 0
    let SECTION_RESULT = 1
    let CELL_RECENT = "recentCell"
    let CELL_RESULT = "resultCell"
    
    let searchBar = UISearchBar()
    var recentSearches = [String]()
    var resultList = [String]()
    var searchHistory = [SearchData]()
    
    var allArtists = [Artist]()
    var allIdols = [Idol]()
    var allAlbums = [Album]()
    
    var allPhotocards = [Photocard]()
    var filteredPhotocards = [Photocard]()
    
    var keyword: String?
    
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .photocard
    
    // Core Data
    var managedObjectContext: NSManagedObjectContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        managedObjectContext = appDelegate?.persistentContainer?.viewContext
        
        filteredPhotocards = allPhotocards
        
        // Setup search bar
        searchBar.delegate = self
        searchBar.sizeToFit()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search Market"
        navigationItem.titleView = searchBar
        
        if let text = keyword {
            searchBar.text = text
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        
        // Get user's search history
        recentSearches = []
        do {
            let searchDataList = try managedObjectContext!.fetch(SearchData.fetchRequest()) as [SearchData]
            let sortedSearchData = searchDataList.sorted(by: { $0.date! < $1.date! })
            for data in sortedSearchData {
                if data.byUser == databaseController?.currentUser.id {
                    let searchText = data.text!
                    recentSearches.append(searchText)
                }
            }
            tableView.reloadData()
        } catch {
            print("Unable to fetch search history")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text?.isEmpty == true {
            return recentSearches.count
        } else {
            return resultList.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchBar.text?.isEmpty == true {
            return "Search History"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchBar.text?.isEmpty == true {
            let recentCell = tableView.dequeueReusableCell(withIdentifier: CELL_RECENT, for: indexPath)
            
            var content = recentCell.defaultContentConfiguration()
            content.text = recentSearches[recentSearches.count - indexPath.row - 1]
            recentCell.contentConfiguration = content
            
            return recentCell
            
        } else {
            let resultCell = tableView.dequeueReusableCell(withIdentifier: CELL_RESULT, for: indexPath)
            
            var content = resultCell.defaultContentConfiguration()
            content.text = resultList[indexPath.row]
            resultCell.contentConfiguration = content
            
            return resultCell
        }
    }
    
    // MARK: - Table view delegate

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if searchBar.text?.isEmpty == true {
            return true
        } else {
            return false
        }
    }
     
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let searchText = recentSearches[recentSearches.count - indexPath.row - 1]
            recentSearches.remove(at: recentSearches.count - indexPath.row - 1)
            deleteSearchHistory(searchText: searchText)
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchBar.text?.isEmpty == true {
            keyword = recentSearches[recentSearches.count - indexPath.row - 1]
        } else {
            keyword = resultList[indexPath.row]
        }
        let searchText = keyword!.lowercased()
        filteredPhotocards = allPhotocards.filter({ (photocard: Photocard) -> Bool in
            let searchArtist = photocard.artist?.name?.lowercased().contains(searchText) ?? false
            let searchIdol = photocard.idol?.name?.lowercased().contains(searchText) ?? false
            let searchAlbum =  photocard.album?.name?.lowercased().contains(searchText) ?? false
            
            return searchArtist || searchIdol || searchAlbum
        })
        print("Did Select Row \(keyword!)!")
        if recentSearches.contains(keyword!) {
            recentSearches.removeAll { text in
                return text == keyword
            }
        }
        recentSearches.append(keyword!)
        
        saveSearchHistory(searchText: keyword!)
        
        performSegue(withIdentifier: "photocardResultsSegue", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text, !searchText.isEmpty {
            // Add search text to search history
            if recentSearches.contains(searchText) {
                recentSearches.removeAll { text in
                    return text == searchText
                }
            }
            recentSearches.append(searchText)
            
            saveSearchHistory(searchText: searchText)
            
            // Show photocards
            keyword = searchText
            print("Search Button Clicked \(keyword!)!")
            performSegue(withIdentifier: "photocardResultsSegue", sender: self)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Update resultList
        guard let searchText = searchBar.text?.lowercased() else {
            return
        }
        
        searchHelper(searchText: searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("Did Begin Editing!!")
        guard let searchText = searchBar.text?.lowercased(), searchText.isEmpty == false else { return }
        print("Did Begin Editing!! ---------- Got text!!")
        
        searchHelper(searchText: searchText)
    }
    
    func searchHelper(searchText: String) {
        if searchText.count > 0 {
            print("Text Did Change!")
            var resultSet = Set<String>()
            
            filteredPhotocards = allPhotocards.filter({ (photocard: Photocard) -> Bool in
                let searchArtist = photocard.artist?.name?.lowercased().contains(searchText) ?? false
                let searchIdol = photocard.idol?.name?.lowercased().contains(searchText) ?? false
                let searchAlbum =  photocard.album?.name?.lowercased().contains(searchText) ?? false
                
                // For search results
                if searchArtist {
                    resultSet.insert((photocard.artist?.name)!)
                }
                if searchIdol {
                    resultSet.insert((photocard.idol?.name)!)
                }
                if searchAlbum {
                    resultSet.insert((photocard.album?.name)!)
                }
                
                return searchArtist || searchIdol || searchAlbum
            })
            
            resultList = Array(resultSet)
            print(resultList)
            // Try to sort with relevance to searchText
            var scoreList = [String: Double]()
            for result in resultList {
                let score = result.levenshteinDistanceScore(to: searchText)
                scoreList[result] = score
            }
            let sortedScoreList = scoreList.sorted(by: { $0.value > $1.value })
            var newResultList = [String]()
            for (result, _) in sortedScoreList {
                newResultList.append(result)
            }
            resultList = newResultList
            print(resultList)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass 'keyword' to next controller.
        if segue.identifier == "photocardResultsSegue" {
            let destination = segue.destination as! ResultCollectionViewController
            destination.keyword = self.keyword
            destination.allPhotocards = self.filteredPhotocards
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
        allPhotocards = photocards
        tableView.reloadData()
    }
    
    func onAllListingsChange(change: DatabaseChange, listings: [Listing]) {
        //
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        //
    }
    
    // MARK: - Core Data
    
    func saveSearchHistory(searchText: String) {
        // Add search text to search history
        // Check if search exists in history, if it does, move to most recent
        // (Delete the old one and add a new one)
        // Delete from database
        do {
            let searchDataList = try managedObjectContext!.fetch(SearchData.fetchRequest()) as [SearchData]
            for data in searchDataList {
                if data.byUser == databaseController?.currentUser.id {
                    if data.text == searchText {
                        managedObjectContext?.delete(data)
                    }
                }
            }
        } catch {
            print("Unable to fetch search history")
        }
        
        // Add in database
        do {
            let searchHistoryEntity = NSEntityDescription.insertNewObject(forEntityName: "SearchData", into: managedObjectContext!) as! SearchData
            searchHistoryEntity.text = searchText
            searchHistoryEntity.date = Date().description
            searchHistoryEntity.byUser = databaseController?.currentUser.id
            try managedObjectContext?.save()
            
        } catch {
            print("Error saving search text to search history: \(searchText)")
        }
    }
    
    func deleteSearchHistory(searchText: String) {
        do {
            let searchDataList = try managedObjectContext!.fetch(SearchData.fetchRequest()) as [SearchData]
            for data in searchDataList {
                if data.byUser == databaseController?.currentUser.id {
                    if data.text == searchText {
                        managedObjectContext?.delete(data)
                    }
                }
            }
        } catch {
            print("Unable to fetch search history")
        }
    }
    
}

extension String {
    // TODO: Reference
    // https://stackoverflow.com/a/54651172
    func levenshteinDistanceScore(to string: String, ignoreCase: Bool = true, trimWhiteSpacesAndNewLines: Bool = true) -> Double {

        var firstString = String(self.prefix(string.count))
        var secondString = string

        if ignoreCase {
            firstString = firstString.lowercased()
            secondString = secondString.lowercased()
        }
        if trimWhiteSpacesAndNewLines {
            firstString = firstString.trimmingCharacters(in: .whitespacesAndNewlines)
            secondString = secondString.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let empty = [Int](repeating:0, count: secondString.count)
        var last = [Int](0...secondString.count)

        for (i, tLett) in firstString.enumerated() {
            var cur = [i + 1] + empty
            for (j, sLett) in secondString.enumerated() {
                cur[j + 1] = tLett == sLett ? last[j] : Swift.min(last[j], last[j + 1], cur[j])+1
            }
            last = cur
        }

        // maximum string length between the two
        let lowestScore = max(firstString.count, secondString.count)

        if let validDistance = last.last {
            return  1 - (Double(validDistance) / Double(lowestScore))
        }

        return 0.0
    }
}
