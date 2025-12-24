//
//  MeshGradientBackground.swift
//  ProductivityTracker
//
//  Animated gradient mesh for depth and visual interest
//

import SwiftUI

struct MeshGradientBackground: View {
    let colors: [Color]
    let animated: Bool

    @State private var phase: Double = 0

    init(colors: [Color] = [.blue, .purple, .pink], animated: Bool = true) {
        self.colors = colors
        self.animated = animated
    }

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

            // Animated gradient orbs
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 400
                        )
                    )
                    .frame(width: 800, height: 800)
                    .offset(
                        x: orbitX(for: index),
                        y: orbitY(for: index)
                    )
                    .blur(radius: 80)
            }
        }
        .onAppear {
            if animated {
                withAnimation(
                    .linear(duration: 30)
                    .repeatForever(autoreverses: true)
                ) {
                    phase = .pi * 2
                }
            }
        }
    }

    private func orbitX(for index: Int) -> CGFloat {
        let baseOffset: CGFloat = [100, -150, 50][index % 3]
        let amplitude: CGFloat = [60, 50, 70][index % 3]
        return baseOffset + amplitude * CGFloat(sin(phase + Double(index) * 0.8))
    }

    private func orbitY(for index: Int) -> CGFloat {
        let baseOffset: CGFloat = [50, -100, 100][index % 3]
        let amplitude: CGFloat = [50, 60, 40][index % 3]
        return baseOffset + amplitude * CGFloat(cos(phase + Double(index) * 1.2))
    }
}

struct StaticGradientOrbs: View {
    var body: some View {
        ZStack {
            // Top-left orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.blue.opacity(0.2), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 500
                    )
                )
                .offset(x: -200, y: -200)
                .blur(radius: 60)

            // Bottom-right orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.purple.opacity(0.15), .clear],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 500
                    )
                )
                .offset(x: 200, y: 200)
                .blur(radius: 60)

            // Center orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.pink.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .blur(radius: 80)
        }
    }
}
