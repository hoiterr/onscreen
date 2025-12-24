//
//  ActivityClassifier.swift
//  ProductivityTracker
//
//  Protocol for pluggable activity classification
//  Allows for ML-based classifiers in the future
//

import Foundation

protocol ActivityClassifier {
    func classify(
        appName: String,
        bundleID: String,
        windowTitle: String?,
        url: String?
    ) -> ActivityCategory
}

// MARK: - Heuristic Classifier (Placeholder for ML)

class HeuristicClassifier: ActivityClassifier {
    func classify(
        appName: String,
        bundleID: String,
        windowTitle: String?,
        url: String?
    ) -> ActivityCategory {
        let lowercasedApp = appName.lowercased()
        let lowercasedBundle = bundleID.lowercased()
        let lowercasedTitle = windowTitle?.lowercased() ?? ""
        let lowercasedURL = url?.lowercased() ?? ""

        // Communication apps
        let communicationKeywords = ["mail", "messages", "slack", "discord", "zoom", "teams", "skype", "telegram", "whatsapp"]
        if communicationKeywords.contains(where: { lowercasedApp.contains($0) || lowercasedBundle.contains($0) }) {
            return .communication
        }

        // Development/Work apps
        let workKeywords = ["xcode", "code", "terminal", "iterm", "docker", "postman", "git", "sql", "database", "figma", "sketch"]
        if workKeywords.contains(where: { lowercasedApp.contains($0) || lowercasedBundle.contains($0) }) {
            return .work
        }

        // Research/Documentation
        let researchKeywords = ["notion", "evernote", "bear", "notes", "documentation", "docs", "pdf", "reader", "kindle"]
        if researchKeywords.contains(where: { lowercasedApp.contains($0) || lowercasedBundle.contains($0) || lowercasedTitle.contains($0) }) {
            return .research
        }

        // URL-based classification for browsers
        if !lowercasedURL.isEmpty {
            if lowercasedURL.contains("github") || lowercasedURL.contains("stackoverflow") || lowercasedURL.contains("developer") {
                return .work
            }
            if lowercasedURL.contains("youtube") || lowercasedURL.contains("netflix") || lowercasedURL.contains("twitch") || lowercasedURL.contains("reddit") {
                return .leisure
            }
            if lowercasedURL.contains("wikipedia") || lowercasedURL.contains("arxiv") || lowercasedURL.contains("medium") {
                return .research
            }
        }

        // Leisure apps
        let leisureKeywords = ["music", "spotify", "youtube", "netflix", "steam", "game", "entertainment", "photo", "photos"]
        if leisureKeywords.contains(where: { lowercasedApp.contains($0) || lowercasedBundle.contains($0) }) {
            return .leisure
        }

        return .uncategorized
    }
}
