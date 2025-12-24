//
//  RuleEngine.swift
//  ProductivityTracker
//
//  Applies user-defined rules to categorize activities
//

import Foundation
import CoreData

class RuleEngine: ObservableObject {
    @Published private(set) var rules: [RuleEntity] = []

    private let persistenceController: PersistenceController
    private let heuristicClassifier: HeuristicClassifier

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.heuristicClassifier = HeuristicClassifier()
        loadRules()
    }

    func loadRules() {
        rules = persistenceController.fetchAllRules()
    }

    func categorize(
        appName: String,
        bundleID: String,
        windowTitle: String?,
        url: String?
    ) -> ActivityCategory {
        // Apply rules in priority order
        for rule in rules.sorted(by: { $0.priority < $1.priority }) {
            if rule.isEnabled {
                let ruleModel = convertToRuleModel(rule)
                if ruleModel.matches(appName: appName, bundleID: bundleID, windowTitle: windowTitle, url: url) {
                    return rule.categoryEnum
                }
            }
        }

        // Fall back to heuristic classifier
        return heuristicClassifier.classify(
            appName: appName,
            bundleID: bundleID,
            windowTitle: windowTitle,
            url: url
        )
    }

    func addRule(
        name: String,
        conditionType: RuleConditionType,
        pattern: String,
        category: ActivityCategory
    ) {
        let priority = Int16(rules.count)
        let _ = persistenceController.createRule(
            name: name,
            conditionType: conditionType.rawValue,
            pattern: pattern,
            category: category.rawValue,
            priority: priority,
            isEnabled: true
        )
        loadRules()
    }

    func updateRule(_ rule: RuleEntity) {
        persistenceController.saveContext()
        loadRules()
    }

    func deleteRule(_ rule: RuleEntity) {
        persistenceController.deleteRule(rule)
        loadRules()
    }

    func reorderRules(from: IndexSet, to: Int) {
        var updatedRules = rules
        updatedRules.move(fromOffsets: from, toOffset: to)

        // Update priorities
        for (index, rule) in updatedRules.enumerated() {
            rule.priority = Int16(index)
        }

        persistenceController.saveContext()
        loadRules()
    }

    private func convertToRuleModel(_ entity: RuleEntity) -> Rule {
        return Rule(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            conditionType: entity.conditionTypeEnum,
            pattern: entity.pattern ?? "",
            category: entity.categoryEnum,
            priority: Int(entity.priority),
            isEnabled: entity.isEnabled
        )
    }
}
