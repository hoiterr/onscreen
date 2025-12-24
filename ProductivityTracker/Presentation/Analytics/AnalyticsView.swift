//
//  AnalyticsView.swift
//  ProductivityTracker
//
//  Analytics dashboard with charts and time range filters
//

import SwiftUI
import Charts
import CoreData

enum TimeRange: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case custom = "Custom"

    var dateRange: (Date, Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .yesterday:
            let start = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
            let end = calendar.startOfDay(for: now)
            return (start, end)

        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now))!
            let end = now
            return (start, end)

        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now))!
            let end = now
            return (start, end)

        case .custom:
            return (now, now)
        }
    }
}

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryService: CategoryService

    @State private var selectedTimeRange: TimeRange = .today
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var showCustomDatePicker = false

    @State private var sessions: [SessionEntity] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with time range selector
                VStack(alignment: .leading, spacing: 16) {
                    Text("Analytics")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    // Time range picker
                    HStack(spacing: 12) {
                        ForEach(TimeRange.allCases.filter { $0 != .custom }, id: \.self) { range in
                            Button(action: {
                                selectedTimeRange = range
                                loadSessions()
                            }) {
                                Text(range.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedTimeRange == range ?
                                        Color.accentColor.opacity(0.2) :
                                        Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            showCustomDatePicker.toggle()
                        }) {
                            Text("Custom")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedTimeRange == .custom ?
                                    Color.accentColor.opacity(0.2) :
                                    Color.clear
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showCustomDatePicker) {
                            CustomDateRangeView(
                                startDate: $customStartDate,
                                endDate: $customEndDate,
                                onApply: {
                                    selectedTimeRange = .custom
                                    loadSessions()
                                    showCustomDatePicker = false
                                }
                            )
                        }
                    }
                }

                // Summary metrics
                SummaryMetricsView(sessions: sessions)

                // Category distribution chart
                CategoryDistributionChart(sessions: sessions)

                // Daily breakdown chart
                DailyBreakdownChart(sessions: sessions, timeRange: selectedTimeRange)

                // Timeline view for today
                if selectedTimeRange == .today {
                    TimelineView(sessions: sessions)
                }

                // Top apps chart
                TopAppsChart(sessions: sessions)
            }
            .padding()
        }
        .onAppear {
            loadSessions()
        }
    }

    private func loadSessions() {
        let (startDate, endDate) = selectedTimeRange == .custom ?
            (customStartDate, customEndDate) :
            selectedTimeRange.dateRange

        sessions = PersistenceController.shared.fetchSessions(from: startDate, to: endDate)
    }
}

// MARK: - Custom Date Range Picker

struct CustomDateRangeView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Date Range")
                .font(.headline)

            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.compact)

            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                .datePickerStyle(.compact)

            Button("Apply", action: onApply)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300)
    }
}

// MARK: - Summary Metrics

struct SummaryMetricsView: View {
    let sessions: [SessionEntity]
    @EnvironmentObject var categoryService: CategoryService

    private var totalDuration: TimeInterval {
        categoryService.getTotalDuration(from: sessions)
    }

    private var categoryStats: [ActivityCategory: TimeInterval] {
        categoryService.getCategoryStats(from: sessions)
    }

    private var workPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return (categoryStats[.work] ?? 0) / totalDuration * 100
    }

    private var leisurePercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return (categoryStats[.leisure] ?? 0) / totalDuration * 100
    }

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text("Summary")
                    .font(.headline)

                HStack(spacing: 32) {
                    MetricItem(
                        title: "Total Time",
                        value: categoryService.formatDuration(totalDuration),
                        icon: "clock.fill",
                        color: .blue
                    )

                    MetricItem(
                        title: "Work Focus",
                        value: String(format: "%.0f%%", workPercentage),
                        icon: "briefcase.fill",
                        color: .blue
                    )

                    MetricItem(
                        title: "Leisure",
                        value: String(format: "%.0f%%", leisurePercentage),
                        icon: "gamecontroller.fill",
                        color: .green
                    )

                    MetricItem(
                        title: "Sessions",
                        value: "\(sessions.count)",
                        icon: "square.stack.3d.up.fill",
                        color: .purple
                    )
                }
            }
        }
    }
}

struct MetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Distribution Chart

struct CategoryDistributionChart: View {
    let sessions: [SessionEntity]
    @EnvironmentObject var categoryService: CategoryService

    private var categoryStats: [ActivityCategory: TimeInterval] {
        categoryService.getCategoryStats(from: sessions)
    }

    private var chartData: [(ActivityCategory, TimeInterval)] {
        categoryStats
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Category Distribution")
                    .font(.headline)

                if chartData.isEmpty {
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    Chart(chartData, id: \.0) { category, duration in
                        SectorMark(
                            angle: .value("Duration", duration),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(category.color)
                        .cornerRadius(4)
                    }
                    .frame(height: 300)
                    .chartLegend(position: .trailing, alignment: .center)

                    // Legend
                    HStack(spacing: 24) {
                        ForEach(chartData, id: \.0) { category, duration in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)

                                    Text(categoryService.formatDuration(duration))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Daily Breakdown Chart

struct DailyBreakdownChart: View {
    let sessions: [SessionEntity]
    let timeRange: TimeRange
    @EnvironmentObject var categoryService: CategoryService

    private var dailyData: [(Date, ActivityCategory, TimeInterval)] {
        let calendar = Calendar.current
        var data: [Date: [ActivityCategory: TimeInterval]] = [:]

        for session in sessions {
            guard let startTime = session.startTime else { continue }
            let day = calendar.startOfDay(for: startTime)

            let category = ActivityCategory(rawValue: session.category ?? "uncategorized") ?? .uncategorized

            if data[day] == nil {
                data[day] = [:]
            }

            data[day]?[category, default: 0] += session.duration
        }

        var result: [(Date, ActivityCategory, TimeInterval)] = []
        for (day, categories) in data {
            for (category, duration) in categories {
                result.append((day, category, duration))
            }
        }

        return result.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Daily Breakdown")
                    .font(.headline)

                if dailyData.isEmpty {
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    Chart(dailyData, id: \.0) { date, category, duration in
                        BarMark(
                            x: .value("Date", date, unit: .day),
                            y: .value("Duration", duration / 3600.0)
                        )
                        .foregroundStyle(category.color)
                    }
                    .frame(height: 300)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let hours = value.as(Double.self) {
                                    Text("\(Int(hours))h")
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Timeline View

struct TimelineView: View {
    let sessions: [SessionEntity]

    private var sortedSessions: [SessionEntity] {
        sessions.sorted { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Timeline")
                    .font(.headline)

                if sortedSessions.isEmpty {
                    Text("No activity yet today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(sortedSessions) { session in
                                TimelineBlock(session: session)
                            }
                        }
                        .frame(height: 60)
                    }

                    // Time labels
                    HStack {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour):00")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

struct TimelineBlock: View {
    let session: SessionEntity

    private var category: ActivityCategory {
        ActivityCategory(rawValue: session.category ?? "uncategorized") ?? .uncategorized
    }

    private var width: CGFloat {
        CGFloat(session.duration / 60.0) * 2 // 2 pixels per minute
    }

    var body: some View {
        Rectangle()
            .fill(category.color)
            .frame(width: max(width, 4))
            .cornerRadius(2)
            .help("\(session.appName ?? "Unknown")\n\(session.formattedDuration)")
    }
}

// MARK: - Top Apps Chart

struct TopAppsChart: View {
    let sessions: [SessionEntity]
    @EnvironmentObject var categoryService: CategoryService

    private var topApps: [(String, TimeInterval)] {
        categoryService.getTopApps(from: sessions, limit: 10)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Top Applications")
                    .font(.headline)

                if topApps.isEmpty {
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    Chart(topApps, id: \.0) { appName, duration in
                        BarMark(
                            x: .value("Duration", duration / 3600.0),
                            y: .value("App", appName)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: CGFloat(topApps.count * 40))
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let hours = value.as(Double.self) {
                                    Text("\(String(format: "%.1f", hours))h")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
