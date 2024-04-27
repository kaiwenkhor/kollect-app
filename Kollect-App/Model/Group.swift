//
//  Group.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import FirebaseFirestoreSwift

class Group: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var members = [Idol]()
//    var image: String?
    var albums = [Album]()
    var isSolo: Bool?
//    var debutDate: Date?
//    var company: String?
//    var isActive: Bool?
//    var fanclubName: String?
}
