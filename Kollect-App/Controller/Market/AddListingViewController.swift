//
//  AddListingViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 25/05/2024.
//

import UIKit
import FirebaseStorage

class AddListingViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let CELL_ADD = "addCell"
    let CELL_IMAGE = "imageCell"
    let MAX_IMAGE_COUNT = 2

    var photocard = Photocard()
    var imageList = [UIImage]()
    var imageNameList = [String]()
    
    var currentUser = User()
    
    var indicator = UIActivityIndicatorView()
    
    weak var databaseController: DatabaseProtocol?
    var storageReference = Storage.storage().reference()
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var photocardImageView: UIImageView!
    @IBOutlet weak var idolLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    // NumberFormatter to format price input
    let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        navigationItem.title = "Add Listing"
        
        currentUser = databaseController!.currentUser
        
        backgroundView.layer.cornerRadius = 20
        if let image = databaseController?.getImage(imageData: photocard.image!) {
            photocardImageView.image = image
        }
        photocardImageView.layer.cornerRadius = 8
        idolLabel.text = photocard.idol?.name
        artistLabel.text = photocard.artist?.name
        albumLabel.text = photocard.album?.name

        // Do any additional setup after loading the view.
        imageCollectionView.dataSource = self
        imageCollectionView.setCollectionViewLayout(createLayout(), animated: false)
        imageCollectionView.reloadData()
        imageCollectionView.layoutIfNeeded()
        imageCollectionView.isScrollEnabled = false
        
        // Set up price text field
        priceTextField.keyboardType = .decimalPad
        priceTextField.delegate = self
        
        // Set up description text view
        descriptionTextView.delegate = self
        descriptionTextView.layer.borderWidth = 0.2
        descriptionTextView.layer.borderColor = UIColor.secondaryLabel.cgColor
        descriptionTextView.layer.cornerRadius = 5
        
        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageHeightConstraint.constant = imageCollectionView.collectionViewLayout.collectionViewContentSize.height
    }
    
    @IBAction func handleTap(_ sender: Any) {
        view.endEditing(true)
    }
    
    // Add listing to database
    /// Adds a new listing to the database.
    ///
    /// This function handles the process of adding a new listing to the database, including:
    /// - Validating user input (required fields and price format).
    /// - Uploading images to Firebase Storage.
    /// - Creating a new listing document in Firestore.
    /// - Displaying error messages if necessary.
    ///
    /// - Parameter sender: The object that triggered the action (e.g., a button).
    @IBAction func addListing(_ sender: Any) {
        self.indicator.startAnimating()
        
        // Check if required details are filled.
        if imageList.count == MAX_IMAGE_COUNT && priceTextField.text?.isEmpty == false {
            
            // Check if price is a valid number.
            guard let priceText = priceTextField.text, let price = Double(priceText) else {
                self.indicator.stopAnimating()
                return
            }
            
            // Handle images
            for image in imageList {
                let uid = UUID().uuidString
                
                // Convert the image to JPEG data.
                guard let data = image.jpegData(compressionQuality: 0.8) else {
                    displayMessage(title: "Error", message: "Image data could not be compressed")
                    self.indicator.stopAnimating()
                    return
                }
                
                // Get the current user's ID.
                guard let sellerID = currentUser.id else {
                    displayMessage(title: "Error", message: "No user logged in!")
                    self.indicator.stopAnimating()
                    return
                }
                
                // Create a reference to the image in Firebase Storage.
                let imageRef = storageReference.child("/listings/\(sellerID)/images/\(uid)")
                
                // Set the content type of the image metadata.
                let metaData = StorageMetadata()
                metaData.contentType = "image/jpg"
                
                // Upload the image to Firebase Storage.
                let uploadTask = imageRef.putData(data, metadata: metaData)
                
                // Observe the upload task for success and failure events.
                uploadTask.observe(.success) { snapshot in
                    self.imageNameList.append(uid)
                    
                    // Check if all images have been uploaded.
                    if self.imageNameList.count == self.MAX_IMAGE_COUNT {
                        // Create a new listing using the database controller.
                        if let newListing = self.databaseController?.addListing(photocard: self.photocard, price: price, seller: self.currentUser, images: self.imageNameList, descriptionText: self.descriptionTextView.text ?? "") {
                            print("New listing added: \(newListing.id!)")
                            self.navigationController?.popViewController(animated: true)
                            self.indicator.stopAnimating()
                        } else {
                            self.displayMessage(title: "Error", message: "Unable to add listing. Please try again")
                            self.indicator.stopAnimating()
                        }
                    }
                }
                uploadTask.observe(.failure) { snapshot in
                    self.displayMessage(title: "Error", message: "\(String(describing: snapshot.error))")
                    self.indicator.stopAnimating()
                }
            }
        } else {
            displayMessage(title: "Incomplete Form", message: "Please fill in the necessary fields")
            self.indicator.stopAnimating()
        }
    }
    
    // MARK: - UICollectionViewCompositionalLayout
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        // Horizontal side-scrolling layout.
        //  * Group is all images side-by-side.
        //  * Group is 1/4 x screen width, and height is 1/4 x screen width.
        //  * Image width is 1 x group width, with height as 1 x group width
        //  * This makes item dimensions 1:1
        //  * contentInsets puts a 1 pixel margin around each poster.
        //  * orthogonalScrollingBehavior property allows side-scrolling.
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let itemLayout = NSCollectionLayoutItem(layoutSize: itemSize)
        itemLayout.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/4), heightDimension: .fractionalWidth(1/4))
        let groupLayout = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [itemLayout])
        
        let sectionLayout = NSCollectionLayoutSection(group: groupLayout)
        sectionLayout.orthogonalScrollingBehavior = .continuous
        sectionLayout.boundarySupplementaryItems = [createFooterLayout()]
        sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        
        return UICollectionViewCompositionalLayout(section: sectionLayout)
    }
    
    func createFooterLayout() -> NSCollectionLayoutBoundarySupplementaryItem {
        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30))
        let footerLayout = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        
        return footerLayout
    }
    
    /// Animates the view's frame up or down by a specified distance.
    ///
    /// This function is commonly used to adjust the view's position when a keyboard appears or disappears, preventing the view from being obscured by the keyboard.
    /// It also toggles the visibility of the navigation bar, which can be useful for adjusting the layout when the keyboard is present.
    ///
    /// - Parameter up: A `Bool` value indicating whether to move the view up (`true`) or down (`false`).
    ///
    /// **Reference:**
    /// [https://stackoverflow.com/a/6908258](https://stackoverflow.com/a/6908258)
    func animateTextField(up: Bool) {
        
        let movementDistance: CGFloat = -300
        let movementDuration: Double = 0.3
        
        var movement:CGFloat = 0
        if up {
            movement = movementDistance
        } else {
            movement = -movementDistance
        }
        
        UIView.animate(withDuration: movementDuration, delay: 0, options: [.beginFromCurrentState]) {
            self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        }
        
        self.view.window?.backgroundColor = UIColor.systemBackground
        self.navigationController?.navigationBar.isHidden.toggle()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        animateTextField(up: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        animateTextField(up: false)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        animateTextField(up: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        animateTextField(up: false)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            imageList.append(pickedImage)
            imageCollectionView.reloadData()
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension AddListingViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if imageList.count < MAX_IMAGE_COUNT {
            return imageList.count + 1
        } else {
            return imageList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var index = indexPath.row
        
        // Add Cell
        if imageList.count < MAX_IMAGE_COUNT {
            index = index - 1
            if indexPath.row == 0 {
                let addCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ADD, for: indexPath) as! AddListingAddImageCollectionViewCell
                
                // Remove all existing actions to prevent calling same action multiple times
                addCell.addImageButton.removeTarget(nil, action: nil, for: .touchUpInside)
                
                addCell.addImageButton.addAction(UIAction { action in
                    let controller = UIImagePickerController()
                    controller.allowsEditing = true
                    controller.delegate = self
                    
                    let actionSheet = UIAlertController(title: nil, message: "Select Option", preferredStyle: .actionSheet)
                    
                    let cameraAction = UIAlertAction(title: "Camera", style: .default) { action in
                        controller.sourceType = .camera
                        self.present(controller, animated: true, completion: nil)
                    }
                    
                    let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { action in
                        controller.sourceType = .photoLibrary
                        self.present(controller, animated: true, completion: nil)
                    }
                    
                    let albumAction = UIAlertAction(title: "Photo Album", style: .default) { action in
                        controller.sourceType = .savedPhotosAlbum
                        self.present(controller, animated: true, completion: nil)
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        actionSheet.addAction(cameraAction)
                    }
                    actionSheet.addAction(libraryAction)
                    actionSheet.addAction(albumAction)
                    actionSheet.addAction(cancelAction)
                    
                    self.present(actionSheet, animated: true, completion: nil)
                    
                }, for: .touchUpInside)
                
                addCell.layer.cornerRadius = 6
                return addCell
            }
        }
        
        // Image Cell
        let imageCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_IMAGE, for: indexPath) as! AddListingImageCollectionViewCell
        
        imageCell.listingImageView.image = imageList[index]
        // Remove all existing actions to prevent calling same action multiple times
        imageCell.deleteImageButton.removeTarget(nil, action: nil, for: .touchUpInside)
        // Remove image
        imageCell.deleteImageButton.addAction(UIAction { action in
            self.imageList.remove(at: index)
            collectionView.reloadData()
        }, for: .touchUpInside)
        
        imageCell.deleteImageButton.configuration?.background.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
        imageCell.layer.cornerRadius = 6
        
        return imageCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionFooter = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footerView", for: indexPath) as? FooterCollectionReusableView {
            sectionFooter.countLabel.text = "\(imageList.count)/\(MAX_IMAGE_COUNT) photos added."
            
            return sectionFooter
        }
        return UICollectionReusableView()
    }
}
