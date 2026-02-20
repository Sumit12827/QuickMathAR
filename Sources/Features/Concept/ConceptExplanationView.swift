//
//  ConceptExplanationView.swift
//  QuickMathsAR
//
//  Provides intuitive, visual explanation of equation types
//

#if os(iOS)
import SwiftUI

/// A view that explains equation concepts visually with interactive exploration
public struct ConceptExplanationView: View {

    // MARK: - Properties

    public let equation: String
    public let equationType: EquationType
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

    @StateObject private var fallbackAnalyzer = EquationAnalyzer()
    @State private var coeffSliderValue: Double = 1.0
    @State private var expandedConnection: String? = nil
    @State private var challengeAnswer: Int? = nil
    @State private var showBallAnimation = false
    @State private var ballProgress: CGFloat = 0

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

    private var content: EquationLearningContent? {
        ContentLoader.shared.getEquationContent(for: equationType)
    }

    private var effectiveAnalysis: EquationAnalysis? {
        if let analysis = analysis { return analysis }
        if case .completed(let a) = fallbackAnalyzer.state { return a }
        return nil
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                        .padding(.bottom, 4)

                    // Interactive coefficient explorer with live graph
                    interactiveExplorerCard

                    // Interactive concept flow (if available)
                    if let conceptFlow = content?.conceptFlow, !conceptFlow.isEmpty {
                        ConceptPagerView(pages: conceptFlow, accentColor: accentColor)
                            .frame(height: 480)
                            .padding(.bottom, 8)
                    }

                    // Real world connections
                    realWorldConnectionsCard

                    // Quick challenge
                    quickChallengeCard
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

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
            if analysis == nil {
                fallbackAnalyzer.analyze(equation: equation, type: equationType)
            }
            // Initialize slider from analysis
            if let a = effectiveAnalysis {
                if equationType == .linear {
                    coeffSliderValue = Double(a.coefficients.first(where: { $0.symbol == "m" })?.value ?? 1)
                } else {
                    coeffSliderValue = Double(a.coefficients.first(where: { $0.symbol == "a" })?.value ?? 1)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: equationType == .linear ? "line.diagonal" : "point.topleft.down.to.point.bottomright.curvepath")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(accentColor)
                .frame(width: 88, height: 88)
                .background(
                    Circle()
                        .fill(accentColor.opacity(0.1))
                )

            Text(equation)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

            Text(equationType.displayName)
                .font(.headline)
                .foregroundStyle(accentColor)
        }
    }

    // MARK: - Interactive Explorer Card

    private var interactiveExplorerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("Interactive Explorer")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(accentColor)
            }

            VStack(spacing: 12) {
                let param = equationType == .linear ? "slope" : "'a'"

                Text("What happens when you change \(param)?")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Live interactive graph
                ZStack {
                    InteractiveGraphCanvas(
                        value: coeffSliderValue,
                        equationType: equationType,
                        accentColor: accentColor,
                        showBall: showBallAnimation,
                        ballProgress: ballProgress
                    )
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )

                // Slider with value display
                HStack {
                    Text(equationType == .linear ? "Slope" : "a")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Slider(value: $coeffSliderValue, in: -3...3, step: 0.5)
                        .tint(accentColor)

                    Text(String(format: "%.1f", coeffSliderValue))
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(accentColor)
                        .frame(width: 40)
                }
                .onChange(of: coeffSliderValue) { _, newValue in
                    HapticManager.shared.light()
                    // Reset ball animation on slider change
                    if showBallAnimation {
                        showBallAnimation = false
                        ballProgress = 0
                    }
                }

                // Direction indicator
                HStack(spacing: 6) {
                    Image(systemName: sliderDirectionIcon)
                        .font(.caption)
                        .foregroundStyle(accentColor)

                    Text(sliderDirectionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Ball animation button
                Button {
                    showBallAnimation = true
                    ballProgress = 0
                    withAnimation(.easeInOut(duration: 2.0)) {
                        ballProgress = 1
                    }
                    HapticManager.shared.light()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                        Text("Watch a ball follow this path")
                            .font(.caption)
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var sliderDirectionIcon: String {
        if equationType == .linear {
            if coeffSliderValue > 0 { return "arrow.up.right" }
            else if coeffSliderValue < 0 { return "arrow.down.right" }
            else { return "arrow.right" }
        } else {
            if coeffSliderValue > 0 { return "arrow.up.to.line" }
            else if coeffSliderValue < 0 { return "arrow.down.to.line" }
            else { return "minus" }
        }
    }

    private var sliderDirectionText: String {
        if equationType == .linear {
            if coeffSliderValue > 1 { return "Steep upward slope" }
            else if coeffSliderValue > 0 { return "Gentle upward slope" }
            else if coeffSliderValue == 0 { return "Flat \u{2014} horizontal line" }
            else if coeffSliderValue > -1 { return "Gentle downward slope" }
            else { return "Steep downward slope" }
        } else {
            if coeffSliderValue > 1 { return "Opens upward (U-shape) \u{2014} Narrow" }
            else if coeffSliderValue > 0 { return "Opens upward (U-shape) \u{2014} Wide" }
            else if abs(coeffSliderValue) < 0.3 { return "Nearly flat \u{2014} approaching a line" }
            else if coeffSliderValue > -1 { return "Opens downward (\u{2229}-shape) \u{2014} Wide" }
            else { return "Opens downward (\u{2229}-shape) \u{2014} Narrow" }
        }
    }

    // MARK: - Real World Connections Card

    private var realWorldConnectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Real World Connections")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "globe")
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                ForEach(realWorldItems, id: \.icon) { item in
                    realWorldRow(item: item)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func realWorldRow(item: RealWorldItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedConnection = expandedConnection == item.icon ? nil : item.icon
                }
                HapticManager.shared.light()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.body)
                        .foregroundStyle(accentColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(accentColor.opacity(0.1))
                        )

                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: expandedConnection == item.icon ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if expandedConnection == item.icon {
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 44)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private struct RealWorldItem {
        let icon: String
        let title: String
        let description: String
    }

    private var realWorldItems: [RealWorldItem] {
        if equationType == .quadratic {
            return [
                RealWorldItem(icon: "basketball.fill", title: "Basketball shots", description: "The arc of a basketball follows a parabolic path \u{2014} the coefficients determine how high and far it goes."),
                RealWorldItem(icon: "building.columns.fill", title: "Bridge arches", description: "Many bridges use parabolic arches because they distribute weight evenly along the curve."),
                RealWorldItem(icon: "chart.line.uptrend.xyaxis", title: "Profit curves", description: "Businesses use quadratic models to find the price point that maximizes profit."),
                RealWorldItem(icon: "scope", title: "Satellite dishes", description: "Parabolic reflectors focus signals to a single point \u{2014} the vertex of the parabola.")
            ]
        } else {
            return [
                RealWorldItem(icon: "car.fill", title: "Constant speed travel", description: "Distance = speed \u{00D7} time is a linear relationship. Double the time, double the distance."),
                RealWorldItem(icon: "dollarsign.circle.fill", title: "Hourly wages", description: "Your earnings grow linearly with hours worked \u{2014} the slope is your hourly rate."),
                RealWorldItem(icon: "thermometer.medium", title: "Temperature conversion", description: "Celsius to Fahrenheit is a linear equation: F = 1.8C + 32."),
                RealWorldItem(icon: "bolt.fill", title: "Ohm's Law", description: "Voltage = Current \u{00D7} Resistance. A straight-line relationship fundamental to electronics.")
            ]
        }
    }

    // MARK: - Quick Challenge Card

    private var quickChallengeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .foregroundStyle(.orange)

                Text("Quick Check")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(challengeQuestion)
                .font(.subheadline)
                .foregroundStyle(.primary)

            // Answer options as pill buttons
            HStack(spacing: 8) {
                ForEach(Array(challengeOptions.enumerated()), id: \.offset) { index, option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            challengeAnswer = index
                        }
                        if index == correctChallengeIndex {
                            HapticManager.shared.play(.success)
                        } else {
                            HapticManager.shared.play(.warning)
                        }
                    } label: {
                        Text(option)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(challengeButtonForeground(index))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(challengeButtonBackground(index))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(challengeButtonBorder(index), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(challengeAnswer != nil)
                }
            }

            // Feedback
            if let answer = challengeAnswer {
                Text(answer == correctChallengeIndex ? "Correct!" : "Not quite \u{2014} \(challengeExplanation)")
                    .font(.caption)
                    .foregroundStyle(answer == correctChallengeIndex ? .green : .orange)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.orange.opacity(0.15), lineWidth: 1)
        )
    }

    private func challengeButtonForeground(_ index: Int) -> Color {
        guard let answer = challengeAnswer else { return .primary }
        if index == correctChallengeIndex { return .white }
        if index == answer { return .white }
        return .primary
    }

    private func challengeButtonBackground(_ index: Int) -> Color {
        guard let answer = challengeAnswer else { return Color(.tertiarySystemGroupedBackground) }
        if index == correctChallengeIndex { return .green }
        if index == answer { return .red.opacity(0.7) }
        return Color(.tertiarySystemGroupedBackground)
    }

    private func challengeButtonBorder(_ index: Int) -> Color {
        guard challengeAnswer != nil else { return accentColor.opacity(0.2) }
        return .clear
    }

    private var challengeQuestion: String {
        if equationType == .quadratic {
            return "If the discriminant is negative, how many real roots does the equation have?"
        } else {
            return "If the slope is zero, what does the graph look like?"
        }
    }

    private var challengeOptions: [String] {
        if equationType == .quadratic {
            return ["0", "1", "2", "Infinite"]
        } else {
            return ["Vertical line", "Horizontal line", "Diagonal line", "No graph"]
        }
    }

    private var correctChallengeIndex: Int {
        0 // First option is correct for both
    }

    private var challengeExplanation: String {
        if equationType == .quadratic {
            return "A negative discriminant means the parabola never crosses the x-axis."
        } else {
            return "Zero slope means no change in y \u{2014} a perfectly flat horizontal line."
        }
    }
}

// MARK: - Interactive Graph Canvas (responds to slider value)

struct InteractiveGraphCanvas: View {
    let value: Double
    let equationType: EquationType
    let accentColor: Color
    var showBall: Bool = false
    var ballProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                // Grid
                let gridSpacing = size.width / 8
                for i in stride(from: CGFloat(0), through: size.width, by: gridSpacing) {
                    var line = Path()
                    line.move(to: CGPoint(x: i, y: 0))
                    line.addLine(to: CGPoint(x: i, y: size.height))
                    context.stroke(line, with: .color(.gray.opacity(0.08)), lineWidth: 0.5)
                }
                for i in stride(from: CGFloat(0), through: size.height, by: gridSpacing) {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: i))
                    line.addLine(to: CGPoint(x: size.width, y: i))
                    context.stroke(line, with: .color(.gray.opacity(0.08)), lineWidth: 0.5)
                }

                // Axes
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

                if equationType == .linear {
                    let slope = value * 0.5
                    let startY = center.y + slope * center.x
                    let endY = center.y - slope * center.x
                    curve.move(to: CGPoint(x: 0, y: startY))
                    curve.addLine(to: CGPoint(x: size.width, y: endY))
                } else {
                    let step: CGFloat = 2
                    for x in stride(from: CGFloat(0), through: size.width, by: step) {
                        let normalizedX = (x - center.x) / (size.width / 4)
                        let y = center.y - value * (normalizedX * normalizedX) * 15

                        if x == 0 {
                            curve.move(to: CGPoint(x: x, y: min(max(y, -10), size.height + 10)))
                        } else {
                            curve.addLine(to: CGPoint(x: x, y: min(max(y, -10), size.height + 10)))
                        }
                    }
                }

                context.stroke(
                    curve,
                    with: .color(accentColor),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )

                // Ball animation
                if showBall {
                    let ballX = size.width * ballProgress
                    let ballY: CGFloat
                    if equationType == .linear {
                        let slope = value * 0.5
                        ballY = center.y + slope * center.x - slope * ballX
                    } else {
                        let normalizedX = (ballX - center.x) / (size.width / 4)
                        ballY = center.y - value * (normalizedX * normalizedX) * 15
                    }

                    let clampedY = min(max(ballY, 4), size.height - 4)
                    let ballRect = CGRect(x: ballX - 5, y: clampedY - 5, width: 10, height: 10)
                    context.fill(Path(ellipseIn: ballRect), with: .color(.orange))
                    // Glow
                    let glowRect = CGRect(x: ballX - 8, y: clampedY - 8, width: 16, height: 16)
                    context.fill(Path(ellipseIn: glowRect), with: .color(.orange.opacity(0.3)))
                }
            }
        }
    }
}

// MARK: - Simple Graph Preview (kept for backward compat)

struct SimpleGraphPreview: View {
    let equationType: EquationType

    var body: some View {
        InteractiveGraphCanvas(
            value: equationType == .quadratic ? 1.0 : 1.0,
            equationType: equationType,
            accentColor: equationType == .linear ? .blue : .purple
        )
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
            equation: "x\u{00B2} + 5x + 6 = 0",
            equationType: .quadratic
        )
        .environmentObject(NavigationCoordinator())
    }
}
#endif
