//
//  StatusBarController.swift
//  ProductivityTracker
//
//  Menubar extra with quick stats and controls
//

import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Productivity Tracker")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

// MARK: - Popover Content

struct MenuBarPopoverView: View {
    @StateObject private var trackingService = TrackingService.shared
    @StateObject private var categoryService = CategoryService.shared

    @State private var todaySessions: [SessionEntity] = []

    var body: some View {
        ZStack {
            // Background with liquid glass effect
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                MenuBarHeader()

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        // Current Activity
                        if let window = trackingService.currentWindow {
                            CurrentActivitySection(window: window)
                        }

                        Divider()

                        // Today's Stats
                        TodayStatsSection(sessions: todaySessions)

                        Divider()

                        // Quick Actions
                        QuickActionsSection()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadTodaySessions()
        }
    }

    private func loadTodaySessions() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        todaySessions = PersistenceController.shared.fetchSessions(from: startOfDay, to: endOfDay)
    }
}

// MARK: - Sections

struct MenuBarHeader: View {
    var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Productivity Tracker")
                    .font(.headline)

                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                NSApplication.shared.activate(ignoringOtherApps: true)
                for window in NSApplication.shared.windows {
                    if window.title.isEmpty || window.title.contains("Productivity") {
                        window.makeKeyAndOrderFront(nil)
                        break
                    }
                }
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct CurrentActivitySection: View {
    let window: ActiveWindow
    @StateObject private var trackingService = TrackingService.shared

    private var currentCategory: ActivityCategory {
        if let session = trackingService.currentSession {
            return ActivityCategory(rawValue: session.category ?? "uncategorized") ?? .uncategorized
        }
        return .uncategorized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Activity")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                Image(systemName: currentCategory.icon)
                    .font(.title2)
                    .foregroundStyle(currentCategory.color)
                    .frame(width: 40, height: 40)
                    .background(currentCategory.color.opacity(0.2))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(window.appName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let title = window.windowTitle {
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Text(currentCategory.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(currentCategory.color.opacity(0.2))
                        .cornerRadius(4)
                }

                Spacer()
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(12)

            // Session duration
            if let session = trackingService.currentSession {
                HStack {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Session: \(session.formattedDuration)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
        }
    }
}

struct TodayStatsSection: View {
    let sessions: [SessionEntity]
    @StateObject private var categoryService = CategoryService.shared

    private var totalDuration: TimeInterval {
        categoryService.getTotalDuration(from: sessions)
    }

    private var categoryStats: [ActivityCategory: TimeInterval] {
        categoryService.getCategoryStats(from: sessions)
    }

    private var topCategories: [(ActivityCategory, TimeInterval)] {
        categoryStats
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Summary")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Total time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(categoryService.formatDuration(totalDuration))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(sessions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(12)

            // Top categories
            if !topCategories.isEmpty {
                VStack(spacing: 8) {
                    ForEach(topCategories, id: \.0) { category, duration in
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.caption)
                                .foregroundStyle(category.color)
                                .frame(width: 24)

                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)

                            Spacer()

                            Text(categoryService.formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial)
                .cornerRadius(12)
            }
        }
    }
}

struct QuickActionsSection: View {
    @StateObject private var trackingService = TrackingService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                // Pause/Resume button
                Button(action: {
                    if trackingService.isTracking {
                        trackingService.pauseTracking()
                    } else {
                        trackingService.resumeTracking()
                    }
                }) {
                    HStack {
                        Image(systemName: trackingService.isTracking ? "pause.fill" : "play.fill")

                        Text(trackingService.isTracking ? "Pause Tracking" : "Resume Tracking")
                            .fontWeight(.medium)

                        Spacer()
                    }
                    .padding(12)
                    .background(trackingService.isTracking ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                // Manual category override
                if trackingService.currentSession != nil {
                    Menu {
                        ForEach(ActivityCategory.allCases, id: \.self) { category in
                            Button(action: {
                                trackingService.manuallySetCategory(category)
                            }) {
                                Label(category.displayName, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tag.fill")

                            Text("Change Category")
                                .fontWeight(.medium)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(.regularMaterial)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }

                // Quit button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")

                        Text("Quit")
                            .fontWeight(.medium)

                        Spacer()
                    }
                    .padding(12)
                    .background(.regularMaterial)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
