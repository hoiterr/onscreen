//
//  TrackingService.swift
//  ProductivityTracker
//
//  Core tracking engine that monitors active windows and creates sessions
//

import Foundation
import Combine
import AppKit

class TrackingService: ObservableObject {
    static let shared = TrackingService()

    @Published private(set) var isTracking = false
    @Published private(set) var currentSession: SessionEntity?
    @Published private(set) var currentWindow: ActiveWindow?
    @Published private(set) var todayTotalDuration: TimeInterval = 0
    @Published var lastError: AppError?

    private var trackingTimer: Timer?
    private var pollInterval: TimeInterval = 2.0 // Poll every 2 seconds
    private var debounceThreshold: TimeInterval = 5.0 // Ignore switches shorter than 5 seconds

    private let windowTracker = WindowTracker.shared
    private let browserDetector = BrowserURLDetector.shared
    private let idleMonitor = IdleMonitor.shared
    private let ruleEngine = RuleEngine()
    private let persistenceController = PersistenceController.shared

    private var lastActiveWindow: ActiveWindow?
    private var sessionStartTime: Date?

    private init() {
        // Load today's total on init
        updateTodayTotal()
    }

    // MARK: - Public Methods

    func startTracking() {
        guard !isTracking else { return }

        // Check permissions before starting
        if !windowTracker.checkScreenRecordingPermission() {
            lastError = .permissionDenied(.screenRecording)
            print("⚠️ Screen Recording permission not granted")
            // Continue anyway - will track apps without window titles
        }

        isTracking = true

        trackingTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.trackCurrentActivity()
        }

        trackingTimer?.tolerance = 0.5

        print("✅ Tracking started")
    }

    func stopTracking() {
        guard isTracking else { return }

        isTracking = false
        trackingTimer?.invalidate()
        trackingTimer = nil

        // End current session
        if let session = currentSession {
            endSession(session)
        }

        print("⏹ Tracking stopped")
    }

    func pauseTracking() {
        stopTracking()
    }

    func resumeTracking() {
        startTracking()
    }

    func manuallySetCategory(_ category: ActivityCategory) {
        guard let session = currentSession else { return }

        session.category = category.rawValue
        persistenceController.saveContext()

        print("📝 Manually set category to: \(category.displayName)")
    }

    // MARK: - Private Methods

    private func trackCurrentActivity() {
        // Check if user is idle
        if idleMonitor.isUserIdle() {
            if let session = currentSession {
                endSession(session)
            }
            return
        }

        // Get current active window
        guard var activeWindow = windowTracker.getCurrentActiveWindow() else {
            return
        }

        // Try to get browser URL if applicable
        if let url = browserDetector.getCurrentBrowserURL(for: activeWindow.bundleID) {
            activeWindow = ActiveWindow(
                appName: activeWindow.appName,
                bundleID: activeWindow.bundleID,
                windowTitle: activeWindow.windowTitle,
                url: url
            )
        }

        // Check if window has changed
        if lastActiveWindow != activeWindow {
            handleWindowChange(to: activeWindow)
        } else {
            // Update current session duration
            if let session = currentSession, let startTime = sessionStartTime {
                let now = Date()
                session.endTime = now
                session.duration = now.timeIntervalSince(startTime)
                persistenceController.saveContext()

                updateTodayTotal()
            }
        }

        currentWindow = activeWindow
    }

    private func handleWindowChange(to newWindow: ActiveWindow) {
        let now = Date()

        // End previous session if it exists
        if let session = currentSession, let startTime = sessionStartTime {
            let duration = now.timeIntervalSince(startTime)

            // Only save if duration is above debounce threshold
            if duration >= debounceThreshold {
                endSession(session)
            } else {
                // Delete short session
                persistenceController.container.viewContext.delete(session)
                persistenceController.saveContext()
            }
        }

        // Start new session
        startSession(for: newWindow, at: now)

        lastActiveWindow = newWindow
    }

    private func startSession(for window: ActiveWindow, at time: Date) {
        // Categorize the activity
        let category = ruleEngine.categorize(
            appName: window.appName,
            bundleID: window.bundleID,
            windowTitle: window.windowTitle,
            url: window.url
        )

        // Create new session
        let session = persistenceController.createSession(
            appName: window.appName,
            bundleID: window.bundleID,
            windowTitle: window.windowTitle,
            url: window.url,
            startTime: time,
            category: category.rawValue
        )

        currentSession = session
        sessionStartTime = time

        print("▶️ Started session: \(window.appName) [\(category.displayName)]")
    }

    private func endSession(_ session: SessionEntity) {
        let now = Date()

        persistenceController.updateSession(session, endTime: now)

        print("⏸ Ended session: \(session.appName ?? "Unknown") - Duration: \(session.formattedDuration)")

        currentSession = nil
        sessionStartTime = nil

        updateTodayTotal()
    }

    private func updateTodayTotal() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let sessions = persistenceController.fetchSessions(from: startOfDay, to: endOfDay)
        todayTotalDuration = sessions.reduce(0) { $0 + $1.duration }
    }

    func setIdleThreshold(minutes: Int) {
        idleMonitor.setIdleThreshold(seconds: TimeInterval(minutes * 60))
    }

    func setDebounceThreshold(seconds: TimeInterval) {
        debounceThreshold = seconds
    }
}
