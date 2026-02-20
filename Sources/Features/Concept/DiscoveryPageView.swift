//
//  DiscoveryPageView.swift
//  QuickMathsAR
//
//  Interactive discovery page with visual element and insight reveal
//

#if os(iOS)
import SwiftUI

/// Discovery page with interactive element and insight reveal
struct DiscoveryPageView: View {
    let page: ConceptFlowPage
    let accentColor: Color

    @State private var showInsight = false
    @State private var interactionComplete = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height > 700 ? 24 : 16) {
                // Title
                if let title = page.title {
                    Text(title)
                        .font(.system(size: min(geometry.size.height > 700 ? 24 : 20, 24), weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 20)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Interactive element
                interactiveElement
                    .frame(height: min(geometry.size.height * 0.35, 200))

                // Insight reveal
                if showInsight, let insight = page.insight {
                    InsightCard(text: insight, accentColor: accentColor)
                        .padding(.horizontal, 20)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }

                Spacer(minLength: 20)

                // Interaction hint
                if !interactionComplete {
                    Text(hintText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title ?? "Discovery"). \(page.insight ?? "")")
    }

    @ViewBuilder
    private var interactiveElement: some View {
        switch page.interaction {
        case "add_remove_weights":
            WeightInteraction(accentColor: accentColor) {
                triggerInsight()
            }
        case "slider_coefficients":
            CoefficientSliders(accentColor: accentColor) {
                triggerInsight()
            }
        default:
            // Fallback: tap to reveal
            TapToRevealElement(accentColor: accentColor) {
                triggerInsight()
            }
        }
    }

    private var hintText: String {
        switch page.interaction {
        case "add_remove_weights":
            return "Tap to add or remove weights"
        case "slider_coefficients":
            return "Drag the sliders to see how the curve changes"
        default:
            return "Tap to discover"
        }
    }

    private func triggerInsight() {
        interactionComplete = true
        HapticManager.shared.success()

        if reduceMotion {
            showInsight = true
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showInsight = true
            }
        }
    }
}

// MARK: - Insight Card

private struct InsightCard: View {
    let text: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.title3)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .safeBody(alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Weight Interaction

private struct WeightInteraction: View {
    let accentColor: Color
    let onComplete: () -> Void

    @State private var leftWeight = 2
    @State private var rightWeight = 2
    @State private var hasInteracted = false

    var body: some View {
        VStack(spacing: 16) {
            // Scale visualization
            HStack(spacing: 40) {
                // Left side
                VStack {
                    Text("Left")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    WeightStack(count: leftWeight, color: .blue)

                    Button {
                        leftWeight = min(5, leftWeight + 1)
                        checkBalance()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(accentColor)
                    }
                }

                // Equals sign
                Text("=")
                    .font(.title)
                    .foregroundStyle(isBalanced ? .green : .orange)

                // Right side
                VStack {
                    Text("Right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    WeightStack(count: rightWeight, color: .green)

                    Button {
                        rightWeight = min(5, rightWeight + 1)
                        checkBalance()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(accentColor)
                    }
                }
            }

            // Balance indicator
            Text(isBalanced ? "Balanced! ✓" : "Not balanced")
                .font(.caption)
                .foregroundStyle(isBalanced ? .green : .orange)
        }
    }

    private var isBalanced: Bool {
        leftWeight == rightWeight
    }

    private func checkBalance() {
        if !hasInteracted {
            hasInteracted = true
            onComplete()
        }
    }
}

private struct WeightStack: View {
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .fill(color.opacity(0.7))
                    .frame(width: 20, height: 20)
            }
        }
        .frame(height: 30)
    }
}

// MARK: - Coefficient Sliders

private struct CoefficientSliders: View {
    let accentColor: Color
    let onComplete: () -> Void

    @State private var aValue: Double = 1.0
    @State private var hasInteracted = false

    var body: some View {
        VStack(spacing: 20) {
            // Mini parabola
            ParabolaPreview(a: aValue, accentColor: accentColor)
                .frame(height: 100)

            // Slider for 'a'
            VStack(alignment: .leading, spacing: 8) {
                Text("a = \(aValue, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: $aValue, in: -2...2, step: 0.1) { editing in
                    if !hasInteracted && !editing {
                        hasInteracted = true
                        onComplete()
                    }
                }
                .tint(accentColor)
            }
            .padding(.horizontal)
        }
    }
}

private struct ParabolaPreview: View {
    let a: Double
    let accentColor: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midY = height / 2

                path.move(to: CGPoint(x: 0, y: midY + a * 50))

                for x in stride(from: 0, through: width, by: 2) {
                    let normalizedX = (x - width / 2) / 50
                    let y = midY - a * normalizedX * normalizedX * 10
                    path.addLine(to: CGPoint(x: x, y: max(0, min(height, y))))
                }
            }
            .stroke(accentColor, lineWidth: 3)
        }
    }
}

// MARK: - Tap to Reveal

private struct TapToRevealElement: View {
    let accentColor: Color
    let onComplete: () -> Void

    @State private var revealed = false

    var body: some View {
        Button {
            revealed = true
            onComplete()
        } label: {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 100, height: 100)

                if revealed {
                    Image(systemName: "checkmark")
                        .font(.largeTitle)
                        .foregroundStyle(accentColor)
                } else {
                    Image(systemName: "hand.tap.fill")
                        .font(.largeTitle)
                        .foregroundStyle(accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DiscoveryPageView(
        page: ConceptFlowPage(
            page: "discovery",
            title: "Keep it balanced",
            visual: "interactive_scale",
            interaction: "add_remove_weights",
            insight: "Whatever you do to one side, you must do to the other."
        ),
        accentColor: .blue
    )
}
#endif
