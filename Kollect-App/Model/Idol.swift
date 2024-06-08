//
//  Idol.swift
//  Kollect-App
//
//  Created by Daryl Khor on 21/04/2024.
//

import Foundation
import FirebaseFirestoreSwift

class Idol: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var birthday: String?
    var image: String?
}
