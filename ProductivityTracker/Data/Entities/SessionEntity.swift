//
//  SessionEntity+CoreDataClass.swift
//  ProductivityTracker
//
//  Core Data entity for activity sessions
//

import Foundation
import CoreData

@objc(SessionEntity)
public class SessionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var appName: String?
    @NSManaged public var bundleID: String?
    @NSManaged public var windowTitle: String?
    @NSManaged public var url: String?
    @NSManaged public var category: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var duration: Double
}

extension SessionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionEntity> {
        return NSFetchRequest<SessionEntity>(entityName: "SessionEntity")
    }

    var durationMinutes: Double {
        duration / 60.0
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

extension SessionEntity: Identifiable {}
