//
//  CardTransform3D.swift
//  ProductivityTracker
//
//  3D transform effects for interactive depth
//

import SwiftUI

struct CardTransform3DModifier: ViewModifier {
    let intensity: CGFloat
    let shadowDepth: Bool

    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var isHovered: Bool = false
    @State private var mouseLocation: CGPoint = .zero

    init(intensity: CGFloat = 1.0, shadowDepth: Bool = true) {
        self.intensity = intensity
        self.shadowDepth = shadowDepth
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .rotation3DEffect(
                    .degrees(rotationX),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .rotation3DEffect(
                    .degrees(rotationY),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .shadow(
                    color: shadowDepth ? Color.black.opacity(0.2) : .clear,
                    radius: isHovered ? 20 : 10,
                    x: rotationY * (shadowDepth ? 0.5 : 0),
                    y: -rotationX * (shadowDepth ? 0.5 : 0)
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: rotationX)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: rotationY)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        isHovered = true
                        mouseLocation = location
                        updateRotation(in: geometry.size)
                    case .ended:
                        isHovered = false
                        rotationX = 0
                        rotationY = 0
                    }
                }
        }
    }

    private func updateRotation(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        let deltaX = mouseLocation.x - centerX
        let deltaY = mouseLocation.y - centerY

        // Normalize to -1...1 range and apply intensity
        let normalizedX = (deltaY / centerY) * 10 * intensity
        let normalizedY = (deltaX / centerX) * 10 * intensity

        rotationX = -normalizedX
        rotationY = normalizedY
    }
}

extension View {
    func cardTransform3D(intensity: CGFloat = 1.0, shadowDepth: Bool = true) -> some View {
        modifier(CardTransform3DModifier(intensity: intensity, shadowDepth: shadowDepth))
    }
}

// MARK: - Floating Card Effect

struct FloatingCardModifier: ViewModifier {
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0

    let delay: Double
    let duration: Double
    let amplitude: CGFloat

    init(delay: Double = 0, duration: Double = 3.0, amplitude: CGFloat = 8) {
        self.delay = delay
        self.duration = duration
        self.amplitude = amplitude
    }

    func body(content: Content) -> some View {
        content
            .offset(y: yOffset)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),
                perspective: 1.0
            )
            .onAppear {
                // Floating animation
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    yOffset = amplitude
                }

                // Subtle rotation
                withAnimation(
                    .easeInOut(duration: duration * 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    rotation = 2
                }
            }
    }
}

extension View {
    func floatingCard(delay: Double = 0, duration: Double = 3.0, amplitude: CGFloat = 8) -> some View {
        modifier(FloatingCardModifier(delay: delay, duration: duration, amplitude: amplitude))
    }
}

// MARK: - Magnetic Card Effect

struct MagneticCardModifier: ViewModifier {
    let strength: CGFloat

    @State private var offset: CGSize = .zero
    @State private var mouseLocation: CGPoint = .zero
    @State private var isHovered: Bool = false

    init(strength: CGFloat = 0.15) {
        self.strength = strength
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .offset(offset)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: offset)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        isHovered = true
                        mouseLocation = location
                        updateOffset(in: geometry.size)
                    case .ended:
                        isHovered = false
                        offset = .zero
                    }
                }
        }
    }

    private func updateOffset(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        let deltaX = mouseLocation.x - centerX
        let deltaY = mouseLocation.y - centerY

        offset = CGSize(
            width: deltaX * strength,
            height: deltaY * strength
        )
    }
}

extension View {
    func magneticCard(strength: CGFloat = 0.15) -> some View {
        modifier(MagneticCardModifier(strength: strength))
    }
}

// MARK: - Parallax Layers

struct ParallaxLayer: ViewModifier {
    let depth: CGFloat

    @State private var offset: CGSize = .zero
    @State private var mouseLocation: CGPoint = .zero

    init(depth: CGFloat = 1.0) {
        self.depth = depth
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .offset(offset)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: offset)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        mouseLocation = location
                        updateParallax(in: geometry.size)
                    case .ended:
                        offset = .zero
                    }
                }
        }
    }

    private func updateParallax(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        let deltaX = mouseLocation.x - centerX
        let deltaY = mouseLocation.y - centerY

        let normalizedX = (deltaX / centerX) * 20 * depth
        let normalizedY = (deltaY / centerY) * 20 * depth

        offset = CGSize(width: normalizedX, height: normalizedY)
    }
}

extension View {
    func parallaxLayer(depth: CGFloat = 1.0) -> some View {
        modifier(ParallaxLayer(depth: depth))
    }
}

// MARK: - Flip Card

struct FlipCardModifier: ViewModifier {
    @Binding var isFlipped: Bool

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isFlipped)
    }
}

struct FlipCard<Front: View, Back: View>: View {
    let front: Front
    let back: Back
    @State private var isFlipped: Bool = false

    init(@ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self.front = front()
        self.back = back()
    }

    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .modifier(FlipCardModifier(isFlipped: $isFlipped))

            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .modifier(FlipCardModifier(isFlipped: $isFlipped))
        }
        .onTapGesture {
            isFlipped.toggle()
        }
    }
}
