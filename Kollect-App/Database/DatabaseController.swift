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
    case idol
    case group
    case album
    case photocard
    case user
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    
    // Idol
    func onAllIdolsChange(change: DatabaseChange, idols: [Idol])
    
    // Group
//    func onGroupMemberChange(change: DatabaseChange, groupMembers: [Idol])
    func onAllGroupsChange(change: DatabaseChange, groups: [Group])
    
    // Album
    func onAllAlbumsChange(change: DatabaseChange, albums: [Album])
    
    // Photocard
    func onAllPhotocardsChange(change: DatabaseChange, photocards: [Photocard])
    
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
    
    // Group
    func addGroup(groupName: String) -> Group
    func deleteGroup(group: Group)
    func addIdolToGroup(idol: Idol, group: Group) -> Bool
    func removeIdolFromGroup(idol: Idol, group: Group)
    func addAlbumToGroup(album: Album, group: Group) -> Bool
    func removeAlbumFromGroup(album: Album, group: Group)
    
    // Album
    func addAlbum(albumName: String, albumImage: String) -> Album
    func deleteAlbum(album: Album)
    func addPhotocardToAlbum(photocard: Photocard, album: Album) -> Bool
    func removePhotocardFromAlbum(photocard: Photocard, album: Album)
    
    // Photocard
    func addPhotocard(idol: Idol, group: Group, album: Album, image: String) -> Photocard
    func deletePhotocard(photocard: Photocard)
    
    // User
    var currentUser: User {get set}
    
    func addUser(userID: String, username: String, isAnonymous: Bool) -> User
    func deleteUser(user: User)
    func addPhotocardToCollection(photocard: Photocard, user: User) -> Bool
    func addPhotocardToFavourites(photocard: Photocard, user: User) -> Bool
    func addPhotocardToWishlist(photocard: Photocard, user: User) -> Bool
    func removePhotocardFromCollection(photocard: Photocard, user: User)
    func removePhotocardFromFavourites(photocard: Photocard, user: User)
    func removePhotocardFromWishlist(photocard: Photocard, user: User)
    
    // Authentication
    func logInAccount(email: String, password: String) async
    func createAccount(email: String, username: String, password: String) async
}
