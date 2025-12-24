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
            // Main content area with animated mesh gradient background
            ZStack {
                // Mesh gradient background
                MeshGradientBackground(
                    colors: [.blue, .purple, .pink],
                    animated: true
                )
                .ignoresSafeArea()

                // Content with animated transitions
                Group {
                    switch selectedNavigation {
                    case .dashboard:
                        DashboardView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .opacity
                            ))
                    case .analytics:
                        AnalyticsView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    case .rules:
                        RulesView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    case .settings:
                        SettingsView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding()
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedNavigation)
            }
        }
        .errorAlert($trackingService.lastError)
        .onReceive(NotificationCenter.default.publisher(for: .navigateTo)) { notification in
            if let navigationItem = notification.object as? NavigationItem {
                withAnimation {
                    selectedNavigation = navigationItem
                }
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
                    .shortcutTooltip(action: item.rawValue, shortcut: shortcutKey(for: item))
            }
            .listStyle(.sidebar)
            .hapticFeedback(.selection)

            Divider()

            // Tracking status
            TrackingStatusView()
                .padding()
                .background(.ultraThinMaterial)
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
    }

    private func shortcutKey(for item: NavigationItem) -> String {
        switch item {
        case .dashboard: return "1"
        case .analytics: return "2"
        case .rules: return "3"
        case .settings: return "4"
        }
    }
}

struct TrackingStatusView: View {
    @EnvironmentObject var trackingService: TrackingService

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatusTooltip(
                    isActive: trackingService.isTracking,
                    activeMessage: "Activity tracking is running",
                    inactiveMessage: "Activity tracking is paused"
                )

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
                .hapticFeedback(.impact(.medium))
                .shortcutTooltip(action: "Pause Tracking", shortcut: "⇧T")
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
                .hapticFeedback(.notification(.success))
                .shortcutTooltip(action: "Resume Tracking", shortcut: "⇧T")
            }
        }
    }
}
