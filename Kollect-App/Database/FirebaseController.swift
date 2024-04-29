//
//  FirebaseController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class FirebaseController: NSObject, DatabaseProtocol {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var idolList: [Idol]
    var artistList: [Artist]
    var albumList: [Album]
    var photocardList: [Photocard]
    var currentUser: User
    let DEFAULT_USERNAME = "Anonymous"
    var authController: Auth
    var database: Firestore
    var idolsRef: CollectionReference?
    var artistsRef: CollectionReference?
    var albumsRef: CollectionReference?
    var photocardsRef: CollectionReference?
    var usersRef: CollectionReference?
    
    override init() {
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        
        idolList = [Idol]()
        artistList = [Artist]()
        albumList = [Album]()
        photocardList = [Photocard]()
        currentUser = User()
        
        super.init()
        
        // Sign in anonymously
        Task {
            do {
                let authResult = try await authController.signInAnonymously()
                currentUser = addUser(userID: authResult.user.uid, username: DEFAULT_USERNAME, isAnonymous: true)
            } catch {
                fatalError("Firebase Authentication Failed with Error \(String(describing: error))")
            }
            self.setupIdolListener()
        }
    }
    
    func logInAccount(email: String, password: String) async {
        do {
            let authResult = try await authController.signIn(withEmail: email, password: password)
            currentUser.id = authResult.user.uid
            print("Log in: \(authResult.user.uid)")
        } catch {
            print("Authentication failed with error:: \(error.localizedDescription)")
        }
        
        if idolsRef == nil {
            self.setupIdolListener()
        }
        
        // Change user
        self.setupUserListener()
    }
    
    func createAccount(email: String, username: String, password: String) async {
        do {
            let authResult = try await authController.createUser(withEmail: email, password: password)
            currentUser = addUser(userID: authResult.user.uid, username: username, isAnonymous: false)
        } catch {
            print("User creation failed with error: \(error.localizedDescription)")
        }
        
        if idolsRef == nil {
            self.setupIdolListener()
        }
        
        // Change user
        self.setupUserListener()
    }
    
    func cleanup() {
        // Empty
    }
    
    func addListener(listener: any DatabaseListener) {
        listeners.addDelegate(listener)
        
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
        
        // Collection
        if listener.listenerType == .user || listener.listenerType == .all {
            listener.onUserChange(change: .update, user: currentUser)
        }
    }
    
    func removeListener(listener: any DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func addIdol(idolName: String, idolBirthday: String) -> Idol {
        let idol = Idol()
        idol.name = idolName
        idol.birthday = idolBirthday
        
        // WHERE DO I ADD DEFAULT DATA??
        
        if let idolRef = idolsRef?.addDocument(data: ["name": idolName, "birthday": idolBirthday]) {
            idol.id = idolRef.documentID
        }
        
        return idol
    }
    
    func deleteIdol(idol: Idol) {
        if let idolID = idol.id {
            idolsRef?.document(idolID).delete()
        }
        
        // Delete from artist (if any)
        // Delete its photocards (if any)
        // Delete from collection (if any)
    }
    
    func addArtist(artistName: String) -> Artist {
        let artist = Artist()
        artist.name = artistName
        
        if let artistRef = artistsRef?.addDocument(data: ["name": artistName]) {
            artist.id = artistRef.documentID
        }
        
        return artist
    }
    
    func deleteArtist(artist: Artist) {
        if let artistID = artist.id {
            artistsRef?.document(artistID).delete()
        }
    }
    
    func addIdolToArtist(idol: Idol, artist: Artist) -> Bool {
        guard let idolID = idol.id, let artistID = artist.id else {
            return false
        }
        
        if let newIdolRef = idolsRef?.document(idolID) {
            artistsRef?.document(artistID).updateData(
                ["members": FieldValue.arrayUnion([newIdolRef])]
            )
        }
        
        return true
    }
    
    func removeIdolFromArtist(idol: Idol, artist: Artist) {
        if artist.members.contains(idol), let artistID = artist.id, let idolID = idol.id {
            if let removedIdolRef = idolsRef?.document(idolID) {
                artistsRef?.document(artistID).updateData(
                    ["members": FieldValue.arrayRemove([removedIdolRef])]
                )
            }
        }
    }
    
    func addAlbum(albumName: String, albumImage: String) -> Album {
        let album = Album()
        album.name = albumName
        album.image = albumImage
        
        if let albumRef = albumsRef?.addDocument(data: ["name": albumName, "image": albumImage]) {
            album.id = albumRef.documentID
        }
        
        return album
    }
    
    func deleteAlbum(album: Album) {
        if let albumID = album.id {
            albumsRef?.document(albumID).delete()
        }
    }
    
    func addAlbumToArtist(album: Album, artist: Artist) -> Bool {
        guard let albumID = album.id, let artistID = artist.id else {
            return false
        }
        
        if let newAlbumRef = albumsRef?.document(albumID) {
            artistsRef?.document(artistID).updateData(
                ["albums": FieldValue.arrayUnion([newAlbumRef])]
            )
        }
        
        return true
    }
    
    func removeAlbumFromArtist(album: Album, artist: Artist) {
        if artist.albums.contains(album), let artistID = artist.id, let albumID = album.id {
            if let removedAlbumRef = albumsRef?.document(albumID) {
                artistsRef?.document(artistID).updateData(
                    ["albums": FieldValue.arrayRemove([removedAlbumRef])]
                )
            }
        }
    }
    
    func addPhotocardToAlbum(photocard: Photocard, album: Album) -> Bool {
        guard let photocardID = photocard.id, let albumID = album.id else {
            return false
        }
        
        if let newPhotocardRef = photocardsRef?.document(photocardID) {
            albumsRef?.document(albumID).updateData(
                ["photocards": FieldValue.arrayUnion([newPhotocardRef])]
            )
        }
        
        return true
    }
    
    func removePhotocardFromAlbum(photocard: Photocard, album: Album) {
        if album.photocards.contains(photocard), let albumID = album.id, let photocardID = photocard.id {
            if let removedPhotocardRef = photocardsRef?.document(albumID) {
                albumsRef?.document(albumID).updateData(
                    ["albums": FieldValue.arrayRemove([removedPhotocardRef])]
                )
            }
        }
    }
    
    func addPhotocard(idol: Idol, artist: Artist, album: Album, image: String) -> Photocard {
        let photocard = Photocard()
        photocard.idol = idol
        photocard.artist = artist
        photocard.album = album
        photocard.image = image
        
        // Should save idol name only or idol object
        if let idolID = idol.id, let artistID = artist.id, let albumID = album.id {
            
            if let idolRef = idolsRef?.document(idolID), let artistRef = artistsRef?.document(artistID), let albumRef = albumsRef?.document(albumID) {
                
                if let photocardRef = photocardsRef?.addDocument(data: ["idol": idolRef, "artist": artistRef, "album": albumRef, "image": image]) {
                    
                    photocard.id = photocardRef.documentID
                }
            }
        }
        
        // Add to Artist -> Album -> Idol
        if !addPhotocardToAlbum(photocard: photocard, album: album) {
            print("Error adding photocard to album.")
        }
        
        return photocard
    }
    
    func deletePhotocard(photocard: Photocard) {
        if let photocardID = photocard.id {
            photocardsRef?.document(photocardID).delete()
        }
    }
    
    func addUser(userID: String, username: String, isAnonymous: Bool) -> User {
        usersRef = database.collection("users")
        let user = User()
        user.id = userID
        user.name = username
        user.isAnonymous = isAnonymous
        
        // Create user document
        if let userRef = usersRef?.document(userID) {
            userRef.setData(["name": username])
        }
        
        return user
    }
    
    func deleteUser(user: User) {
        if let userID = user.id {
            // Deletes 'collection' too
            usersRef?.document(userID).delete()
        }
    }
    
    func addPhotocardToCollection(photocard: Photocard, user: User) -> Bool {
        guard let photocardID = photocard.id, let userID = user.id else {
            return false
        }
        
        if let newPhotocardRef = photocardsRef?.document(photocardID) {
            usersRef?.document(userID).updateData(
                ["all": FieldValue.arrayUnion([newPhotocardRef])]
            )
        }
        
        return true
    }
    
    func addPhotocardToFavourites(photocard: Photocard, user: User) -> Bool {
        guard let photocardID = photocard.id, let userID = user.id else {
            return false
        }
        
        if let newPhotocardRef = photocardsRef?.document(photocardID) {
            usersRef?.document(userID).updateData(
                ["favourites": FieldValue.arrayUnion([newPhotocardRef])]
            )
        }
        
        return true
    }
    
    func addPhotocardToWishlist(photocard: Photocard, user: User) -> Bool {
        guard let photocardID = photocard.id, let userID = user.id else {
            return false
        }
        
        if let newPhotocardRef = photocardsRef?.document(photocardID) {
            usersRef?.document(userID).updateData(
                ["wishlist": FieldValue.arrayUnion([newPhotocardRef])]
            )
        }
        
        return true
    }
    
    func removePhotocardFromCollection(photocard: Photocard, user: User) {
        if user.all.contains(photocard), let userID = user.id, let photocardID = photocard.id {
            if let removedPhotocardRef = photocardsRef?.document(photocardID) {
                usersRef?.document(userID).updateData(
                    ["all": FieldValue.arrayRemove([removedPhotocardRef])]
                )
            }
        }
    }
    
    func removePhotocardFromFavourites(photocard: Photocard, user: User) {
        if user.favourites.contains(photocard), let userID = user.id, let photocardID = photocard.id {
            if let removedPhotocardRef = photocardsRef?.document(photocardID) {
                usersRef?.document(userID).updateData(
                    ["favourites": FieldValue.arrayRemove([removedPhotocardRef])]
                )
            }
        }
    }
    
    func removePhotocardFromWishlist(photocard: Photocard, user: User) {
        if user.wishlist.contains(photocard), let userID = user.id, let photocardID = photocard.id {
            if let removedPhotocardRef = photocardsRef?.document(photocardID) {
                usersRef?.document(userID).updateData(
                    ["wishlist": FieldValue.arrayRemove([removedPhotocardRef])]
                )
            }
        }
    }
    
    // MARK: - Firebase Controller Specific m=Methods
    func getPhotocardByID(_ id: String) -> Photocard? {
        return photocardList.first(where: { $0.id == id })
    }
    
    func setupIdolListener() {
        idolsRef = database.collection("idols")
        idolsRef?.addSnapshotListener() { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            self.parseIdolSnapshot(snapshot: querySnapshot)
            
            // First-time calls
            if self.artistsRef == nil {
                self.setupArtistListener()
            }
            
            if self.photocardsRef == nil {
                self.setupPhotocardListener()
            }
            
            if self.usersRef == nil {
                self.setupUserListener()
            }
        }
    }
    
    func setupArtistListener() {
        artistsRef = database.collection("artists")
        artistsRef?.addSnapshotListener() { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            self.parseArtistSnapshot(snapshot: querySnapshot)
        }
    }
    
    func setupPhotocardListener() {
        photocardsRef = database.collection("photocards")
        photocardsRef?.addSnapshotListener() { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            self.parsePhotocardSnapshot(snapshot: querySnapshot)
        }
    }
    
    func setupUserListener() {
        usersRef = database.collection("users")
        usersRef?.whereField("name", isEqualTo: currentUser.id!).addSnapshotListener { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot, let userSnapshot = querySnapshot.documents.first else {
                print("Error fetching user: \(String(describing: error))")
                return
            }
            
            self.parseUserSnapsnot(snapshot: userSnapshot)
        }
    }
    
    func parseIdolSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            var idol: Idol
            
            do {
                idol = try change.document.data(as: Idol.self)
            } catch {
                fatalError("Unable to decode idol: \(error.localizedDescription)")
            }
            
            if change.type == .added {
                if !idolList.contains(idol) {
                    idolList.insert(idol, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                idolList.remove(at: Int(change.oldIndex))
                idolList.insert(idol, at: Int(change.newIndex))
            } else if change.type == .removed {
                idolList.remove(at: Int(change.oldIndex))
            }
            
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.idol || listener.listenerType == ListenerType.all {
                    listener.onAllIdolsChange(change: .update, idols: idolList)
                }
            }
        }
    }
    
    func parseArtistSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            var artist: Artist
            
            do {
                artist = try change.document.data(as: Artist.self)
            } catch {
                fatalError("Unable to decode artist: \(error.localizedDescription)")
            }
            
            if change.type == .added {
                if !artistList.contains(artist) {
                    artistList.insert(artist, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                artistList.remove(at: Int(change.oldIndex))
                artistList.insert(artist, at: Int(change.newIndex))
            } else if change.type == .removed {
                artistList.remove(at: Int(change.oldIndex))
            }
            
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.artist || listener.listenerType == ListenerType.all {
                    listener.onAllArtistsChange(change: .update, artists: artistList)
                }
            }
        }
    }
    
    func parsePhotocardSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            var photocard: Photocard
            
            do {
                photocard = try change.document.data(as: Photocard.self)
            } catch {
                fatalError("Unable to decode photocard: \(error.localizedDescription)")
            }
            
            if change.type == .added {
                if !photocardList.contains(photocard) {
                    photocardList.insert(photocard, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                photocardList.remove(at: Int(change.oldIndex))
                photocardList.insert(photocard, at: Int(change.newIndex))
            } else if change.type == .removed {
                photocardList.remove(at: Int(change.oldIndex))
            }
            
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.photocard || listener.listenerType == ListenerType.all {
                    listener.onAllPhotocardsChange(change: .update, photocards: photocardList)
                }
            }
        }
    }
    
    func parseUserSnapsnot(snapshot: QueryDocumentSnapshot) {
        currentUser = User()
        currentUser.name = snapshot.data()["name"] as? String
        currentUser.id = snapshot.documentID
        
        if let allReferences = snapshot.data()["all"] as? [DocumentReference] {
            for reference in allReferences {
                if let photocard = getPhotocardByID(reference.documentID) {
                    currentUser.all.append(photocard)
                }
            }
        }
        
        if let favouriteReferences = snapshot.data()["favourites"] as? [DocumentReference] {
            for reference in favouriteReferences {
                if let photocard = getPhotocardByID(reference.documentID) {
                    currentUser.favourites.append(photocard)
                }
            }
        }
        
        if let wishlistReferences = snapshot.data()["wishlist"] as? [DocumentReference] {
            for reference in wishlistReferences {
                if let photocard = getPhotocardByID(reference.documentID) {
                    currentUser.wishlist.append(photocard)
                }
            }
        }
        
        listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.user {
                listener.onUserChange(change: .update, user: currentUser)
            }
        }
    }
    
    // Only call when adding initial data
    func createDefaults() {
        let idolA = addIdol(idolName: "A", idolBirthday: "2001-01-01")
        let idolB = addIdol(idolName: "B", idolBirthday: "2002-02-02")
        let idolC = addIdol(idolName: "C", idolBirthday: "2003-03-03")
        let idolD = addIdol(idolName: "D", idolBirthday: "2004-04-04")
        let idolE = addIdol(idolName: "E", idolBirthday: "2005-05-05")
        let idolF = addIdol(idolName: "F", idolBirthday: "2006-06-06")
        
        let artistA = addArtist(artistName: "123")
        let artistB = addArtist(artistName: "456")
        let artistC = addArtist(artistName: "789")
        
        let albumA = addAlbum(albumName: "Album 1", albumImage: "")
        let albumB = addAlbum(albumName: "Album 2", albumImage: "")
        let albumC = addAlbum(albumName: "Album 3", albumImage: "")
        let albumD = addAlbum(albumName: "Album 4", albumImage: "")
        let albumE = addAlbum(albumName: "Album 5", albumImage: "")
        let albumF = addAlbum(albumName: "Album 6", albumImage: "")
        
        let _ = addIdolToArtist(idol: idolA, artist: artistA)
        let _ = addIdolToArtist(idol: idolB, artist: artistA)
        let _ = addIdolToArtist(idol: idolC, artist: artistB)
        let _ = addIdolToArtist(idol: idolD, artist: artistB)
        let _ = addIdolToArtist(idol: idolE, artist: artistC)
        let _ = addIdolToArtist(idol: idolF, artist: artistC)
        
        let _ = addAlbumToArtist(album: albumA, artist: artistA)
        let _ = addAlbumToArtist(album: albumB, artist: artistA)
        let _ = addAlbumToArtist(album: albumC, artist: artistB)
        let _ = addAlbumToArtist(album: albumD, artist: artistB)
        let _ = addAlbumToArtist(album: albumE, artist: artistC)
        let _ = addAlbumToArtist(album: albumF, artist: artistC)
        
        let _ = addPhotocard(idol: idolA, artist: artistA, album: albumA, image: "")
        let _ = addPhotocard(idol: idolA, artist: artistA, album: albumB, image: "")
        let _ = addPhotocard(idol: idolB, artist: artistA, album: albumA, image: "")
        let _ = addPhotocard(idol: idolB, artist: artistA, album: albumB, image: "")
        let _ = addPhotocard(idol: idolC, artist: artistB, album: albumC, image: "")
        let _ = addPhotocard(idol: idolC, artist: artistB, album: albumD, image: "")
        let _ = addPhotocard(idol: idolD, artist: artistB, album: albumC, image: "")
        let _ = addPhotocard(idol: idolD, artist: artistB, album: albumD, image: "")
        let _ = addPhotocard(idol: idolE, artist: artistC, album: albumE, image: "")
        let _ = addPhotocard(idol: idolE, artist: artistC, album: albumF, image: "")
        let _ = addPhotocard(idol: idolF, artist: artistC, album: albumE, image: "")
        let _ = addPhotocard(idol: idolF, artist: artistC, album: albumF, image: "")
    }
}
