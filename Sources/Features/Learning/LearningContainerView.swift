//
//  LearningContainerView.swift
//  QuickMathsAR
//
//  Container for step-by-step solving of the user's specific equation.
//  Uses EquationStepGenerator for dynamic steps and a global DetailLevelSelector.
//

#if os(iOS)
import SwiftUI

/// Container view that displays a step-by-step solution for the user's
/// specific equation, with a global detail level selector, step progress
/// indicator, and one-step-at-a-time focused display.
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

    @State private var detailLevel: ExplanationLevel = .intermediate
    @State private var steps: [SolvingStep] = []
    @State private var content: EquationLearningContent?
    @State private var isLoading: Bool = true
    @State private var loadError: Bool = false
    @State private var currentStepIndex: Int = 0
    @State private var hasCompletedExample: Bool = false
    @State private var explanationEngine = ExplanationEngine()
    @State private var usingDynamicSteps: Bool = false
    @State private var expandedWhyStep: Int? = nil

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

    private var displaySteps: [SolvingStep] {
        if usingDynamicSteps { return steps }
        return currentExample?.steps ?? []
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Sticky detail level selector
            DetailLevelSelectorView(
                selectedLevel: $detailLevel,
                isAIAvailable: isFoundationModelAvailable()
            )

            ScrollView {
                VStack(spacing: 24) {
                    if !steps.isEmpty || content != nil {
                        headerSection
                        stepProgressIndicator

                        // One-step-at-a-time focused display
                        focusedStepSection

                        // Step navigation list (collapsed)
                        stepNavigationList

                        if hasCompletedExample {
                            completionMessage
                        }
                    } else if isLoading {
                        loadingView
                    } else {
                        errorView
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 24)
            }

            // Fixed bottom action bar
            if !steps.isEmpty || content != nil {
                FixedBottomActionBar(accentColor: accentColor) {
                    HStack(spacing: 8) {
                        Image(systemName: hasCompletedExample ? "arkit" : "arrow.right")
                        Text(hasCompletedExample ? "See It in AR" : "Next Step")
                    }
                } primaryAction: {
                    if hasCompletedExample {
                        navigationCoordinator.push(.arVisualization(equation: equation, type: equationType))
                    } else {
                        advanceStep()
                    }
                } secondaryLabel: {
                    Text("Jump to Takeaways")
                } secondaryAction: {
                    let insights = generateInsights()
                    navigationCoordinator.push(.reflection(equationType: equationType, insights: insights))
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Solve Step-by-Step")
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

                Text("Your Equation")
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
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .safeTitle(minScale: 0.6)

            if usingDynamicSteps {
                Label("Steps generated for your equation", systemImage: "cpu")
                    .font(.caption2)
                    .foregroundStyle(.purple.opacity(0.8))
            }
        }
    }

    // MARK: - Step Progress Indicator

    private var stepProgressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(min(currentStepIndex + 1, displaySteps.count)) of \(displaySteps.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(progressPercent)%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemGroupedBackground))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor)
                        .frame(width: geometry.size.width * progressFraction)
                        .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var progressPercent: Int {
        guard !displaySteps.isEmpty else { return 0 }
        return Int((Double(currentStepIndex + 1) / Double(displaySteps.count)) * 100)
    }

    private var progressFraction: CGFloat {
        guard !displaySteps.isEmpty else { return 0 }
        return CGFloat(currentStepIndex + 1) / CGFloat(displaySteps.count)
    }

    // MARK: - Focused Step Section (One Step at a Time)

    private var focusedStepSection: some View {
        Group {
            if currentStepIndex < displaySteps.count {
                let step = displaySteps[currentStepIndex]
                let previousResult: String? = currentStepIndex > 0 ? displaySteps[currentStepIndex - 1].result : nil

                VStack(alignment: .leading, spacing: 16) {
                    // Step number + title
                    stepHeader(step: step)

                    // Math content
                    stepMathContent(previousResult: previousResult, step: step)

                    // Reasoning at current detail level
                    let reasoning: String = reasoningText(for: step)
                    if !reasoning.isEmpty {
                        reasoningView(text: reasoning)
                    }

                    // Expandable "Why this works?"
                    whyThisWorksSection(step: step)

                    // Navigation buttons
                    navigationButtons()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
                )
                .id("step-\(currentStepIndex)")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Focused Step Helpers

    @ViewBuilder
    private func stepHeader(step: SolvingStep) -> some View {
        HStack(spacing: 12) {
            Text("\(currentStepIndex + 1)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(accentColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Step \(currentStepIndex + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(step.action)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .safeTitle(minScale: 0.8, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func stepMathContent(previousResult: String?, step: SolvingStep) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let prev = previousResult {
                Text(prev)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text(step.result ?? step.action)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
        }
    }

    @ViewBuilder
    private func reasoningView(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: detailLevelIcon)
                .font(.caption)
                .foregroundStyle(accentColor.opacity(0.6))
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .safeCaption(alignment: .leading)
        }
        .animation(.easeInOut(duration: 0.2), value: detailLevel)
    }

    @ViewBuilder
    private func whyThisWorksSection(step: SolvingStep) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedWhyStep = expandedWhyStep == step.id ? nil : step.id
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: expandedWhyStep == step.id ? "chevron.up" : "questionmark.circle")
                    .font(.caption)
                Text(expandedWhyStep == step.id ? "Hide explanation" : "Why this works?")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(accentColor)
        }
        .buttonStyle(.plain)

        if expandedWhyStep == step.id {
            Text(whyThisWorks(step: step))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.05))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private func navigationButtons() -> some View {
        HStack(spacing: 12) {
            if currentStepIndex > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStepIndex -= 1
                    }
                    HapticManager.shared.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if currentStepIndex < displaySteps.count - 1 {
                Button {
                    advanceStep()
                } label: {
                    HStack(spacing: 4) {
                        Text("Next Step")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(accentColor)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var detailLevelIcon: String {
        switch detailLevel {
        case .beginner: return "text.bubble"
        case .intermediate: return "book.closed"
        case .advanced: return "graduationcap"
        }
    }

    private func advanceStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStepIndex < displaySteps.count - 1 {
                currentStepIndex += 1
            } else {
                hasCompletedExample = true
            }
        }
        HapticManager.shared.light()
    }

    // MARK: - Step Navigation List (Collapsed)

    private var stepNavigationList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(displaySteps.indices), id: \.self) { index in
                let step = displaySteps[index]
                let isPast = index < currentStepIndex
                let isCurrent = index == currentStepIndex

                StepNavigationRow(
                    title: step.action,
                    isPast: isPast,
                    isCurrent: isCurrent,
                    accentColor: accentColor
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStepIndex = index
                    }
                    HapticManager.shared.light()
                }
                .disabled(index > currentStepIndex)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private struct StepNavigationRow: View {
        let title: String
        let isPast: Bool
        let isCurrent: Bool
        let accentColor: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: isPast ? "checkmark.circle.fill" : (isCurrent ? "circle.inset.filled" : "circle"))
                        .font(.caption)
                        .foregroundStyle(isPast || isCurrent ? AnyShapeStyle(accentColor) : AnyShapeStyle(.tertiary))

                    Text(title)
                        .font(.caption)
                        .fontWeight(isCurrent ? .semibold : .regular)
                        .foregroundStyle(isPast || isCurrent ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCurrent ? accentColor.opacity(0.06) : .clear)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Step Reasoning (Detail-Level Aware)

    private func reasoningText(for step: SolvingStep) -> String {
        switch detailLevel {
        case .beginner:
            return step.reasoning.text
        case .intermediate:
            return step.reasoning.detailedText ?? step.reasoning.text
        case .advanced:
            let detailed = step.reasoning.detailedText ?? step.reasoning.text
            if let metaphor = step.reasoning.metaphorText {
                return "\(detailed)\n\n\(metaphor)"
            }
            return detailed
        }
    }

    private func whyThisWorks(step: SolvingStep) -> String {
        switch detailLevel {
        case .beginner:
            return step.reasoning.metaphorText ?? step.reasoning.text
        case .intermediate:
            return step.reasoning.detailedText ?? step.reasoning.text
        case .advanced:
            var result = step.reasoning.detailedText ?? step.reasoning.text
            if let metaphor = step.reasoning.metaphorText {
                result += "\n\n\(metaphor)"
            }
            return result
        }
    }

    // MARK: - Completion Message

    private var completionMessage: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Great Progress!")
                    .font(.headline)
                Text("You've solved your equation step by step")
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
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)

            VStack(spacing: 8) {
                Text("Preparing solution steps...")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Building a step-by-step walkthrough for your equation")
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
                Text("Couldn't generate steps")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("We'll show you a pre-made example instead.")
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

    // MARK: - Content Loading

    private func loadContent() {
        isLoading = true
        loadError = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let generator = EquationStepGenerator()
            if let dynamicSteps = generator.generateSteps(equation: equation, type: equationType),
               !dynamicSteps.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) {
                    steps = dynamicSteps
                    usingDynamicSteps = true
                    isLoading = false
                }
                content = ContentLoader.shared.getEquationContent(for: equationType)
                return
            }

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

// MARK: - Prediction Option Button (kept for potential reuse)

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

// MARK: - Interactive Graph Preview (kept for backward compat)

struct InteractiveGraphPreview: View {
    let value: Double
    let equationType: EquationType

    var body: some View {
        InteractiveGraphCanvas(
            value: value,
            equationType: equationType,
            accentColor: equationType == .linear ? .blue : .purple
        )
    }
}

// MARK: - Preview

#Preview("Learning Container - Linear") {
    NavigationStack {
        LearningContainerView(
            equation: "2x + 5 = 13",
            equationType: .linear
        )
        .environmentObject(NavigationCoordinator())
    }
}

#Preview("Learning Container - Quadratic") {
    NavigationStack {
        LearningContainerView(
            equation: "x\u{00B2} + 5x + 6 = 0",
            equationType: .quadratic
        )
        .environmentObject(NavigationCoordinator())
    }
}
#endif

