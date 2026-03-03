//
//  MissionStatementView.swift
//  QuickMathsAR
//
//  Displays the mission framing for a learning example
//

#if os(iOS)
import SwiftUI

/// A view that displays the before → after mission framing with narrative text
public struct MissionStatementView: View {
    let missionStatement: MissionStatement

    @State private var showNarrative = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(missionStatement: MissionStatement) {
        self.missionStatement = missionStatement
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Before → After transformation
            HStack(spacing: 12) {
                // Before state
                equationBubble(missionStatement.before, label: "Start", color: .orange)

                // Arrow
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                // After state
                equationBubble(missionStatement.after, label: "Goal", color: .green)
            }
            .padding(.horizontal)

            // Narrative
            if showNarrative {
                Text(missionStatement.narrative)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .onAppear {
            if reduceMotion {
                showNarrative = true
            } else {
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                    showNarrative = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mission: Transform \(missionStatement.before) to find \(missionStatement.after). \(missionStatement.narrative)")
    }

    private func equationBubble(_ equation: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(equation)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Preview

#Preview {
    MissionStatementView(
        missionStatement: MissionStatement(
            before: "2x + 5 = 13",
            after: "x = ?",
            narrative: "x is doubled then increased by 5. Peel away the layers."
        )
    )
    .padding()
}
#endif
