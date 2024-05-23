//
//  UserViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 16/05/2024.
//

import UIKit
import CoreData

class UserViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DatabaseListener {
    
    let SECTION_PHOTO = 0
    let SECTION_NAME = 1
    let CELL_PHOTO = "photoCell"
    let CELL_NAME = "nameCell"
    let titleList = ["Name"]
    var detailList = [String]()
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    var currentUser = User()
    var userName: String?
    var userImage: UIImage?
    let DEFAULT_IMAGE = "Default_Profile_Image"
    var managedObjectContext: NSManagedObjectContext?
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userInfoTableView: UITableView!
    
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    
    @IBAction func editDone(_ sender: Any) {
        guard let id = currentUser.id else {
            return
        }
        
        databaseController?.updateUserDetails(userID: id, newName: userName ?? currentUser.name!, newImage: currentUser.image ?? DEFAULT_IMAGE)
        
        navigationController?.popViewController(animated: true)
        editBarButton.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "User Profile"
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        managedObjectContext = appDelegate?.persistentContainer?.viewContext
        
        userInfoTableView.dataSource = self
        userInfoTableView.delegate = self
//        userInfoTableView.isScrollEnabled = false
        
        // Get image from Core Data
        if currentUser.image == nil || currentUser.image?.isEmpty == true {
            userImageView.image = UIImage(named: DEFAULT_IMAGE)
        } else {
//            userImageView.image = UIImage(named: currentUser.image ?? DEFAULT_IMAGE)
            userImageView.image = loadImageData(filename: currentUser.image!)
        }
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        
        userNameLabel.text = currentUser.name
        userEmailLabel.text = currentUser.email
        
        detailList.append(currentUser.name!)
        
        editBarButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //
    }
    
    // MARK: - Database Listener
    
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
    
    func onAllListingsChange(change: DatabaseChange, listings: [Listing]) {
        // Do nothing
    }
    
    func onUserChange(change: DatabaseChange, user: User) {
        currentUser = user
        userInfoTableView.reloadData()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text?.isEmpty == false && textField.text != currentUser.name {
            editBarButton.isEnabled = true
            userName = textField.text
            userImage = userImageView.image
        } else {
            editBarButton.isEnabled = false
            userName = nil
            userImage = nil
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    // Called when user selected a photo to be saved
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            userImageView.image = pickedImage
            
            // Ensure image exists within the imageView
            guard let image = userImageView.image else {
                displayMessage(title: "Error", message: "Cannot save until an image has been selected!")
                return
            }
            
            // Generate filename
            let timestamp = UInt(Date().timeIntervalSince1970)
            let filename = "\(timestamp).jpg"
            
            // Compress image into data stream using jpeg compression
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                displayMessage(title: "Error", message: "Image data could not be compressed")
                return
            }
            
            // Get access to the app's document directory and attempt to save the file
            let pathsList = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentDirectory = pathsList[0]
            let imageFile = documentDirectory.appendingPathComponent(filename)
            
            // Store filename into Core Data entity (to retrieve later)
            do {
                try data.write(to: imageFile)
                
                let imageEntity = NSEntityDescription.insertNewObject(forEntityName: "UserImageMetaData", into: managedObjectContext!) as! UserImageMetaData
                
                imageEntity.filename = filename
                try managedObjectContext?.save()
                
                // Set to current user
                currentUser.image = filename
                editBarButton.isEnabled = true
                
//                navigationController?.popViewController(animated: true)
                
            } catch {
                displayMessage(title: "Error", message: "\(error)")
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func loadImageData(filename: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        let imageURL = documentsDirectory.appendingPathComponent(filename)
        let image = UIImage(contentsOfFile: imageURL.path)
        
        return image
    }

}

// MARK: - UITableViewDataSource

extension UserViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_PHOTO:
            return 1
        case SECTION_NAME:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_PHOTO {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_PHOTO, for: indexPath)
            
            var content = cell.defaultContentConfiguration()
            content.text = "Change Profile Photo"
            content.image = UIImage(systemName: "photo.badge.plus")
            cell.contentConfiguration = content
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_NAME, for: indexPath) as! NameTableViewCell
            
            cell.nameLabel.text = titleList[indexPath.row]
            cell.nameTextField.text = detailList[indexPath.row]
            cell.nameTextField.addAction(UIAction { action in
                let text = cell.nameTextField.text
                if text?.isEmpty == false && text != self.currentUser.name {
                    self.editBarButton.isEnabled = true
                    self.userName = text
                    self.userImage = self.userImageView.image
                } else {
                    self.editBarButton.isEnabled = false
                    self.userName = nil
                    self.userImage = nil
                }
            }, for: .editingChanged)
            cell.selectionStyle = .none
            
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension UserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_PHOTO {
            // Add action sheet
            // Open Gallery
            // Take Photo
            // Delete Photo
            // Cancel
            let controller = UIImagePickerController()
            controller.allowsEditing = true
            controller.delegate = self
            
            let actionSheet = UIAlertController(title: nil, message: "Select Option:", preferredStyle: .actionSheet)
            
            let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { action in
                controller.sourceType = .camera
                self.present(controller, animated: true, completion: nil)
            }
            
            let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { action in
                controller.sourceType = .photoLibrary
                self.present(controller, animated: true, completion: nil)
            }
            // FIXME: Photo is not deleted
            let deleteAction = UIAlertAction(title: "Delete Photo", style: .destructive) { action in
                guard let id = self.currentUser.id, let newName = self.currentUser.name else { return }
                self.databaseController?.updateUserDetails(userID: id, newName: newName, newImage: self.DEFAULT_IMAGE)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                actionSheet.addAction(cameraAction)
            }
            
            actionSheet.addAction(libraryAction)
            actionSheet.addAction(deleteAction)
            actionSheet.addAction(cancelAction)
            
            self.present(actionSheet, animated: true, completion: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
