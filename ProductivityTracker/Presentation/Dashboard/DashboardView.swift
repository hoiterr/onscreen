//
//  DashboardView.swift
//  ProductivityTracker
//
//  Main dashboard with today's summary and stats
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var trackingService: TrackingService
    @EnvironmentObject var categoryService: CategoryService

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SessionEntity.startTime, ascending: false)],
        predicate: NSPredicate(
            format: "startTime >= %@ AND startTime <= %@",
            Calendar.current.startOfDay(for: Date()) as NSDate,
            Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))! as NSDate
        ),
        animation: .spring(response: 0.4, dampingFraction: 0.8)
    )
    private var todaySessions: FetchedResults<SessionEntity>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))

                    Spacer()

                    // Current activity indicator
                    if let currentWindow = trackingService.currentWindow {
                        CurrentActivityCard(window: currentWindow)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: trackingService.currentWindow?.appName)

                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    TotalTimeCard(sessions: Array(todaySessions))
                        .transition(.scale.combined(with: .opacity))
                    ActiveSessionCard()
                        .transition(.scale.combined(with: .opacity))
                    SessionCountCard(count: todaySessions.count)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: todaySessions.count)

                // Category breakdown
                CategoryBreakdownCard(sessions: Array(todaySessions))
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))

                // Top apps
                TopAppsCard(sessions: Array(todaySessions))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))

                // Recent activity
                RecentActivityCard(sessions: Array(todaySessions))
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            .padding()
        }
    }
}

// MARK: - Dashboard Cards

struct GlassCard<Content: View>: View {
    let content: Content
    @State private var isHovered = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.05), radius: isHovered ? 12 : 10, x: 0, y: isHovered ? 6 : 5)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct CurrentActivityCard: View {
    let window: ActiveWindow
    @EnvironmentObject var trackingService: TrackingService
    @State private var isPulsing = false

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                ZStack {
                    // Pulsing background circle
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0 : 1)

                    Image(systemName: "app.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        isPulsing = true
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(window.appName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let title = window.windowTitle {
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: .green, radius: 2)

                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .frame(width: 320)
    }
}

struct TotalTimeCard: View {
    let sessions: [SessionEntity]
    @EnvironmentObject var categoryService: CategoryService

    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    Spacer()
                }

                Text(categoryService.formatDuration(totalDuration))
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Total Time Today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ActiveSessionCard: View {
    @EnvironmentObject var trackingService: TrackingService

    private var currentDuration: TimeInterval {
        guard let session = trackingService.currentSession else { return 0 }
        return session.duration
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundStyle(.green)

                    Spacer()
                }

                Text(formatDuration(currentDuration))
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Current Session")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SessionCountCard: View {
    let count: Int

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)

                    Spacer()
                }

                Text("\(count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CategoryBreakdownCard: View {
    let sessions: [SessionEntity]
    @EnvironmentObject var categoryService: CategoryService

    private var categoryStats: [ActivityCategory: TimeInterval] {
        categoryService.getCategoryStats(from: sessions)
    }

    private var sortedCategories: [(ActivityCategory, TimeInterval)] {
        categoryStats.sorted { $0.value > $1.value }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Category Breakdown")
                    .font(.headline)

                if sortedCategories.allSatisfy({ $0.1 == 0 }) {
                    Text("No activity yet today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .transition(.opacity)
                } else {
                    ForEach(Array(sortedCategories.filter { $0.1 > 0 }.enumerated()), id: \.element.0) { index, element in
                        CategoryRow(category: element.0, duration: element.1)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: element.1)
                    }
                }
            }
        }
    }
}

struct CategoryRow: View {
    let category: ActivityCategory
    let duration: TimeInterval
    @EnvironmentObject var categoryService: CategoryService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(category.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(categoryService.formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Progress indicator (visual representation)
            Circle()
                .fill(category.color.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}

struct TopAppsCard: View {
    let sessions: [SessionEntity]
    @EnvironmentObject var categoryService: CategoryService

    private var topApps: [(String, TimeInterval)] {
        categoryService.getTopApps(from: sessions, limit: 5)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Top Applications")
                    .font(.headline)

                if topApps.isEmpty {
                    Text("No applications tracked yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(Array(topApps.enumerated()), id: \.offset) { index, app in
                        TopAppRow(rank: index + 1, appName: app.0, duration: app.1)
                    }
                }
            }
        }
    }
}

struct TopAppRow: View {
    let rank: Int
    let appName: String
    let duration: TimeInterval
    @EnvironmentObject var categoryService: CategoryService

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(categoryService.formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct RecentActivityCard: View {
    let sessions: [SessionEntity]

    private var recentSessions: [SessionEntity] {
        Array(sessions.prefix(10))
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Activity")
                    .font(.headline)

                if recentSessions.isEmpty {
                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(recentSessions) { session in
                        RecentActivityRow(session: session)
                    }
                }
            }
        }
    }
}

struct RecentActivityRow: View {
    let session: SessionEntity

    private var category: ActivityCategory {
        ActivityCategory(rawValue: session.category ?? "uncategorized") ?? .uncategorized
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.body)
                .foregroundStyle(category.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.appName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let title = session.windowTitle {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(session.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
