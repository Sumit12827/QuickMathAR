//
//  UnknownEquationView.swift
//  QuickMathsAR
//
//  Displays encouraging guidance when an equation can't be classified
//

import SwiftUI

/// A view that displays guidance for unrecognized equation types
/// Provides encouragement and suggests foundational concepts to review
struct UnknownEquationView: View {
    
    // MARK: - Properties
    
    /// The unknown equation content to display
    let content: UnknownEquationContent
    
    /// The equation that couldn't be classified (if available)
    let equation: String?
    
    /// Action to navigate to a foundational concept
    var onSelectConcept: ((String) -> Void)?
    
    /// Action to try scanning again
    var onTryAgain: (() -> Void)?
    
    // MARK: - Environment
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Computed Properties
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : 20
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header illustration
                headerSection
                
                // Equation display (if available)
                if let equation = equation, !equation.isEmpty {
                    equationCard(equation)
                }
                
                // Explanation card
                explanationCard
                
                // Encouragement card
                encouragementCard
                
                // Suggested foundations
                foundationsSection
                
                // Next steps
                nextStepsSection
                
                // Try again button
                if onTryAgain != nil {
                    tryAgainButton
                }
                
                // Bottom spacing
                Spacer(minLength: 40)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(content.displayName)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "questionmark.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.orange)
                .frame(width: 88, height: 88)
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                )
            
            // Subtitle
            Text("Don't worry—this is a learning opportunity!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeBody()
        }
    }
    
    // MARK: - Equation Card
    
    private func equationCard(_ equation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Your Equation")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "function")
                    .foregroundStyle(.secondary)
            }
            
            Text(equation)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }
    
    // MARK: - Explanation Card
    
    private var explanationCard: some View {
        LearningCard(
            title: "Why Can't We Classify This?",
            icon: "info.circle",
            iconColor: .blue
        ) {
            Text(content.explanation)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .safeBody(alignment: .leading)
        }
    }

    // MARK: - Encouragement Card

    private var encouragementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.yellow)

                Text("Keep Going!")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .safeTitle(minScale: 0.85, alignment: .leading)
            }

            Text(content.encouragement)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .safeBody(alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Foundations Section
    
    private var foundationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Review These Foundations")
                    .font(.headline)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "book")
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 4)
            
            // Foundation concept buttons
            VStack(spacing: 8) {
                ForEach(content.suggestedFoundations, id: \.self) { conceptId in
                    FoundationButton(
                        conceptId: conceptId,
                        action: { onSelectConcept?(conceptId) }
                    )
                }
            }
        }
    }
    
    // MARK: - Next Steps Section
    
    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("What You Can Do")
                    .font(.headline)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "checklist")
                    .foregroundStyle(.purple)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(content.nextSteps.enumerated()), id: \.offset) { index, step in
                    NextStepRow(
                        number: index + 1,
                        text: step,
                        isLast: index == content.nextSteps.count - 1
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - Try Again Button
    
    private var tryAgainButton: some View {
        Button(action: {
            onTryAgain?()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "camera")
                Text("Scan Again")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 400)
    }
}

// MARK: - Foundation Button

/// A button to navigate to a foundational concept
struct FoundationButton: View {
    let conceptId: String
    let action: () -> Void
    
    private var displayName: String {
        conceptId.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private var icon: String {
        switch conceptId {
        case "addition": return "plus"
        case "subtraction": return "minus"
        case "multiplication": return "multiply"
        case "division": return "divide"
        case "order_of_operations": return "parentheses"
        default: return "function"
        }
    }
    
    private var color: Color {
        switch conceptId {
        case "addition": return .green
        case "subtraction": return .orange
        case "multiplication": return .blue
        case "division": return .purple
        case "order_of_operations": return .pink
        default: return .teal
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                Text(displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Next Step Row

/// A row displaying a next step suggestion
struct NextStepRow: View {
    let number: Int
    let text: String
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.7))
                    )
                
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .safeBody(alignment: .leading)

                Spacer()
            }
            .padding(14)
            
            if !isLast {
                Divider()
                    .padding(.leading, 46)
            }
        }
    }
}

// MARK: - Preview

#Preview("Unknown Equation") {
    NavigationStack {
        UnknownEquationView(
            content: UnknownEquationContent(
                version: "1.0",
                equationType: "unknown",
                displayName: "Unrecognized Equation",
                explanation: "Some equations don't fit into the categories we can recognize and explain step by step. This doesn't mean there's anything wrong—mathematics includes many types of equations.",
                encouragement: "Not being able to classify an equation is actually a great learning moment! The best way to prepare for these is to make sure you have a strong foundation in the basics.",
                suggestedFoundations: ["addition", "subtraction", "multiplication", "division"],
                reasonsForUnknown: [
                    UnknownReason(reason: "Higher-degree polynomials", explanation: "Equations with x³, x⁴, or higher powers."),
                    UnknownReason(reason: "Trigonometric functions", explanation: "Equations with sin, cos, tan.")
                ],
                nextSteps: [
                    "Review the foundational arithmetic concepts.",
                    "Practice with linear equations until they feel natural.",
                    "Try scanning the equation again with better lighting."
                ],
                arAvailable: false
            ),
            equation: "sin(x) + 2 = 0",
            onSelectConcept: { _ in },
            onTryAgain: {}
        )
    }
}
