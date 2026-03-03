//
//  ArithmeticConceptView.swift
//  QuickMathsAR
//
//  Displays foundational arithmetic concepts in a calm, readable format
//

#if os(iOS)
import SwiftUI
import UIKit

/// A view that displays an arithmetic concept (addition, subtraction, etc.)
/// Presents the definition, relevance to equations, and conceptual examples
struct ArithmeticConceptView: View {
    
    // MARK: - Properties
    
    /// The arithmetic concept to display
    let concept: ArithmeticConcept
    
    // MARK: - Environment
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Computed Properties
    
    /// Horizontal padding based on size class
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : 20
    }
    
    /// Color for the concept based on its type
    private var conceptColor: Color {
        switch concept.id {
        case "addition":
            return .green
        case "subtraction":
            return .orange
        case "multiplication":
            return .blue
        case "division":
            return .purple
        case "order_of_operations":
            return .pink
        default:
            return .teal
        }
    }
    
    /// Icon for the concept
    private var conceptIcon: String {
        switch concept.id {
        case "addition":
            return "plus"
        case "subtraction":
            return "minus"
        case "multiplication":
            return "multiply"
        case "division":
            return "divide"
        case "order_of_operations":
            return "parentheses"
        default:
            return "function"
        }
    }
    
    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Symbol header
                symbolHeader

                // Check for interactive mode
                if concept.interactionType != nil {
                    // Interactive content
                    InteractiveOperatorView(concept: concept)
                } else {
                    // Original static content
                    definitionCard
                    whyItMattersCard
                    examplesSection
                }

                // Bottom spacing
                Spacer(minLength: 100)
            }
            .padding(EdgeInsets(top: 24, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(concept.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Symbol Header
    
    private var symbolHeader: some View {
        VStack(spacing: 12) {
            // Large symbol display
            Text(concept.symbol)
                .font(.system(size: 64, weight: .medium, design: .rounded))
                .foregroundStyle(conceptColor)
                .minimumScaleFactor(0.5)
                .frame(minWidth: 88, minHeight: 88)
                .padding(12)
                .background(
                    Circle()
                        .fill(conceptColor.opacity(0.1))
                )
            
            // Subtitle
            Text("Foundation Concept")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeInline()
        }
    }
    
    // MARK: - Definition Card
    
    private var definitionCard: some View {
        LearningCard(
            title: "What is \(concept.name)?",
            icon: "lightbulb",
            iconColor: .yellow
        ) {
            Text(concept.definition)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .safeBody(alignment: .leading)
        }
    }

    // MARK: - Why It Matters Card

    private var whyItMattersCard: some View {
        LearningCard(
            title: "Why It Matters in Equations",
            icon: "link",
            iconColor: conceptColor
        ) {
            Text(concept.whyItMatters)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .safeBody(alignment: .leading)
        }
    }
    
    // MARK: - Examples Section
    
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label {
                Text("Conceptual Examples")
                    .font(.headline)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundStyle(conceptColor)
            }
            .padding(.horizontal, 4)
            
            // Example cards
            VStack(spacing: 12) {
                ForEach(concept.conceptualExamples) { example in
                    ConceptualExampleCard(
                        example: example,
                        color: conceptColor
                    )
                }
            }
        }
    }
}

// MARK: - Conceptual Example Card

/// Displays a single conceptual example for an arithmetic operation
struct ConceptualExampleCard: View {
    let example: ConceptualExample
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Expression display
            Text(example.expression)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(color)
            
            // Divider
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 1)
            
            // Explanation
            Text(example.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .safeBody(alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}



// MARK: - Preview

#Preview("Addition Concept") {
    NavigationStack {
        ArithmeticConceptView(
            concept: ArithmeticConcept(
                id: "addition",
                name: "Addition",
                symbol: "+",
                definition: "Addition is the process of combining two or more quantities to find their total. When we add, we're asking: 'How much do we have altogether?'",
                whyItMatters: "In equations, addition appears when quantities are being combined. Understanding addition helps you recognize when terms are being grouped together.",
                conceptualExamples: [
                    ConceptualExample(
                        expression: "3 + 5",
                        explanation: "This represents taking a group of 3 and combining it with a group of 5."
                    ),
                    ConceptualExample(
                        expression: "x + 7",
                        explanation: "Here, we're combining an unknown quantity (x) with 7."
                    )
                ]
            )
        )
    }
}

#Preview("Multiplication Concept") {
    NavigationStack {
        ArithmeticConceptView(
            concept: ArithmeticConcept(
                id: "multiplication",
                name: "Multiplication",
                symbol: "×",
                definition: "Multiplication is repeated addition—it tells us what we get when we have multiple groups of the same size.",
                whyItMatters: "In equations, multiplication often appears as a coefficient in front of a variable (like 3x, meaning '3 groups of x').",
                conceptualExamples: [
                    ConceptualExample(
                        expression: "4 × 6",
                        explanation: "This represents having 4 groups, each containing 6 items."
                    ),
                    ConceptualExample(
                        expression: "3x",
                        explanation: "This means '3 groups of x' or 'x added to itself 3 times'."
                    )
                ]
            )
        )
    }
}

#endif
