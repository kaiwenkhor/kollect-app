//
//  Artist.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import FirebaseFirestoreSwift

class Artist: NSObject {
    @DocumentID var id: String?
    var name: String?
    var members = [Idol]()
    var image: String?
    var albums = [Album]()
    var isSolo: Bool?
}
