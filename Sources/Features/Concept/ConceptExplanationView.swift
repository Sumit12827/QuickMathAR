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
    
    /// Optional pre-computed analysis from Screen 1
    public let analysis: EquationAnalysis?
    
    public init(equation: String, equationType: EquationType, analysis: EquationAnalysis? = nil) {
        self.equation = equation
        self.equationType = equationType
        self.analysis = analysis
    }

    
    // MARK: - Environment
    
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - State
    
    /// Fallback analyzer if no analysis was passed from Screen 1
    @StateObject private var fallbackAnalyzer = EquationAnalyzer()
    
    /// Coefficient slider value for interactive exploration
    @State private var coeffSliderValue: Double = 1.0
    
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

    /// The effective analysis — from parameter or fallback
    private var effectiveAnalysis: EquationAnalysis? {
        if let analysis = analysis {
            return analysis
        }
        if case .completed(let a) = fallbackAnalyzer.state {
            return a
        }
        return nil
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header with equation
                    headerSection
                        .padding(.bottom, 4)
                    
                    // Equation-specific AI insight (NEW)
                    equationInsightCard
                    
                    // Interactive coefficient explorer (NEW)
                    if effectiveAnalysis != nil {
                        coefficientExplorerCard
                    }

                    // Interactive concept flow (if available in content)
                    if let conceptFlow = content?.conceptFlow, !conceptFlow.isEmpty {
                        ConceptPagerView(pages: conceptFlow, accentColor: accentColor)
                            .frame(height: 480)
                            .padding(.bottom, 8)
                    } else {
                        // Fallback to static cards
                        VStack(spacing: 16) {
                            whatIsItCard
                            realWorldCard
                            confusionCard
                            visualCard
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            // Fixed bottom action bar — always visible
            FixedBottomActionBar(accentColor: accentColor) {
                HStack(spacing: 8) {
                    Text("See It Step by Step")
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
            } primaryAction: {
                navigationCoordinator.push(.learning(equation: equation, type: equationType))
            } secondaryLabel: {
                HStack(spacing: 6) {
                    Image(systemName: "arkit")
                    Text("Skip to AR")
                }
            } secondaryAction: {
                navigationCoordinator.push(.arVisualization(equation: equation, type: equationType))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Understand Visually")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // If no analysis was passed, run the analyzer
            if analysis == nil {
                fallbackAnalyzer.analyze(equation: equation, type: equationType)
            }
        }
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
    
    // MARK: - Equation Insight Card (NEW)
    
    private var equationInsightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with AI badge
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.body)
                    .foregroundStyle(.purple)
                
                Text("About Your Equation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                if isFoundationModelAvailable() {
                    Label("Apple Intelligence", systemImage: "apple.intelligence")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.purple.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.purple.opacity(0.1))
                        )
                }
            }
            
            if let a = effectiveAnalysis {
                // What this equation does
                Text(a.whatThisEquationDoes)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .safeBody(alignment: .leading)
                
                // Real-world analogy
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .frame(width: 20)
                    
                    Text(a.realWorldAnalogy)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .safeCaption(alignment: .leading)
                }
                
                // Solution preview
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    
                    Text(a.solutionPreview)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            } else {
                // Loading shimmer
                VStack(alignment: .leading, spacing: 10) {
                    ShimmerView(lineCount: 1)
                        .frame(height: 16)
                    ShimmerView(lineCount: 1)
                        .frame(height: 16)
                        .frame(maxWidth: 240)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.purple.opacity(0.4), .purple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Coefficient Explorer Card (NEW)
    
    private var coefficientExplorerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("What do the numbers mean?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(accentColor)
            }
            
            if let a = effectiveAnalysis, !a.coefficients.isEmpty {
                // Coefficient badges
                HStack(spacing: 10) {
                    ForEach(a.coefficients, id: \.symbol) { coeff in
                        VStack(spacing: 4) {
                            Text(coeff.symbol)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(accentColor)
                            
                            Text(coeff.displayValue)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Text(coeff.meaning)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accentColor.opacity(0.06))
                        )
                    }
                }
                
                // Interactive exploration
                VStack(spacing: 10) {
                    let param = equationType == .linear ? "slope" : "'a'"
                    HStack {
                        Text("Adjust \(param)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Slider(value: $coeffSliderValue, in: -3...3, step: 0.5)
                            .tint(accentColor)
                        
                        Text(String(format: "%.1f", coeffSliderValue))
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundStyle(accentColor)
                            .frame(width: 40)
                    }
                    
                    SimpleGraphPreview(equationType: equationType)
                        .frame(height: 100)
                    
                    Text(coefficientExplorerInsight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var coefficientExplorerInsight: String {
        if equationType == .linear {
            if coeffSliderValue > 1 {
                return "A steep positive slope — the line rises quickly to the right."
            } else if coeffSliderValue > 0 {
                return "A gentle positive slope — the line rises slowly."
            } else if coeffSliderValue == 0 {
                return "Flat line — no change in y at all."
            } else if coeffSliderValue > -1 {
                return "A gentle negative slope — the line falls slowly."
            } else {
                return "A steep negative slope — the line drops quickly."
            }
        } else {
            if coeffSliderValue > 0.5 {
                return "Parabola opens upward (U-shape). Larger 'a' makes it narrower."
            } else if coeffSliderValue > -0.5 {
                return "Nearly flat — close to a straight line."
            } else {
                return "Parabola opens downward (∩-shape). More negative 'a' makes it narrower."
            }
        }
    }
    
    // MARK: - Continue Section (moved to fixed bottom bar in body)
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
