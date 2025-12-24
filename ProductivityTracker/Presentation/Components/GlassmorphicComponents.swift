//
//  GlassmorphicComponents.swift
//  ProductivityTracker
//
//  Enhanced glassmorphism with multi-layer depth
//

import SwiftUI

// MARK: - Glass Material Types

enum GlassMaterial {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick

    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .ultraThick: return .ultraThickMaterial
        }
    }

    var borderOpacity: Double {
        switch self {
        case .ultraThin: return 0.15
        case .thin: return 0.12
        case .regular: return 0.1
        case .thick: return 0.08
        case .ultraThick: return 0.05
        }
    }
}

// MARK: - Enhanced Glass Card

struct EnhancedGlassCard<Content: View>: View {
    let content: Content
    let material: GlassMaterial
    let cornerRadius: CGFloat
    let padding: CGFloat
    let borderGradient: Bool
    let shadowEnabled: Bool

    init(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 20,
        borderGradient: Bool = true,
        shadowEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderGradient = borderGradient
        self.shadowEnabled = shadowEnabled
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(material.material)

                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            borderGradient ?
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(material.borderOpacity * 1.5),
                                    Color.white.opacity(material.borderOpacity * 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(material.borderOpacity)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: shadowEnabled ? Color.black.opacity(0.05) : .clear,
                radius: shadowEnabled ? 10 : 0,
                y: shadowEnabled ? 5 : 0
            )
    }
}

// MARK: - Frosted Glass

struct FrostedGlass<Content: View>: View {
    let content: Content
    let tint: Color
    let intensity: Double
    let cornerRadius: CGFloat

    init(
        tint: Color = .clear,
        intensity: Double = 1.0,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.tint = tint
        self.intensity = intensity
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .background(
                ZStack {
                    // Tinted background
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(0.1 * intensity))

                    // Blur material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(intensity)

                    // Light refraction effect
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.2 * intensity),
                                    .clear,
                                    .white.opacity(0.1 * intensity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
    }
}

// MARK: - Liquid Glass

struct LiquidGlass<Content: View>: View {
    let content: Content
    let colors: [Color]
    let cornerRadius: CGFloat

    @State private var animationPhase: Double = 0

    init(
        colors: [Color] = [.blue, .purple, .pink],
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.colors = colors
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .background(
                ZStack {
                    // Animated gradient background
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            AngularGradient(
                                colors: colors + [colors[0]],
                                center: .center,
                                startAngle: .degrees(animationPhase),
                                endAngle: .degrees(animationPhase + 360)
                            )
                        )
                        .opacity(0.15)
                        .blur(radius: 20)

                    // Glass layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Shimmer overlay
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * 0.3)
                            .offset(x: geometry.size.width * CGFloat(sin(animationPhase * .pi / 180)))
                    }
                    .mask(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    animationPhase = 360
                }
            }
    }
}

// MARK: - Glass Button

struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let tint: Color
    let isProminent: Bool

    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false

    init(
        _ title: String,
        icon: String? = nil,
        tint: Color = .blue,
        isProminent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.isProminent = isProminent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(isProminent ? .white : tint)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint, tint.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tint.opacity(isHovered ? 0.15 : 0.1))
                    }

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .shadow(color: tint.opacity(isProminent ? 0.3 : 0.1), radius: isHovered ? 12 : 8, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .pressEvents(
            onPress: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = true
                }
            },
            onRelease: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        )
    }
}

// MARK: - Glass Pill

struct GlassPill: View {
    let text: String
    let color: Color
    let icon: String?

    init(_ text: String, color: Color = .blue, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)

                Capsule()
                    .fill(color.opacity(0.15))

                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            }
        )
    }
}

// MARK: - Depth Glass Card

struct DepthGlassCard<Content: View>: View {
    let content: Content
    let depth: Int

    @State private var hoveredLayer: Int? = nil

    init(depth: Int = 3, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.depth = depth
    }

    var body: some View {
        ZStack {
            ForEach(0..<depth, id: \.self) { layer in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .offset(
                        x: CGFloat(layer) * 2,
                        y: CGFloat(layer) * 2
                    )
                    .opacity(1.0 - (Double(layer) * 0.2))
                    .blur(radius: CGFloat(layer) * 0.5)
            }

            content
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
}

// MARK: - Glass Divider

struct GlassDivider: View {
    let thickness: CGFloat
    let gradient: Bool

    init(thickness: CGFloat = 1, gradient: Bool = true) {
        self.thickness = thickness
        self.gradient = gradient
    }

    var body: some View {
        Rectangle()
            .fill(
                gradient ?
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.white.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: thickness)
    }
}

// MARK: - Morphing Glass Background

struct MorphingGlassBackground: View {
    @State private var phase1: Double = 0
    @State private var phase2: Double = 0
    @State private var phase3: Double = 0

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Morphing blobs
            Canvas { context, size in
                let blob1 = createBlob(
                    in: size,
                    center: CGPoint(
                        x: size.width * 0.3 + sin(phase1) * 100,
                        y: size.height * 0.3 + cos(phase1 * 0.8) * 80
                    ),
                    radius: 200,
                    color: .blue
                )

                let blob2 = createBlob(
                    in: size,
                    center: CGPoint(
                        x: size.width * 0.7 + sin(phase2 * 1.2) * 120,
                        y: size.height * 0.6 + cos(phase2) * 90
                    ),
                    radius: 180,
                    color: .purple
                )

                let blob3 = createBlob(
                    in: size,
                    center: CGPoint(
                        x: size.width * 0.5 + sin(phase3 * 0.9) * 110,
                        y: size.height * 0.8 + cos(phase3 * 1.1) * 70
                    ),
                    radius: 160,
                    color: .pink
                )

                context.draw(blob1, at: .zero, anchor: .topLeading)
                context.draw(blob2, at: .zero, anchor: .topLeading)
                context.draw(blob3, at: .zero, anchor: .topLeading)
            }
            .blur(radius: 60)
            .opacity(0.3)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase1 = .pi * 2
            }
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                phase2 = .pi * 2
            }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                phase3 = .pi * 2
            }
        }
    }

    private func createBlob(in size: CGSize, center: CGPoint, radius: CGFloat, color: Color) -> GraphicsContext.ResolvedImage {
        let renderer = ImageRenderer(content:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.6), color.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
        )
        return GraphicsContext.ResolvedImage(renderer.cgImage!)
    }
}

// MARK: - Press Events Helper

struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPress()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onRelease()
                    }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - View Extensions

extension View {
    func enhancedGlass(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 20
    ) -> some View {
        EnhancedGlassCard(
            material: material,
            cornerRadius: cornerRadius,
            padding: padding
        ) {
            self
        }
    }

    func frostedGlass(
        tint: Color = .clear,
        intensity: Double = 1.0,
        cornerRadius: CGFloat = 16
    ) -> some View {
        FrostedGlass(
            tint: tint,
            intensity: intensity,
            cornerRadius: cornerRadius
        ) {
            self
        }
    }

    func liquidGlass(
        colors: [Color] = [.blue, .purple, .pink],
        cornerRadius: CGFloat = 16
    ) -> some View {
        LiquidGlass(
            colors: colors,
            cornerRadius: cornerRadius
        ) {
            self
        }
    }
}
