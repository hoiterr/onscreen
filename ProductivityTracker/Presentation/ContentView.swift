//
//  ContentView.swift
//  ProductivityTracker
//
//  Main app container with sidebar navigation
//

import SwiftUI

enum NavigationItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case analytics = "Analytics"
    case rules = "Rules"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .analytics: return "chart.bar.fill"
        case .rules: return "list.bullet.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedNavigation: NavigationItem = .dashboard
    @EnvironmentObject var trackingService: TrackingService
    @EnvironmentObject var categoryService: CategoryService

    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(selectedNavigation: $selectedNavigation)
        } detail: {
            // Main content area with liquid glass background
            ZStack {
                // Base layer - subtle gradient
                LinearGradient(
                    colors: [
                        Color(nsColor: .windowBackgroundColor),
                        Color(nsColor: .windowBackgroundColor).opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Content
                Group {
                    switch selectedNavigation {
                    case .dashboard:
                        DashboardView()
                    case .analytics:
                        AnalyticsView()
                    case .rules:
                        RulesView()
                    case .settings:
                        SettingsView()
                    }
                }
                .padding()
            }
        }
    }
}

struct SidebarView: View {
    @Binding var selectedNavigation: NavigationItem
    @EnvironmentObject var trackingService: TrackingService

    var body: some View {
        VStack(spacing: 0) {
            // App header
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Productivity Tracker")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)

            Divider()

            // Navigation items
            List(NavigationItem.allCases, id: \.self, selection: $selectedNavigation) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)

            Divider()

            // Tracking status
            TrackingStatusView()
                .padding()
                .background(.ultraThinMaterial)
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
    }
}

struct TrackingStatusView: View {
    @EnvironmentObject var trackingService: TrackingService

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(trackingService.isTracking ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(trackingService.isTracking ? "Tracking" : "Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            if trackingService.isTracking {
                Button(action: {
                    trackingService.pauseTracking()
                }) {
                    Label("Pause", systemImage: "pause.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button(action: {
                    trackingService.resumeTracking()
                }) {
                    Label("Resume", systemImage: "play.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
}
