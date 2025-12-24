//
//  Rule.swift
//  ProductivityTracker
//

import Foundation

struct Rule: Identifiable, Codable {
    let id: UUID
    var name: String
    var conditionType: RuleConditionType
    var pattern: String
    var category: ActivityCategory
    var priority: Int
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        conditionType: RuleConditionType,
        pattern: String,
        category: ActivityCategory,
        priority: Int = 0,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.conditionType = conditionType
        self.pattern = pattern
        self.category = category
        self.priority = priority
        self.isEnabled = isEnabled
    }

    func matches(appName: String, bundleID: String, windowTitle: String?, url: String?) -> Bool {
        guard isEnabled else { return false }

        switch conditionType {
        case .app:
            return bundleID.lowercased().contains(pattern.lowercased()) ||
                   appName.lowercased().contains(pattern.lowercased())

        case .url:
            guard let url = url else { return false }
            return matchesPattern(pattern, in: url)

        case .title:
            guard let title = windowTitle else { return false }
            return matchesPattern(pattern, in: title)
        }
    }

    private func matchesPattern(_ pattern: String, in text: String) -> Bool {
        let lowercasedText = text.lowercased()
        let lowercasedPattern = pattern.lowercased()

        // Support wildcards
        if pattern.contains("*") {
            let regexPattern = "^" + pattern.replacingOccurrences(of: "*", with: ".*") + "$"
            if let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                return regex.firstMatch(in: text, options: [], range: range) != nil
            }
        }

        // Simple substring match
        return lowercasedText.contains(lowercasedPattern)
    }
}
