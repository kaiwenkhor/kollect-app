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
    var groupList: [Group]
    var albumList: [Album]
    var photocardList: [Photocard]
    var currentUser: User
    let DEFAULT_USERNAME = "Anonymous"
    var authController: Auth
    var database: Firestore
    var idolsRef: CollectionReference?
    var groupsRef: CollectionReference?
    var albumsRef: CollectionReference?
    var photocardsRef: CollectionReference?
    var usersRef: CollectionReference?
    
    override init() {
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        
        idolList = [Idol]()
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
    
    func addIdolToGroup(idol: Idol, group: Group) -> Bool {
        guard let idolID = idol.id, let groupID = group.id else {
            return false
        }
        
        if let newIdolRef = idolsRef?.document(idolID) {
            groupsRef?.document(groupID).updateData(
                ["members": FieldValue.arrayUnion([newIdolRef])]
            )
        }
        
        return true
    }
    
    func removeIdolFromGroup(idol: Idol, group: Group) {
        if group.members.contains(idol), let groupID = group.id, let idolID = idol.id {
            if let removedIdolRef = idolsRef?.document(idolID) {
                groupsRef?.document(groupID).updateData(
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
    
    func addPhotocard(idol: Idol, group: Group, album: Album, image: String) -> Photocard {
        let photocard = Photocard()
        photocard.idol = idol
        photocard.group = group
        photocard.album = album
        photocard.image = image
        
        // Should save idol name only or idol object
        if let photocardRef = photocardsRef?.addDocument(data: ["idol": idol, "group": group, "album": album, "image": image]) {
            
            photocard.id = photocardRef.documentID
        }
        
        // Add to Group -> Album -> Idol
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
        let idolA = addIdol(idolName: "A", idolBirthday: "2001-01-01")
        let idolB = addIdol(idolName: "B", idolBirthday: "2002-02-02")
        let idolC = addIdol(idolName: "C", idolBirthday: "2003-03-03")
        let idolD = addIdol(idolName: "D", idolBirthday: "2004-04-04")
        let idolE = addIdol(idolName: "E", idolBirthday: "2005-05-05")
        let idolF = addIdol(idolName: "F", idolBirthday: "2006-06-06")
        
        let groupA = addGroup(groupName: "123")
        let groupB = addGroup(groupName: "456")
        let groupC = addGroup(groupName: "789")
        
        let albumA = addAlbum(albumName: "Album 1", albumImage: "")
        let albumB = addAlbum(albumName: "Album 2", albumImage: "")
        let albumC = addAlbum(albumName: "Album 3", albumImage: "")
        let albumD = addAlbum(albumName: "Album 4", albumImage: "")
        let albumE = addAlbum(albumName: "Album 5", albumImage: "")
        let albumF = addAlbum(albumName: "Album 6", albumImage: "")
        
        let _ = addIdolToGroup(idol: idolA, group: groupA)
        let _ = addIdolToGroup(idol: idolB, group: groupA)
        let _ = addIdolToGroup(idol: idolC, group: groupB)
        let _ = addIdolToGroup(idol: idolD, group: groupB)
        let _ = addIdolToGroup(idol: idolE, group: groupC)
        let _ = addIdolToGroup(idol: idolF, group: groupC)
        
        let _ = addAlbumToGroup(album: albumA, group: groupA)
        let _ = addAlbumToGroup(album: albumB, group: groupA)
        let _ = addAlbumToGroup(album: albumC, group: groupB)
        let _ = addAlbumToGroup(album: albumD, group: groupB)
        let _ = addAlbumToGroup(album: albumE, group: groupC)
        let _ = addAlbumToGroup(album: albumF, group: groupC)
        
        let _ = addPhotocard(idol: idolA, group: groupA, album: albumA, image: "")
        let _ = addPhotocard(idol: idolA, group: groupA, album: albumB, image: "")
        let _ = addPhotocard(idol: idolB, group: groupA, album: albumA, image: "")
        let _ = addPhotocard(idol: idolB, group: groupA, album: albumB, image: "")
        let _ = addPhotocard(idol: idolC, group: groupB, album: albumC, image: "")
        let _ = addPhotocard(idol: idolC, group: groupB, album: albumD, image: "")
        let _ = addPhotocard(idol: idolD, group: groupB, album: albumC, image: "")
        let _ = addPhotocard(idol: idolD, group: groupB, album: albumD, image: "")
        let _ = addPhotocard(idol: idolE, group: groupC, album: albumE, image: "")
        let _ = addPhotocard(idol: idolE, group: groupC, album: albumF, image: "")
        let _ = addPhotocard(idol: idolF, group: groupC, album: albumE, image: "")
        let _ = addPhotocard(idol: idolF, group: groupC, album: albumF, image: "")
    }
}
