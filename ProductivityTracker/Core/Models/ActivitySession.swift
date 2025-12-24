//
//  ActivitySession.swift
//  ProductivityTracker
//

import Foundation

struct ActivitySession: Identifiable, Codable {
    let id: UUID
    let appName: String
    let bundleID: String
    let windowTitle: String?
    let url: String?
    var category: ActivityCategory
    let startTime: Date
    var endTime: Date
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    init(
        id: UUID = UUID(),
        appName: String,
        bundleID: String,
        windowTitle: String? = nil,
        url: String? = nil,
        category: ActivityCategory = .uncategorized,
        startTime: Date,
        endTime: Date? = nil
    ) {
        self.id = id
        self.appName = appName
        self.bundleID = bundleID
        self.windowTitle = windowTitle
        self.url = url
        self.category = category
        self.startTime = startTime
        self.endTime = endTime ?? startTime
    }
}

struct ActiveWindow: Equatable {
    let appName: String
    let bundleID: String
    let windowTitle: String?
    let url: String?

    static func == (lhs: ActiveWindow, rhs: ActiveWindow) -> Bool {
        return lhs.appName == rhs.appName &&
               lhs.bundleID == rhs.bundleID &&
               lhs.windowTitle == rhs.windowTitle &&
               lhs.url == rhs.url
    }
}
