//
//  MenuTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 24/04/2024.
//

import UIKit
import CoreData

class MenuTableViewController: UITableViewController, DatabaseListener {
    
    let SECTION_USER = 0
    let SECTION_MENU = 1
    let SECTION_AUTH = 2
    let CELL_USER = "userCell"
    let CELL_MENU = "menuCell"
    let CELL_AUTH = "authCell"
    let ITEM_WISHLIST = "Wishlist"
    let ITEM_TRANSACTION = "Transactions"
    let ITEM_NOTI = "Notifications"
    let ITEM_SETTING = "Settings"
    let menuList = ["Wishlist", "Transactions", "Notifications", "Settings"]
    let iconList = ["star.fill", "scroll.fill", "bell.fill", "gearshape.fill"]
    var currentUser = User()
    var userImage: UIImage?
    var userImagePath: String?
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    var managedObjectContext: NSManagedObjectContext?
    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        managedObjectContext = appDelegate?.persistentContainer?.viewContext

        navigationItem.title = "Account"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        
        do {
            // Fetch all image metadata
            let imageDataList = try managedObjectContext!.fetch(UserImageMetaData.fetchRequest()) as [UserImageMetaData]
            
            for data in imageDataList {
                let filename = data.filename!
                
                if filename == currentUser.image {
                    if let image = loadImageData(filename: filename) {
                        userImage = image
                        userImagePath = filename
                    }
                }
            }
                
        } catch {
            print("Unable to fetch image")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case SECTION_USER:
                return 1
            case SECTION_MENU:
                return menuList.count
            case SECTION_AUTH:
                return 1
            default:
                return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_USER {
            // Configure and return a user cell
            let userCell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath) as! UserTableViewCell
            
            if currentUser.isAnonymous == true {
                userCell.userImageView.image = UIImage.defaultProfile
                userCell.userNameLabel.text = "Guest User"
            } else {
                if userImage != nil {
                    userCell.userImageView.image = userImage
                } else {
                    userCell.userImageView.image = UIImage.defaultProfile
                }
                userCell.userNameLabel.text = currentUser.name
            }
            userCell.userIdLabel.text = "ID: \(currentUser.id!)"
         
            userCell.userImageView.layer.cornerRadius = userCell.userImageView.frame.size.width / 2
            
            return userCell
            
        } else if indexPath.section == SECTION_MENU {
            // Configure and return the menu cells instead
            let menuCell = tableView.dequeueReusableCell(withIdentifier: CELL_MENU, for: indexPath)
            
            var content = menuCell.defaultContentConfiguration()
            
            let menuItem = menuList[indexPath.row]
            content.text = menuItem
            content.image = UIImage(systemName: iconList[indexPath.row])
            
            menuCell.contentConfiguration = content
            return menuCell
            
        } else {
            let authCell = tableView.dequeueReusableCell(withIdentifier: CELL_AUTH, for: indexPath)
            var content = authCell.defaultContentConfiguration()
            
            if currentUser.isAnonymous == true {
                content.text = "Log In"
                content.image = UIImage(systemName: "arrowshape.right.circle.fill")
            } else {
                content.text = "Sign Out"
                content.image = UIImage(systemName: "arrowshape.left.circle.fill")
                content.textProperties.color = UIColor.red
                content.imageProperties.tintColor = UIColor.red
            }
            
            authCell.contentConfiguration = content
            return authCell
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == SECTION_USER {
            return 88
        }
        return tableView.rowHeight
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_USER {
            
            // Shud do one section? but still need to have a header/title
            // Can show user here, and add a 'Edit profile' in menuList
            if currentUser.isAnonymous == true {
                performSegue(withIdentifier: "logInFromMenuSegue", sender: self)
            } else {
                performSegue(withIdentifier: "userFromMenuSegue", sender: self)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else if indexPath.section == SECTION_MENU {
            let menuItem = menuList[indexPath.row]
            if currentUser.isAnonymous == true {
                if menuItem == ITEM_WISHLIST {
                    performSegue(withIdentifier: "logInFromMenuSegue", sender: self)
                } else if menuItem == ITEM_TRANSACTION {
                    performSegue(withIdentifier: "logInFromMenuSegue", sender: self)
                } else if menuItem == ITEM_NOTI {
//                    performSegue(withIdentifier: "notificationsSegue", sender: self)
                } else if menuItem == ITEM_SETTING {
                    performSegue(withIdentifier: "settingsFromMenuSegue", sender: self)
                }
                
            } else {
                if menuItem == ITEM_WISHLIST {
                    performSegue(withIdentifier: "wishlistFromMenuSegue", sender: self)
                } else if menuItem == ITEM_TRANSACTION {
//                    performSegue(withIdentifier: "transactionsSegue", sender: self)
                } else if menuItem == ITEM_NOTI {
//                    performSegue(withIdentifier: "notificationsSegue", sender: self)
                } else if menuItem == ITEM_SETTING {
                    performSegue(withIdentifier: "settingsFromMenuSegue", sender: self)
                }
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else if indexPath.section == SECTION_AUTH {
            if currentUser.isAnonymous == true {
                performSegue(withIdentifier: "logInFromMenuSegue", sender: self)
                tableView.deselectRow(at: indexPath, animated: true)
                
            } else {
                let actionSheet = UIAlertController(title: nil, message: "Sign out of \(currentUser.name ?? "account")?", preferredStyle: .actionSheet)
                
                let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { action in
                    Task {
                        self.indicator.startAnimating()
                        let result = await self.databaseController?.signOutAccount()
                        self.indicator.stopAnimating()
                        if result == false {
                            self.displayMessage(title: "Sign Out Error", message: "User sign out failed")
                        }
                        self.currentUser = self.databaseController!.currentUser
                        tableView.reloadData()
                        // Go to first tab
//                        self.tabBarController?.selectedIndex = 0
                    }
                    self.indicator.stopAnimating()
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                actionSheet.addAction(signOutAction)
                actionSheet.addAction(cancelAction)
                
                self.present(actionSheet, animated: true, completion: nil)
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "userFromMenuSegue" {
            let destination = segue.destination as! UserViewController
            destination.currentUser = currentUser
        }
    }
    
    // MARK: - DatabaseListener
    
    func onAllIdolsChange(change: DatabaseChange, idols: [Idol]) {
        // Do nothing
    }
    
    func onAllArtistsChange(change: DatabaseChange, artists: [Artist]) {
        // Do nothing
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
        currentUser = user
        print("User change \(currentUser.id!)")
        tableView.reloadData()
    }
    
    //
    
    func loadImageData(filename: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        let imageURL = documentsDirectory.appendingPathComponent(filename)
        let image = UIImage(contentsOfFile: imageURL.path)
        
        return image
    }

}
