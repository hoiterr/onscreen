//
//  PersistenceController.swift
//  ProductivityTracker
//

import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ProductivityTracker")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Session Management

    func createSession(
        appName: String,
        bundleID: String,
        windowTitle: String?,
        url: String?,
        startTime: Date,
        category: String
    ) -> SessionEntity {
        let context = container.viewContext
        let session = SessionEntity(context: context)
        session.id = UUID()
        session.appName = appName
        session.bundleID = bundleID
        session.windowTitle = windowTitle
        session.url = url
        session.startTime = startTime
        session.endTime = startTime
        session.category = category
        session.duration = 0

        saveContext()
        return session
    }

    func updateSession(_ session: SessionEntity, endTime: Date) {
        session.endTime = endTime
        session.duration = endTime.timeIntervalSince(session.startTime ?? endTime)
        saveContext()
    }

    func fetchSessions(from startDate: Date, to endDate: Date) -> [SessionEntity] {
        let context = container.viewContext
        let request = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SessionEntity.startTime, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch sessions: \(error)")
            return []
        }
    }

    // MARK: - Rule Management

    func createRule(
        name: String,
        conditionType: String,
        pattern: String,
        category: String,
        priority: Int16,
        isEnabled: Bool
    ) -> RuleEntity {
        let context = container.viewContext
        let rule = RuleEntity(context: context)
        rule.id = UUID()
        rule.name = name
        rule.conditionType = conditionType
        rule.pattern = pattern
        rule.category = category
        rule.priority = priority
        rule.isEnabled = isEnabled
        rule.createdAt = Date()

        saveContext()
        return rule
    }

    func deleteRule(_ rule: RuleEntity) {
        container.viewContext.delete(rule)
        saveContext()
    }

    func fetchAllRules() -> [RuleEntity] {
        let context = container.viewContext
        let request = RuleEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RuleEntity.priority, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch rules: \(error)")
            return []
        }
    }

    // MARK: - Data Management

    func deleteAllData() {
        let context = container.viewContext

        // Delete all sessions
        let sessionRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SessionEntity")
        let sessionDelete = NSBatchDeleteRequest(fetchRequest: sessionRequest)

        // Delete all rules
        let ruleRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RuleEntity")
        let ruleDelete = NSBatchDeleteRequest(fetchRequest: ruleRequest)

        do {
            try context.execute(sessionDelete)
            try context.execute(ruleDelete)
            saveContext()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }

    func deleteSessionsOlderThan(months: Int) {
        guard let cutoffDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) else {
            return
        }

        let context = container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SessionEntity")
        request.predicate = NSPredicate(format: "startTime < %@", cutoffDate as NSDate)

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            print("Failed to delete old sessions: \(error)")
        }
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    // MARK: - Export

    func exportToJSON(from startDate: Date, to endDate: Date) -> Data? {
        let sessions = fetchSessions(from: startDate, to: endDate)

        let exportData = sessions.map { session in
            [
                "id": session.id?.uuidString ?? "",
                "appName": session.appName ?? "",
                "bundleID": session.bundleID ?? "",
                "windowTitle": session.windowTitle ?? "",
                "url": session.url ?? "",
                "category": session.category ?? "",
                "startTime": ISO8601DateFormatter().string(from: session.startTime ?? Date()),
                "endTime": ISO8601DateFormatter().string(from: session.endTime ?? Date()),
                "duration": session.duration
            ] as [String: Any]
        }

        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }

    func exportToCSV(from startDate: Date, to endDate: Date) -> String {
        let sessions = fetchSessions(from: startDate, to: endDate)

        var csv = "App Name,Bundle ID,Window Title,URL,Category,Start Time,End Time,Duration (seconds)\n"

        let dateFormatter = ISO8601DateFormatter()

        for session in sessions {
            let appName = session.appName?.replacingOccurrences(of: ",", with: ";") ?? ""
            let bundleID = session.bundleID ?? ""
            let windowTitle = session.windowTitle?.replacingOccurrences(of: ",", with: ";") ?? ""
            let url = session.url?.replacingOccurrences(of: ",", with: ";") ?? ""
            let category = session.category ?? ""
            let startTime = dateFormatter.string(from: session.startTime ?? Date())
            let endTime = dateFormatter.string(from: session.endTime ?? Date())
            let duration = String(format: "%.2f", session.duration)

            csv += "\"\(appName)\",\"\(bundleID)\",\"\(windowTitle)\",\"\(url)\",\"\(category)\",\"\(startTime)\",\"\(endTime)\",\(duration)\n"
        }

        return csv
    }
}
