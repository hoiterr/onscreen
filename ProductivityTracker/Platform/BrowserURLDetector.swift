//
//  BrowserURLDetector.swift
//  ProductivityTracker
//
//  Detects browser URLs using AppleScript
//  Requires: Automation permission for Safari/Chrome
//

import Cocoa

class BrowserURLDetector {
    static let shared = BrowserURLDetector()

    private let supportedBrowsers: [String: String] = [
        "com.apple.Safari": "Safari",
        "com.google.Chrome": "Google Chrome",
        "org.mozilla.firefox": "Firefox",
        "com.microsoft.edgemac": "Microsoft Edge",
        "com.brave.Browser": "Brave Browser"
    ]

    private init() {}

    func getCurrentBrowserURL(for bundleID: String) -> String? {
        guard supportedBrowsers.keys.contains(bundleID) else {
            return nil
        }

        switch bundleID {
        case "com.apple.Safari":
            return getSafariURL()
        case "com.google.Chrome":
            return getChromeURL()
        case "org.mozilla.firefox":
            return getFirefoxURL()
        case "com.microsoft.edgemac":
            return getEdgeURL()
        case "com.brave.Browser":
            return getBraveURL()
        default:
            return nil
        }
    }

    private func getSafariURL() -> String? {
        let script = """
        tell application "Safari"
            if (count of windows) > 0 then
                get URL of current tab of front window
            end if
        end tell
        """
        return executeAppleScript(script)
    }

    private func getChromeURL() -> String? {
        let script = """
        tell application "Google Chrome"
            if (count of windows) > 0 then
                get URL of active tab of front window
            end if
        end tell
        """
        return executeAppleScript(script)
    }

    private func getFirefoxURL() -> String? {
        // Firefox doesn't support AppleScript well, fallback to nil
        return nil
    }

    private func getEdgeURL() -> String? {
        let script = """
        tell application "Microsoft Edge"
            if (count of windows) > 0 then
                get URL of active tab of front window
            end if
        end tell
        """
        return executeAppleScript(script)
    }

    private func getBraveURL() -> String? {
        let script = """
        tell application "Brave Browser"
            if (count of windows) > 0 then
                get URL of active tab of front window
            end if
        end tell
        """
        return executeAppleScript(script)
    }

    private func executeAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            return nil
        }

        let output = scriptObject.executeAndReturnError(&error)

        if let error = error {
            // Silently fail - likely due to missing permissions
            return nil
        }

        return output.stringValue
    }

    func checkAutomationPermission(for bundleID: String) -> Bool {
        guard supportedBrowsers.keys.contains(bundleID) else {
            return false
        }

        // Try to execute a simple script
        let testScript = """
        tell application "\(supportedBrowsers[bundleID] ?? "")"
            return true
        end tell
        """

        return executeAppleScript(testScript) != nil
    }
}
