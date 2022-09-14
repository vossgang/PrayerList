//
//  PrayerRequest+CoreDataProperties.swift
//  PrayerRequest
//
//  Created by Matthew Voss on 9/12/22.
//
//

import Foundation
import CoreData


extension PrayerRequest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PrayerRequest> {
        return NSFetchRequest<PrayerRequest>(entityName: "PrayerRequest")
    }

    @NSManaged public var answered: Bool
    @NSManaged public var detailText: String?
    @NSManaged public var interval: Int32
    @NSManaged public var last: Date?
    @NSManaged public var tag: Int32
    @NSManaged public var titleText: String?

}

extension PrayerRequest : Identifiable {

}
