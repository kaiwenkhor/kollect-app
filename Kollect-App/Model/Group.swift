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
    var members = [Artist]()
//    var debutDate: Date?
//    var company: String?
//    var isActive: Bool?
//    var fanclubName: String?
}
