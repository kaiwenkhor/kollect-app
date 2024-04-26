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
    var artistList: [Artist]
    var groupList: [Group]
    var albumList: [Album]
    var photocardList: [Photocard]
    var currentUser: User
    let DEFAULT_USERNAME = "Anonymous"
    var authController: Auth
    var database: Firestore
    var artistsRef: CollectionReference?
    var groupsRef: CollectionReference?
    var albumsRef: CollectionReference?
    var photocardsRef: CollectionReference?
    var usersRef: CollectionReference?
    
    override init() {
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        
        artistList = [Artist]()
        groupList = [Group]()
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
            self.setupArtistListener()
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
        
        if artistsRef == nil {
            self.setupArtistListener()
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
        
        if artistsRef == nil {
            self.setupArtistListener()
        }
        
        // Change user
        self.setupUserListener()
    }
    
    func cleanup() {
        // Empty
    }
    
    func addListener(listener: any DatabaseListener) {
        listeners.addDelegate(listener)
        
        // Artist
        if listener.listenerType == .artist || listener.listenerType == .all {
            listener.onAllArtistsChange(change: .update, artists: artistList)
        }
        
        // Group
        if listener.listenerType == .group || listener.listenerType == .all {
            listener.onAllGroupsChange(change: .update, groups: groupList)
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
    
    func addArtist(artistName: String, artistBirthday: String) -> Artist {
        let artist = Artist()
        artist.name = artistName
        artist.birthday = artistBirthday
        
        // WHERE DO I ADD DEFAULT DATA??
        
        if let artistRef = artistsRef?.addDocument(data: ["name": artistName, "birthday": artistBirthday]) {
            artist.id = artistRef.documentID
        }
        
        return artist
    }
    
    func deleteArtist(artist: Artist) {
        if let artistID = artist.id {
            artistsRef?.document(artistID).delete()
        }
        
        // Delete from group (if any)
        // Delete its photocards (if any)
        // Delete from collection (if any)
    }
    
    func addGroup(groupName: String) -> Group {
        let group = Group()
        group.name = groupName
        
        if let groupRef = groupsRef?.addDocument(data: ["name": groupName]) {
            group.id = groupRef.documentID
        }
        
        return group
    }
    
    func deleteGroup(group: Group) {
        if let groupID = group.id {
            groupsRef?.document(groupID).delete()
        }
    }
    
    func addArtistToGroup(artist: Artist, group: Group) -> Bool {
        guard let artistID = artist.id, let groupID = group.id else {
            return false
        }
        
        if let newArtistRef = artistsRef?.document(artistID) {
            groupsRef?.document(groupID).updateData(
                ["members": FieldValue.arrayUnion([newArtistRef])]
            )
        }
        
        return true
    }
    
    func removeArtistFromGroup(artist: Artist, group: Group) {
        if group.members.contains(artist), let groupID = group.id, let artistID = artist.id {
            if let removedArtistRef = artistsRef?.document(artistID) {
                groupsRef?.document(groupID).updateData(
                    ["members": FieldValue.arrayRemove([removedArtistRef])]
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
    
    func addAlbumToGroup(album: Album, group: Group) -> Bool {
        guard let albumID = album.id, let groupID = group.id else {
            return false
        }
        
        if let newAlbumRef = albumsRef?.document(albumID) {
            groupsRef?.document(groupID).updateData(
                ["albums": FieldValue.arrayUnion([newAlbumRef])]
            )
        }
        
        return true
    }
    
    func removeAlbumFromGroup(album: Album, group: Group) {
        if group.albums.contains(album), let groupID = group.id, let albumID = album.id {
            if let removedAlbumRef = albumsRef?.document(albumID) {
                groupsRef?.document(groupID).updateData(
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
    
    func addPhotocard(artist: Artist, group: Group, album: Album, image: String) -> Photocard {
        let photocard = Photocard()
        photocard.artist = artist
        photocard.group = group
        photocard.album = album
        photocard.image = image
        
        // Should save artist name only or artist object
        if let photocardRef = photocardsRef?.addDocument(data: ["artist": artist, "group": group, "album": album, "image": image]) {
            
            photocard.id = photocardRef.documentID
        }
        
        // Add to Group -> Album -> Artist
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
    
    func setupArtistListener() {
        artistsRef = database.collection("artists")
        artistsRef?.addSnapshotListener() { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            self.parseArtistSnapshot(snapshot: querySnapshot)
            
            // First-time calls
            if self.groupsRef == nil {
                self.setupGroupListener()
            }
            
            if self.photocardsRef == nil {
                self.setupPhotocardListener()
            }
            
            if self.usersRef == nil {
                self.setupUserListener()
            }
        }
    }
    
    func setupGroupListener() {
        groupsRef = database.collection("groups")
        groupsRef?.addSnapshotListener() { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            self.parseGroupSnapshot(snapshot: querySnapshot)
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
    
    func parseGroupSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            var group: Group
            
            do {
                group = try change.document.data(as: Group.self)
            } catch {
                fatalError("Unable to decode artist: \(error.localizedDescription)")
            }
            
            if change.type == .added {
                if !groupList.contains(group) {
                    groupList.insert(group, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                groupList.remove(at: Int(change.oldIndex))
                groupList.insert(group, at: Int(change.newIndex))
            } else if change.type == .removed {
                groupList.remove(at: Int(change.oldIndex))
            }
            
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.group || listener.listenerType == ListenerType.all {
                    listener.onAllGroupsChange(change: .update, groups: groupList)
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
                fatalError("Unable to decode artist: \(error.localizedDescription)")
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
        currentUser.id = snapshot.data()["id"] as? String
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
        let artistA = addArtist(artistName: "A", artistBirthday: "2001-01-01")
        let artistB = addArtist(artistName: "B", artistBirthday: "2002-02-02")
        let artistC = addArtist(artistName: "C", artistBirthday: "2003-03-03")
        let artistD = addArtist(artistName: "D", artistBirthday: "2004-04-04")
        let artistE = addArtist(artistName: "E", artistBirthday: "2005-05-05")
        let artistF = addArtist(artistName: "F", artistBirthday: "2006-06-06")
        
        let groupA = addGroup(groupName: "123")
        let groupB = addGroup(groupName: "456")
        let groupC = addGroup(groupName: "789")
        
        let albumA = addAlbum(albumName: "Album 1", albumImage: "")
        let albumB = addAlbum(albumName: "Album 2", albumImage: "")
        let albumC = addAlbum(albumName: "Album 3", albumImage: "")
        let albumD = addAlbum(albumName: "Album 4", albumImage: "")
        let albumE = addAlbum(albumName: "Album 5", albumImage: "")
        let albumF = addAlbum(albumName: "Album 6", albumImage: "")
        
        let _ = addArtistToGroup(artist: artistA, group: groupA)
        let _ = addArtistToGroup(artist: artistB, group: groupA)
        let _ = addArtistToGroup(artist: artistC, group: groupB)
        let _ = addArtistToGroup(artist: artistD, group: groupB)
        let _ = addArtistToGroup(artist: artistE, group: groupC)
        let _ = addArtistToGroup(artist: artistF, group: groupC)
        
        let _ = addAlbumToGroup(album: albumA, group: groupA)
        let _ = addAlbumToGroup(album: albumB, group: groupA)
        let _ = addAlbumToGroup(album: albumC, group: groupB)
        let _ = addAlbumToGroup(album: albumD, group: groupB)
        let _ = addAlbumToGroup(album: albumE, group: groupC)
        let _ = addAlbumToGroup(album: albumF, group: groupC)
        
        let _ = addPhotocard(artist: artistA, group: groupA, album: albumA, image: "")
        let _ = addPhotocard(artist: artistA, group: groupA, album: albumB, image: "")
        let _ = addPhotocard(artist: artistB, group: groupA, album: albumA, image: "")
        let _ = addPhotocard(artist: artistB, group: groupA, album: albumB, image: "")
        let _ = addPhotocard(artist: artistC, group: groupB, album: albumC, image: "")
        let _ = addPhotocard(artist: artistC, group: groupB, album: albumD, image: "")
        let _ = addPhotocard(artist: artistD, group: groupB, album: albumC, image: "")
        let _ = addPhotocard(artist: artistD, group: groupB, album: albumD, image: "")
        let _ = addPhotocard(artist: artistE, group: groupC, album: albumE, image: "")
        let _ = addPhotocard(artist: artistE, group: groupC, album: albumF, image: "")
        let _ = addPhotocard(artist: artistF, group: groupC, album: albumE, image: "")
        let _ = addPhotocard(artist: artistF, group: groupC, album: albumF, image: "")
    }
}
