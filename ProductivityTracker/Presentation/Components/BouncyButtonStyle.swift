//
//  BouncyButtonStyle.swift
//  ProductivityTracker
//
//  Tactile button style with press animation
//

import SwiftUI

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PressableButtonStyle: ButtonStyle {
    let pressDepth: CGFloat
    let cornerRadius: CGFloat

    init(pressDepth: CGFloat = 2, cornerRadius: CGFloat = 10) {
        self.pressDepth = pressDepth
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
            )
            .offset(y: configuration.isPressed ? pressDepth : 0)
            .shadow(
                color: .black.opacity(0.2),
                radius: configuration.isPressed ? 2 : 8,
                y: configuration.isPressed ? 1 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BouncyButtonStyle {
    static var bouncy: BouncyButtonStyle {
        BouncyButtonStyle()
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle {
        PressableButtonStyle()
    }
}
