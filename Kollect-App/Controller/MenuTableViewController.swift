//
//  MenuTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 24/04/2024.
//

import UIKit

class MenuTableViewController: UITableViewController, DatabaseListener {
    
    let SECTION_USER = 0
    let SECTION_MENU = 1
    let CELL_USER = "userCell"
    let CELL_MENU = "menuCell"
    let ITEM_WISHLIST = "Wishlist"
    let ITEM_TRANSACTION = "Transactions"
    let ITEM_NOTI = "Notifications"
    let ITEM_SETTING = "Settings"
    let ITEM_LOGOUT = "Log out"
    let ITEM_LOGIN = "Log in"
    let menuList = ["Wishlist", "Transactions", "Notifications", "Settings", "Log out"]
    let iconList = ["star.fill", "scroll.fill", "bell.fill", "gearshape.fill", "rectangle.portrait.and.arrow.right"]
    let noUserMenuList = ["Wishlist", "Transactions", "Notifications", "Settings", "Log in"]
    let noUserIconList = ["star.fill", "scroll.fill", "bell.fill", "gearshape.fill", "person.fill"]
    var currentUser = User()
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case SECTION_USER:
                return 1
            case SECTION_MENU:
                if currentUser.isAnonymous == true {
                    return noUserMenuList.count
                } else {
                    return menuList.count
                }
            default:
                return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_USER {
            // Configure and return a user cell
            let userCell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath)
            
            var content = userCell.defaultContentConfiguration()
            
            if currentUser.isAnonymous == true {
                content.text = "Guest User"
            } else {
                content.text = currentUser.name
            }
            content.secondaryText = "UID: \(currentUser.id!)"
            userCell.contentConfiguration = content
            
            return userCell
            
        } else {
            // Configure and return the menu cells instead
            let menuCell = tableView.dequeueReusableCell(withIdentifier: CELL_MENU, for: indexPath)
            
            var content = menuCell.defaultContentConfiguration()
            
            // Only show 'Log out' when user is logged in.
            if currentUser.isAnonymous == true {
                let menuItem = noUserMenuList[indexPath.row]
                content.text = menuItem
                content.image = UIImage(systemName: noUserIconList[indexPath.row])
                // Set icon colour
//                content.imageProperties.tintColor = UIColor.systemPink
            } else {
                let menuItem = menuList[indexPath.row]
                content.text = menuItem
                content.image = UIImage(systemName: iconList[indexPath.row])
                if menuItem == "Log out" {
                    content.textProperties.color = UIColor.red
                    content.imageProperties.tintColor = UIColor.red
                }
            }
            
            menuCell.contentConfiguration = content
            
            return menuCell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_USER {
            
            
            // Shud do one section? but still need to have a header/title
            // Can show user here, and add a 'Edit profile' in menuList
            // this is not clickable
            
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else {
            if currentUser.isAnonymous == true {
                let menuItem = noUserMenuList[indexPath.row]
                
                if menuItem == ITEM_WISHLIST {
                    performSegue(withIdentifier: "logInFromMenuSegue", sender: self)
                } else if menuItem == ITEM_TRANSACTION {
                    performSegue(withIdentifier: "logInFromMenuSegue", sender: self)
                } else if menuItem == ITEM_NOTI {
//                    performSegue(withIdentifier: "notificationsSegue", sender: self)
                } else if menuItem == ITEM_SETTING {
                    performSegue(withIdentifier: "settingsFromMenuSegue", sender: self)
                } else if menuItem == ITEM_LOGIN {
                    performSegue(withIdentifier: "logInFromMenuSegue", sender: self)
                }
            } else {
                let menuItem = menuList[indexPath.row]
                
                if menuItem == ITEM_WISHLIST {
                    performSegue(withIdentifier: "wishlistFromMenuSegue", sender: self)
                } else if menuItem == ITEM_TRANSACTION {
//                    performSegue(withIdentifier: "transactionsSegue", sender: self)
                } else if menuItem == ITEM_NOTI {
//                    performSegue(withIdentifier: "notificationsSegue", sender: self)
                } else if menuItem == ITEM_SETTING {
                    performSegue(withIdentifier: "settingsFromMenuSegue", sender: self)
                } else if menuItem == ITEM_LOGOUT {
//                    performSegue(withIdentifier: "logOutSegue", sender: self)
                }
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //
    }
    
    func onAllIdolsChange(change: DatabaseChange, idols: [Idol]) {
        // Do nothing
    }
    
    func onAllGroupsChange(change: DatabaseChange, groups: [Group]) {
        // Do nothing
    }
    
    func onAllAlbumsChange(change: DatabaseChange, albums: [Album]) {
        // Do nothing
    }
    
    func onAllPhotocardsChange(change: DatabaseChange, photocards: [Photocard]) {
        // Do nothing
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        currentUser = user
        tableView.reloadData()
    }

}
