//
//  ChartAnimations.swift
//  ProductivityTracker
//
//  Enhanced animations for Swift Charts and data visualizations
//

import SwiftUI
import Charts

// MARK: - Animated Chart Container

struct AnimatedChartContainer<Content: View>: View {
    let content: Content
    let delay: Double

    @State private var isVisible: Bool = false

    init(delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.delay = delay
        self.content = content()
    }

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Staggered Bar Data

struct StaggeredChartData: Identifiable {
    let id: UUID
    let value: Double
    let label: String
    let color: Color
    var animationDelay: Double = 0

    init(value: Double, label: String, color: Color, delay: Double = 0) {
        self.id = UUID()
        self.value = value
        self.label = label
        self.color = color
        self.animationDelay = delay
    }
}

// MARK: - Animated Bar Chart

struct AnimatedBar: View {
    let height: CGFloat
    let color: Color
    let delay: Double

    @State private var animatedHeight: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: animatedHeight)
            .shadow(color: color.opacity(0.3), radius: 8, y: 4)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay)) {
                    animatedHeight = height
                }
            }
            .onChange(of: height) { newHeight in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animatedHeight = newHeight
                }
            }
    }
}

// MARK: - Animated Donut Chart

struct AnimatedDonutSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let delay: Double

    @State private var animatedEndAngle: Angle

    init(startAngle: Angle, endAngle: Angle, color: Color, delay: Double = 0) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.color = color
        self.delay = delay
        self._animatedEndAngle = State(initialValue: startAngle)
    }

    var body: some View {
        Circle()
            .trim(from: startAngle.radians / (2 * .pi), to: animatedEndAngle.radians / (2 * .pi))
            .stroke(
                AngularGradient(
                    colors: [color, color.opacity(0.7), color],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 40, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .onAppear {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(delay)) {
                    animatedEndAngle = endAngle
                }
            }
            .onChange(of: endAngle) { newAngle in
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    animatedEndAngle = newAngle
                }
            }
    }
}

// MARK: - Animated Line Path

struct AnimatedLinePath: Shape {
    var progress: CGFloat
    let points: [CGPoint]

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }

        var path = Path()
        let totalPoints = CGFloat(points.count - 1)
        let visiblePoints = Int(totalPoints * progress)

        if visiblePoints > 0 {
            path.move(to: points[0])

            for i in 1...min(visiblePoints, points.count - 1) {
                path.addLine(to: points[i])
            }

            // Interpolate the last segment
            if visiblePoints < points.count - 1 {
                let fraction = (totalPoints * progress) - CGFloat(visiblePoints)
                let start = points[visiblePoints]
                let end = points[visiblePoints + 1]
                let interpolated = CGPoint(
                    x: start.x + (end.x - start.x) * fraction,
                    y: start.y + (end.y - start.y) * fraction
                )
                path.addLine(to: interpolated)
            }
        }

        return path
    }
}

struct AnimatedLineChart: View {
    let points: [CGPoint]
    let color: Color

    @State private var progress: CGFloat = 0

    var body: some View {
        AnimatedLinePath(progress: progress, points: points)
            .stroke(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: color.opacity(0.4), radius: 4, y: 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    progress = 1.0
                }
            }
    }
}

// MARK: - Pulsing Data Point

struct PulsingDataPoint: View {
    let color: Color
    let size: CGFloat

    @State private var isPulsing: Bool = false

    init(color: Color, size: CGFloat = 12) {
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 0.5)

            // Inner dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.6), radius: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Chart Highlight Effect

struct ChartHighlightModifier: ViewModifier {
    @Binding var isHighlighted: Bool
    let color: Color

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .shadow(color: isHighlighted ? color.opacity(0.5) : .clear, radius: isHighlighted ? 16 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }
}

extension View {
    func chartHighlight(isHighlighted: Binding<Bool>, color: Color = .blue) -> some View {
        modifier(ChartHighlightModifier(isHighlighted: isHighlighted, color: color))
    }
}

// MARK: - Morphing Number Display

struct MorphingNumberDisplay: View {
    let value: Double
    let suffix: String
    let color: Color

    @State private var displayValue: Double = 0

    init(value: Double, suffix: String = "", color: Color = .primary) {
        self.value = value
        self.suffix = suffix
        self.color = color
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(String(format: "%.0f", displayValue))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .contentTransition(.numericText(value: displayValue))

            if !suffix.isEmpty {
                Text(suffix)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color.opacity(0.7))
            }
        }
        .onAppear {
            animateValue()
        }
        .onChange(of: value) { _ in
            animateValue()
        }
    }

    private func animateValue() {
        let steps = 60
        let duration = 1.5
        let stepDuration = duration / Double(steps)
        let startValue = displayValue

        for step in 0...steps {
            let delay = Double(step) * stepDuration
            let progress = Double(step) / Double(steps)
            let easedProgress = easeOutExpo(progress)
            let newValue = startValue + (value - startValue) * easedProgress

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: stepDuration)) {
                    displayValue = newValue
                }
            }
        }
    }

    private func easeOutExpo(_ x: Double) -> Double {
        x == 1.0 ? 1.0 : 1.0 - pow(2, -10 * x)
    }
}

// MARK: - Animated Grid Lines

struct AnimatedGridLines: View {
    let lineCount: Int
    let color: Color

    @State private var opacity: Double = 0

    init(lines: Int = 5, color: Color = .gray.opacity(0.2)) {
        self.lineCount = lines
        self.color = color
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<lineCount, id: \.self) { index in
                    Path { path in
                        let y = geometry.size.height * CGFloat(index) / CGFloat(lineCount - 1)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .opacity(opacity)
                    .animation(.easeIn(duration: 0.5).delay(Double(index) * 0.1), value: opacity)
                }
            }
        }
        .onAppear {
            opacity = 1.0
        }
    }
}

// MARK: - Chart Legend with Animation

struct AnimatedLegendItem: View {
    let color: Color
    let label: String
    let value: String
    let delay: Double

    @State private var isVisible: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 12, height: 12)
                .shadow(color: color.opacity(0.4), radius: 3)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Interactive Chart Tooltip

struct ChartTooltip: View {
    let title: String
    let value: String
    let color: Color

    @State private var scale: CGFloat = 0.8

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(12)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func animatedChart(delay: Double = 0) -> some View {
        AnimatedChartContainer(delay: delay) {
            self
        }
    }
}
