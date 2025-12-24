//
//  RulesView.swift
//  ProductivityTracker
//
//  Manage categorization rules
//

import SwiftUI
import CoreData

struct RulesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var ruleEngine = RuleEngine()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RuleEntity.priority, ascending: true)],
        animation: .default
    )
    private var rules: FetchedResults<RuleEntity>

    @State private var showAddRule = false
    @State private var editingRule: RuleEntity?

    private func moveRules(from source: IndexSet, to destination: Int) {
        // Convert to array for manipulation
        var rulesArray = Array(rules)
        rulesArray.move(fromOffsets: source, toOffset: destination)

        // Update priorities
        for (index, rule) in rulesArray.enumerated() {
            rule.priority = Int16(index)
        }

        // Save changes
        try? viewContext.save()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rules")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text("Define how activities are categorized")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        showAddRule = true
                    }) {
                        Label("Add Rule", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .hapticFeedback(.impact(.light))
                    .shortcutTooltip(action: "Add New Rule", shortcut: "N")
                }

                // Rules list
                GlassCard {
                    VStack(spacing: 0) {
                        if rules.isEmpty {
                            FirstTimeEmptyState(
                                icon: "list.bullet.rectangle",
                                title: "Welcome to Rules!",
                                steps: [
                                    "Create rules to automatically categorize activities",
                                    "Match by app name, URL, or window title",
                                    "Drag to reorder rule priority"
                                ],
                                actionTitle: "Add Your First Rule",
                                action: { showAddRule = true }
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            // Rules table
                            VStack(spacing: 0) {
                                // Header
                                HStack(spacing: 16) {
                                    Text("Priority")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 60, alignment: .leading)
                                        .tooltip("Evaluation order (drag to reorder)", position: .top)

                                    Text("Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 150, alignment: .leading)
                                        .tooltip("Rule identifier", position: .top)

                                    Text("Condition")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 120, alignment: .leading)
                                        .tooltip("What to match against", position: .top)

                                    Text("Pattern")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(minWidth: 150, alignment: .leading)
                                        .tooltip("Match pattern (supports wildcards)", position: .top)

                                    Text("Category")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 120, alignment: .leading)
                                        .tooltip("Assigned activity category", position: .top)

                                    Text("Status")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                        .tooltip("Enable or disable rule", position: .top)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.secondary.opacity(0.1))

                                Divider()

                                // Rules with drag-to-reorder
                                ForEach(Array(rules.enumerated()), id: \.element) { index, rule in
                                    VStack(spacing: 0) {
                                        RuleRow(
                                            rule: rule,
                                            priority: index + 1,
                                            onEdit: {
                                                editingRule = rule
                                            },
                                            onDelete: {
                                                ruleEngine.deleteRule(rule)
                                            },
                                            onToggle: {
                                                rule.isEnabled.toggle()
                                                ruleEngine.updateRule(rule)
                                            }
                                        )

                                        if index < rules.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .onMove { from, to in
                                    moveRules(from: from, to: to)
                                }
                            }
                        }
                    }
                }
                .toolbar {
                    if !rules.isEmpty {
                        EditButton()
                    }
                }

                // Info card
                InfoCard()
            }
            .padding()
        }
        .sheet(isPresented: $showAddRule) {
            RuleEditorView(onSave: { name, conditionType, pattern, category in
                ruleEngine.addRule(
                    name: name,
                    conditionType: conditionType,
                    pattern: pattern,
                    category: category
                )
                showAddRule = false
            })
        }
        .sheet(item: $editingRule) { rule in
            RuleEditorView(
                existingRule: rule,
                onSave: { name, conditionType, pattern, category in
                    rule.name = name
                    rule.conditionType = conditionType.rawValue
                    rule.pattern = pattern
                    rule.category = category.rawValue
                    ruleEngine.updateRule(rule)
                    editingRule = nil
                }
            )
        }
    }
}

// MARK: - Rule Row

struct RuleRow: View {
    @ObservedObject var rule: RuleEntity
    let priority: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void

    private var category: ActivityCategory {
        ActivityCategory(rawValue: rule.category ?? "uncategorized") ?? .uncategorized
    }

    var body: some View {
        HStack(spacing: 16) {
            Text("\(priority)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(rule.name ?? "")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 150, alignment: .leading)

            Text(rule.conditionTypeEnum.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(6)
                .frame(width: 120, alignment: .leading)

            Text(rule.pattern ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(minWidth: 150, alignment: .leading)

            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(category.color)

                Text(category.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(category.color.opacity(0.2))
            .cornerRadius(6)
            .frame(width: 120, alignment: .leading)

            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .frame(width: 80)
            .hapticFeedback(.notification(.success))
            .tooltip(rule.isEnabled ? "Disable this rule" : "Enable this rule", position: .top)

            Spacer()

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .hapticFeedback(.impact(.light))
                .tooltip("Edit rule", position: .top)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .hapticFeedback(.custom(.heartbeat))
                .tooltip("Delete rule", position: .top)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Rule Editor

struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var conditionType: RuleConditionType
    @State private var pattern: String
    @State private var category: ActivityCategory

    let onSave: (String, RuleConditionType, String, ActivityCategory) -> Void

    init(
        existingRule: RuleEntity? = nil,
        onSave: @escaping (String, RuleConditionType, String, ActivityCategory) -> Void
    ) {
        self.onSave = onSave

        if let rule = existingRule {
            _name = State(initialValue: rule.name ?? "")
            _conditionType = State(initialValue: rule.conditionTypeEnum)
            _pattern = State(initialValue: rule.pattern ?? "")
            _category = State(initialValue: rule.categoryEnum)
        } else {
            _name = State(initialValue: "")
            _conditionType = State(initialValue: .app)
            _pattern = State(initialValue: "")
            _category = State(initialValue: .work)
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Edit Rule")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }

            Divider()

            // Form
            VStack(alignment: .leading, spacing: 16) {
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rule Name")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("e.g., GitHub Work", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                // Condition Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Condition Type")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("", selection: $conditionType) {
                        ForEach(RuleConditionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Pattern
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pattern")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField(placeholderForCondition(), text: $pattern)
                        .textFieldStyle(.roundedBorder)

                    Text(descriptionForCondition())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("", selection: $category) {
                        ForEach(ActivityCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Spacer()

            Divider()

            // Actions
            HStack {
                Spacer()

                Button("Save") {
                    onSave(name, conditionType, pattern, category)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || pattern.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding(24)
        .frame(width: 500, height: 500)
    }

    private func placeholderForCondition() -> String {
        switch conditionType {
        case .app:
            return "e.g., xcode, terminal, slack"
        case .url:
            return "e.g., *github.com*, *youtube.com*"
        case .title:
            return "e.g., *documentation*, *meeting*"
        }
    }

    private func descriptionForCondition() -> String {
        switch conditionType {
        case .app:
            return "Matches app name or bundle ID (case-insensitive)"
        case .url:
            return "Matches URL pattern. Use * as wildcard"
        case .title:
            return "Matches window title. Use * as wildcard"
        }
    }
}

// MARK: - Info Card

struct InfoCard: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    Text("How Rules Work")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        icon: "arrow.up.arrow.down",
                        text: "Rules are evaluated in priority order (top to bottom)"
                    )

                    InfoRow(
                        icon: "checkmark.circle",
                        text: "The first matching rule determines the category"
                    )

                    InfoRow(
                        icon: "brain",
                        text: "If no rule matches, automatic classification is used"
                    )

                    InfoRow(
                        icon: "asterisk",
                        text: "Use * as wildcard in patterns (e.g., *github.com*)"
                    )
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
