//
//  TooltipSystem.swift
//  ProductivityTracker
//
//  Rich contextual tooltips with smart positioning
//

import SwiftUI

// MARK: - Tooltip Style

enum TooltipStyle {
    case `default`
    case info
    case success
    case warning
    case error

    var backgroundColor: Color {
        switch self {
        case .default: return .primary.opacity(0.95)
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }

    var foregroundColor: Color {
        .white
    }

    var icon: String? {
        switch self {
        case .default: return nil
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

// MARK: - Tooltip Position

enum TooltipPosition {
    case top
    case bottom
    case leading
    case trailing
    case auto

    func computePosition(targetFrame: CGRect, tooltipSize: CGSize, screenBounds: CGRect) -> (position: TooltipPosition, offset: CGPoint) {
        if self != .auto {
            return (self, offset(for: self, targetFrame: targetFrame, tooltipSize: tooltipSize))
        }

        // Auto positioning logic
        let spaceAbove = targetFrame.minY - screenBounds.minY
        let spaceBelow = screenBounds.maxY - targetFrame.maxY
        let spaceLeading = targetFrame.minX - screenBounds.minX
        let spaceTrailing = screenBounds.maxX - targetFrame.maxX

        let preferredPosition: TooltipPosition
        if spaceAbove > tooltipSize.height + 20 {
            preferredPosition = .top
        } else if spaceBelow > tooltipSize.height + 20 {
            preferredPosition = .bottom
        } else if spaceTrailing > tooltipSize.width + 20 {
            preferredPosition = .trailing
        } else if spaceLeading > tooltipSize.width + 20 {
            preferredPosition = .leading
        } else {
            preferredPosition = .bottom // Fallback
        }

        return (preferredPosition, offset(for: preferredPosition, targetFrame: targetFrame, tooltipSize: tooltipSize))
    }

    private func offset(for position: TooltipPosition, targetFrame: CGRect, tooltipSize: CGSize) -> CGPoint {
        let spacing: CGFloat = 12

        switch position {
        case .top:
            return CGPoint(
                x: targetFrame.midX - tooltipSize.width / 2,
                y: targetFrame.minY - tooltipSize.height - spacing
            )
        case .bottom:
            return CGPoint(
                x: targetFrame.midX - tooltipSize.width / 2,
                y: targetFrame.maxY + spacing
            )
        case .leading:
            return CGPoint(
                x: targetFrame.minX - tooltipSize.width - spacing,
                y: targetFrame.midY - tooltipSize.height / 2
            )
        case .trailing:
            return CGPoint(
                x: targetFrame.maxX + spacing,
                y: targetFrame.midY - tooltipSize.height / 2
            )
        case .auto:
            return .zero // Should not reach here
        }
    }
}

// MARK: - Tooltip Content

struct TooltipContent {
    let title: String?
    let message: String
    let style: TooltipStyle
    let icon: String?
    let maxWidth: CGFloat

    init(message: String, title: String? = nil, style: TooltipStyle = .default, icon: String? = nil, maxWidth: CGFloat = 250) {
        self.message = message
        self.title = title
        self.style = style
        self.icon = icon ?? style.icon
        self.maxWidth = maxWidth
    }
}

// MARK: - Tooltip View

struct TooltipView: View {
    let content: TooltipContent
    let position: TooltipPosition

    var body: some View {
        VStack(alignment: .leading, spacing: content.title != nil ? 6 : 0) {
            if let title = content.title {
                HStack(spacing: 8) {
                    if let icon = content.icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                    }

                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                }
            }

            Text(content.message)
                .font(.system(size: 12))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(content.style.foregroundColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: content.maxWidth)
        .background(
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(content.style.backgroundColor)

                // Pointer
                TooltipPointer(position: position, color: content.style.backgroundColor)
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Tooltip Pointer

struct TooltipPointer: View {
    let position: TooltipPosition
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let size: CGFloat = 8

                switch position {
                case .top:
                    // Pointer at bottom center
                    let centerX = geometry.size.width / 2
                    let bottomY = geometry.size.height
                    path.move(to: CGPoint(x: centerX, y: bottomY + size))
                    path.addLine(to: CGPoint(x: centerX - size, y: bottomY))
                    path.addLine(to: CGPoint(x: centerX + size, y: bottomY))
                    path.closeSubpath()

                case .bottom:
                    // Pointer at top center
                    let centerX = geometry.size.width / 2
                    path.move(to: CGPoint(x: centerX, y: -size))
                    path.addLine(to: CGPoint(x: centerX - size, y: 0))
                    path.addLine(to: CGPoint(x: centerX + size, y: 0))
                    path.closeSubpath()

                case .leading:
                    // Pointer at right center
                    let centerY = geometry.size.height / 2
                    let rightX = geometry.size.width
                    path.move(to: CGPoint(x: rightX + size, y: centerY))
                    path.addLine(to: CGPoint(x: rightX, y: centerY - size))
                    path.addLine(to: CGPoint(x: rightX, y: centerY + size))
                    path.closeSubpath()

                case .trailing:
                    // Pointer at left center
                    let centerY = geometry.size.height / 2
                    path.move(to: CGPoint(x: -size, y: centerY))
                    path.addLine(to: CGPoint(x: 0, y: centerY - size))
                    path.addLine(to: CGPoint(x: 0, y: centerY + size))
                    path.closeSubpath()

                case .auto:
                    break
                }
            }
            .fill(color)
        }
    }
}

// MARK: - Tooltip Modifier

struct TooltipModifier: ViewModifier {
    let content: TooltipContent
    let position: TooltipPosition
    let hoverDelay: Double

    @State private var isHovered: Bool = false
    @State private var showTooltip: Bool = false
    @State private var hoverTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: TooltipPreferenceKey.self,
                        value: geometry.frame(in: .global)
                    )
                }
            )
            .onPreferenceChange(TooltipPreferenceKey.self) { frame in
                // Store frame for positioning
            }
            .overlay(
                Group {
                    if showTooltip {
                        TooltipView(content: self.content, position: position)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showTooltip)
                            .zIndex(1000)
                    }
                },
                alignment: alignmentForPosition(position)
            )
            .onHover { hovering in
                isHovered = hovering

                hoverTask?.cancel()

                if hovering {
                    hoverTask = Task {
                        try? await Task.sleep(nanoseconds: UInt64(hoverDelay * 1_000_000_000))
                        if !Task.isCancelled {
                            await MainActor.run {
                                withAnimation {
                                    showTooltip = true
                                }
                            }
                        }
                    }
                } else {
                    withAnimation {
                        showTooltip = false
                    }
                }
            }
    }

    private func alignmentForPosition(_ position: TooltipPosition) -> Alignment {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        case .auto: return .top
        }
    }
}

struct TooltipPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - View Extensions

extension View {
    func tooltip(_ message: String, position: TooltipPosition = .auto, style: TooltipStyle = .default, delay: Double = 0.5) -> some View {
        modifier(TooltipModifier(
            content: TooltipContent(message: message, style: style),
            position: position,
            hoverDelay: delay
        ))
    }

    func tooltip(_ content: TooltipContent, position: TooltipPosition = .auto, delay: Double = 0.5) -> some View {
        modifier(TooltipModifier(
            content: content,
            position: position,
            hoverDelay: delay
        ))
    }
}

// MARK: - Rich Tooltip Variants

struct InfoTooltip: ViewModifier {
    let title: String
    let message: String
    let position: TooltipPosition

    func body(content: Content) -> some View {
        content.tooltip(
            TooltipContent(message: message, title: title, style: .info),
            position: position
        )
    }
}

struct KeyboardShortcutTooltip: ViewModifier {
    let action: String
    let shortcut: String

    func body(content: Content) -> some View {
        content.tooltip(
            TooltipContent(
                message: "\(action)\nShortcut: ⌘\(shortcut)",
                style: .default
            ),
            position: .bottom
        )
    }
}

extension View {
    func infoTooltip(title: String, message: String, position: TooltipPosition = .auto) -> some View {
        modifier(InfoTooltip(title: title, message: message, position: position))
    }

    func shortcutTooltip(action: String, shortcut: String) -> some View {
        modifier(KeyboardShortcutTooltip(action: action, shortcut: shortcut))
    }
}

// MARK: - Help Icon with Tooltip

struct HelpIconWithTooltip: View {
    let message: String
    let title: String?

    init(_ message: String, title: String? = nil) {
        self.message = message
        self.title = title
    }

    var body: some View {
        Image(systemName: "questionmark.circle.fill")
            .foregroundColor(.secondary)
            .font(.system(size: 14))
            .tooltip(
                TooltipContent(
                    message: message,
                    title: title,
                    style: .info,
                    maxWidth: 300
                ),
                position: .trailing
            )
    }
}

// MARK: - Status Tooltip

struct StatusTooltip: View {
    let isActive: Bool
    let activeMessage: String
    let inactiveMessage: String

    var body: some View {
        Circle()
            .fill(isActive ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
            .tooltip(
                isActive ? activeMessage : inactiveMessage,
                style: isActive ? .success : .default
            )
    }
}
