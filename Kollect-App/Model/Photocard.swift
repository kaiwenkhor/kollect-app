//
//  Photocard.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import FirebaseFirestoreSwift

class Photocard: NSObject, Codable {
    @DocumentID var id: String?
    var image: String?
    var idol: Idol?
    var group: Group?
    var album: Album?
//    var price: String?
}
