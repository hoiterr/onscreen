//
//  ProductivityTrackerApp.swift
//  ProductivityTracker
//
//  A privacy-preserving productivity analytics app for macOS
//

import SwiftUI
import AppKit

@main
struct ProductivityTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var persistenceController = PersistenceController.shared
    @StateObject private var trackingService = TrackingService.shared
    @StateObject private var categoryService = CategoryService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(trackingService)
                .environmentObject(categoryService)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) { }

            // Navigation and tracking shortcuts
            CommandGroup(after: .sidebar) {
                Button("Dashboard") {
                    NotificationCenter.default.post(name: .navigateTo, object: NavigationItem.dashboard)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Analytics") {
                    NotificationCenter.default.post(name: .navigateTo, object: NavigationItem.analytics)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Rules") {
                    NotificationCenter.default.post(name: .navigateTo, object: NavigationItem.rules)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Settings") {
                    NotificationCenter.default.post(name: .navigateTo, object: NavigationItem.settings)
                }
                .keyboardShortcut("4", modifiers: .command)

                Divider()

                Button(trackingService.isTracking ? "Pause Tracking" : "Resume Tracking") {
                    if trackingService.isTracking {
                        trackingService.pauseTracking()
                    } else {
                        trackingService.resumeTracking()
                    }
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(trackingService)
                .environmentObject(categoryService)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize menubar extra
        statusBarController = StatusBarController()

        // Start tracking service
        TrackingService.shared.startTracking()

        // Initialize default categories and rules if first launch
        CategoryService.shared.initializeDefaultsIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        TrackingService.shared.stopTracking()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}
