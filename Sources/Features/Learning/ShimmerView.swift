//
//  ShimmerView.swift
//  QuickMathsAR
//


import SwiftUI

/// Shimmer placeholder that mimics the shape of explanation content.
/// Shows lines of varying width with a traveling gradient.
struct ShimmerView: View {
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationPhase: CGFloat = -1.0
    
    /// Number of placeholder lines to display
    let lineCount: Int
    
    init(lineCount: Int = 4) {
        self.lineCount = lineCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<lineCount, id: \.self) { index in
                shimmerLine(widthFraction: lineWidth(for: index))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                animationPhase = 2.0
            }
        }
        .accessibilityLabel("Loading explanation")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - Private
    
    private func shimmerLine(widthFraction: CGFloat) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 4)
                .fill(shimmerGradient(width: geometry.size.width))
                .frame(width: geometry.size.width * widthFraction)
        }
        .frame(height: 12)
    }
    
    private func shimmerGradient(width: CGFloat) -> some ShapeStyle {
        if reduceMotion {
            // Static shimmer for reduce motion
            return AnyShapeStyle(Color(.systemGray5))
        }
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color(.systemGray5),
                    Color(.systemGray4),
                    Color(.systemGray5)
                ],
                startPoint: UnitPoint(x: animationPhase - 0.5, y: 0.5),
                endPoint: UnitPoint(x: animationPhase, y: 0.5)
            )
        )
    }
    
    /// Vary line widths to look natural (like text of different lengths)
    private func lineWidth(for index: Int) -> CGFloat {
        switch index % 4 {
        case 0: return 1.0
        case 1: return 0.85
        case 2: return 0.92
        case 3: return 0.6
        default: return 0.8
        }
    }
}

#Preview("Shimmer Loading") {
    VStack(spacing: 20) {
        ShimmerView()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding()
        
        ShimmerView(lineCount: 2)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding()
    }
}
