//
//  LearningView.swift
//  QuickMathsAR
//
//  Displays structured learning content in a calm, readable format
//

import SwiftUI

/// A view that displays educational content for equation types
/// Presents step-by-step explanations with a calm, readable layout
struct LearningView: View {
    
    // MARK: - Properties
    
    /// The equation learning content to display
    let content: EquationLearningContent
    
    /// The specific example to show (optional, defaults to first)
    let selectedExample: LearningExample?
    
    /// Action when AR button is tapped
    var onViewInAR: (() -> Void)?
    
    /// AI explanation engine (optional — nil means no AI features)
    var explanationEngine: ExplanationEngine?
    
    // MARK: - Environment
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Computed Properties
    
    /// The example to display
    private var displayedExample: LearningExample? {
        selectedExample ?? content.examples.first
    }
    
    /// Horizontal padding based on size class
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : 20
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header section
                headerSection
                
                // Definition card
                definitionCard
                
                // Solving approach card
                solvingApproachCard
                
                // Step-by-step walkthrough
                if let example = displayedExample {
                    exampleSection(example: example)
                }
                
                // AR button (if available)
                if content.arAvailable {
                    arButton
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
        .onDisappear {
            explanationEngine?.cancelAll()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Subtle type indicator
            HStack {
                Image(systemName: equationTypeIcon)
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                
                Text("Learning Mode")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.1))
            )
        }
    }
    
    // MARK: - Definition Card
    
    private var definitionCard: some View {
        LearningCard(
            title: "What is it?",
            icon: "lightbulb",
            iconColor: .yellow
        ) {
            Text(content.definition)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .safeBody(alignment: .leading)
        }
    }
    
    // MARK: - Solving Approach Card
    
    private var solvingApproachCard: some View {
        LearningCard(
            title: "How to Think About It",
            icon: "brain.head.profile",
            iconColor: .purple
        ) {
            Text(content.solvingMethodConcept)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .safeBody(alignment: .leading)
        }
    }
    
    // MARK: - Example Section
    
    private func exampleSection(example: LearningExample) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Label {
                    Text("Step-by-Step Walkthrough")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .safeTitle(minScale: 0.8, alignment: .leading)
                } icon: {
                    Image(systemName: "list.number")
                        .foregroundStyle(accentColor)
                }

                Spacer()

                // Difficulty badge
                DifficultyBadge(difficulty: example.difficulty)
            }
            .padding(.horizontal, 4)
            
            // Example equation display
            ExampleEquationCard(equation: example.equation)
            
            // Description
            if !example.description.isEmpty {
                Text(example.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            
            // Mission statement (if available)
            if let missionStatement = example.missionStatement {
                MissionStatementView(missionStatement: missionStatement)
            }
            
            // Thinking path (if available)
            if let thinkingPath = example.thinkingPath, !thinkingPath.isEmpty {
                ThinkingPathView(steps: thinkingPath)
            }
            
            // Factoring puzzle (if available, for quadratics)
            if let puzzle = example.factoringPuzzle {
                FactoringPuzzleView(puzzle: puzzle)
            }
            
            // Steps
            VStack(spacing: 12) {
                ForEach(Array(example.steps.enumerated()), id: \.element.id) { index, step in
                    let previousResult: String? = index > 0 ? example.steps[index - 1].result : nil
                    StepCard(
                        step: step,
                        isKeyStep: isKeyStep(step),
                        accentColor: accentColor,
                        equation: example.equation,
                        totalSteps: example.steps.count,
                        previousStepResult: previousResult,
                        explanationEngine: explanationEngine
                    )
                }
            }
        }
    }
    
    // MARK: - AR Button
    
    private var arButton: some View {
        Button(action: {
            onViewInAR?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arkit")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("View in AR")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("See this concept visualized")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel("View in AR")
        .accessibilityHint("Opens augmented reality visualization of this concept")
    }

    // MARK: - Helpers
    
    /// Determines if a step is a key step (worth highlighting)
    private func isKeyStep(_ step: SolvingStep) -> Bool {
        // Highlight steps that reference an arithmetic concept
        // or are the final step
        step.arithmeticConceptUsed != nil ||
        step.stepNumber == displayedExample?.steps.count
    }
    
    /// Icon for the equation type
    private var equationTypeIcon: String {
        switch content.equationType {
        case "linear":
            return "line.diagonal"
        case "quadratic":
            return "point.topleft.down.to.point.bottomright.curvepath"
        default:
            return "function"
        }
    }
    
    /// Accent color for the equation type
    private var accentColor: Color {
        switch content.equationType {
        case "linear":
            return .blue
        case "quadratic":
            return .purple
        default:
            return .orange
        }
    }
}

// MARK: - Learning Card Component

/// A reusable card container for learning content sections
struct LearningCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card header
            Label {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            
            // Card content
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Example Equation Card

/// Displays the example equation prominently
struct ExampleEquationCard: View {
    let equation: String

    var body: some View {
        Text(equation)
            .font(.system(size: 28, weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
            .safeTitle(minScale: 0.6)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Step Card Component

/// Displays a single step in the learning walkthrough
struct StepCard: View {
    let step: SolvingStep
    let isKeyStep: Bool
    let accentColor: Color
    
    // AI explanation integration (optional for backward compatibility)
    var equation: String? = nil
    var totalSteps: Int = 0
    var previousStepResult: String? = nil
    var explanationEngine: ExplanationEngine? = nil

    @State private var showDetailedReasoning = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number indicator
            stepNumberView

            // Step content
            VStack(alignment: .leading, spacing: 8) {
                // Action (what we're doing)
                Text(step.action)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .safeBody(alignment: .leading)

                // Reasoning (why we're doing it)
                Text(step.reasoning.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .safeBody(alignment: .leading)

                // Detailed reasoning expandable (if available)
                if let detailed = step.reasoning.detailedText {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDetailedReasoning.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showDetailedReasoning ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                            Text(showDetailedReasoning ? "Less detail" : "More detail")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }

                    if showDetailedReasoning {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(detailed)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineSpacing(2)

                            // Metaphor if available
                            if let metaphor = step.reasoning.metaphorText {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                    Text(metaphor)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .italic()
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.yellow.opacity(0.1))
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Result (the outcome)
                if let result = step.result, !result.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Text(result)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(accentColor)
                    }
                    .padding(.top, 4)
                }

                // Arithmetic concept tag (if present)
                if let concept = step.arithmeticConceptUsed {
                    ConceptTag(concept: concept)
                        .padding(.top, 4)
                }
                
                // "Why This Works" AI explanation card
                if let engine = explanationEngine, let eq = equation {
                    WhyThisWorksCard(
                        step: step,
                        equation: eq,
                        totalSteps: totalSteps,
                        previousStepResult: previousStepResult,
                        accentColor: accentColor,
                        explanationEngine: engine
                    )
                    .padding(.top, 6)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isKeyStep ? accentColor.opacity(0.05) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isKeyStep ? accentColor.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private var stepNumberView: some View {
        Text("\(step.stepNumber)")
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(isKeyStep ? .white : accentColor)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(isKeyStep ? accentColor : accentColor.opacity(0.15))
            )
    }
}

// MARK: - Concept Tag Component

/// A small tag showing which arithmetic concept is used
struct ConceptTag: View {
    let concept: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bookmark.fill")
                .font(.caption2)
            
            Text(formattedConcept)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var formattedConcept: String {
        concept.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Difficulty Badge Component

/// Displays the difficulty level of an example
struct DifficultyBadge: View {
    let difficulty: String
    
    var body: some View {
        Text(difficulty.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(difficultyColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(difficultyColor.opacity(0.1))
            )
    }
    
    private var difficultyColor: Color {
        switch difficulty.lowercased() {
        case "beginner":
            return .green
        case "intermediate":
            return .orange
        case "advanced":
            return .red
        default:
            return .secondary
        }
    }
}

// MARK: - Preview

#Preview("Linear Equation Learning") {
    NavigationStack {
        LearningView(
            content: EquationLearningContent(
                version: "1.0",
                equationType: "linear",
                displayName: "Linear Equations",
                definition: "A linear equation is an equation where the variable appears only to the first power—no squares, cubes, or higher powers. The word 'linear' comes from 'line' because when you graph these equations, they always form a straight line.",
                solvingMethodConcept: "The goal when solving a linear equation is to isolate the variable—get it alone on one side of the equals sign. We do this by performing the same operation on both sides of the equation, keeping it balanced.",
                prerequisites: ["addition", "subtraction", "multiplication", "division"],
                examples: [
                    LearningExample(
                        equation: "2x + 5 = 13",
                        difficulty: "intermediate",
                        description: "A two-step equation combining multiplication and addition.",
                        steps: [
                            SolvingStep(
                                stepNumber: 1,
                                action: "Understand the structure of the equation",
                                reasoning: .simple("Reading '2x + 5', the order of operations tells us: first x is multiplied by 2, then 5 is added to that result."),
                                result: "Plan: subtract 5, then divide by 2",
                                arithmeticConceptUsed: "order_of_operations"
                            ),
                            SolvingStep(
                                stepNumber: 2,
                                action: "Remove the added constant first",
                                reasoning: .simple("We subtract 5 from both sides to eliminate the +5 on the left."),
                                result: "2x = 8",
                                arithmeticConceptUsed: "subtraction"
                            ),
                            SolvingStep(
                                stepNumber: 3,
                                action: "Remove the coefficient",
                                reasoning: .simple("Now we have 2x = 8. We divide both sides by 2 to isolate x."),
                                result: "x = 4",
                                arithmeticConceptUsed: "division"
                            )
                        ]
                    )
                ],
                arAvailable: true
            ),
            selectedExample: nil,
            onViewInAR: {}
        )
    }
}

#Preview("Quadratic Equation Learning") {
    NavigationStack {
        LearningView(
            content: EquationLearningContent(
                version: "1.0",
                equationType: "quadratic",
                displayName: "Quadratic Equations",
                definition: "A quadratic equation is an equation where the highest power of the variable is 2. When graphed, quadratic equations form a curved shape called a parabola.",
                solvingMethodConcept: "Solving quadratic equations requires different thinking than linear equations because of the squared term. The main approach is factoring.",
                prerequisites: ["addition", "subtraction", "multiplication", "division"],
                examples: [
                    LearningExample(
                        equation: "x² + 5x + 6 = 0",
                        difficulty: "intermediate",
                        description: "A standard quadratic that can be factored.",
                        steps: [
                            SolvingStep(
                                stepNumber: 1,
                                action: "Understand the standard form",
                                reasoning: .simple("This is in standard form: x² + bx + c = 0. The goal is to factor it."),
                                result: "We want to write this as (x + ?)(x + ?) = 0",
                                arithmeticConceptUsed: nil
                            ),
                            SolvingStep(
                                stepNumber: 2,
                                action: "Find two numbers",
                                reasoning: .simple("We need two numbers that add to 5 and multiply to 6. Those are 2 and 3."),
                                result: "The numbers are 2 and 3",
                                arithmeticConceptUsed: "multiplication"
                            )
                        ]
                    )
                ],
                arAvailable: true
            ),
            selectedExample: nil,
            onViewInAR: {}
        )
    }
}
