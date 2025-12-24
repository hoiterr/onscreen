//
//  WindowTracker.swift
//  ProductivityTracker
//
//  Tracks active window information using CGWindowListCopyWindowInfo
//  Requires: Screen Recording permission
//

import Cocoa
import ApplicationServices

class WindowTracker {
    static let shared = WindowTracker()

    private init() {}

    func getCurrentActiveWindow() -> ActiveWindow? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appName = frontApp.localizedName ?? "Unknown"
        let bundleID = frontApp.bundleIdentifier ?? "unknown"

        // Get window title using CGWindowList
        let windowTitle = getActiveWindowTitle(for: frontApp.processIdentifier)

        return ActiveWindow(
            appName: appName,
            bundleID: bundleID,
            windowTitle: windowTitle,
            url: nil
        )
    }

    private func getActiveWindowTitle(for pid: pid_t) -> String? {
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]

        guard let windowList = windowListInfo else {
            return nil
        }

        for window in windowList {
            guard let windowPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  windowPID == pid,
                  let windowTitle = window[kCGWindowName as String] as? String,
                  !windowTitle.isEmpty else {
                continue
            }

            return windowTitle
        }

        return nil
    }

    func checkScreenRecordingPermission() -> Bool {
        // Check if we can read window info
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]

        guard let windowList = windowListInfo, !windowList.isEmpty else {
            return false
        }

        // Try to access window name (requires Screen Recording permission on macOS 10.15+)
        for window in windowList {
            if window[kCGWindowName as String] != nil {
                return true
            }
        }

        return false
    }

    func requestScreenRecordingPermission() {
        // Opening System Settings to Screen Recording section
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}
