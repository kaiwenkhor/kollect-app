//
//  FirebaseController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage

class FirebaseController: NSObject, DatabaseProtocol {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var idolList: [Idol]
    var artistList: [Artist]
    var albumList: [Album]
    var photocardList: [Photocard]
    var listingList: [Listing]
    var userList: [User]
    var currentUser: User
    var defaultUserImage: UIImage?
    let DEFAULT_USER_IMAGE = "Default_Profile_Image.jpg"
    let DEFAULT_USERNAME = "Anonymous"
    var authController: Auth
    var database: Firestore
    var idolsRef: CollectionReference?
    var artistsRef: CollectionReference?
    var albumsRef: CollectionReference?
    var photocardsRef: CollectionReference?
    var listingsRef: CollectionReference?
    var usersRef: CollectionReference?
    var imagesRef: CollectionReference?
    
    var storageReference: Storage?
    let storageRootPath = "gs://kollect-app-3d7a3.appspot.com"
    
    override init() {
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        storageReference = Storage.storage()
        
        idolList = [Idol]()
        artistList = [Artist]()
        albumList = [Album]()
        photocardList = [Photocard]()
        listingList = [Listing]()
        userList = [User]()
        currentUser = User()
        
        super.init()
        
        // Sign in anonymously
        Task {
            await signInAnonymous()
            loadDefaultImage(filename: DEFAULT_USER_IMAGE)
        }
    }
    
    /// Signs in a user anonymously.
    ///
    /// This function uses Firebase Authentication to create an anonymous user account.
    /// If successful, it creates a new `currentUser` object and sets up listeners for idols and user data.
    func signInAnonymous() async {
        do {
            // Attempt to sign in anonymously.
            let authResult = try await authController.signInAnonymously()
            
            // Create a new `currentUser` object with details from the anonymous user.
            currentUser = addUser(userID: authResult.user.uid, username: DEFAULT_USERNAME, isAnonymous: authResult.user.isAnonymous, email: "")
            print("Sign in anonymously: \(authResult.user.uid)")
            
        } catch {
            fatalError("Firebase Authentication Failed with Error \(String(describing: error))")
        }
        
        // If the idols reference is not yet set up, initialise it.
        if idolsRef == nil {
            self.setupIdolListener()
        }
        
        // Set up a listener for user data.
        self.setupUserListener()
    }
    
    /// Logs in a user with the provided email and password.
    /// - Parameters:
    ///   - email: The email address of the user.
    ///   - password: The password of the user.
    /// - Returns: `true` if the login was successful, `false` otherwise.
    func logInAccount(email: String, password: String) async -> Bool{
        do {
            // Attempt to sign in the user using the provided email and password.
            let authResult = try await authController.signIn(withEmail: email, password: password)
            
            // If the sign-in is successful, update the current user's ID.
            currentUser.id = authResult.user.uid
            print("Sign in: \(authResult.user.uid)")
            
        } catch {
            print("Firebase Authentication failed with error:: \(error.localizedDescription)")
            return false
        }
        
        // If the idols reference is not yet set up, initialise it.
        if idolsRef == nil {
            self.setupIdolListener()
        }
        
        // Set up a listener for user data.
        self.setupUserListener()
        
        return true
    }
    
    /// Creates a new user account with the provided email, username, and password.
    /// - Parameters:
    ///   - email: The email address for the new user account.
    ///   - username: The desired username for the new user account.
    ///   - password: The password for the new user account.
    /// - Returns: `true` if the account creation was successful, `false` otherwise.
    func createAccount(email: String, username: String, password: String) async -> Bool {
        do {
            // Attempt to create a new user account using the provided email and password.
            let authResult = try await authController.createUser(withEmail: email, password: password)
            
            // If account creation is successful, create a new `currentUser` object with the user's details.
            currentUser = addUser(userID: authResult.user.uid, username: username, isAnonymous: false, email: email)
            print("Create user: \(authResult.user.uid)")
            
        } catch {
            print("User creation failed with error: \(error.localizedDescription)")
            return false
        }
        
        // If the idols reference is not yet set up, initialise it.
        if idolsRef == nil {
            self.setupIdolListener()
        }
        
        // Set up a listener for user data.
        self.setupUserListener()
        
        return true
    }
    
    /// Signs out the current user and signs in anonymously.
    /// - Returns: `true` if the sign-out and anonymous sign-in were successful, `false` otherwise.
    func signOutAccount() async -> Bool {
        do {
            // Attempt to sign out the current user.
            try authController.signOut()
            
            // After signing out, sign in anonymously.
            await signInAnonymous()
            
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    func cleanup() {
        // Empty
    }
    
    /// Adds a listener to the list of listeners.
    ///
    /// This function registers a `DatabaseListener` to receive updates on specific data types.
    /// The listener will be notified of changes to idols, artists, albums, photocards, listings, or the user's data,
    /// depending on the `listenerType` specified in the listener.
    ///
    /// - Parameter listener: The `DatabaseListener` to add.
    func addListener(listener: any DatabaseListener) {
        // Add the listener to the list of delegates.
        listeners.addDelegate(listener)
        
        // Notify the listener of initial data based on its listener type.
        
        // Idol
        if listener.listenerType == .idol || listener.listenerType == .all {
            listener.onAllIdolsChange(change: .update, idols: idolList)
        }
        
        // Artist
        if listener.listenerType == .artist || listener.listenerType == .all {
            listener.onAllArtistsChange(change: .update, artists: artistList)
        }
        
        // Album
        if listener.listenerType == .album || listener.listenerType == .all {
            listener.onAllAlbumsChange(change: .update, albums: albumList)
        }
        
        // Photocard
        if listener.listenerType == .photocard || listener.listenerType == .all {
            listener.onAllPhotocardsChange(change: .update, photocards: photocardList)
        }
        
        // Listing
        if listener.listenerType == .listing || listener.listenerType == .all {
            listener.onAllListingsChange(change: .update, listings: listingList)
        }
        
        // Collection
        if listener.listenerType == .user || listener.listenerType == .all {
            listener.onUserChange(change: .update, user: currentUser)
        }
    }
    
    /// Removes a listener from the list of listeners.
    ///
    /// This function removes a `DatabaseListener` from the list of listeners, preventing it from receiving further updates.
    ///
    /// - Parameter listener: The `DatabaseListener` to remove.
    func removeListener(listener: any DatabaseListener) {
        // Remove the listener from the list of delegates.
        listeners.removeDelegate(listener)
    }
    
    // MARK: - Idol
    
    /// Adds a new idol to the database.
    /// - Parameters:
    ///   - idolName: The name of the idol.
    ///   - idolBirthday: The birthday of the idol.
    /// - Returns: The newly created `Idol` object.
    func addIdol(idolName: String, idolBirthday: String) -> Idol {
        // Get a reference to the "idols" collection in the Firestore database.
        idolsRef = database.collection("idols")
        
        // Create a new `Idol` object.
        let idol = Idol()
        idol.name = idolName
        idol.birthday = idolBirthday
        
        // Add a new document to the "idols" collection with the idol's data.
        if let idolRef = idolsRef?.addDocument(data: ["name": idolName, "birthday": idolBirthday]) {
            idol.id = idolRef.documentID
        }
        
        return idol
    }
    
    /// Deletes an idol from the database.
    ///
    /// This function removes the idol from the database and also performs related cleanup tasks, such as:
    /// - Removing the idol from any associated artists.
    /// - Deleting any photocards associated with the idol.
    ///
    /// - Parameter idol: The `Idol` object to delete.
    func deleteIdol(idol: Idol) {
        // Delete the corresponding document from the "idols" collection.
        if let idolID = idol.id {
            idolsRef?.document(idolID).delete()
        }
        
        // Delete the idol from any associated artists.
        for artist in artistList {
            removeIdolFromArtist(idol: idol, artist: artist)
        }
        
        // Delete any photocards associated with the idol.
        for photocard in photocardList {
            if photocard.idol == idol {
                deletePhotocard(photocard: photocard)
            }
        }
    }
    
    // MARK: - Artist
    
    /// Adds a new artist to the database.
    /// - Parameter artistName: The name of the artist.
    /// - Returns: The newly created `Artist` object.
    func addArtist(artistName: String) -> Artist {
        // Get a reference to the "artists" collection in the Firestore database.
        artistsRef = database.collection("artists")
        
        // Create a new `Artist` object.
        let artist = Artist()
        artist.name = artistName
        
        // Add a new document to the "artists" collection with the artist's data.
        if let artistRef = artistsRef?.addDocument(data: ["name": artistName]) {
            artist.id = artistRef.documentID
        }
        
        return artist
    }
    
    /// Deletes an artist from the database.
    /// - Parameter artist: The `Artist` object to delete.
    func deleteArtist(artist: Artist) {
        // Delete the corresponding document from the "artists" collection.
        if let artistID = artist.id {
            artistsRef?.document(artistID).delete()
        }
    }
    
    /// Adds an idol to an artist's members list.
    /// - Parameters:
    ///   - idol: The `Idol` object to add.
    ///   - artist: The `Artist` object to add the idol to.
    /// - Returns: `true` if the idol was successfully added, `false` otherwise.
    func addIdolToArtist(idol: Idol, artist: Artist) -> Bool {
        // Check if the idol and artist exist.
        guard let idolID = idol.id, let artistID = artist.id else {
            return false
        }
        
        // Get a reference to the idol's document.
        if let newIdolRef = idolsRef?.document(idolID) {
            // Update the artist's document to add the idol to the "members" array.
            artistsRef?.document(artistID).updateData(
                ["members": FieldValue.arrayUnion([newIdolRef])]
            )
        }
        
        return true
    }
    
    /// Removes an idol from an artist's members list.
    /// - Parameters:
    ///   - idol: The `Idol` object to remove.
    ///   - artist: The `Artist` object to remove the idol from.
    func removeIdolFromArtist(idol: Idol, artist: Artist) {
        // Check if the artist's members list contains the idol
        if artist.members.contains(idol), let artistID = artist.id, let idolID = idol.id {
            // Get a reference to the idol's document.
            if let removedIdolRef = idolsRef?.document(idolID) {
                // Update the artist's document to remove the idol from the "members" array.
                artistsRef?.document(artistID).updateData(
                    ["members": FieldValue.arrayRemove([removedIdolRef])]
                )
            }
        }
    }
    
    /// Adds an album to an artist's albums list.
    /// - Parameters:
    ///   - album: The `Album` object to add.
    ///   - artist: The `Artist` object to add the album to.
    /// - Returns: `true` if the album was successfully added, `false` otherwise.
    func addAlbumToArtist(album: Album, artist: Artist) -> Bool {
        // Check if the album and artist exist.
        guard let albumID = album.id, let artistID = artist.id else {
            return false
        }
        
        // Get a reference to the album's document.
        if let newAlbumRef = albumsRef?.document(albumID) {
            // Update the artist's document to add the album to the "albums" array.
            artistsRef?.document(artistID).updateData(
                ["albums": FieldValue.arrayUnion([newAlbumRef])]
            )
        }
        
        return true
    }
    
    /// Removes an album from an artist's albums list.
    /// - Parameters:
    ///   - album: The `Album` object to remove.
    ///   - artist: The `Artist` object to remove the album from.
    func removeAlbumFromArtist(album: Album, artist: Artist) {
        // Check if the artist's albums list contains the album
        if artist.albums.contains(album), let artistID = artist.id, let albumID = album.id {
            // Get a reference to the album's document.
            if let removedAlbumRef = albumsRef?.document(albumID) {
                // Update the artist's document to remove the album from the "albums" array.
                artistsRef?.document(artistID).updateData(
                    ["albums": FieldValue.arrayRemove([removedAlbumRef])]
                )
            }
        }
    }
    
    // MARK: - Album
    
    /// Adds a new album to the database and associates it with an artist.
    /// - Parameters:
    ///   - albumName: The name of the album.
    ///   - artist: The `Artist` object associated with the album.
    /// - Returns: The newly created `Album` object.
    func addAlbum(albumName: String, artist: Artist) -> Album {
        // Get a reference to the "albums" collection in the Firestore database.
        albumsRef = database.collection("albums")
        
        // Create a new `Album` object.
        let album = Album()
        album.name = albumName
        album.artist = artist
        
        // Add a new document to the "albums" collection with the album's data.
        if let albumRef = albumsRef?.addDocument(data: ["name": albumName]) {
            album.id = albumRef.documentID
        }
        
        // Add the album to the artist's albums list.
        if !addAlbumToArtist(album: album, artist: artist) {
            print("Failed to add album \(album.name!) to artist \(artist.name!)")
        }
        
        return album
    }
    
    /// Deletes an album from the database and removes it from its associated artist.
    /// - Parameter album: The `Album` object to delete.
    func deleteAlbum(album: Album) {
        // Delete the corresponding document from the "albums" collection.
        if let albumID = album.id {
            albumsRef?.document(albumID).delete()
        }
        
        // If the album has an associated artist, remove it from the artist's albums list.
        if let artist = album.artist {
            removeAlbumFromArtist(album: album, artist: artist)
        }
    }
    
    // MARK: - Photocard
    
    /// Adds a new photocard to the database and associates it with an idol, artist, and album.
    /// - Parameters:
    ///   - idol: The `Idol` object associated with the photocard.
    ///   - artist: The `Artist` object associated with the photocard.
    ///   - album: The `Album` object associated with the photocard.
    ///   - image: The image URL or filename for the photocard.
    /// - Returns: The newly created `Photocard` object.
    func addPhotocard(idol: Idol, artist: Artist, album: Album, image: String) -> Photocard {
        // Get a reference to the "photocards" collection in the Firestore database.
        photocardsRef = database.collection("photocards")
        
        // Create a new `Photocard` object.
        let photocard = Photocard()
        photocard.idol = idol
        photocard.artist = artist
        photocard.album = album
        
        if let idolID = idol.id, let artistID = artist.id, let albumID = album.id {
            // Get references to the idol, artist, and album documents.
            if let idolRef = idolsRef?.document(idolID), let artistRef = artistsRef?.document(artistID), let albumRef = albumsRef?.document(albumID) {
                // Add a new document to the "photocards" collection with the photocard's data.
                if let photocardRef = photocardsRef?.addDocument(data: ["idol": idolRef, "artist": artistRef, "album": albumRef]) {
                    
                    photocard.id = photocardRef.documentID
                    
                    let filename = ("\(image).png")
                    
                    // Create a reference to the photocard image in Cloud Storage.
                    let imagePath = "\(storageRootPath)/photocards/images/\(filename)"
                    
                    // Add a new document to the "images" subcollection with the image's data.
                    photocardRef.collection("images").document("\(filename)").setData(["url": "\(imagePath)"])
                    
                    // Set the `image` property of the `Photocard` object to the image filename and path.
                    photocard.image = (filename, imagePath)
                }
            }
        }
        
        return photocard
    }
    
    /// Deletes a photocard from the database and removes it from any associated collections or wishlists.
    /// - Parameter photocard: The `Photocard` object to delete.
    func deletePhotocard(photocard: Photocard) {
        // Delete the corresponding document from the "photocards" collection.
        if let photocardID = photocard.id {
            photocardsRef?.document(photocardID).delete()
        }
        
        // Remove the photocard from the user's collection and wishlist.
        if currentUser.isAnonymous != false {
            for allPhotocard in currentUser.all {
                if allPhotocard == photocard {
                    removePhotocardFromCollection(photocard: photocard, user: currentUser)
                }
            }
            for wishlistPhotocard in currentUser.wishlist {
                if wishlistPhotocard == photocard {
                    removePhotocardFromWishlist(photocard: photocard, user: currentUser)
                }
            }
        }
    }
    
    // MARK: - Listing
    
    /// Adds a new listing to the database.
    /// - Parameters:
    ///   - photocard: The `Photocard` object associated with the listing.
    ///   - price: The price of the listing.
    ///   - seller: The `User` object representing the seller.
    ///   - images: An array of image URLs or filenames for the listing.
    ///   - descriptionText: The description of the listing.
    /// - Returns: The newly created `Listing` object.
    func addListing(photocard: Photocard, price: Double, seller: User, images: [String], descriptionText: String) -> Listing {
        // Get a reference to the "listings" collection in the Firestore database.
        listingsRef = database.collection("listings")
        
        // Create a new `Listing` object.
        let listing = Listing()
        listing.photocard = photocard
        listing.price = price
        listing.seller = seller
        listing.listDate = Date().description
        listing.descriptionText = descriptionText
        
        if let photocardID = photocard.id, let sellerID = seller.id {
            // Get references to the photocard and seller documents.
            if let photocardRef = photocardsRef?.document(photocardID), let sellerRef = usersRef?.document(sellerID) {
                // Add a new document to the "listings" collection with the listing's data.
                if let listingRef = listingsRef?.addDocument(data: ["photocard": photocardRef, "price": price, "seller": sellerRef, "listDate": listing.listDate!, "descriptionText": descriptionText]) {
                    listing.id = listingRef.documentID
                    
                    for image in images {
                        // Create a reference to the listing image in Cloud Storage.
                        let imagePath = "\(storageRootPath)/listings/\(sellerID)/images/\(image)"
                        listingRef.collection("images").document("\(image)").setData(["url": "\(imagePath)"])
                        
                        // Add the image filename and path to the listing's images array.
                        let filename = ("\(image).jpg")
                        listing.images.append((filename, imagePath))
                    }
                }
            }
        }
        
        return listing
    }
    
    /// Deletes a listing from the database.
    /// - Parameter listing: The `Listing` object to delete.
    func deleteListing(listing: Listing) {
        // Delete the corresponding document from the "listings" collection.
        if let listingID = listing.id {
            listingsRef?.document(listingID).delete()
        }
    }
    
    // MARK: - User
    
    /// Adds a new user to the database.
    /// - Parameters:
    ///   - userID: The user's ID.
    ///   - username: The user's username.
    ///   - isAnonymous: Whether the user is anonymous.
    ///   - email: The user's email address.
    /// - Returns: The newly created `User` object.
    func addUser(userID: String, username: String, isAnonymous: Bool, email: String) -> User {
        // Get a reference to the "users" collection in the Firestore database.
        usersRef = database.collection("users")
        
        // Create a new `User` object.
        let user = User()
        user.id = userID
        user.name = username
        user.isAnonymous = isAnonymous
        user.email = email
        
        // Set the default user image URL.
        let imageURL = "\(storageRootPath)/default/images/\(DEFAULT_USER_IMAGE)"
        user.image = (DEFAULT_USER_IMAGE, imageURL)
        
        // Create a new document in the "users" collection with the user's data.
        if let userRef = usersRef?.document(userID) {
            userRef.setData(["name": username, "email": email, "isAnonymous": isAnonymous, "image": [user.image?.0, user.image?.1]])
        }
        
        return user
    }
    
    /// Deletes a user from the database.
    /// - Parameter user: The `User` object to delete.
    func deleteUser(user: User) {
        // Delete the corresponding document from the "users" collection.
        if let userID = user.id {
            // Deletes 'collection' too
            usersRef?.document(userID).delete()
        }
    }
    
    /// Updates a user's details in the database.
    /// - Parameters:
    ///   - userID: The ID of the user to update.
    ///   - newName: The new username for the user.
    ///   - newImage: The new image filename for the user.
    func updateUserDetails(userID: String, newName: String, newImage: String) {
        // Get a reference to the user's document.
        if let userRef = usersRef?.document(userID) {
            // Construct the new image URL.
            let imageURL = "\(storageRootPath)/users/\(userID)/images/\(newImage)"
            
            // Update the user's document with the new name and image.
            userRef.updateData(["name": newName, "image": [newImage, imageURL]])
        }
    }
    
    /// DescriptionAdds a photocard to a user's collection.
    /// - Parameters:
    ///   - photocard: The `Photocard` object to add to the collection.
    ///   - user: The `User` object whose collection to update.
    /// - Returns: `true` if the photocard was successfully added, `false` otherwise.
    func addPhotocardToCollection(photocard: Photocard, user: User) -> Bool {
        // Check if the photocard and user exist.
        guard let photocardID = photocard.id, let userID = user.id else {
            return false
        }
        
        // Get a reference to the photocard's document.
        if let newPhotocardRef = photocardsRef?.document(photocardID) {
            // Update the user's document to add the photocard to the "all" array.
            usersRef?.document(userID).updateData(
                ["all": FieldValue.arrayUnion([newPhotocardRef])]
            )
        }
        
        return true
    }
    
    /// Adds a photocard to a user's favourites list.
    /// - Parameters:
    ///   - photocard: The `Photocard` object to add to the favourites list.
    ///   - user: The `User` object whose favourites list to update.
    /// - Returns: `true` if the photocard was successfully added, `false` otherwise.
    func addPhotocardToFavourites(photocard: Photocard, user: User) -> Bool {
        // Check if the photocard and user exist.
        guard let photocardID = photocard.id, let userID = user.id else {
            return false
        }
        
        // Get a reference to the photocard's document.
        if let newPhotocardRef = photocardsRef?.document(photocardID) {
            // Update the user's document to add the photocard to the "favourites" array.
            usersRef?.document(userID).updateData(
                ["favourites": FieldValue.arrayUnion([newPhotocardRef])]
            )
        }
        
        return true
    }
    
    /// Adds a photocard to a user's wishlist.
    /// - Parameters:
    ///   - photocard: The `Photocard` object to add to the wishlist.
    ///   - user: The `User` object whose wishlist to update.
    /// - Returns: `true` if the photocard was successfully added, `false` otherwise.
    func addPhotocardToWishlist(photocard: Photocard, user: User) -> Bool {
        // Check if the photocard and user exist.
        guard let photocardID = photocard.id, let userID = user.id else {
            return false
        }
        
        // Get a reference to the photocard's document.
        if let newPhotocardRef = photocardsRef?.document(photocardID) {
            // Update the user's document to add the photocard to the "wishlist" array.
            usersRef?.document(userID).updateData(
                ["wishlist": FieldValue.arrayUnion([newPhotocardRef])]
            )
        }
        
        return true
    }
    
    /// Removes a photocard from a user's collection.
    /// - Parameters:
    ///   - photocard: The `Photocard` object to remove from the collection.
    ///   - user: The `User` object whose collection to update.
    func removePhotocardFromCollection(photocard: Photocard, user: User) {
        // Check if the user's collection contains the photocard.
        if user.all.contains(photocard), let userID = user.id, let photocardID = photocard.id {
            // Get a reference to the photocard's document.
            if let removedPhotocardRef = photocardsRef?.document(photocardID) {
                // Update the user's document to remove the photocard from the "all" array.
                usersRef?.document(userID).updateData(
                    ["all": FieldValue.arrayRemove([removedPhotocardRef])]
                )
            }
        }
        // Also remove the photocard from the user's favourites list.
        removePhotocardFromFavourites(photocard: photocard, user: user)
    }
    
    /// Removes a photocard from a user's favourites list.
    /// - Parameters:
    ///   - photocard: The `Photocard` object to remove from the favourites list.
    ///   - user: The `User` object whose favourites list to update.
    func removePhotocardFromFavourites(photocard: Photocard, user: User) {
        // Check if the user's favourites list contains the photocard.
        if user.favourites.contains(photocard), let userID = user.id, let photocardID = photocard.id {
            // Get a reference to the photocard's document.
            if let removedPhotocardRef = photocardsRef?.document(photocardID) {
                // Update the user's document to remove the photocard from the "favourites" array.
                usersRef?.document(userID).updateData(
                    ["favourites": FieldValue.arrayRemove([removedPhotocardRef])]
                )
            }
        }
    }
    
    /// Removes a photocard from a user's wishlist.
    /// - Parameters:
    ///   - photocard: The `Photocard` object to remove from the wishlist.
    ///   - user: The `User` object whose wishlist to update.
    func removePhotocardFromWishlist(photocard: Photocard, user: User) {
        // Check if the user's wishlist contains the photocard.
        if user.wishlist.contains(photocard), let userID = user.id, let photocardID = photocard.id {
            // Get a reference to the photocard's document.
            if let removedPhotocardRef = photocardsRef?.document(photocardID) {
                // Update the user's document to remove the photocard from the "wishlist" array.
                usersRef?.document(userID).updateData(
                    ["wishlist": FieldValue.arrayRemove([removedPhotocardRef])]
                )
            }
        }
    }
    
    // MARK: - File Storage
    
    /// Loads an image from the local file system.
    /// - Parameter filename: The name of the image file to load.
    /// - Returns: The loaded `UIImage` object, or `nil` if the image cannot be loaded.
    func loadImageData(filename: String) -> UIImage? {
        // Get the documents directory URL.
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        // Construct the full image URL by appending the filename to the documents directory URL.
        let imageURL = documentsDirectory.appendingPathComponent(filename)
        
        // Load the image from the file.
        let image = UIImage(contentsOfFile: imageURL.path)
        return image
    }
    
    /// Retrieves an image from either local storage or Firebase Storage.
    /// - Parameter imageData: A tuple containing the filename and image URL.
    /// - Returns: The retrieved `UIImage` object, or `nil` if the image cannot be retrieved.
    func getImage(imageData: (String, String)) -> UIImage? {
        let (filename, imageURL) = imageData
        
        // Load the image from the local file system.
        if let image = self.loadImageData(filename: filename) {
            return image
            
        } else {
            // Download from Firebase Storage.
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            
            // Download the image to the local file.
            let downloadTask = storageReference?.reference(forURL: imageURL).write(toFile: fileURL)
            var image: UIImage?
            
            // Observe the download task for success and failure events.
            downloadTask?.observe(.success) { snapshot in
                // Load the image from the local file.
                image = self.loadImageData(filename: filename)
            }

            downloadTask?.observe(.failure) { snapshot in
                print("\(String(describing: snapshot.error))")
            }
            
            return image
        }
    }
    
    // MARK: - Firebase Controller Specific m=Methods
    
    // MARK: Get Object ID
    
    /// Retrieves an `Idol` object from the `idolList` based on its ID.
    /// - Parameter id: The ID of the idol to retrieve.
    /// - Returns: The `Idol` object with the matching ID, or `nil` if no idol with that ID is found.
    func getIdolByID(_ id: String) -> Idol? {
        return idolList.first(where: { $0.id == id })
    }
    
    /// Retrieves an `Album` object from the `albumList` based on its ID.
    /// - Parameter id: The ID of the album to retrieve.
    /// - Returns: The `Album` object with the matching ID, or `nil` if no album with that ID is found.
    func getAlbumByID(_ id: String) -> Album? {
        return albumList.first(where: { $0.id == id })
    }
    
    /// Retrieves an `Artist` object from the `artistList` based on its ID.
    /// - Parameter id: The ID of the artist to retrieve.
    /// - Returns: The `Artist` object with the matching ID, or `nil` if no artist with that ID is found.
    func getArtistByID(_ id: String) -> Artist? {
        return artistList.first(where: { $0.id == id })
    }
    
    /// Retrieves a `Photocard` object from the `photocardList` based on its ID.
    /// - Parameter id: The ID of the photocard to retrieve.
    /// - Returns: The `Photocard` object with the matching ID, or `nil` if no photocard with that ID is found.
    func getPhotocardByID(_ id: String) -> Photocard? {
        return photocardList.first(where: { $0.id == id })
    }
    
    /// Retrieves a `Listing` object from the `listingList` based on its ID.
    /// - Parameter id: The ID of the listing to retrieve.
    /// - Returns: The `Listing` object with the matching ID, or `nil` if no listing with that ID is found.
    func getListingByID(_ id: String) -> Listing? {
        return listingList.first(where: { $0.id == id })
    }
    
    /// Retrieves a `User` object from the `userList` based on its ID.
    /// - Parameter id: The ID of the user to retrieve.
    /// - Returns: The `User` object with the matching ID, or `nil` if no user with that ID is found.
    func getUserByID(_ id: String) -> User? {
        return userList.first(where: { $0.id == id })
    }
    
    // MARK: Setup Listener
    
    /// Sets up a listener for changes in the "idols" collection.
    ///
    /// This function creates a snapshot listener for the "idols" collection in Firestore.
    /// When changes occur in the collection, the listener will trigger the `parseIdolSnapshot(snapshot:)` function.
    /// It also sets up listeners for other collections (albums, artists, photocards, users, and listings)
    /// if they haven't been set up already.
    func setupIdolListener() {
        // Get a reference to the "idols" collection in the Firestore database.
        idolsRef = database.collection("idols")
        
        // Add a snapshot listener to the "idols" collection.
        idolsRef?.addSnapshotListener() { (querySnapshot, error) in
            // Handle any errors that occur while fetching documents.
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            // Parse the snapshot to update the `idolList`.
            self.parseIdolSnapshot(snapshot: querySnapshot)
            
            // Set up listeners for other collections if they haven't been set up already.
            if self.albumsRef == nil {
                self.setupAlbumListener()
            }
            if self.artistsRef == nil {
                self.setupArtistListener()
            }
            if self.photocardsRef == nil {
                self.setupPhotocardListener()
            }
            if self.usersRef == nil {
                self.setupUserListener()
            }
            if self.listingsRef == nil {
                self.setupListingListener()
            }
        }
    }
    
    /// Sets up a listener for changes in the "artists" collection.
    ///
    /// This function creates a snapshot listener for the "artists" collection in Firestore.
    /// When changes occur in the collection, the listener will trigger the `parseArtistSnapshot(snapshot:)` function.
    func setupArtistListener() {
        // Get a reference to the "artists" collection in the Firestore database.
        artistsRef = database.collection("artists")
        
        // Add a snapshot listener to the "artists" collection.
        artistsRef?.addSnapshotListener() { (querySnapshot, error) in
            // Handle any errors that occur while fetching documents.
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            // Parse the snapshot to update the `artistList`.
            self.parseArtistSnapshot(snapshot: querySnapshot)
        }
    }
    
    /// Sets up a listener for changes in the "albums" collection.
    ///
    /// This function creates a snapshot listener for the "albums" collection in Firestore.
    /// When changes occur in the collection, the listener will trigger the `parseAlbumSnapshot(snapshot:)` function.
    func setupAlbumListener() {
        // Get a reference to the "albums" collection in the Firestore database.
        albumsRef = database.collection("albums")
        
        // Add a snapshot listener to the "albums" collection.
        albumsRef?.addSnapshotListener() { (querySnapshot, error) in
            // Handle any errors that occur while fetching documents.
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            // Parse the snapshot to update the `albumList`.
            self.parseAlbumSnapshot(snapshot: querySnapshot)
        }
    }
    
    /// Sets up a listener for changes in the "photocards" collection.
    ///
    /// This function creates a snapshot listener for the "photocards" collection in Firestore.
    /// When changes occur in the collection, the listener will trigger the `parsePhotocardSnapshot(snapshot:)` function.
    func setupPhotocardListener() {
        // Get a reference to the "photocards" collection in the Firestore database.
        photocardsRef = database.collection("photocards")
        
        // Add a snapshot listener to the "photocards" collection.
        photocardsRef?.addSnapshotListener() { (querySnapshot, error) in
            // Handle any errors that occur while fetching documents.
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            // Parse the snapshot to update the `photocardList`.
            self.parsePhotocardSnapshot(snapshot: querySnapshot)
        }
    }
    
    /// Sets up a listener for changes in the "listings" collection.
    ///
    /// This function creates a snapshot listener for the "listings" collection in Firestore.
    /// When changes occur in the collection, the listener will trigger the `parseListingSnapshot(snapshot:)` function.
    func setupListingListener() {
        // Get a reference to the "listings" collection in the Firestore database.
        listingsRef = database.collection("listings")
        
        // Add a snapshot listener to the "listings" collection.
        listingsRef?.addSnapshotListener() { (querySnapshot, error) in
            // Handle any errors that occur while fetching documents.
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            // Parse the snapshot to update the `listingList`.
            self.parseListingSnapshot(snapshot: querySnapshot)
        }
    }
    
    /// Sets up a listener for changes in the "users" collection.
    ///
    /// This function creates a snapshot listener for the "users" collection in Firestore.
    /// When changes occur in the collection, the listener will trigger the `parseUserSnapsnot(snapshot:)` function.
    func setupUserListener() {
        // Get a reference to the "users" collection in the Firestore database.
        usersRef = database.collection("users")
        
        // Add a snapshot listener to the "users" collection.
        usersRef?.addSnapshotListener() { (querySnapshot, error) in
            // Handle any errors that occur while fetching documents.
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            // Parse the snapshot to update the `userList`.
            self.parseUserSnapsnot(snapshot: querySnapshot)
        }
    }
    
    // MARK: Parse Snapshot
    
    /// Parses a snapshot of the "idols" collection and updates the `idolList`.
    ///
    /// This function iterates through the document changes in the snapshot and updates the `idolList` accordingly.
    /// It handles added, modified, and removed documents. It also notifies listeners of the changes.
    ///
    /// - Parameter snapshot: The snapshot of the "idols" collection.
    func parseIdolSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            var idol: Idol
            
            // Decode the document data into an Idol object.
            do {
                idol = try change.document.data(as: Idol.self)
            } catch {
                fatalError("Unable to decode idol: \(error.localizedDescription)")
            }
            
            // Handle different types of document changes.
            if change.type == .added {
                // If the idol is not already in the list, add it at the correct index.
                if !idolList.contains(idol) {
                    idolList.insert(idol, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                // Remove the idol from the list at its old index and insert it at its new index.
                idolList.remove(at: Int(change.oldIndex))
                idolList.insert(idol, at: Int(change.newIndex))
            } else if change.type == .removed {
                // Remove the idol from the list at its old index.
                idolList.remove(at: Int(change.oldIndex))
            }
            
            // Notify listeners of the changes.
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.idol || listener.listenerType == ListenerType.all {
                    listener.onAllIdolsChange(change: .update, idols: idolList)
                }
            }
        }
    }
    
    /// Parses a snapshot of the "artists" collection and updates the `artistList`.
    ///
    /// This function iterates through the document changes in the snapshot and updates the `artistList` accordingly.
    /// It handles added, modified, and removed documents. It also notifies listeners of the changes.
    ///
    /// - Parameter snapshot: The snapshot of the "artists" collection.
    func parseArtistSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            let artist = Artist()
            
            // Extract data from the document.
            artist.id = change.document.documentID
            artist.name = change.document.data()["name"] as? String
            artist.image = change.document.data()["image"] as? String
            
            // Retrieve associated albums and members.
            if let albumReferences = change.document.data()["albums"] as? [DocumentReference] {
                for reference in albumReferences {
                    if let album = getAlbumByID(reference.documentID) {
                        artist.albums.append(album)
                    }
                }
            }
            
            if let memberReferences = change.document.data()["members"] as? [DocumentReference] {
                for reference in memberReferences {
                    if let member = getIdolByID(reference.documentID) {
                        artist.members.append(member)
                    }
                }
            }
            
            // Handle different types of document changes.
            if change.type == .added {
                // If the artist is not already in the list, add it at the correct index.
                if !artistList.contains(artist) {
                    artistList.insert(artist, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                // Remove the artist from the list at its old index and insert it at its new index.
                artistList.remove(at: Int(change.oldIndex))
                artistList.insert(artist, at: Int(change.newIndex))
            } else if change.type == .removed {
                // Remove the artist from the list at its old index.
                artistList.remove(at: Int(change.oldIndex))
            }
            
            // Notify listeners of the changes.
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.artist || listener.listenerType == ListenerType.all {
                    listener.onAllArtistsChange(change: .update, artists: artistList)
                }
            }
        }
    }
    
    /// Parses a snapshot of the "albums" collection and updates the `albumList`.
    ///
    /// This function iterates through the document changes in the snapshot and updates the `albumList` accordingly.
    /// It handles added, modified, and removed documents. It also notifies listeners of the changes.
    ///
    /// - Parameter snapshot: The snapshot of the "albums" collection.
    func parseAlbumSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            
            let album = Album()
            
            // Extract data from the document.
            album.id = change.document.documentID
            album.name = change.document.data()["name"] as? String
            
            // Handle different types of document changes.
            if change.type == .added {
                // If the album is not already in the list, add it at the correct index.
                if !albumList.contains(album) {
                    albumList.insert(album, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                // Remove the album from the list at its old index and insert it at its new index.
                albumList.remove(at: Int(change.oldIndex))
                albumList.insert(album, at: Int(change.newIndex))
            } else if change.type == .removed {
                // Remove the album from the list at its old index.
                albumList.remove(at: Int(change.oldIndex))
            }
            
            // Notify listeners of the changes.
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.album || listener.listenerType == ListenerType.all {
                    listener.onAllAlbumsChange(change: .update, albums: albumList)
                }
            }
        }
    }
    
    /// Parses a snapshot of the "photocards" collection and updates the `photocardList`.
    ///
    /// This function iterates through the document changes in the snapshot and updates the `photocardList` accordingly.
    /// It handles added, modified, and removed documents. It also notifies listeners of the changes.
    ///
    /// - Parameter snapshot: The snapshot of the "photocards" collection.
    func parsePhotocardSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            let photocard = Photocard()
            
            // Extract data from the document.
            photocard.id = change.document.documentID
            
            // Retrieve associated idol, artist, and album.
            if let idolReference = change.document.data()["idol"] as? DocumentReference {
                if let idol = getIdolByID(idolReference.documentID) {
                    photocard.idol = idol
                }
            }
            
            if let artistReference = change.document.data()["artist"] as? DocumentReference {
                if let artist = getArtistByID(artistReference.documentID) {
                    photocard.artist = artist
                }
            }
            
            if let albumReference = change.document.data()["album"] as? DocumentReference {
                if let album = getAlbumByID(albumReference.documentID) {
                    photocard.album = album
                }
            }
            
            // Retrieve the photocard image.
            change.document.reference.collection("images").getDocuments { (querySnapshot, error) in
                guard let querySnapshot = querySnapshot else {
                    print("Failed to fetch documents with error: \(String(describing: error))")
                    return
                }
                
                if let image = querySnapshot.documents.last, let url = image.data()["url"] as? String {
                    let imageName = image.documentID
                    photocard.image = (imageName, url)
                } else {
                    print("[Photocard] No image found")
                }
            }
            
            // Handle different types of document changes.
            if change.type == .added {
                // If the photocard is not already in the list, add it at the correct index.
                if !photocardList.contains(photocard) {
                    photocardList.insert(photocard, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                // Remove the photocard from the list at its old index and insert it at its new index.
                photocardList.remove(at: Int(change.oldIndex))
                photocardList.insert(photocard, at: Int(change.newIndex))
            } else if change.type == .removed {
                // Remove the photocard from the list at its old index.
                photocardList.remove(at: Int(change.oldIndex))
            }
            
            // Notify listeners of the changes.
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.photocard || listener.listenerType == ListenerType.all {
                    listener.onAllPhotocardsChange(change: .update, photocards: photocardList)
                }
            }
        }
    }
    
    /// Parses a snapshot of the "users" collection and updates the `userList`.
    ///
    /// This function iterates through the document changes in the snapshot and updates the `userList` accordingly.
    /// It handles added, modified, and removed documents. It also notifies listeners of the changes and updates the `currentUser` if necessary.
    ///
    /// - Parameter snapshot: The snapshot of the "users" collection.
    func parseUserSnapsnot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            let user = User()
            
            // Extract data from the document.
            user.name = change.document.data()["name"] as? String
            user.email = change.document.data()["email"] as? String
            user.isAnonymous = change.document.data()["isAnonymous"] as? Bool
            user.id = change.document.documentID
            
            // Retrieve associated photocards from the "all", "favourites", and "wishlist" arrays.
            if let allReferences = change.document.data()["all"] as? [DocumentReference] {
                for reference in allReferences {
                    if let photocard = getPhotocardByID(reference.documentID) {
                        user.all.append(photocard)
                    }
                }
            }
            
            if let favouriteReferences = change.document.data()["favourites"] as? [DocumentReference] {
                for reference in favouriteReferences {
                    if let photocard = getPhotocardByID(reference.documentID) {
                        user.favourites.append(photocard)
                    }
                }
            }
            
            if let wishlistReferences = change.document.data()["wishlist"] as? [DocumentReference] {
                for reference in wishlistReferences {
                    if let photocard = getPhotocardByID(reference.documentID) {
                        user.wishlist.append(photocard)
                    }
                }
            }
            
            // Retrieve the user's image.
            if let a = change.document.data()["image"] as? [String] {
                // Extract the filename and image URL from the imageData array.
                if a.count == 2 {
                    if let imageName = a.first, let imageURL = a.last {
                        user.image = (imageName, imageURL)
                    }
                }
            }
            
            // Handle different types of document changes.
            if change.type == .added {
                // If the user is not already in the list, add it at the correct index.
                if !userList.contains(user) {
                    userList.insert(user, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                // Remove the user from the list at its old index and insert it at its new index.
                userList.remove(at: Int(change.oldIndex))
                userList.insert(user, at: Int(change.newIndex))
            } else if change.type == .removed {
                // Remove the user from the list at its old index.
                userList.remove(at: Int(change.oldIndex))
            }
            
            // Update the `currentUser` if the current user's ID matches the parsed user's ID.
            if user.id == currentUser.id {
                currentUser = user
                
                // Notify listeners of the changes to the `currentUser`.
                listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.user {
                        listener.onUserChange(change: .update, user: currentUser)
                    }
                }
            }
        }
    }
    
    /// Parses a snapshot of the "listings" collection and updates the `listingList`.
    ///
    /// This function iterates through the document changes in the snapshot and updates the `listingList` accordingly.
    /// It handles added, modified, and removed documents. It also notifies listeners of the changes.
    ///
    /// - Parameter snapshot: The snapshot of the "listings" collection.
    func parseListingSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            let listing = Listing()
            
            // Extract data from the document.
            listing.id = change.document.documentID
            listing.price = change.document.data()["price"] as? Double
            listing.listDate = change.document.data()["listDate"] as? String
            listing.descriptionText = change.document.data()["descriptionText"] as? String
            
            // Retrieve associated photocard and seller.
            if let photocardReference = change.document.data()["photocard"] as? DocumentReference {
                if let photocard = getPhotocardByID(photocardReference.documentID) {
                    listing.photocard = photocard
                }
            }
            
            if let sellerReference = change.document.data()["seller"] as? DocumentReference {
                if let seller = getUserByID(sellerReference.documentID) {
                    listing.seller = seller
                } else {
                    print("Failed to get seller by id")
                }
            }
            
            // Retrieve the listing images.
            change.document.reference.collection("images").getDocuments { (querySnapshot, error) in
                guard let querySnapshot = querySnapshot else {
                    print("Failed to fetch documents with error: \(String(describing: error))")
                    return
                }
                
                // Extract the image filename and URL from each document.
                for image in querySnapshot.documents {
                    if let url = image.data()["url"] as? String {
                        let imageName = image.documentID
                        listing.images.append((imageName, url))
                    }
                }
            }
            
            // Handle different types of document changes.
            if change.type == .added {
                // If the listing is not already in the list, add it at the correct index.
                if !listingList.contains(listing) {
                    listingList.insert(listing, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                // Remove the listing from the list at its old index and insert it at its new index.
                listingList.remove(at: Int(change.oldIndex))
                listingList.insert(listing, at: Int(change.newIndex))
            } else if change.type == .removed {
                // Remove the listing from the list at its old index.
                listingList.remove(at: Int(change.oldIndex))
            }
            
            // Notify listeners of the changes.
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.listing || listener.listenerType == ListenerType.all {
                    listener.onAllListingsChange(change: .update, listings: listingList)
                }
            }
        }
    }
    
    /// Loads a default image from Firebase Storage and sets it as the `defaultUserImage`.
    ///
    /// This function downloads the specified image from Firebase Storage and saves it to the local file system.
    /// It then loads the image from the local file and sets it as the `defaultUserImage`.
    ///
    /// - Parameter filename: The name of the image file to download.
    func loadDefaultImage(filename: String) {
        // Get the documents directory URL.
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        // Construct the full image URL in Firebase Storage.
        let imageURL = "\(storageRootPath)/default/images/\(filename)"
        
        // Construct the full file URL in the local file system.
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        // Download the image to the local file.
        let downloadTask = storageReference?.reference(forURL: imageURL).write(toFile: fileURL)
        
        // Observe the download task for success and failure events.
        downloadTask?.observe(.success) { snapshot in
            // Load the image from the local file.
            if let image = self.loadImageData(filename: filename) {
                self.defaultUserImage = image
            }
        }
        
        downloadTask?.observe(.failure) { snapshot in
            print("\(String(describing: snapshot.error))")
        }
    }
    
}
