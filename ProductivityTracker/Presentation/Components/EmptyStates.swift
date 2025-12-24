//
//  EmptyStates.swift
//  ProductivityTracker
//
//  Beautiful animated empty states for various scenarios
//

import SwiftUI

// MARK: - Base Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = -10
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(iconScale)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(iconRotation))
                    .scaleEffect(iconScale)
            }

            // Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(BouncyButtonStyle())
                .opacity(contentOpacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                iconScale = 1.0
                iconRotation = 0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
    }
}

// MARK: - No Data Empty State

struct NoDataEmptyState: View {
    let title: String
    let message: String

    @State private var isAnimating = false

    init(title: String = "No Data Yet", message: String = "Start tracking your activity to see insights here") {
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: 32) {
            // Animated chart icon
            ZStack {
                // Background circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                        .frame(width: CGFloat(80 + index * 30), height: CGFloat(80 + index * 30))
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .opacity(isAnimating ? 0.3 : 0.6)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }

                // Chart bars
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 12, height: CGFloat([30, 50, 35, 45][index]))
                            .scaleEffect(y: isAnimating ? 1.0 : 0.5, anchor: .bottom)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.7)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: isAnimating
                            )
                    }
                }
            }
            .frame(height: 160)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Search Empty State

struct SearchEmptyState: View {
    let searchTerm: String

    @State private var magnifyingGlassScale: CGFloat = 1.0
    @State private var magnifyingGlassRotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            // Animated magnifying glass
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(magnifyingGlassScale)
                    .rotationEffect(.degrees(magnifyingGlassRotation))
            }

            VStack(spacing: 12) {
                Text("No Results Found")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text("No results for \"\(searchTerm)\"\nTry adjusting your search")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                magnifyingGlassScale = 1.1
                magnifyingGlassRotation = 10
            }
        }
    }
}

// MARK: - First Time Empty State

struct FirstTimeEmptyState: View {
    let icon: String
    let title: String
    let steps: [String]
    let actionTitle: String
    let action: () -> Void

    @State private var visibleSteps: Set<Int> = []

    init(
        icon: String = "sparkles",
        title: String = "Welcome!",
        steps: [String],
        actionTitle: String = "Get Started",
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.steps = steps
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 32) {
            // Animated icon
            Image(systemName: icon)
                .font(.system(size: 70, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.3), radius: 20)

            VStack(spacing: 20) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)

                // Steps
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)

                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text(step)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .opacity(visibleSteps.contains(index) ? 1 : 0)
                        .offset(x: visibleSteps.contains(index) ? 0 : -20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.15), value: visibleSteps)
                    }
                }
                .padding(.vertical)
            }

            Button(action: action) {
                HStack(spacing: 8) {
                    Text(actionTitle)
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            for index in steps.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    visibleSteps.insert(index)
                }
            }
        }
    }
}

// MARK: - Error Empty State

struct ErrorEmptyState: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    @State private var isShaking = false
    @State private var pulseScale: CGFloat = 1.0

    init(
        title: String = "Something Went Wrong",
        message: String = "We encountered an error. Please try again.",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 24) {
            // Error icon with pulse
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.red.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseScale)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: isShaking ? -5 : 5)
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Shake animation
            withAnimation(.easeInOut(duration: 0.1).repeatCount(4, autoreverses: true)) {
                isShaking = true
            }

            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Permission Required Empty State

struct PermissionEmptyState: View {
    let permission: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    @State private var lockRotation: Double = 0
    @State private var lockScale: CGFloat = 1.0

    init(
        permission: String,
        message: String,
        actionTitle: String = "Grant Permission",
        action: @escaping () -> Void
    ) {
        self.permission = permission
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            // Animated lock
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.yellow.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "lock.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(lockRotation))
                    .scaleEffect(lockScale)
            }

            VStack(spacing: 12) {
                Text("\(permission) Permission Required")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }

            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                    Text(actionTitle)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .shadow(color: .orange.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                lockRotation = 10
                lockScale = 1.05
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func emptyState(
        isVisible: Bool,
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        ZStack {
            self.opacity(isVisible ? 0 : 1)

            if isVisible {
                EmptyStateView(
                    icon: icon,
                    title: title,
                    message: message,
                    actionTitle: actionTitle,
                    action: action
                )
                .transition(.opacity)
            }
        }
    }
}
