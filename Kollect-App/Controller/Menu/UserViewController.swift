//
//  UserViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 16/05/2024.
//

import UIKit
import CoreData
import FirebaseStorage

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
    
    var imageList = [UIImage]()
    var imagePathList = [String]()
    
    var managedObjectContext: NSManagedObjectContext?
    var storageReference = Storage.storage().reference()
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userInfoTableView: UITableView!
    
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    
    @IBAction func editDone(_ sender: Any) {
        guard let image = userImageView.image else {
            displayMessage(title: "Error", message: "No image found!")
            return
        }
        
        let uid = UUID().uuidString
//        let filename = "\(uid).jpg"
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            displayMessage(title: "Error", message: "Image data could not be compressed!")
            return
        }
        
        guard let userID = currentUser.id else {
            displayMessage(title: "Error", message: "No user logged in!")
            return
        }
        
        // Location of saved photos
        let imageRef = storageReference.child("/users/\(userID)/images/\(uid)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        // Upload image to Firebase Storage
        let uploadTask = imageRef.putData(data, metadata: metadata)
        uploadTask.observe(.success) { snapshot in
            self.databaseController?.updateUserDetails(userID: userID, newName: self.userName ?? self.currentUser.name!, newImage: uid)
            self.navigationController?.popViewController(animated: true)
            self.editBarButton.isEnabled = false
        }
        uploadTask.observe(.failure) { snapshot in
            self.displayMessage(title: "Error", message: "\(String(describing: snapshot.error))")
        }
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
        
        userImageView.image = userImage
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
    
    // MARK: - UIImagePickerControllerDelegate
    
    // Called when user selected a photo to be saved
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            userImageView.image = pickedImage
            editBarButton.isEnabled = true
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
