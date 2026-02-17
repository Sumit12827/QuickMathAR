//
//  ConceptExplanationView.swift
//  QuickMathsAR
//
//  Provides intuitive, visual explanation of equation types
//

import SwiftUI

/// A view that explains equation concepts intuitively without heavy formulas
/// Focuses on "what", "why", and common misconceptions
public struct ConceptExplanationView: View {
    
    // MARK: - Properties
    
    /// The equation being explained
    public let equation: String
    
    /// The type of equation
    public let equationType: EquationType
    
    public init(equation: String, equationType: EquationType) {
        self.equation = equation
        self.equationType = equationType
    }

    
    // MARK: - Environment
    
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Computed Properties
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : 20
    }
    
    private var accentColor: Color {
        switch equationType {
        case .linear: return .blue
        case .quadratic: return .purple
        case .constant: return .gray
        default: return .orange
        }
    }
    
    /// Load content to check for conceptFlow
    private var content: EquationLearningContent? {
        ContentLoader.shared.getEquationContent(for: equationType)
    }
    
    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header with equation
                    headerSection
                        .padding(.bottom, 4)

                    // Interactive concept flow (if available in content)
                    if let conceptFlow = content?.conceptFlow, !conceptFlow.isEmpty {
                        ConceptPagerView(pages: conceptFlow, accentColor: accentColor)
                            .frame(height: 480)
                            .padding(.bottom, 8)
                    } else {
                        // Fallback to static cards
                        VStack(spacing: 16) {
                            // What is it?
                            whatIsItCard

                            // Real-world relevance
                            realWorldCard

                            // Common confusion points
                            confusionCard

                            // Visual representation
                            visualCard
                        }
                    }

                    // Continue button
                    continueSection
                        .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("The Concept")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: equationType == .linear ? "line.diagonal" : "point.topleft.down.to.point.bottomright.curvepath")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(accentColor)
                .frame(width: 88, height: 88)
                .background(
                    Circle()
                        .fill(accentColor.opacity(0.1))
                )
            
            // Equation display
            Text(equation)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            
            // Type label
            Text(equationType.displayName)
                .font(.headline)
                .foregroundStyle(accentColor)
        }
    }
    
    // MARK: - What Is It Card

    private var whatIsItCard: some View {
        ConceptCard(
            title: "What is a \(equationType.displayName)?",
            icon: "lightbulb.fill",
            iconColor: .yellow
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(whatIsItIntro)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .safeBody(alignment: .leading)

                // Key characteristics as bullet points
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(whatIsItKeyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(accentColor)
                            Text(point)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var whatIsItIntro: String {
        switch equationType {
        case .linear:
            return "Think of a linear equation as a balance scale. Whatever you do to one side, you must do to the other to keep it balanced."
        case .quadratic:
            return "A quadratic equation is like a fountain of water—it goes up, reaches a peak, and comes back down."
        case .constant:
            return "A constant equation has no variables—it's just comparing two numbers. These are often true or false statements."
        default:
            return "This is an advanced equation type. These build on the concepts from linear and quadratic equations."
        }
    }

    private var whatIsItKeyPoints: [String] {
        switch equationType {
        case .linear:
            return [
                "Forms a straight line when graphed—no curves",
                "Has exactly one solution (one value of x)",
                "The highest power of x is 1"
            ]
        case .quadratic:
            return [
                "The squared term (x²) creates a curved parabola",
                "Can have 0, 1, or 2 solutions",
                "Found everywhere: thrown balls, bridges, satellite dishes"
            ]
        case .constant:
            return [
                "No variables—just pure numbers",
                "Either always true or always false"
            ]
        default:
            return [
                "Advanced equation types build on fundamentals",
                "Practice with linear and quadratic equations first"
            ]
        }
    }
    
    // MARK: - Real World Card
    
    private var realWorldCard: some View {
        ConceptCard(
            title: "Why Does This Matter?",
            icon: "globe",
            iconColor: .green
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(realWorldExamples, id: \.self) { example in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline)
                        
                        Text(example)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var realWorldExamples: [String] {
        switch equationType {
        case .linear:
            return [
                "Calculating how long a trip will take at constant speed",
                "Figuring out earnings based on hourly wage",
                "Converting between temperature scales (Celsius ↔ Fahrenheit)",
                "Predicting costs when there's a flat fee plus per-unit charge"
            ]
        case .quadratic:
            return [
                "Predicting where a basketball will land after a throw",
                "Designing arches in architecture and bridges",
                "Calculating maximum profit in business",
                "Understanding how objects fall under gravity"
            ]
        case .constant:
            return [
                "Checking if mathematical statements are true",
                "Verifying basic arithmetic calculations"
            ]
        default:
            return [
                "Advanced equation types model complex real-world phenomena",
                "Understanding basics helps you tackle harder problems later"
            ]
        }
    }
    
    // MARK: - Confusion Card

    private var confusionCard: some View {
        ConceptCard(
            title: "Common Pitfalls",
            icon: "exclamationmark.triangle.fill",
            iconColor: .orange
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(confusionPoints, id: \.title) { point in
                    CommonMistakeCard(
                        title: point.title,
                        explanation: point.explanation,
                        accentColor: accentColor
                    )
                }
            }
        }
    }
    
    private var confusionPoints: [(title: String, explanation: String)] {
        switch equationType {
        case .linear:
            return [
                ("Order of operations", "Remember to undo operations in reverse order—like unwrapping a gift!"),
                ("Negative signs", "When you move a term to the other side, its sign flips."),
                ("Fractions as coefficients", "Multiply both sides by the denominator to clear fractions.")
            ]
        case .quadratic:
            return [
                ("Two solutions", "Unlike linear equations, quadratics can have 0, 1, or 2 solutions."),
                ("Factoring vs. Formula", "Not all quadratics factor nicely—that's when the quadratic formula helps."),
                ("The parabola direction", "If 'a' is positive, it opens upward ∪. If negative, it opens downward ∩.")
            ]
        case .constant:
            return [
                ("No variables to solve", "These equations just tell you if a statement is true or false."),
                ("Simple but important", "They help verify your work in more complex problems.")
            ]
        default:
            return [
                ("Complex structures", "Advanced equations need specialized techniques."),
                ("Multiple solutions", "Can have many solutions depending on the equation type.")
            ]
        }
    }
    
    // MARK: - Visual Card

    private var visualCard: some View {
        ConceptCard(
            title: "Visual Intuition",
            icon: "eye.fill",
            iconColor: accentColor
        ) {
            VStack(spacing: 16) {
                // Simple visual representation
                if equationType != .unknown {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))

                        SimpleGraphPreview(equationType: equationType)
                            .padding(8)
                    }
                    .frame(height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    )
                }

                // Graph description with key points
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(visualKeyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                                .foregroundStyle(accentColor)
                            Text(point)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var visualKeyPoints: [String] {
        switch equationType {
        case .linear:
            return [
                "Always graphs as a straight line",
                "Slope tells you how steep the line is",
                "Y-intercept is where it crosses the vertical axis"
            ]
        case .quadratic:
            return [
                "Forms a parabola—a smooth U-shape",
                "The vertex is the highest or lowest point",
                "Opens up if 'a' is positive, down if negative"
            ]
        case .constant:
            return [
                "No graph needed—just a true or false statement",
                "Think of it as checking if both sides balance"
            ]
        default:
            return [
                "Creates complex curves with multiple features",
                "Shape depends on the equation's structure and coefficients"
            ]
        }
    }
    
    // MARK: - Continue Section

    private var continueSection: some View {
        VStack(spacing: 12) {
            // Primary: Continue to examples
            Button {
                HapticManager.shared.medium()
                navigationCoordinator.push(.learning(equation: equation, type: equationType))
            } label: {
                HStack(spacing: 8) {
                    Text("Continue to Examples")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor)
                )
                .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            // Secondary: Jump to AR
            Button {
                HapticManager.shared.light()
                navigationCoordinator.push(.arVisualization(equation: equation, type: equationType))
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arkit")
                    Text("Or Visualize in AR")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 400)
    }
}

// MARK: - Concept Card Component

struct ConceptCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Label {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .safeTitle(minScale: 0.85, alignment: .leading)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            
            // Content
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

// MARK: - Common Mistake Card

struct CommonMistakeCard: View {
    let title: String
    let explanation: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red.opacity(0.8))

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Simple Graph Preview

struct SimpleGraphPreview: View {
    let equationType: EquationType
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                // Draw axes
                var xAxis = Path()
                xAxis.move(to: CGPoint(x: 0, y: center.y))
                xAxis.addLine(to: CGPoint(x: size.width, y: center.y))
                context.stroke(xAxis, with: .color(.gray.opacity(0.3)), lineWidth: 1)
                
                var yAxis = Path()
                yAxis.move(to: CGPoint(x: center.x, y: 0))
                yAxis.addLine(to: CGPoint(x: center.x, y: size.height))
                context.stroke(yAxis, with: .color(.gray.opacity(0.3)), lineWidth: 1)
                
                // Draw curve
                var curve = Path()
                let color: Color = equationType == .linear ? .blue : .purple
                
                if equationType == .linear {
                    // Draw a line: y = x
                    curve.move(to: CGPoint(x: 20, y: size.height - 20))
                    curve.addLine(to: CGPoint(x: size.width - 20, y: 20))
                } else {
                    // Draw a parabola
                    let step: CGFloat = 2
                    for x in stride(from: CGFloat(0), through: size.width, by: step) {
                        let normalizedX = (x - center.x) / (size.width / 4)
                        let y = center.y - (normalizedX * normalizedX) * 20
                        
                        if x == 0 {
                            curve.move(to: CGPoint(x: x, y: y))
                        } else {
                            curve.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                
                context.stroke(
                    curve,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Preview

#Preview("Linear Concept") {
    NavigationStack {
        ConceptExplanationView(
            equation: "2x + 5 = 13",
            equationType: .linear
        )
        .environmentObject(NavigationCoordinator())
    }
}

#Preview("Quadratic Concept") {
    NavigationStack {
        ConceptExplanationView(
            equation: "x² + 5x + 6 = 0",
            equationType: .quadratic
        )
        .environmentObject(NavigationCoordinator())
    }
}
