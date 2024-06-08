//
//  DatabaseController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import UIKit

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case idol
    case artist
    case album
    case photocard
    case listing
    case user
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    
    // Idol
    func onAllIdolsChange(change: DatabaseChange, idols: [Idol])
    
    // Artist
    func onAllArtistsChange(change: DatabaseChange, artists: [Artist])
    
    // Album
    func onAllAlbumsChange(change: DatabaseChange, albums: [Album])
    
    // Photocard
    func onAllPhotocardsChange(change: DatabaseChange, photocards: [Photocard])
    
    // Listing
    func onAllListingsChange(change: DatabaseChange, listings: [Listing])
    
    // User
    func onUserChange(change: DatabaseChange, user: User)
}

protocol DatabaseProtocol: AnyObject {
    func cleanup()
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    // Idol
    func addIdol(idolName: String, idolBirthday: String) -> Idol
    func deleteIdol(idol: Idol)
    
    // Artist
    func addArtist(artistName: String) -> Artist
    func deleteArtist(artist: Artist)
    func addIdolToArtist(idol: Idol, artist: Artist) -> Bool
    func removeIdolFromArtist(idol: Idol, artist: Artist)
    func addAlbumToArtist(album: Album, artist: Artist) -> Bool
    func removeAlbumFromArtist(album: Album, artist: Artist)
    
    // Album
    func addAlbum(albumName: String, artist: Artist) -> Album
    func deleteAlbum(album: Album)
    
    // Photocard
    func addPhotocard(idol: Idol, artist: Artist, album: Album, image: String) -> Photocard
    func deletePhotocard(photocard: Photocard)
    
    // Listing
    func addListing(photocard: Photocard, price: Double, seller: User, images: [String], descriptionText: String) -> Listing
    func deleteListing(listing: Listing)
    
    // User
    var currentUser: User {get set}
    
    func addUser(userID: String, username: String, isAnonymous: Bool, email: String) -> User
    func deleteUser(user: User)
    func updateUserDetails(userID: String, newName: String, newImage: String)
    func addPhotocardToCollection(photocard: Photocard, user: User) -> Bool
    func addPhotocardToFavourites(photocard: Photocard, user: User) -> Bool
    func addPhotocardToWishlist(photocard: Photocard, user: User) -> Bool
    func removePhotocardFromCollection(photocard: Photocard, user: User)
    func removePhotocardFromFavourites(photocard: Photocard, user: User)
    func removePhotocardFromWishlist(photocard: Photocard, user: User)
    
    // Authentication
    func logInAccount(email: String, password: String) async -> Bool
    func createAccount(email: String, username: String, password: String) async -> Bool
    func signInAnonymous() async
    func signOutAccount() async -> Bool
    
    // File Storage
    func loadImageData(filename: String) -> UIImage?
    func getImage(imageData: (String, String)) -> UIImage?
    
    var defaultUserImage: UIImage? {get set}
}
