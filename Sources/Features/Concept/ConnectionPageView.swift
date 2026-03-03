//
//  ConnectionPageView.swift
//  QuickMathsAR
//
//  Displays real-world application scenarios as tappable cards
//

#if os(iOS)
import SwiftUI

/// Connection page showing real-world applications
struct ConnectionPageView: View {
    let page: ConceptFlowPage
    let accentColor: Color

    @State private var expandedScenario: Int? = nil

    var body: some View {
        VStack(spacing: 14) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.title)
                    .foregroundStyle(accentColor)

                Text("Real-World Connections")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Scenario cards
            if let scenarios = page.scenarios {
                ForEach(Array(scenarios.enumerated()), id: \.offset) { index, scenario in
                    ScenarioCard(
                        scenario: scenario,
                        isExpanded: expandedScenario == index,
                        accentColor: accentColor
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if expandedScenario == index {
                                expandedScenario = nil
                            } else {
                                expandedScenario = index
                                HapticManager.shared.light()
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 20)
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Real-world connections")
    }
}

// MARK: - Scenario Card

private struct ScenarioCard: View {
    let scenario: ConnectionScenario
    let isExpanded: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(spacing: 12) {
                    Text(scenario.icon)
                        .font(.title2)

                    Text(scenario.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .safeInline()

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        if let equation = scenario.equation {
                            Text(equation)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(accentColor)
                        }

                        if let description = scenario.description {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .safeCaption(alignment: .leading)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scenario.title). \(scenario.description ?? "")")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
    }
}

// MARK: - Preview

#Preview {
    ConnectionPageView(
        page: ConceptFlowPage(
            page: "connection",
            scenarios: [
                ConnectionScenario(icon: "🚗", title: "Road trip", equation: "distance = speed × time", description: "Calculate travel time"),
                ConnectionScenario(icon: "💰", title: "Savings", equation: "total = deposit + interest", description: "Track your money"),
                ConnectionScenario(icon: "🌡️", title: "Temperature", equation: "F = (9/5)C + 32", description: "Convert between scales")
            ]
        ),
        accentColor: .blue
    )
    .padding()
}
#endif
