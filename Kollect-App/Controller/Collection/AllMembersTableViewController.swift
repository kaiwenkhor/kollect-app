//
//  AllMembersTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/05/2024.
//

import UIKit

class AllMembersTableViewController: UITableViewController, UISearchResultsUpdating {
    
    let CELL_MEMBER = "memberCell"
    var allMembers = [Idol]()
    var filteredMembers = [Idol]()
    weak var databaseController: DatabaseProtocol?
    weak var memberDelegate: SelectMemberDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredMembers = allMembers
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search All Members"
        navigationItem.searchController = searchController
        
        // This view controller decides how the search controller is presented.
        definesPresentationContext = true
        
        tableView.keyboardDismissMode = .onDrag
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
        return filteredMembers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure and return a member cell
        let memberCell = tableView.dequeueReusableCell(withIdentifier: CELL_MEMBER, for: indexPath)
        
        var content = memberCell.defaultContentConfiguration()
        let member = filteredMembers[indexPath.row]
        content.text = member.name
        memberCell.contentConfiguration = content
        
        return memberCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let memberDelegate = memberDelegate {
            if memberDelegate.selectMember(filteredMembers[indexPath.row]) {
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
            filteredMembers = allMembers.filter({ (member: Idol) -> Bool in
                return (member.name?.lowercased().contains(searchText) ?? false)
            })
        } else {
            filteredMembers = allMembers
        }
        
        tableView.reloadData()
    }

}
