//
//  SettingsTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 24/04/2024.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    let SECTION_SETTING = 0
    let CELL_SETTING = "settingCell"
    let ITEM_ABOUT = "About"
    let settingsList = ["About"]
    let iconList = ["info.circle"]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return settingsList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingCell = tableView.dequeueReusableCell(withIdentifier: CELL_SETTING, for: indexPath)
        var content = settingCell.defaultContentConfiguration()
        
        let settingItem = settingsList[indexPath.row]
        content.text = settingItem
        content.image = UIImage(systemName: iconList[indexPath.row])
        
        settingCell.contentConfiguration = content
        
        return settingCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = settingsList[indexPath.row]
        
        if selectedItem == ITEM_ABOUT {
            performSegue(withIdentifier: "aboutSegue", sender: self)
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

}
