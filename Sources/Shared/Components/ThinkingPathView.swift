//
//  ThinkingPathView.swift
//  QuickMathsAR
//
//  Displays the visual thinking path as connected steps before the solution
//

import SwiftUI

/// A view that displays the thinking path as connected nodes
public struct ThinkingPathView: View {
    let steps: [String]

    @State private var visibleSteps: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(steps: [String]) {
        self.steps = steps
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Thinking Path")
                    .font(.headline)
            }
            .padding(.bottom, 12)

            // Steps
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                ThinkingStepRow(
                    step: step,
                    stepNumber: index + 1,
                    isLast: index == steps.count - 1,
                    isVisible: index < visibleSteps
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .onAppear {
            animateSteps()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Thinking path with \(steps.count) steps: \(steps.joined(separator: ", "))")
    }

    private func animateSteps() {
        if reduceMotion {
            visibleSteps = steps.count
        } else {
            for i in 0..<steps.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        visibleSteps = i + 1
                    }
                }
            }
        }
    }
}

// MARK: - Step Row

private struct ThinkingStepRow: View {
    let step: String
    let stepNumber: Int
    let isLast: Bool
    let isVisible: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Connector line and dot
            VStack(spacing: 0) {
                // Step dot
                Circle()
                    .fill(isVisible ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)

                // Connector line (not for last item)
                if !isLast {
                    Rectangle()
                        .fill(isVisible ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(height: 24)
                }
            }

            // Step text
            Text(step)
                .font(.subheadline)
                .foregroundStyle(isVisible ? Color.primary : Color.secondary.opacity(0.5))
                .padding(.bottom, isLast ? 0 : 16)
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : -10)
        }
    }
}

// MARK: - Preview

#Preview {
    ThinkingPathView(steps: [
        "Identify what's around x",
        "Use inverse operations",
        "Keep the scale balanced",
        "Simplify to find x"
    ])
    .padding()
}
