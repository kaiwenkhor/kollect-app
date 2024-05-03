//
//  Album.swift
//  Kollect-App
//
//  Created by Daryl Khor on 26/04/2024.
//

import Foundation
import FirebaseFirestoreSwift

class Album: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var image: String?
//    var photocards = [Photocard]()
    // Future: Sort by date
//    var dateReleased: Date?
}
