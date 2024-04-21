//
//  Artist.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import FirebaseFirestoreSwift

class Artist: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    // Only using birthday to display (future: sort by age)
    var birthday: String?
//    var country: String?
}
