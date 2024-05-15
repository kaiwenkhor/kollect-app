//
//  User.swift
//  Kollect-App
//
//  Created by Daryl Khor on 23/04/2024.
//

import Foundation
import FirebaseFirestoreSwift

class User: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var all = [Photocard]()
    var favourites = [Photocard]()
    var wishlist = [Photocard]()
    var isAnonymous: Bool?
    var image: String?
}
