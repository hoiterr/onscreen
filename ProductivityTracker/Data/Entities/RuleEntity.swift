//
//  RuleEntity+CoreDataClass.swift
//  ProductivityTracker
//

import Foundation
import CoreData

@objc(RuleEntity)
public class RuleEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var conditionType: String? // "app", "url", "title"
    @NSManaged public var pattern: String?
    @NSManaged public var category: String?
    @NSManaged public var priority: Int16
    @NSManaged public var isEnabled: Bool
    @NSManaged public var createdAt: Date?
}

extension RuleEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RuleEntity> {
        return NSFetchRequest<RuleEntity>(entityName: "RuleEntity")
    }

    var conditionTypeEnum: RuleConditionType {
        get {
            RuleConditionType(rawValue: conditionType ?? "app") ?? .app
        }
        set {
            conditionType = newValue.rawValue
        }
    }

    var categoryEnum: ActivityCategory {
        get {
            ActivityCategory(rawValue: category ?? "uncategorized") ?? .uncategorized
        }
        set {
            category = newValue.rawValue
        }
    }
}

extension RuleEntity: Identifiable {}

enum RuleConditionType: String, CaseIterable, Codable {
    case app = "app"
    case url = "url"
    case title = "title"

    var displayName: String {
        switch self {
        case .app: return "Application"
        case .url: return "URL Pattern"
        case .title: return "Window Title"
        }
    }
}
