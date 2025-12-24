//
//  IdleMonitor.swift
//  ProductivityTracker
//
//  Monitors user idle time using CGEventSource
//

import Cocoa
import ApplicationServices

class IdleMonitor {
    static let shared = IdleMonitor()

    private var idleThreshold: TimeInterval = 300 // 5 minutes default

    private init() {}

    func setIdleThreshold(seconds: TimeInterval) {
        idleThreshold = seconds
    }

    func isUserIdle() -> Bool {
        return getIdleTime() >= idleThreshold
    }

    func getIdleTime() -> TimeInterval {
        // Get system idle time in seconds
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .mouseMoved
        )
        return TimeInterval(idleTime)
    }

    func getIdleTimeFormatted() -> String {
        let idleTime = getIdleTime()
        let minutes = Int(idleTime) / 60
        let seconds = Int(idleTime) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
