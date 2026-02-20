//
//  StepThroughInteraction.swift
//  QuickMathsAR
//
//  Interactive step-through for order of operations
//

#if os(iOS)
import SwiftUI
import UIKit

struct StepThroughInteraction: View {
    let config: [String: AnyCodableValue]?
    let onComplete: () -> Void

    @State private var currentStep: Int = 0
    @State private var expression: String = "2 + 3 x 4"
    @State private var steps: [OperationStep] = []
    @State private var highlightedPart: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Expression display
            VStack(spacing: 8) {
                Text("Evaluate:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(currentExpression)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .safeTitle(minScale: 0.7)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Steps indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }

            // Current step explanation
            if currentStep < steps.count {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Step \(currentStep + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)

                        Spacer()

                        Text(steps[currentStep].operation)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                            .safeInline(minScale: 0.8)
                    }

                    Text(steps[currentStep].explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .safeBody(alignment: .leading)

                    // Calculation display
                    HStack(spacing: 8) {
                        Text(steps[currentStep].before)
                            .foregroundStyle(.secondary)
                            .safeInline(minScale: 0.7)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.blue)
                        Text(steps[currentStep].after)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .safeInline(minScale: 0.7)
                    }
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }

            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentStep -= 1
                        }
                        HapticManager.shared.light()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentStep += 1
                        }
                        HapticManager.shared.medium()
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue, in: Capsule())
                    }
                } else if currentStep == steps.count - 1 {
                    Button {
                        onComplete()
                    } label: {
                        Label("Done", systemImage: "checkmark")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.green, in: Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .onAppear {
            loadConfig()
            setupSteps()
        }
    }

    private var currentExpression: String {
        if currentStep < steps.count {
            return steps[currentStep].displayExpression
        }
        return expression
    }

    private func loadConfig() {
        if let config = config {
            if let expr = config["expression"]?.stringValue {
                expression = expr
            }
        }
    }

    private func setupSteps() {
        // Default example: 2 + 3 x 4
        steps = [
            OperationStep(
                displayExpression: "2 + 3 x 4",
                operation: "Multiplication first",
                explanation: "Order of operations: multiply before adding",
                before: "3 x 4",
                after: "12"
            ),
            OperationStep(
                displayExpression: "2 + 12",
                operation: "Addition",
                explanation: "Now we can add the results",
                before: "2 + 12",
                after: "14"
            ),
            OperationStep(
                displayExpression: "= 14",
                operation: "Final Answer",
                explanation: "The expression evaluates to 14",
                before: "2 + 3 x 4",
                after: "14"
            )
        ]
    }
}

// MARK: - Operation Step

private struct OperationStep {
    let displayExpression: String
    let operation: String
    let explanation: String
    let before: String
    let after: String
}

#Preview {
    StepThroughInteraction(config: nil, onComplete: {})
        .padding()
}

#endif
