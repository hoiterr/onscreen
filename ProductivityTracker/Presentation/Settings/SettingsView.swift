//
//  SettingsView.swift
//  ProductivityTracker
//
//  App settings and preferences
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var trackingService: TrackingService
    @AppStorage("idleTimeoutMinutes") private var idleTimeoutMinutes: Int = 5
    @AppStorage("debounceThresholdSeconds") private var debounceThresholdSeconds: Int = 5
    @AppStorage("dataRetentionMonths") private var dataRetentionMonths: Int = 12
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    @State private var showDeleteConfirmation = false
    @State private var showExportOptions = false
    @State private var showPermissionsAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text("Configure tracking behavior and privacy")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Tracking Settings
                SettingsSection(title: "Tracking", icon: "clock.fill", color: .blue) {
                    SettingRow(
                        title: "Idle Timeout",
                        description: "Stop tracking after inactivity"
                    ) {
                        HStack {
                            TextField("", value: $idleTimeoutMinutes, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .onChange(of: idleTimeoutMinutes) { _, newValue in
                                    trackingService.setIdleThreshold(minutes: newValue)
                                }

                            Text("minutes")
                                .foregroundColor(.secondary)
                        }
                    }

                    SettingRow(
                        title: "Debounce Threshold",
                        description: "Ignore switches shorter than"
                    ) {
                        HStack {
                            TextField("", value: $debounceThresholdSeconds, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .onChange(of: debounceThresholdSeconds) { _, newValue in
                                    trackingService.setDebounceThreshold(seconds: TimeInterval(newValue))
                                }

                            Text("seconds")
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    SettingRow(
                        title: "Launch at Login",
                        description: "Automatically start tracking when you log in"
                    ) {
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                            .hapticFeedback(.notification(.success))
                            .onChange(of: launchAtLogin) { _, newValue in
                                do {
                                    try LaunchAtLoginService.shared.setLaunchAtLogin(newValue)
                                } catch {
                                    print("Failed to set launch at login: \(error)")
                                    // Revert on failure
                                    launchAtLogin = !newValue
                                }
                            }
                    }
                    .tooltip("Enable to start tracking automatically", position: .bottom)
                }

                // Privacy Settings
                SettingsSection(title: "Privacy", icon: "lock.shield.fill", color: .green) {
                    SettingRow(
                        title: "Data Storage",
                        description: "All data is stored locally on your Mac"
                    ) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }

                    SettingRow(
                        title: "Data Retention",
                        description: "Automatically delete data older than"
                    ) {
                        Picker("", selection: $dataRetentionMonths) {
                            Text("3 months").tag(3)
                            Text("6 months").tag(6)
                            Text("12 months").tag(12)
                            Text("Keep all").tag(999)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }

                    Divider()

                    VStack(spacing: 12) {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Delete All Data", systemImage: "trash.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .hapticFeedback(.custom(.heartbeat))
                        .tooltip("Permanently delete all tracked data", position: .bottom, style: .warning)
                        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Delete", role: .destructive) {
                                deleteAllData()
                            }
                        } message: {
                            Text("This will permanently delete all tracked sessions and rules. This action cannot be undone.")
                        }
                    }
                }

                // Permissions
                SettingsSection(title: "Permissions", icon: "key.fill", color: .orange) {
                    PermissionRow(
                        title: "Screen Recording",
                        description: "Required to read window titles",
                        isGranted: WindowTracker.shared.checkScreenRecordingPermission()
                    ) {
                        WindowTracker.shared.requestScreenRecordingPermission()
                    }

                    PermissionRow(
                        title: "Automation",
                        description: "Required to read browser URLs",
                        isGranted: true // Can't easily check this
                    ) {
                        // Open System Settings
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
                    }
                }

                // Data Export
                SettingsSection(title: "Data Export", icon: "square.and.arrow.up.fill", color: .purple) {
                    SettingRow(
                        title: "Export Format",
                        description: "Export your tracking data"
                    ) {
                        HStack(spacing: 12) {
                            Button("Export CSV") {
                                exportData(format: .csv)
                            }
                            .buttonStyle(.bordered)
                            .hapticFeedback(.impact(.light))
                            .tooltip("Export data as comma-separated values", position: .bottom)

                            Button("Export JSON") {
                                exportData(format: .json)
                            }
                            .buttonStyle(.bordered)
                            .hapticFeedback(.impact(.light))
                            .tooltip("Export data as JSON format", position: .bottom)
                        }
                    }
                }

                // About
                SettingsSection(title: "About", icon: "info.circle.fill", color: .gray) {
                    SettingRow(
                        title: "Version",
                        description: "Productivity Tracker"
                    ) {
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    SettingRow(
                        title: "Privacy",
                        description: "No data ever leaves your device"
                    ) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
        }
    }

    private func deleteAllData() {
        PersistenceController.shared.deleteAllData()
    }

    private func exportData(format: ExportFormat) {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -dataRetentionMonths, to: Date()) ?? Date()
        let endDate = Date()

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [format == .csv ? .commaSeparatedText : .json]
        savePanel.nameFieldStringValue = "productivity_data.\(format.rawValue)"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let data: Data
                    if format == .csv {
                        let csvString = PersistenceController.shared.exportToCSV(from: startDate, to: endDate)
                        data = csvString.data(using: .utf8) ?? Data()
                    } else {
                        data = PersistenceController.shared.exportToJSON(from: startDate, to: endDate) ?? Data()
                    }

                    try data.write(to: url)

                    // Show success notification
                    let notification = NSUserNotification()
                    notification.title = "Export Successful"
                    notification.informativeText = "Data exported to \(url.lastPathComponent)"
                    NSUserNotificationCenter.default.deliver(notification)
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }
}

enum ExportFormat: String {
    case csv
    case json
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)

                    Text(title)
                        .font(.headline)

                    Spacer()
                }

                VStack(spacing: 12) {
                    content
                }
            }
        }
    }
}

struct SettingRow<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            content
        }
        .padding(.vertical, 4)
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text("Granted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button("Grant Access") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .hapticFeedback(.notification(.warning))
                .tooltip("Open System Settings to grant permission", position: .bottom)
            }
        }
        .padding(.vertical, 4)
    }
}
