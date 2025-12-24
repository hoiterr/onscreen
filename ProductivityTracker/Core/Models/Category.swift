//
//  Category.swift
//  ProductivityTracker
//

import SwiftUI

enum ActivityCategory: String, CaseIterable, Codable {
    case work = "work"
    case leisure = "leisure"
    case research = "research"
    case communication = "communication"
    case uncategorized = "uncategorized"

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .leisure: return "Leisure"
        case .research: return "Research"
        case .communication: return "Communication"
        case .uncategorized: return "Uncategorized"
        }
    }

    var color: Color {
        switch self {
        case .work: return .blue
        case .leisure: return .green
        case .research: return .purple
        case .communication: return .orange
        case .uncategorized: return .gray
        }
    }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .leisure: return "gamecontroller.fill"
        case .research: return "book.fill"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .uncategorized: return "questionmark.circle.fill"
        }
    }
}
