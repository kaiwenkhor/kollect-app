//
//  DatabaseController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case artist
    case group
    case photocard
    case user
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    
    // Artist
    func onAllArtistsChange(change: DatabaseChange, artists: [Artist])
    
    // Group
//    func onGroupMemberChange(change: DatabaseChange, groupMembers: [Artist])
    func onAllGroupsChange(change: DatabaseChange, groups: [Group])
    
    // Photocard
    func onAllPhotocardsChange(change: DatabaseChange, photocards: [Photocard])
    
    // User
    func onUserChange(change: DatabaseChange, userCollection: [Photocard], userFavourites: [Photocard], userWishlist: [Photocard])
}

protocol DatabaseProtocol: AnyObject {
    func cleanup()
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    // Artist
    func addArtist(artistName: String, artistBirthday: String) -> Artist
    func deleteArtist(artist: Artist)
    
    // Group
    func addGroup(groupName: String) -> Group
    func deleteGroup(group: Group)
    func addArtistToGroup(artist: Artist, group: Group) -> Bool
    func removeArtistFromGroup(artist: Artist, group: Group)
    
    // Photocard
    func addPhotocard(artist: Artist, group: Group, album: String) -> Photocard
    func deletePhotocard(photocard: Photocard)
    
    // User
    var currentUser: User {get set}
    
    func addUser(userID: String) -> User
    func deleteUser(user: User)
    func addPhotocardToCollection(photocard: Photocard, user: User) -> Bool
    func addPhotocardToFavourites(photocard: Photocard, user: User) -> Bool
    func addPhotocardToWishlist(photocard: Photocard, user: User) -> Bool
    func removePhotocardFromCollection(photocard: Photocard, user: User)
    func removePhotocardFromFavourites(photocard: Photocard, user: User)
    func removePhotocardFromWishlist(photocard: Photocard, user: User)
    
    // Authentication
    func logInAccount(email: String, password: String, completion: @escaping (Error?) -> Void)
    func createAccount(email: String, password: String, completion: @escaping (Error?) -> Void)
}
