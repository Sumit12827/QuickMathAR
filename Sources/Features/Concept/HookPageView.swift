//
//  HookPageView.swift
//  QuickMathsAR
//
//  Full-screen hook page with animated visual and title fade-in
//

import SwiftUI

/// The opening hook page that captures attention
struct HookPageView: View {
    let page: ConceptFlowPage
    let accentColor: Color

    @State private var showTitle = false
    @State private var animateVisual = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height > 700 ? 32 : 24) {
                Spacer()

                // Visual element
                visualElement
                    .frame(height: min(geometry.size.height * 0.25, 150))
                    .scaleEffect(animateVisual ? 1.0 : 0.8)
                    .opacity(animateVisual ? 1.0 : 0.0)

                // Title
                if let title = page.title {
                    Text(title)
                        .font(.system(size: min(geometry.size.height > 700 ? 28 : 24, 28), weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(showTitle ? 1.0 : 0.0)
                        .offset(y: showTitle ? 0 : 20)
                }

                Spacer(minLength: 24)

                // Hint to continue
                Text("Swipe to continue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
                    .opacity(showTitle ? 0.6 : 0.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(page.title ?? "Hook page")
    }

    @ViewBuilder
    private var visualElement: some View {
        switch page.visual {
        case "animated_balance_scale":
            BalanceScaleVisual(accentColor: accentColor)
        case "animated_fountain":
            FountainVisual(accentColor: accentColor)
        default:
            // Generic visual
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(accentColor.gradient)
        }
    }

    private func startAnimation() {
        if reduceMotion {
            animateVisual = true
            showTitle = true
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateVisual = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showTitle = true
            }
        }
    }
}

// MARK: - Balance Scale Visual

private struct BalanceScaleVisual: View {
    let accentColor: Color
    @State private var tilt: Double = 0

    var body: some View {
        ZStack {
            // Base
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 4, height: 80)
                .offset(y: 40)

            // Arm
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 160, height: 6)
                .rotationEffect(.degrees(tilt))

            // Left pan
            Circle()
                .fill(accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .strokeBorder(accentColor, lineWidth: 2)
                )
                .offset(x: -60, y: tilt > 0 ? 10 : -10)

            // Right pan
            Circle()
                .fill(accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .strokeBorder(accentColor, lineWidth: 2)
                )
                .offset(x: 60, y: tilt > 0 ? -10 : 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                tilt = 5
            }
        }
    }
}

// MARK: - Fountain Visual

private struct FountainVisual: View {
    let accentColor: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            // Parabola path
            ParabolaShape()
                .stroke(
                    accentColor.gradient,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 120, height: 80)

            // Animated dot
            Circle()
                .fill(accentColor)
                .frame(width: 12, height: 12)
                .offset(x: animate ? 60 : -60, y: animate ? 0 : 0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .onAppear {
            animate = true
        }
    }
}

private struct ParabolaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startX = rect.minX
        let endX = rect.maxX
        let midX = rect.midX
        let topY = rect.minY
        let bottomY = rect.maxY

        path.move(to: CGPoint(x: startX, y: bottomY))
        path.addQuadCurve(
            to: CGPoint(x: endX, y: bottomY),
            control: CGPoint(x: midX, y: topY)
        )

        return path
    }
}

// MARK: - Preview

#Preview {
    HookPageView(
        page: ConceptFlowPage(
            page: "hook",
            title: "Whatever you do, do it on both sides",
            visual: "animated_balance_scale",
            interaction: "tap_to_reveal"
        ),
        accentColor: .blue
    )
}
