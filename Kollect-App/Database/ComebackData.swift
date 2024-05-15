//
//  ComebackData.swift
//  Kollect-App
//
//  Created by Daryl Khor on 15/05/2024.
//

import Foundation

class ComebackData: NSObject, Decodable {
    var date: Double
    var title: String
    
    private enum ComebackKeys: String, CodingKey {
        case date
        case title
    }
    
    required init(from decoder: Decoder) throws {
        // Get the root container
        let rootContainer = try decoder.container(keyedBy: ComebackKeys.self)
        
        // Get the comeback info
        date = try rootContainer.decode(Double.self, forKey: .date)
        title = try rootContainer.decode(String.self, forKey: .title)
    }
}
