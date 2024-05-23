//
//  SearchData+CoreDataProperties.swift
//  Kollect-App
//
//  Created by Daryl Khor on 23/05/2024.
//
//

import Foundation
import CoreData


extension SearchData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SearchData> {
        return NSFetchRequest<SearchData>(entityName: "SearchData")
    }

    @NSManaged public var text: String?
    @NSManaged public var date: String?
    @NSManaged public var byUser: String?

}

extension SearchData : Identifiable {

}
