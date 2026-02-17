//
//  BalanceScaleView.swift
//  QuickMathsAR
//
//  Interactive balance scale for visualizing equation operations
//

import SwiftUI

struct BalanceScaleView: View {
    let leftSide: String
    let rightSide: String

    @State private var leftValue: Double = 0
    @State private var rightValue: Double = 0
    @State private var tiltAngle: Double = 0
    @State private var isBalanced: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            let fontSize = min(24, geometry.size.width * 0.06)
            let scaleWidth = min(280, geometry.size.width - 40)

            ScrollView {
                VStack(spacing: 20) {
                    // Equation display
                    HStack(spacing: 8) {
                        Text(leftSide)
                            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                            .foregroundStyle(.blue)
                            .safeInline(minScale: 0.7)

                        Text("=")
                            .font(.system(size: fontSize, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(rightSide)
                            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                            .foregroundStyle(.purple)
                            .safeInline(minScale: 0.7)
                    }
                    .padding()
                    .frame(maxWidth: contentWidth)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    // Scale visualization
                    ZStack {
                        // Base/stand
                        ScaleStand()

                        // Balance beam
                        ScaleBeam(tiltAngle: tiltAngle, width: scaleWidth)

                        // Left pan
                        ScalePan(side: .left, content: leftSide, tiltAngle: tiltAngle, xOffset: -scaleWidth * 0.43)

                        // Right pan
                        ScalePan(side: .right, content: rightSide, tiltAngle: tiltAngle, xOffset: scaleWidth * 0.43)
                    }
                    .frame(maxWidth: contentWidth)
                    .frame(height: 200)

                    // Balance indicator
                    HStack(spacing: 8) {
                        Image(systemName: isBalanced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(isBalanced ? .green : .orange)

                        Text(isBalanced ? "Balanced!" : "Not balanced - do the same to both sides")
                            .font(.subheadline)
                            .foregroundStyle(isBalanced ? .green : .orange)
                            .safeCaption()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: contentWidth)
                    .background(
                        Capsule()
                            .fill((isBalanced ? Color.green : Color.orange).opacity(0.1))
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }

    func applyOperation(_ operation: String, value: Double, toSide side: Side) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            switch side {
            case .left:
                leftValue += value
            case .right:
                rightValue += value
            }

            updateBalance()
        }
    }

    func applyToBothSides(_ operation: String, value: Double) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            leftValue += value
            rightValue += value
            updateBalance()
        }

        HapticManager.shared.success()
    }

    private func updateBalance() {
        let difference = leftValue - rightValue
        tiltAngle = max(-15, min(15, difference * 3))
        isBalanced = abs(difference) < 0.1
    }

    enum Side {
        case left, right
    }
}

// MARK: - Scale Components

private struct ScaleStand: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Vertical post
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 12, height: 100)

            // Base
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 80, height: 20)
        }
    }
}

private struct ScaleBeam: View {
    let tiltAngle: Double
    var width: CGFloat = 280

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [.brown.opacity(0.8), .brown.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: 12)
            .rotationEffect(.degrees(tiltAngle))
            .offset(y: -50)
    }
}

private struct ScalePan: View {
    let side: BalanceScaleView.Side
    let content: String
    let tiltAngle: Double
    var xOffset: CGFloat = 120

    private var computedXOffset: CGFloat {
        side == .left ? -abs(xOffset) : abs(xOffset)
    }

    private var yOffset: CGFloat {
        let baseTilt = side == .left ? tiltAngle : -tiltAngle
        return -30 + CGFloat(baseTilt * 2)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Strings
            Rectangle()
                .fill(.gray.opacity(0.4))
                .frame(width: 2, height: 30)

            // Pan
            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [.gray.opacity(0.4), .gray.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 20)

                Text(content)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(side == .left ? .blue : .purple)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .offset(y: -20)
            }
        }
        .offset(x: computedXOffset, y: yOffset)
    }
}

#Preview {
    BalanceScaleView(leftSide: "2x + 5", rightSide: "13")
        .padding()
}
