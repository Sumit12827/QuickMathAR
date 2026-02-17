//
//  InsightStripView.swift
//  QuickMathsAR
//
//  Animated contextual feedback strip that displays educational insights.
//

import SwiftUI

/// Displays a contextual insight message with animation.
/// Position: Fixed below the equation display, never overlapping controls.
struct InsightStripView: View {
    let insight: InsightMessage?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let insight = insight {
                HStack(spacing: 10) {
                    Image(systemName: insight.iconName)
                        .font(.subheadline)
                        .foregroundStyle(iconColor(for: insight.type))

                    Text(insight.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundColor(for: insight.type))
                )
                .transition(
                    reduceMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel(insight.text)
                .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.15)
                : .spring(response: 0.35, dampingFraction: 0.75),
            value: insight?.id
        )
        .frame(minHeight: 36)
    }

    // MARK: - Helpers

    private func iconColor(for type: InsightType) -> Color {
        switch type {
        case .guidance:      return .blue
        case .explanation:   return .indigo
        case .celebration:   return .green
        case .gentleNudge:   return .orange
        }
    }

    private func backgroundColor(for type: InsightType) -> Color {
        switch type {
        case .guidance:      return .blue.opacity(0.08)
        case .explanation:   return .indigo.opacity(0.08)
        case .celebration:   return .green.opacity(0.08)
        case .gentleNudge:   return .orange.opacity(0.08)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        InsightStripView(insight: InsightMessage(
            text: "Variable added — x is the unknown we'll solve for.",
            type: .explanation,
            iconName: "questionmark.circle"
        ))

        InsightStripView(insight: InsightMessage(
            text: "Equation formed — both sides must balance.",
            type: .celebration,
            iconName: "equal.circle"
        ))

        InsightStripView(insight: InsightMessage(
            text: "An equation usually starts with a variable or number.",
            type: .gentleNudge,
            iconName: "hand.wave"
        ))
    }
    .padding()
}
