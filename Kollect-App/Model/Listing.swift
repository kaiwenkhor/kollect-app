//
//  Listing.swift
//  Kollect-App
//
//  Created by Daryl Khor on 20/05/2024.
//

import Foundation
import FirebaseFirestoreSwift

class Listing: NSObject {
    @DocumentID var id: String?
    var photocard: Photocard?
    var listDate: String?
    var price: Double?
    var seller: User?
    var images = [(String, String)]()   // [(filename, url)]
    var descriptionText: String?
    
    var sold: Bool?
    var buyer: User?
    var soldDate: String?
}
