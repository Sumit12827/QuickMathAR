//
//  LearningContainerView.swift
//  QuickMathsAR
//
//  Container for LearningView with navigation and interactivity
//

import SwiftUI

/// Container view that wraps LearningView with proper navigation
/// and interactive elements like prediction questions and value sliders
public struct LearningContainerView: View {
    
    // MARK: - Properties
    
    public let equation: String
    public let equationType: EquationType
    
    public init(equation: String, equationType: EquationType) {
        self.equation = equation
        self.equationType = equationType
    }

    
    // MARK: - Environment
    
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - State

    @State private var content: EquationLearningContent?
    @State private var isLoading: Bool = true
    @State private var loadError: Bool = false
    @State private var currentStepIndex: Int = 0
    @State private var showPredictionQuestion: Bool = false
    @State private var selectedPrediction: String?
    @State private var hasCompletedExample: Bool = false
    @State private var sliderValue: Double = 1.0
    
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
    
    private var currentExample: LearningExample? {
        content?.examples.first
    }
    
    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let content = content {
                    // Header
                    headerSection
                    
                    // Interactive slope/coefficient demo
                    if equationType == .linear || equationType == .quadratic {
                        interactiveSliderSection
                    }
                    
                    // Prediction question (appears mid-learning)
                    if showPredictionQuestion {
                        predictionQuestionCard
                    }
                    
                    // Main learning content
                    mainLearningContent(content: content)
                    
                    // Completion section
                    if hasCompletedExample {
                        completionSection
                    }
                    
                } else if isLoading {
                    // Loading state
                    loadingView
                } else {
                    // Error state - content failed to load
                    errorView
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Learning Examples")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadContent()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: equationType == .linear ? "line.diagonal" : "point.topleft.down.to.point.bottomright.curvepath")
                    .foregroundStyle(accentColor)
                
                Text("Interactive Learning")
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
            
            Text(equation)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Interactive Slider Section

    private var interactiveSliderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Explore: What happens when values change?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(accentColor)
            }

            VStack(spacing: 12) {
                // Slider with label
                HStack {
                    Text(equationType == .linear ? "Slope" : "Coefficient 'a'")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $sliderValue, in: -3...3, step: 0.5)
                        .tint(accentColor)
                        .accessibilityLabel(equationType == .linear ? "Slope" : "Coefficient a")
                        .accessibilityValue(String(format: "%.1f", sliderValue))
                        .accessibilityHint("Adjust to see how it affects the graph")

                    Text(String(format: "%.1f", sliderValue))
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(accentColor)
                        .frame(width: 44)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(accentColor.opacity(0.1))
                        )
                        .accessibilityHidden(true)
                }

                // Visual feedback
                InteractiveGraphPreview(value: sliderValue, equationType: equationType)
                    .frame(height: 120)

                // Dynamic insight text with icon
                HStack(spacing: 8) {
                    Image(systemName: sliderInsightIcon)
                        .font(.caption)
                        .foregroundStyle(accentColor)

                    Text(sliderInsight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .onChange(of: sliderValue) { oldValue, newValue in
            // Haptic on crossing zero
            if (oldValue < 0 && newValue >= 0) || (oldValue >= 0 && newValue < 0) {
                HapticManager.shared.medium()
            }
            // Light haptic on integer values
            else if abs(newValue.truncatingRemainder(dividingBy: 1.0)) < 0.05 {
                HapticManager.shared.light()
            }

            // Show prediction question after some interaction
            if abs(newValue) > 1.5 && !showPredictionQuestion && !hasCompletedExample {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPredictionQuestion = true
                }
            }
        }
    }

    private var sliderInsightIcon: String {
        if equationType == .linear {
            if sliderValue > 1 {
                return "arrow.up.right"
            } else if sliderValue < -1 {
                return "arrow.down.right"
            } else if abs(sliderValue) < 0.3 {
                return "arrow.right"
            } else {
                return "line.diagonal"
            }
        } else {
            if sliderValue > 0.5 {
                return "arrow.up.to.line"
            } else if sliderValue < -0.5 {
                return "arrow.down.to.line"
            } else {
                return "minus"
            }
        }
    }
    
    private var sliderInsight: String {
        if equationType == .linear {
            switch sliderValue {
            case let x where x > 2:
                return "Very steep upward slope — the line rises quickly!"
            case let x where x > 0.5:
                return "Rising gently — for every step right, you go up"
            case let x where x > -0.5:
                return "Nearly horizontal — very little change in y"
            case let x where x > -2:
                return "Declining — the line falls as you move right"
            default:
                return "Very steep downward slope — drops quickly!"
            }
        } else {
            switch sliderValue {
            case let x where x > 1.5:
                return "Opens up sharply — narrow parabola with steep sides"
            case let x where x > 0.5:
                return "Opens upward — standard U-shaped curve"
            case let x where x > -0.5:
                return "Nearly flat — approaching a straight line"
            case let x where x > -1.5:
                return "Opens downward — inverted U-shape"
            default:
                return "Opens down sharply — narrow inverted parabola"
            }
        }
    }
    
    // MARK: - Prediction Question
    
    private var predictionQuestionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            predictionHeader
            
            Text(predictionQuestion)
                .font(.body)
                .foregroundStyle(.primary)
            
            predictionOptionsList
            
            predictionFeedback
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var predictionHeader: some View {
        HStack {
            Image(systemName: "questionmark.bubble.fill")
                .foregroundStyle(.orange)
            
            Text("Think About It")
                .font(.headline)
        }
    }
    
    private var predictionOptionsList: some View {
        VStack(spacing: 8) {
            ForEach(predictionOptions, id: \.self) { option in
                PredictionOptionButton(
                    text: option,
                    isSelected: selectedPrediction == option,
                    isCorrect: option == correctPrediction && selectedPrediction != nil,
                    accentColor: accentColor
                ) {
                    handlePredictionSelected(option)
                }
            }
        }
    }
    
    private var predictionFeedback: some View {
        Group {
            if let selected = selectedPrediction {
                Text(selected == correctPrediction ? "Correct! 🎉" : "Not quite, but great thinking! The answer is highlighted above.")
                    .font(.caption)
                    .foregroundStyle(selected == correctPrediction ? .green : .orange)
                    .padding(.top, 4)
            }
        }
    }
    
    private func handlePredictionSelected(_ option: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPrediction = option
        }

        // Haptic feedback based on correctness
        if option == correctPrediction {
            HapticManager.shared.play(.success)
        } else {
            HapticManager.shared.play(.warning)
        }

        // Mark as completed after answering
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                hasCompletedExample = true
            }
        }
    }
    
    private var predictionQuestion: String {
        equationType == .linear
            ? "If we double the slope, what happens to the line?"
            : "If we make 'a' negative, what happens to the parabola?"
    }
    
    private var predictionOptions: [String] {
        equationType == .linear
            ? ["It becomes twice as steep", "It moves up", "It becomes horizontal", "Nothing changes"]
            : ["It flips upside down", "It gets wider", "It moves right", "Nothing changes"]
    }
    
    private var correctPrediction: String {
        equationType == .linear
            ? "It becomes twice as steep"
            : "It flips upside down"
    }
    
    // MARK: - Main Learning Content
    
    private func mainLearningContent(content: EquationLearningContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label {
                Text("Step-by-Step Solution")
                    .font(.headline)
                    .safeTitle(minScale: 0.85, alignment: .leading)
            } icon: {
                Image(systemName: "list.number")
                    .foregroundStyle(accentColor)
            }
            
            // Definition
            LearningCard(
                title: "What You're Learning",
                icon: "lightbulb",
                iconColor: .yellow
            ) {
                Text(content.definition)
                    .font(.body)
                    .lineSpacing(4)
            }
            
            // Solving approach
            LearningCard(
                title: "The Approach",
                icon: "brain.head.profile",
                iconColor: .purple
            ) {
                Text(content.solvingMethodConcept)
                    .font(.body)
                    .lineSpacing(4)
            }
            
            // Steps
            if let example = currentExample {
                ForEach(example.steps) { step in
                    StepCard(
                        step: step,
                        isKeyStep: step.arithmeticConceptUsed != nil,
                        accentColor: accentColor
                    )
                }
            }
        }
    }
    
    // MARK: - Completion Section
    
    private var completionSection: some View {
        VStack(spacing: 16) {
            // Success message
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Great Progress!")
                        .font(.headline)
                    Text("You've explored the interactive example")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green.opacity(0.1))
            )
            
            // Action buttons
            VStack(spacing: 12) {
                // Primary: Visualize in AR
                Button {
                    HapticManager.shared.medium()
                    navigationCoordinator.push(.arVisualization(equation: equation, type: equationType))
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arkit")
                        Text("Visualize in AR")
                    }
                    .font(.headline)
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
                .accessibilityLabel("Visualize in AR")
                .accessibilityHint("Opens augmented reality view of the equation")

                // Secondary: Skip to Reflection
                Button {
                    HapticManager.shared.light()
                    let insights = generateInsights()
                    navigationCoordinator.push(.reflection(equationType: equationType, insights: insights))
                } label: {
                    Text("Skip to Key Takeaways")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skip to key takeaways")
                .accessibilityHint("Skips to the learning summary")
            }
            .frame(maxWidth: 400)
        }
    }
    
    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)

            VStack(spacing: 8) {
                Text("Loading learning content...")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Preparing interactive examples for \(equationType.displayName.lowercased())s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Couldn't load content")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("The learning content for this equation type isn't available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                loadContent()
            } label: {
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }

    // MARK: - Helpers
    
    private func loadContent() {
        isLoading = true
        loadError = false

        // Simulate a brief load time for smoother UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let loadedContent = ContentLoader.shared.getEquationContent(for: equationType)
            withAnimation(.easeInOut(duration: 0.2)) {
                content = loadedContent
                isLoading = false
                loadError = loadedContent == nil
            }
        }
    }
    
    private func generateInsights() -> [String] {
        switch equationType {
        case .linear:
            return [
                "The slope controls how steep the line is",
                "A positive slope means the line goes up from left to right",
                "The y-intercept is where the line crosses the y-axis",
                "Linear equations always have exactly one solution"
            ]
        case .quadratic:
            return [
                "The 'a' coefficient determines if the parabola opens up or down",
                "The vertex is the highest or lowest point",
                "Quadratic equations can have 0, 1, or 2 solutions",
                "The axis of symmetry passes through the vertex"
            ]
        case .constant:
            return [
                "Constant equations have no variables",
                "They represent a horizontal line on a graph",
                "The solution is either always true or always false"
            ]
        default:
            return [
                "This equation type requires advanced techniques",
                "Consider breaking it down into simpler parts",
                "Practice with linear and quadratic equations first"
            ]
        }
    }
}

// MARK: - Interactive Graph Preview

struct InteractiveGraphPreview: View {
    let value: Double
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
                
                // Draw curve based on value
                var curve = Path()
                let color: Color = equationType == .linear ? .blue : .purple
                
                if equationType == .linear {
                    // y = mx (line through origin with slope m)
                    let slope = value * 0.5
                    let startY = center.y + slope * center.x
                    let endY = center.y - slope * center.x
                    curve.move(to: CGPoint(x: 0, y: startY))
                    curve.addLine(to: CGPoint(x: size.width, y: endY))
                } else {
                    // y = ax² (parabola)
                    let step: CGFloat = 2
                    for x in stride(from: CGFloat(0), through: size.width, by: step) {
                        let normalizedX = (x - center.x) / (size.width / 4)
                        let y = center.y - value * (normalizedX * normalizedX) * 15
                        
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

// MARK: - Prediction Option Button

struct PredictionOptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(.white)
                } else if isCorrect && !isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSelected && !isCorrect)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return isCorrect ? .green : .red.opacity(0.7)
        } else if isCorrect {
            return .green.opacity(0.1)
        }
        return Color(.tertiarySystemGroupedBackground)
    }
}

// MARK: - Bullet Point Component

/// A bullet point with icon and text for structured content
struct BulletPoint: View {
    let icon: String
    let text: String
    let iconColor: Color

    init(icon: String = "circle.fill", text: String, iconColor: Color = .blue) {
        self.icon = icon
        self.text = text
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
                .frame(width: 20, alignment: .center)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Key Insight Card

/// A card highlighting key learning insights
struct KeyInsightCard: View {
    let title: String
    let points: [String]
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .safeTitle(minScale: 0.85, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    BulletPoint(
                        icon: "\(index + 1).circle.fill",
                        text: point,
                        iconColor: accentColor
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview

#Preview("Learning Container") {
    NavigationStack {
        LearningContainerView(
            equation: "2x + 5 = 13",
            equationType: .linear
        )
        .environmentObject(NavigationCoordinator())
    }
}
