//
//  ParticleSystem.swift
//  ProductivityTracker
//
//  Celebration particle effects and confetti
//

import SwiftUI

// MARK: - Particle Model

struct Particle: Identifiable {
    let id = UUID()
    let shape: ParticleShape
    let color: Color
    let startPosition: CGPoint
    let velocity: CGVector
    let angularVelocity: Double
    let size: CGFloat
    let lifetime: Double
}

enum ParticleShape {
    case circle
    case square
    case triangle
    case star
    case heart
    case emoji(String)

    @ViewBuilder
    func view(size: CGFloat, color: Color) -> some View {
        switch self {
        case .circle:
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        case .square:
            Rectangle()
                .fill(color)
                .frame(width: size, height: size)
        case .triangle:
            Triangle()
                .fill(color)
                .frame(width: size, height: size)
        case .star:
            Star()
                .fill(color)
                .frame(width: size, height: size)
        case .heart:
            Heart()
                .fill(color)
                .frame(width: size, height: size)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size))
        }
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5

        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi) / Double(points) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.2),
            control1: CGPoint(x: width * 0.5, y: height * 0.1),
            control2: CGPoint(x: width * 0.1, y: height * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width * 0.1, y: height * 0.5),
            control2: CGPoint(x: width * 0.5, y: height * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.2),
            control1: CGPoint(x: width * 0.5, y: height * 0.75),
            control2: CGPoint(x: width * 0.9, y: height * 0.5)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.25),
            control1: CGPoint(x: width * 0.9, y: height * 0.05),
            control2: CGPoint(x: width * 0.5, y: height * 0.1)
        )
        return path
    }
}

// MARK: - Particle Emitter

struct ParticleEmitter: View {
    let particles: [Particle]
    let duration: Double

    @State private var animationProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particle.shape.view(size: particle.size, color: particle.color)
                        .offset(
                            x: particle.startPosition.x + particle.velocity.dx * animationProgress,
                            y: particle.startPosition.y + particle.velocity.dy * animationProgress + gravity * animationProgress * animationProgress
                        )
                        .rotationEffect(.degrees(particle.angularVelocity * Double(animationProgress)))
                        .opacity(1.0 - Double(animationProgress))
                }
            }
            .onAppear {
                withAnimation(.linear(duration: duration)) {
                    animationProgress = 1.0
                }
            }
        }
    }

    private var gravity: CGFloat {
        200 // Pixels per second squared
    }
}

// MARK: - Confetti Effect

struct ConfettiEffect: View {
    @Binding var isActive: Bool
    let particleCount: Int
    let duration: Double

    init(isActive: Binding<Bool>, particleCount: Int = 80, duration: Double = 3.0) {
        self._isActive = isActive
        self.particleCount = particleCount
        self.duration = duration
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isActive {
                    ParticleEmitter(
                        particles: generateConfetti(in: geometry.size),
                        duration: duration
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            isActive = false
                        }
                    }
                }
            }
        }
    }

    private func generateConfetti(in size: CGSize) -> [Particle] {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        let shapes: [ParticleShape] = [.circle, .square, .triangle, .star, .heart]

        return (0..<particleCount).map { _ in
            let angle = Double.random(in: -Double.pi / 4...(-3 * Double.pi / 4))
            let speed = CGFloat.random(in: 200...400)

            return Particle(
                shape: shapes.randomElement()!,
                color: colors.randomElement()!,
                startPosition: CGPoint(x: size.width / 2, y: size.height),
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                ),
                angularVelocity: Double.random(in: -720...720),
                size: CGFloat.random(in: 8...16),
                lifetime: duration
            )
        }
    }
}

// MARK: - Sparkle Effect

struct SparkleEffect: View {
    @Binding var isActive: Bool
    let particleCount: Int
    let duration: Double

    init(isActive: Binding<Bool>, particleCount: Int = 30, duration: Double = 1.5) {
        self._isActive = isActive
        self.particleCount = particleCount
        self.duration = duration
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isActive {
                    ParticleEmitter(
                        particles: generateSparkles(in: geometry.size),
                        duration: duration
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            isActive = false
                        }
                    }
                }
            }
        }
    }

    private func generateSparkles(in size: CGSize) -> [Particle] {
        let colors: [Color] = [.yellow, .white, .cyan, .yellow.opacity(0.8)]

        return (0..<particleCount).map { _ in
            let angle = Double.random(in: 0...(2 * Double.pi))
            let speed = CGFloat.random(in: 100...300)

            return Particle(
                shape: .star,
                color: colors.randomElement()!,
                startPosition: CGPoint(x: size.width / 2, y: size.height / 2),
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                ),
                angularVelocity: Double.random(in: -360...360),
                size: CGFloat.random(in: 6...14),
                lifetime: duration
            )
        }
    }
}

// MARK: - Emoji Celebration

struct EmojiCelebration: View {
    @Binding var isActive: Bool
    let emojis: [String]
    let particleCount: Int
    let duration: Double

    init(isActive: Binding<Bool>, emojis: [String] = ["🎉", "🎊", "⭐️", "✨", "🌟"], particleCount: Int = 40, duration: Double = 2.5) {
        self._isActive = isActive
        self.emojis = emojis
        self.particleCount = particleCount
        self.duration = duration
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isActive {
                    ParticleEmitter(
                        particles: generateEmojiParticles(in: geometry.size),
                        duration: duration
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            isActive = false
                        }
                    }
                }
            }
        }
    }

    private func generateEmojiParticles(in size: CGSize) -> [Particle] {
        return (0..<particleCount).map { _ in
            let angle = Double.random(in: -Double.pi / 3...(-2 * Double.pi / 3))
            let speed = CGFloat.random(in: 150...350)

            return Particle(
                shape: .emoji(emojis.randomElement()!),
                color: .clear,
                startPosition: CGPoint(x: size.width / 2, y: size.height),
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                ),
                angularVelocity: Double.random(in: -180...180),
                size: CGFloat.random(in: 24...40),
                lifetime: duration
            )
        }
    }
}

// MARK: - Success Burst

struct SuccessBurst: View {
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            // Central glow
            if isActive {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.green.opacity(0.6), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(isActive ? 2.0 : 0.1)
                    .opacity(isActive ? 0 : 1)
                    .animation(.easeOut(duration: 0.8), value: isActive)

                // Ring burst
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.green.opacity(0.5), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isActive ? CGFloat(3 + index) : 1.0)
                        .opacity(isActive ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.0)
                            .delay(Double(index) * 0.1),
                            value: isActive
                        )
                }
            }

            SparkleEffect(isActive: $isActive, particleCount: 20, duration: 1.2)
        }
    }
}

// MARK: - Milestone Celebration

struct MilestoneCelebration: View {
    @Binding var isActive: Bool
    let milestone: String

    var body: some View {
        ZStack {
            ConfettiEffect(isActive: $isActive)

            if isActive {
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 80))
                        .scaleEffect(isActive ? 1.0 : 0.1)
                        .opacity(isActive ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: isActive)

                    Text(milestone)
                        .font(.title.bold())
                        .foregroundColor(.primary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 20)
                        .scaleEffect(isActive ? 1.0 : 0.8)
                        .opacity(isActive ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: isActive)
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func confettiCelebration(isActive: Binding<Bool>) -> some View {
        ZStack {
            self
            ConfettiEffect(isActive: isActive)
        }
    }

    func sparkleCelebration(isActive: Binding<Bool>) -> some View {
        ZStack {
            self
            SparkleEffect(isActive: isActive)
        }
    }

    func emojiCelebration(isActive: Binding<Bool>, emojis: [String] = ["🎉", "🎊", "⭐️", "✨", "🌟"]) -> some View {
        ZStack {
            self
            EmojiCelebration(isActive: isActive, emojis: emojis)
        }
    }

    func successBurst(isActive: Binding<Bool>) -> some View {
        ZStack {
            self
            SuccessBurst(isActive: isActive)
        }
    }
}
