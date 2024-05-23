//
//  UserImageMetaData+CoreDataProperties.swift
//  Kollect-App
//
//  Created by Daryl Khor on 19/05/2024.
//
//

import Foundation
import CoreData


extension UserImageMetaData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserImageMetaData> {
        return NSFetchRequest<UserImageMetaData>(entityName: "UserImageMetaData")
    }

    @NSManaged public var filename: String?

}

extension UserImageMetaData : Identifiable {

}
