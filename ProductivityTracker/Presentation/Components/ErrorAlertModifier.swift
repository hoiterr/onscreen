//
//  ErrorAlertModifier.swift
//  ProductivityTracker
//
//  View modifier for displaying app errors with recovery actions
//

import SwiftUI
import AppKit

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(
                error?.errorDescription ?? "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { presentedError in
                // Primary action button
                Button(presentedError.actionTitle ?? "OK") {
                    handleError(presentedError)
                    error = nil
                }

                // Cancel button
                Button("Dismiss", role: .cancel) {
                    error = nil
                }
            } message: { presentedError in
                if let suggestion = presentedError.recoverySuggestion {
                    Text(suggestion)
                }
            }
    }

    private func handleError(_ error: AppError) {
        switch error {
        case .permissionDenied(.screenRecording):
            WindowTracker.shared.requestScreenRecordingPermission()

        case .permissionDenied(.automation):
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }

        case .trackingFailed:
            TrackingService.shared.startTracking()

        case .coreDateError:
            break // Just dismiss

        case .exportFailed, .importFailed:
            break // User will retry manually

        case .browserAccessFailed:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}
