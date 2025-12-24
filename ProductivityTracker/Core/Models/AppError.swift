//
//  AppError.swift
//  ProductivityTracker
//
//  Centralized error handling with user-friendly messages
//

import Foundation

enum AppError: LocalizedError, Identifiable {
    case permissionDenied(PermissionType)
    case trackingFailed(String)
    case coreDateError(String)
    case exportFailed(String)
    case importFailed(String)
    case browserAccessFailed(String)

    var id: String {
        switch self {
        case .permissionDenied(let type):
            return "permission_\(type.rawValue)"
        case .trackingFailed(let msg):
            return "tracking_\(msg)"
        case .coreDateError(let msg):
            return "coredata_\(msg)"
        case .exportFailed(let msg):
            return "export_\(msg)"
        case .importFailed(let msg):
            return "import_\(msg)"
        case .browserAccessFailed(let msg):
            return "browser_\(msg)"
        }
    }

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let type):
            return "\(type.displayName) Permission Required"

        case .trackingFailed(let reason):
            return "Tracking Failed: \(reason)"

        case .coreDateError(let reason):
            return "Data Error: \(reason)"

        case .exportFailed(let reason):
            return "Export Failed: \(reason)"

        case .importFailed(let reason):
            return "Import Failed: \(reason)"

        case .browserAccessFailed(let browser):
            return "Cannot Access \(browser)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied(let type):
            switch type {
            case .screenRecording:
                return "Go to System Settings → Privacy & Security → Screen Recording and enable Productivity Tracker. Then restart the app."
            case .automation:
                return "Go to System Settings → Privacy & Security → Automation and enable access for your browser. Then restart the app."
            }

        case .trackingFailed:
            return "Try restarting the tracking service from the menubar or Settings."

        case .coreDateError:
            return "Try restarting the app. If the problem persists, you may need to reset your data."

        case .exportFailed:
            return "Check that you have write permissions for the selected location and sufficient disk space."

        case .importFailed:
            return "Ensure the file is a valid export from Productivity Tracker."

        case .browserAccessFailed:
            return "Grant automation permission in System Settings → Privacy & Security → Automation."
        }
    }

    var actionTitle: String? {
        switch self {
        case .permissionDenied:
            return "Open Settings"
        case .trackingFailed:
            return "Restart Tracking"
        case .coreDateError:
            return "OK"
        case .exportFailed, .importFailed:
            return "Try Again"
        case .browserAccessFailed:
            return "Grant Permission"
        }
    }
}

enum PermissionType: String {
    case screenRecording
    case automation

    var displayName: String {
        switch self {
        case .screenRecording:
            return "Screen Recording"
        case .automation:
            return "Automation"
        }
    }
}
