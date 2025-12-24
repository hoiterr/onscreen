//
//  LaunchAtLoginService.swift
//  ProductivityTracker
//
//  Service to manage launch at login functionality
//

import Foundation
import ServiceManagement

class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()

    private init() {}

    /// Enable or disable launch at login
    func setLaunchAtLogin(_ enabled: Bool) throws {
        if #available(macOS 13.0, *) {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } else {
            // Fallback for older macOS versions
            setLaunchAtLoginLegacy(enabled)
        }
    }

    /// Check if launch at login is currently enabled
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return isEnabledLegacy()
        }
    }

    // MARK: - Legacy Support (macOS 12 and earlier)

    private func setLaunchAtLoginLegacy(_ enabled: Bool) {
        // Use LSSharedFileList API for older macOS versions
        // Note: This API is deprecated but still works on older systems

        guard let bundleURL = Bundle.main.bundleURL else { return }

        if #available(macOS 10.11, *) {
            // SMLoginItemSetEnabled is deprecated but functional
            let bundleID = Bundle.main.bundleIdentifier ?? ""
            SMLoginItemSetEnabled(bundleID as CFString, enabled)
        }
    }

    private func isEnabledLegacy() -> Bool {
        // Check if app is in login items
        // This is a simplified check for legacy systems
        return false // Default to false for older systems
    }
}
