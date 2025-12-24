//
//  HapticFeedback.swift
//  ProductivityTracker
//
//  Haptic feedback system for tactile interactions
//

import SwiftUI
import AppKit

// MARK: - Haptic Feedback Manager

class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()

    private let performer = NSHapticFeedbackManager.defaultPerformer

    private init() {}

    // MARK: - Feedback Types

    func success() {
        performer.perform(.levelChange, performanceTime: .default)
    }

    func warning() {
        performer.perform(.generic, performanceTime: .default)
    }

    func error() {
        performer.perform(.generic, performanceTime: .default)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performer.perform(.generic, performanceTime: .default)
        }
    }

    func selection() {
        performer.perform(.alignment, performanceTime: .default)
    }

    func impact(intensity: HapticIntensity = .medium) {
        switch intensity {
        case .light:
            performer.perform(.alignment, performanceTime: .default)
        case .medium:
            performer.perform(.generic, performanceTime: .default)
        case .heavy:
            performer.perform(.levelChange, performanceTime: .default)
        }
    }

    func notification(type: HapticNotificationType) {
        switch type {
        case .success:
            success()
        case .warning:
            warning()
        case .error:
            error()
        }
    }

    // MARK: - Custom Patterns

    func customPattern(_ pattern: HapticPattern) {
        switch pattern {
        case .heartbeat:
            performer.perform(.generic, performanceTime: .default)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.performer.perform(.generic, performanceTime: .default)
            }

        case .pulse:
            performer.perform(.alignment, performanceTime: .default)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.performer.perform(.alignment, performanceTime: .default)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.performer.perform(.alignment, performanceTime: .default)
            }

        case .crescendo:
            let delays = [0.0, 0.12, 0.2]
            for (index, delay) in delays.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if index < 2 {
                        self.performer.perform(.alignment, performanceTime: .default)
                    } else {
                        self.performer.perform(.levelChange, performanceTime: .default)
                    }
                }
            }

        case .celebration:
            let delays = [0.0, 0.1, 0.2, 0.35, 0.5]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.performer.perform(.alignment, performanceTime: .default)
                }
            }
        }
    }
}

// MARK: - Haptic Types

enum HapticIntensity {
    case light
    case medium
    case heavy
}

enum HapticNotificationType {
    case success
    case warning
    case error
}

enum HapticPattern {
    case heartbeat
    case pulse
    case crescendo
    case celebration
}

// MARK: - Button Haptic Modifier

struct HapticButtonModifier: ViewModifier {
    let feedbackType: HapticFeedbackType
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        if isEnabled {
                            triggerFeedback(feedbackType)
                        }
                    }
            )
    }

    private func triggerFeedback(_ type: HapticFeedbackType) {
        let manager = HapticFeedbackManager.shared

        switch type {
        case .selection:
            manager.selection()
        case .impact(let intensity):
            manager.impact(intensity: intensity)
        case .notification(let notificationType):
            manager.notification(type: notificationType)
        case .custom(let pattern):
            manager.customPattern(pattern)
        }
    }
}

enum HapticFeedbackType {
    case selection
    case impact(HapticIntensity)
    case notification(HapticNotificationType)
    case custom(HapticPattern)
}

// MARK: - Hover Haptic Modifier

struct HoverHapticModifier: ViewModifier {
    let isEnabled: Bool

    @State private var hasTriggered = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering && !hasTriggered && isEnabled {
                    HapticFeedbackManager.shared.impact(intensity: .light)
                    hasTriggered = true
                } else if !hovering {
                    hasTriggered = false
                }
            }
    }
}

// MARK: - Toggle Haptic Modifier

struct ToggleHapticModifier: ViewModifier {
    @Binding var isOn: Bool
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: isOn) { newValue in
                if isEnabled {
                    if newValue {
                        HapticFeedbackManager.shared.success()
                    } else {
                        HapticFeedbackManager.shared.impact(intensity: .light)
                    }
                }
            }
    }
}

// MARK: - Slider Haptic Modifier

struct SliderHapticModifier: ViewModifier {
    @Binding var value: Double
    let step: Double
    let isEnabled: Bool

    @State private var lastStepValue: Double = 0

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { newValue in
                if isEnabled {
                    let currentStep = floor(newValue / step)
                    if currentStep != lastStepValue {
                        HapticFeedbackManager.shared.selection()
                        lastStepValue = currentStep
                    }
                }
            }
            .onAppear {
                lastStepValue = floor(value / step)
            }
    }
}

// MARK: - Delete Haptic Modifier

struct DeleteHapticModifier: ViewModifier {
    let isEnabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if isEnabled {
                    // Double tap pattern for delete
                    HapticFeedbackManager.shared.warning()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        HapticFeedbackManager.shared.warning()
                    }
                }
                action()
            }
    }
}

// MARK: - Scroll Haptic Modifier

struct ScrollHapticModifier: ViewModifier {
    let threshold: CGFloat
    let isEnabled: Bool

    @State private var lastOffset: CGFloat = 0
    @State private var crossedThresholds: Set<Int> = []

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                if isEnabled {
                    handleScrollOffset(offset)
                }
            }
    }

    private func handleScrollOffset(_ offset: CGFloat) {
        let currentThreshold = Int(floor(abs(offset) / threshold))
        let lastThreshold = Int(floor(abs(lastOffset) / threshold))

        if currentThreshold != lastThreshold && !crossedThresholds.contains(currentThreshold) {
            HapticFeedbackManager.shared.impact(intensity: .light)
            crossedThresholds.insert(currentThreshold)

            // Clear old thresholds
            if crossedThresholds.count > 5 {
                crossedThresholds.removeAll()
            }
        }

        lastOffset = offset
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Extensions

extension View {
    /// Adds haptic feedback to button taps
    func hapticFeedback(_ type: HapticFeedbackType = .impact(.medium), enabled: Bool = true) -> some View {
        modifier(HapticButtonModifier(feedbackType: type, isEnabled: enabled))
    }

    /// Adds subtle haptic feedback on hover
    func hoverHaptic(enabled: Bool = true) -> some View {
        modifier(HoverHapticModifier(isEnabled: enabled))
    }

    /// Adds haptic feedback to toggle changes
    func toggleHaptic(isOn: Binding<Bool>, enabled: Bool = true) -> some View {
        modifier(ToggleHapticModifier(isOn: isOn, isEnabled: enabled))
    }

    /// Adds haptic feedback to slider steps
    func sliderHaptic(value: Binding<Double>, step: Double = 0.1, enabled: Bool = true) -> some View {
        modifier(SliderHapticModifier(value: value, step: step, isEnabled: enabled))
    }

    /// Adds haptic feedback to delete actions
    func deleteHaptic(enabled: Bool = true, action: @escaping () -> Void) -> some View {
        modifier(DeleteHapticModifier(isEnabled: enabled, action: action))
    }

    /// Adds haptic feedback during scrolling at intervals
    func scrollHaptic(threshold: CGFloat = 100, enabled: Bool = true) -> some View {
        modifier(ScrollHapticModifier(threshold: threshold, isEnabled: enabled))
    }
}

// MARK: - Haptic Button Style

struct HapticButtonStyle: ButtonStyle {
    let intensity: HapticIntensity

    init(intensity: HapticIntensity = .medium) {
        self.intensity = intensity
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    HapticFeedbackManager.shared.impact(intensity: intensity)
                }
            }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static var haptic: HapticButtonStyle {
        HapticButtonStyle()
    }

    static func haptic(intensity: HapticIntensity) -> HapticButtonStyle {
        HapticButtonStyle(intensity: intensity)
    }
}

// MARK: - Haptic Slider

struct HapticSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String

    @State private var lastStepValue: Double = 0

    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 0.1,
        label: String = ""
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range, step: step)
                .onChange(of: value) { newValue in
                    let currentStep = round(newValue / step)
                    if currentStep != lastStepValue {
                        HapticFeedbackManager.shared.selection()
                        lastStepValue = currentStep
                    }
                }
                .onAppear {
                    lastStepValue = round(value / step)
                }
        }
    }
}

// MARK: - Haptic Toggle

struct HapticToggle: View {
    @Binding var isOn: Bool
    let label: String

    init(_ label: String, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        Toggle(label, isOn: $isOn)
            .onChange(of: isOn) { newValue in
                if newValue {
                    HapticFeedbackManager.shared.success()
                } else {
                    HapticFeedbackManager.shared.impact(intensity: .light)
                }
            }
    }
}

// MARK: - Haptic Context Menu

extension View {
    func hapticContextMenu<MenuItems: View>(
        @ViewBuilder menuItems: () -> MenuItems
    ) -> some View {
        self.contextMenu {
            menuItems()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            HapticFeedbackManager.shared.impact(intensity: .medium)
        }
    }
}
