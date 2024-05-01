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
                currentUser = addUser(userID: authResult.user.uid, username: DEFAULT_USERNAME, isAnonymous: authResult.user.isAnonymous)
            } catch {
                fatalError("Firebase Authentication Failed with Error \(String(describing: error))")
            }
//            createDefaults()
            self.setupIdolListener()
        }
        
//        idolsRef = database.collection("idols")
//        artistsRef = database.collection("artists")
//        albumsRef = database.collection("albums")
//        photocardsRef = database.collection("photocards")
//        createDefaults()
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
        idolsRef = database.collection("idols")
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
        artistsRef = database.collection("artists")
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
        albumsRef = database.collection("albums")
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
            if let removedPhotocardRef = photocardsRef?.document(photocardID) {
                albumsRef?.document(albumID).updateData(
                    ["albums": FieldValue.arrayRemove([removedPhotocardRef])]
                )
            }
        }
    }
    
    func addPhotocard(idol: Idol, artist: Artist, album: Album, image: String) -> Photocard {
        photocardsRef = database.collection("photocards")
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
    func getArtistByID(_ id: String) -> Artist? {
        return artistList.first(where: { $0.id == id })
    }
    
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
    
    func setupAlbumListener() {
        albumsRef = database.collection("albums")
        albumsRef?.addSnapshotListener() { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            self.parseAlbumSnapshot(snapshot: querySnapshot)
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
        // Match with user document id, as we change the id only in login and sign up and the other currentUser fields might still store the details of the previous user.
        usersRef?.whereField(FieldPath.documentID(), isEqualTo: currentUser.id!).addSnapshotListener { (querySnapshot, error) in
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
            if let artist = getArtistByID(change.document.documentID) {
                
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
            }
            
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.artist || listener.listenerType == ListenerType.all {
                    listener.onAllArtistsChange(change: .update, artists: artistList)
                }
            }
        }
    }
    
    func parseAlbumSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            var album: Album
            
            do {
                album = try change.document.data(as: Album.self)
            } catch {
                fatalError("Unable to decode artist: \(error.localizedDescription)")
            }
            
            if change.type == .added {
                if !albumList.contains(album) {
                    albumList.insert(album, at: Int(change.newIndex))
                }
            } else if change.type == .modified {
                albumList.remove(at: Int(change.oldIndex))
                albumList.insert(album, at: Int(change.newIndex))
            } else if change.type == .removed {
                albumList.remove(at: Int(change.oldIndex))
            }
            
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.album || listener.listenerType == ListenerType.all {
                    listener.onAllAlbumsChange(change: .update, albums: albumList)
                }
            }
        }
    }
    
    func parsePhotocardSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            if let photocard = getPhotocardByID(change.document.documentID) {
                
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
        let jisoo = addIdol(idolName: "Jisoo", idolBirthday: "1995-01-03")
        let jennie = addIdol(idolName: "Jennie", idolBirthday: "1996-01-16")
        let rose = addIdol(idolName: "Rosé", idolBirthday: "1997-02-11")
        let lisa = addIdol(idolName: "Lisa", idolBirthday: "1997-03-27")
        let yeji = addIdol(idolName: "Yeji", idolBirthday: "2000-05-26")
        let lia = addIdol(idolName: "Lia", idolBirthday: "2000-07-21")
        let ryujin = addIdol(idolName: "Ryujin", idolBirthday: "2001-04-17")
        let chaeryeong = addIdol(idolName: "Chaeryeong", idolBirthday: "2001-06-05")
        let yuna = addIdol(idolName: "Yuna", idolBirthday: "2003-12-09")
        let seonghwa = addIdol(idolName: "Seonghwa", idolBirthday: "1998-04-03")
        let hongjoong = addIdol(idolName: "Hongjoong", idolBirthday: "1998-11-07")
        let yunho = addIdol(idolName: "Yunho", idolBirthday: "1999-03-23")
        let yeosang = addIdol(idolName: "Yeosang", idolBirthday: "1999-06-15")
        let san = addIdol(idolName: "San", idolBirthday: "1999-07-10")
        let mingi = addIdol(idolName: "Mingi", idolBirthday: "1999-08-09")
        let wooyoung = addIdol(idolName: "Wooyoung", idolBirthday: "1999-11-26")
        let jongho = addIdol(idolName: "Jongho", idolBirthday: "2000-10-12")
        
        let blackpink = addArtist(artistName: "Blackpink")
        let itzy = addArtist(artistName: "Itzy")
        let ateez = addArtist(artistName: "Ateez")
        
        let theAlbum = addAlbum(albumName: "The Album", albumImage: "BLACKPINK-_The_Album.png")
        let bornPink = addAlbum(albumName: "Born Pink", albumImage: "Born_Pink_Digital.jpeg")
        let notShy = addAlbum(albumName: "Not Shy", albumImage: "Itzy_-_Not_Shy.jpg")
        let bornToBe = addAlbum(albumName: "Born to Be", albumImage: "Itzy_-_Born_to_Be_(digital).jpg")
        let theWorldMovement = addAlbum(albumName: "The World EP.1: Movement", albumImage: "Ateez_-_The_World_EP.1_Movement.png")
        let theWorldOutlaw = addAlbum(albumName: "The World EP.2: Outlaw", albumImage: "Ateez_-_The_World_EP.2_Outlaw.png")
        
        let _ = addIdolToArtist(idol: jisoo, artist: blackpink)
        let _ = addIdolToArtist(idol: jennie, artist: blackpink)
        let _ = addIdolToArtist(idol: rose, artist: blackpink)
        let _ = addIdolToArtist(idol: lisa, artist: blackpink)
        let _ = addIdolToArtist(idol: yeji, artist: itzy)
        let _ = addIdolToArtist(idol: lia, artist: itzy)
        let _ = addIdolToArtist(idol: ryujin, artist: itzy)
        let _ = addIdolToArtist(idol: chaeryeong, artist: itzy)
        let _ = addIdolToArtist(idol: yuna, artist: itzy)
        let _ = addIdolToArtist(idol: seonghwa, artist: ateez)
        let _ = addIdolToArtist(idol: hongjoong, artist: ateez)
        let _ = addIdolToArtist(idol: yunho, artist: ateez)
        let _ = addIdolToArtist(idol: yeosang, artist: ateez)
        let _ = addIdolToArtist(idol: san, artist: ateez)
        let _ = addIdolToArtist(idol: mingi, artist: ateez)
        let _ = addIdolToArtist(idol: wooyoung, artist: ateez)
        let _ = addIdolToArtist(idol: jongho, artist: ateez)
        
        let _ = addAlbumToArtist(album: theAlbum, artist: blackpink)
        let _ = addAlbumToArtist(album: bornPink, artist: blackpink)
        let _ = addAlbumToArtist(album: notShy, artist: itzy)
        let _ = addAlbumToArtist(album: bornToBe, artist: itzy)
        let _ = addAlbumToArtist(album: theWorldMovement, artist: ateez)
        let _ = addAlbumToArtist(album: theWorldOutlaw, artist: ateez)
        
        // Blacpink photocards
        let _ = addPhotocard(idol: jisoo, artist: blackpink, album: theAlbum, image: "Jisoo_Blackpink_TheAlbum_1")
        let _ = addPhotocard(idol: jisoo, artist: blackpink, album: theAlbum, image: "Jisoo_Blackpink_TheAlbum_2")
        let _ = addPhotocard(idol: jisoo, artist: blackpink, album: theAlbum, image: "Jisoo_Blackpink_TheAlbum_3")
        let _ = addPhotocard(idol: jisoo, artist: blackpink, album: theAlbum, image: "Jisoo_Blackpink_TheAlbum_4")
        let _ = addPhotocard(idol: jisoo, artist: blackpink, album: theAlbum, image: "Jisoo_Blackpink_TheAlbum_5")
        let _ = addPhotocard(idol: jennie, artist: blackpink, album: theAlbum, image: "Jennie_Blackpink_TheAlbum_1")
        let _ = addPhotocard(idol: jennie, artist: blackpink, album: theAlbum, image: "Jennie_Blackpink_TheAlbum_2")
        let _ = addPhotocard(idol: jennie, artist: blackpink, album: theAlbum, image: "Jennie_Blackpink_TheAlbum_3")
        let _ = addPhotocard(idol: jennie, artist: blackpink, album: theAlbum, image: "Jennie_Blackpink_TheAlbum_4")
        let _ = addPhotocard(idol: jennie, artist: blackpink, album: theAlbum, image: "Jennie_Blackpink_TheAlbum_5")
        let _ = addPhotocard(idol: rose, artist: blackpink, album: theAlbum, image: "Rosé_Blackpink_TheAlbum_1")
        let _ = addPhotocard(idol: rose, artist: blackpink, album: theAlbum, image: "Rosé_Blackpink_TheAlbum_2")
        let _ = addPhotocard(idol: rose, artist: blackpink, album: theAlbum, image: "Rosé_Blackpink_TheAlbum_3")
        let _ = addPhotocard(idol: rose, artist: blackpink, album: theAlbum, image: "Rosé_Blackpink_TheAlbum_4")
        let _ = addPhotocard(idol: rose, artist: blackpink, album: theAlbum, image: "Rosé_Blackpink_TheAlbum_5")
        let _ = addPhotocard(idol: lisa, artist: blackpink, album: theAlbum, image: "Lisa_Blackpink_TheAlbum_1")
        let _ = addPhotocard(idol: lisa, artist: blackpink, album: theAlbum, image: "Lisa_Blackpink_TheAlbum_2")
        let _ = addPhotocard(idol: lisa, artist: blackpink, album: theAlbum, image: "Lisa_Blackpink_TheAlbum_3")
        let _ = addPhotocard(idol: lisa, artist: blackpink, album: theAlbum, image: "Lisa_Blackpink_TheAlbum_4")
        let _ = addPhotocard(idol: lisa, artist: blackpink, album: theAlbum, image: "Lisa_Blackpink_TheAlbum_5")
        
        // Ateez photocards
        let _ = addPhotocard(idol: hongjoong, artist: ateez, album: theWorldMovement, image: "Hongjoong_Ateez_TheWorldEP1_1.png")
        let _ = addPhotocard(idol: hongjoong, artist: ateez, album: theWorldMovement, image: "Hongjoong_Ateez_TheWorldEP1_2.png")
        let _ = addPhotocard(idol: hongjoong, artist: ateez, album: theWorldMovement, image: "Hongjoong_Ateez_TheWorldEP1_3.png")
        let _ = addPhotocard(idol: seonghwa, artist: ateez, album: theWorldMovement, image: "Seonghwa_Ateez_TheWorldEP1_1.png")
        let _ = addPhotocard(idol: seonghwa, artist: ateez, album: theWorldMovement, image: "Seonghwa_Ateez_TheWorldEP1_2.png")
        let _ = addPhotocard(idol: seonghwa, artist: ateez, album: theWorldMovement, image: "Seonghwa_Ateez_TheWorldEP1_3.png")
        let _ = addPhotocard(idol: yunho, artist: ateez, album: theWorldMovement, image: "Yunho_Ateez_TheWorldEP1_1.png")
        let _ = addPhotocard(idol: yunho, artist: ateez, album: theWorldMovement, image: "Yunho_Ateez_TheWorldEP1_2.png")
        let _ = addPhotocard(idol: yunho, artist: ateez, album: theWorldMovement, image: "Yunho_Ateez_TheWorldEP1_3.png")
        let _ = addPhotocard(idol: yeosang, artist: ateez, album: theWorldMovement, image: "Yeosang_Ateez_TheWorldEP1_1.png")
        let _ = addPhotocard(idol: yeosang, artist: ateez, album: theWorldMovement, image: "Yeosang_Ateez_TheWorldEP1_2.png")
        let _ = addPhotocard(idol: yeosang, artist: ateez, album: theWorldMovement, image: "Yeosang_Ateez_TheWorldEP1_3.png")
        let _ = addPhotocard(idol: san, artist: ateez, album: theWorldMovement, image: "San_Ateez_TheWorldEP1_1.png")
        let _ = addPhotocard(idol: san, artist: ateez, album: theWorldMovement, image: "San_Ateez_TheWorldEP1_2.png")
        let _ = addPhotocard(idol: san, artist: ateez, album: theWorldMovement, image: "San_Ateez_TheWorldEP1_3.png")
        let _ = addPhotocard(idol: mingi, artist: ateez, album: theWorldMovement, image: "Mingi_Ateez_TheWorldEP1_1.png")
        let _ = addPhotocard(idol: mingi, artist: ateez, album: theWorldMovement, image: "Mingi_Ateez_TheWorldEP1_2.png")
        let _ = addPhotocard(idol: mingi, artist: ateez, album: theWorldMovement, image: "Mingi_Ateez_TheWorldEP1_3.png")
        let _ = addPhotocard(idol: wooyoung, artist: ateez, album: theWorldMovement, image: "Wooyoung_Ateez_TheWorldEP1_1.png")
        let _ = addPhotocard(idol: wooyoung, artist: ateez, album: theWorldMovement, image: "Wooyoung_Ateez_TheWorldEP1_2.png")
        let _ = addPhotocard(idol: wooyoung, artist: ateez, album: theWorldMovement, image: "Wooyoung_Ateez_TheWorldEP1_3.png")
        let _ = addPhotocard(idol: jongho, artist: ateez, album: theWorldMovement, image: "Jongho_Ateez_TheWorldEP1_1.png")
        let _ = addPhotocard(idol: jongho, artist: ateez, album: theWorldMovement, image: "Jongho_Ateez_TheWorldEP1_2.png")
        let _ = addPhotocard(idol: jongho, artist: ateez, album: theWorldMovement, image: "Jongho_Ateez_TheWorldEP1_3.png")
    }
}
