//
//  Collection.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import FirebaseFirestoreSwift

class Collection: NSObject, Codable {
    @DocumentID var id: String? // user uid
    var photocards = [Photocard]()
    var favourites = [Photocard]()
    
    // Add a new document in collection "cities"
//    let userUID = user.uid
//    do {
//      try await db.collection("collections").document(userUID).setData([
//        "photocards": [],
//        "favourites": []
//      ])
//      print("Document successfully written!")
//    } catch {
//      print("Error writing document: \(error)" )
//    }
}
