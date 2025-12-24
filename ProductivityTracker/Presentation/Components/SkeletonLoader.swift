//
//  SkeletonLoader.swift
//  ProductivityTracker
//
//  Elegant shimmer loading skeletons
//

import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.3)
                    .offset(x: phase * geometry.size.width)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

struct SkeletonBox: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.gray.opacity(0.2))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonText: View {
    let lineCount: Int
    let spacing: CGFloat

    init(lines: Int = 3, spacing: CGFloat = 8) {
        self.lineCount = lines
        self.spacing = spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lineCount, id: \.self) { index in
                SkeletonBox(
                    width: index == lineCount - 1 ? 120 : nil,
                    height: 12
                )
            }
        }
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonBox(width: 40, height: 40)
                Spacer()
            }

            SkeletonBox(width: 180, height: 32)
            SkeletonBox(width: 120, height: 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SkeletonDashboard: View {
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                SkeletonBox(width: 200, height: 40)
                Spacer()
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                SkeletonCard()
                SkeletonCard()
                SkeletonCard()
            }

            // Large cards
            VStack(spacing: 16) {
                SkeletonBox(width: nil, height: 200)
                    .cornerRadius(16)
                SkeletonBox(width: nil, height: 250)
                    .cornerRadius(16)
            }
        }
        .padding()
    }
}
