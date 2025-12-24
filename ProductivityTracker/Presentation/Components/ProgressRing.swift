//
//  ProgressRing.swift
//  ProductivityTracker
//
//  Circular progress ring with glow effect
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let lineWidth: CGFloat
    let showPercentage: Bool

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        color: Color = .blue,
        lineWidth: CGFloat = 12,
        showPercentage: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            color,
                            color.opacity(0.8),
                            color,
                            color.opacity(0.6),
                            color
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: lineWidth / 2)
                .shadow(color: color.opacity(0.3), radius: lineWidth)

            // Percentage text
            if showPercentage {
                VStack(spacing: 2) {
                    AnimatedIntText(
                        value: Int(animatedProgress * 100),
                        font: .system(size: 28, weight: .bold, design: .rounded)
                    )

                    Text("%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

struct MultiProgressRing: View {
    let segments: [(progress: Double, color: Color)]
    let lineWidth: CGFloat

    @State private var animatedSegments: [Double] = []

    init(segments: [(Double, Color)], lineWidth: CGFloat = 10) {
        self.segments = segments
        self.lineWidth = lineWidth
        _animatedSegments = State(initialValue: Array(repeating: 0, count: segments.count))
    }

    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Segments
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                let startAngle = previousProgress(upTo: index)

                Circle()
                    .trim(
                        from: startAngle,
                        to: startAngle + animatedSegments[index]
                    )
                    .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: segment.color.opacity(0.3), radius: lineWidth / 2)
            }
        }
        .onAppear {
            animateSegments()
        }
        .onChange(of: segments.map { $0.progress }) { _, _ in
            animateSegments()
        }
    }

    private func previousProgress(upTo index: Int) -> Double {
        guard index > 0 else { return 0 }
        return segments[0..<index].reduce(0) { $0 + $1.progress }
    }

    private func animateSegments() {
        for (index, segment) in segments.enumerated() {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                animatedSegments[index] = segment.progress
            }
        }
    }
}

struct ProgressRingPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            ProgressRing(progress: 0.75, color: .blue)
                .frame(width: 120, height: 120)

            ProgressRing(progress: 0.45, color: .green, showPercentage: false)
                .frame(width: 100, height: 100)

            MultiProgressRing(
                segments: [
                    (0.4, .blue),
                    (0.3, .green),
                    (0.2, .purple),
                    (0.1, .orange)
                ]
            )
            .frame(width: 150, height: 150)
        }
        .padding()
    }
}
