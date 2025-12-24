//
//  CategoryService.swift
//  ProductivityTracker
//
//  Manages category-related operations and default rules
//

import Foundation
import Combine

class CategoryService: ObservableObject {
    static let shared = CategoryService()

    @Published var categories: [ActivityCategory] = ActivityCategory.allCases

    private let persistenceController: PersistenceController
    private let userDefaults = UserDefaults.standard
    private let hasInitializedKey = "hasInitializedDefaultRules"

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func initializeDefaultsIfNeeded() {
        guard !userDefaults.bool(forKey: hasInitializedKey) else {
            return
        }

        createDefaultRules()
        userDefaults.set(true, forKey: hasInitializedKey)
    }

    private func createDefaultRules() {
        let defaultRules: [(String, RuleConditionType, String, ActivityCategory)] = [
            // Work
            ("Xcode", .app, "xcode", .work),
            ("VS Code", .app, "code", .work),
            ("Terminal", .app, "terminal", .work),
            ("GitHub", .url, "*github.com*", .work),
            ("Stack Overflow", .url, "*stackoverflow.com*", .work),

            // Communication
            ("Mail", .app, "mail", .communication),
            ("Messages", .app, "messages", .communication),
            ("Slack", .app, "slack", .communication),
            ("Zoom", .app, "zoom", .communication),

            // Research
            ("Wikipedia", .url, "*wikipedia.org*", .research),
            ("Medium", .url, "*medium.com*", .research),
            ("Documentation", .title, "*documentation*", .research),

            // Leisure
            ("YouTube", .url, "*youtube.com*", .leisure),
            ("Netflix", .url, "*netflix.com*", .leisure),
            ("Spotify", .app, "spotify", .leisure),
            ("Reddit", .url, "*reddit.com*", .leisure)
        ]

        for (index, rule) in defaultRules.enumerated() {
            let _ = persistenceController.createRule(
                name: rule.0,
                conditionType: rule.1.rawValue,
                pattern: rule.2,
                category: rule.3.rawValue,
                priority: Int16(index),
                isEnabled: true
            )
        }
    }

    func getCategoryStats(from sessions: [SessionEntity]) -> [ActivityCategory: TimeInterval] {
        var stats: [ActivityCategory: TimeInterval] = [:]

        for category in categories {
            stats[category] = 0
        }

        for session in sessions {
            if let categoryString = session.category,
               let category = ActivityCategory(rawValue: categoryString) {
                stats[category, default: 0] += session.duration
            }
        }

        return stats
    }

    func getTopApps(from sessions: [SessionEntity], limit: Int = 5) -> [(String, TimeInterval)] {
        var appDurations: [String: TimeInterval] = [:]

        for session in sessions {
            let appName = session.appName ?? "Unknown"
            appDurations[appName, default: 0] += session.duration
        }

        return appDurations
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    func getTotalDuration(from sessions: [SessionEntity]) -> TimeInterval {
        return sessions.reduce(0) { $0 + $1.duration }
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
