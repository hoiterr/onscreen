//
//  AnimatedNumberText.swift
//  ProductivityTracker
//
//  Smoothly animated number text that counts up/down
//

import SwiftUI

struct AnimatedNumberText: View {
    let value: Double
    let format: NumberFormatStyle

    @State private var displayValue: Double = 0

    init(value: Double, format: NumberFormatStyle = .number.precision(.fractionLength(0))) {
        self.value = value
        self.format = format
    }

    var body: some View {
        Text(displayValue, format: format)
            .contentTransition(.numericText(value: displayValue))
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            }
    }
}

// For duration formatting
struct AnimatedDurationText: View {
    let duration: TimeInterval

    @State private var displayDuration: TimeInterval = 0

    var body: some View {
        Text(formatDuration(displayDuration))
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    displayDuration = duration
                }
            }
            .onChange(of: duration) { oldValue, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayDuration = newValue
                }
            }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// For integer counts
struct AnimatedIntText: View {
    let value: Int
    let font: Font

    @State private var displayValue: Int = 0

    init(value: Int, font: Font = .body) {
        self.value = value
        self.font = font
    }

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .contentTransition(.numericText(value: Double(displayValue)))
            .onAppear {
                animateCount(from: 0, to: value)
            }
            .onChange(of: value) { oldValue, newValue in
                animateCount(from: oldValue, to: newValue)
            }
    }

    private func animateCount(from start: Int, to end: Int) {
        let steps = 30
        let duration = 0.8
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            let delay = Double(step) * stepDuration
            let value = start + Int(Double(end - start) * Double(step) / Double(steps))

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                displayValue = value
            }
        }
    }
}
