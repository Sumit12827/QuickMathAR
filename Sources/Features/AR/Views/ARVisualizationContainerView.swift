//
//  ARVisualizationContainerView.swift
//  QuickMathsAR
//
//  Container for AR graph visualization with equation parsing and navigation
//

import SwiftUI

/// Container view that wraps ARGraphScreen with proper equation parsing,
/// parameter adjustments, and navigation to reflection
/// Container view that wraps ARGraphScreen with proper equation parsing,
/// parameter adjustments, and navigation to reflection
public struct ARVisualizationContainerView: View {
    
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
    
    @State private var showARView: Bool = false
    @State private var slope: Double = 1.0
    @State private var yIntercept: Double = 0.0
    @State private var coefficientA: Double = 1.0
    @State private var coefficientB: Double = 0.0
    @State private var coefficientC: Double = 0.0
    @State private var hasInteracted: Bool = false
    @State private var showHapticFeedback: Bool = true
    @State private var hasParsedEquation: Bool = false
    
    // MARK: - Computed Properties
    
    private var accentColor: Color {
        switch equationType {
        case .linear: return .blue
        case .quadratic: return .purple
        case .constant: return .gray
        default: return .orange
        }
    }
    
    private var graphData: GraphData {
        if equationType == .linear {
            return GraphDataGenerator.generate(
                linear: LinearEquation(slope: Float(slope), yIntercept: Float(yIntercept))
            )
        } else {
            return GraphDataGenerator.generate(
                quadratic: QuadraticEquation(a: Float(coefficientA), b: Float(coefficientB), c: Float(coefficientC))
            )
        }
    }
    
    private var graphEquationType: GraphEquationType {
        equationType == .linear ? .linear : .quadratic
    }
    
    // MARK: - Body

    public var body: some View {
        Group {
            if showARView {
                // Full AR experience
                ARGraphScreen(
                    equationType: graphEquationType,
                    graphData: graphData,
                    onDismiss: {
                        showARView = false
                    }
                )
            } else {
                // Setup and control screen
                setupScreen
            }
        }
        .navigationBarHidden(showARView)
        .onAppear {
            parseScannedEquation()
        }
    }

    // MARK: - Equation Parsing

    /// Parses the scanned equation and initializes state variables with extracted coefficients
    private func parseScannedEquation() {
        guard !hasParsedEquation else { return }
        hasParsedEquation = true

        if equationType == .linear {
            if let parsed = EquationParser.parseLinearEquation(equation) {
                slope = Double(parsed.slope)
                yIntercept = Double(parsed.yIntercept)
            }
        } else if equationType == .quadratic {
            if let parsed = EquationParser.parseQuadraticEquation(equation) {
                coefficientA = Double(parsed.a)
                coefficientB = Double(parsed.b)
                coefficientC = Double(parsed.c)
            }
        }
    }

    // MARK: - Setup Screen
    
    private var setupScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Equation display with live update
                    equationDisplayCard
                    
                    // Parameter controls
                    parameterControlsSection
                    
                    // 2D Preview
                    previewSection
                    
                    // AR Instructions
                    arInstructionsCard
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 48 : 20)
                .padding(.top, 24)
            }
            
            // Fixed bottom action bar — AR launch always visible
            FixedBottomActionBar(accentColor: accentColor) {
                HStack(spacing: 10) {
                    Image(systemName: "arkit")
                        .font(.title3)
                    Text("Place in Your Space")
                }
            } primaryAction: {
                showARView = true
            } secondaryLabel: {
                Text("Jump to Takeaways")
            } secondaryAction: {
                let insights = generateInsights()
                navigationCoordinator.push(.reflection(equationType: equationType, insights: insights))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AR Visualization")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "arkit")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(accentColor)
                .frame(width: 88, height: 88)
                .background(
                    Circle()
                        .fill(accentColor.opacity(0.1))
                )
            
            Text("See Math in Your Space")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Adjust the parameters below, then place the graph in AR")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Equation Display Card
    
    private var equationDisplayCard: some View {
        VStack(spacing: 12) {
            Text("Scanned: \(equation)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(currentEquationString)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(accentColor)
                .animation(.easeInOut(duration: 0.2), value: currentEquationString)

            if hasInteracted {
                Text("Modified from original")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var currentEquationString: String {
        if equationType == .linear {
            let slopeStr = slope == 1 ? "" : (slope == -1 ? "-" : String(format: "%.1f", slope))
            let interceptStr = yIntercept >= 0 ? "+ \(String(format: "%.1f", yIntercept))" : "- \(String(format: "%.1f", abs(yIntercept)))"
            return "y = \(slopeStr)x \(interceptStr)"
        } else {
            let aStr = coefficientA == 1 ? "" : (coefficientA == -1 ? "-" : String(format: "%.1f", coefficientA))
            let bStr = coefficientB >= 0 ? "+ \(String(format: "%.1f", coefficientB))" : "- \(String(format: "%.1f", abs(coefficientB)))"
            let cStr = coefficientC >= 0 ? "+ \(String(format: "%.1f", coefficientC))" : "- \(String(format: "%.1f", abs(coefficientC)))"
            return "y = \(aStr)x² \(bStr)x \(cStr)"
        }
    }
    
    // MARK: - Parameter Controls
    
    private var parameterControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Adjust Parameters")
                    .font(.headline)
            } icon: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(accentColor)
            }
            
            VStack(spacing: 16) {
                if equationType == .linear {
                    // Slope slider
                    ParameterSlider(
                        label: "Slope (m)",
                        value: $slope,
                        range: -5...5,
                        step: 0.5,
                        color: accentColor,
                        hint: slope > 0 ? "Rising ↗" : (slope < 0 ? "Falling ↘" : "Flat →")
                    )
                    .onChange(of: slope) { _, _ in
                        triggerHaptic()
                        hasInteracted = true
                    }
                    
                    // Y-intercept slider
                    ParameterSlider(
                        label: "Y-Intercept (b)",
                        value: $yIntercept,
                        range: -5...5,
                        step: 0.5,
                        color: .orange,
                        hint: yIntercept > 0 ? "Above origin" : (yIntercept < 0 ? "Below origin" : "Through origin")
                    )
                    .onChange(of: yIntercept) { _, _ in
                        triggerHaptic()
                        hasInteracted = true
                    }
                    
                } else {
                    // Coefficient A slider
                    ParameterSlider(
                        label: "Coefficient a",
                        value: $coefficientA,
                        range: -3...3,
                        step: 0.5,
                        color: accentColor,
                        hint: coefficientA > 0 ? "Opens up ∪" : (coefficientA < 0 ? "Opens down ∩" : "Not a parabola!")
                    )
                    .onChange(of: coefficientA) { _, _ in
                        triggerHaptic()
                        hasInteracted = true
                    }
                    
                    // Coefficient B slider
                    ParameterSlider(
                        label: "Coefficient b",
                        value: $coefficientB,
                        range: -5...5,
                        step: 0.5,
                        color: .orange,
                        hint: "Shifts the vertex horizontally"
                    )
                    .onChange(of: coefficientB) { _, _ in
                        triggerHaptic()
                        hasInteracted = true
                    }
                    
                    // Coefficient C slider
                    ParameterSlider(
                        label: "Coefficient c",
                        value: $coefficientC,
                        range: -5...5,
                        step: 0.5,
                        color: .green,
                        hint: "Moves the graph up or down"
                    )
                    .onChange(of: coefficientC) { _, _ in
                        triggerHaptic()
                        hasInteracted = true
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
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("2D Preview")
                    .font(.subheadline)
                    .fontWeight(.medium)
            } icon: {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.secondary)
            }
            
            Graph2DView(graphData: graphData)
                .frame(height: 200)
        }
    }
    
    // MARK: - AR Instructions Card
    
    private var arInstructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("In AR, you can:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(icon: "figure.walk", text: "Walk around the graph to see it from all angles")
                InstructionRow(icon: "hand.pinch", text: "Pinch to zoom in and out")
                InstructionRow(icon: "hand.draw", text: "Drag along the curve to trace values")
                InstructionRow(icon: "iphone.radiowaves.left.and.right", text: "Feel haptic feedback at key points")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.08))
        )
    }
    
    // MARK: - Launch AR Button & Skip (moved to fixed bottom bar in setupScreen)
    
    // MARK: - Helpers
    
    private func triggerHaptic() {
        guard showHapticFeedback else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func generateInsights() -> [String] {
        switch equationType {
        case .linear:
            return [
                "Changing the slope makes the line steeper or flatter",
                "The y-intercept moves the line up or down",
                "Every point on the line satisfies the equation",
                "Linear graphs are always straight lines"
            ]
        case .quadratic:
            return [
                "The 'a' coefficient controls the parabola's direction and width",
                "The vertex is the turning point of the parabola",
                "Parabolas are symmetric about their axis of symmetry",
                "The roots (x-intercepts) are where the parabola crosses the x-axis"
            ]
        case .constant:
            return [
                "Constant equations have no variables",
                "They represent horizontal lines or simple true/false statements"
            ]
        default:
            return [
                "Higher-degree polynomials create more complex curves",
                "Understanding basic equations helps build to advanced math"
            ]
        }
    }
}

// MARK: - Parameter Slider

struct ParameterSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let color: Color
    let hint: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                    .frame(width: 50, alignment: .trailing)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(color)
                .accessibilityLabel("\(label) slider")
                .accessibilityValue(String(format: "%.1f", value))
            
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview

#Preview("AR Container - Linear") {
    NavigationStack {
        ARVisualizationContainerView(
            equation: "y = 2x + 1",
            equationType: .linear
        )
        .environmentObject(NavigationCoordinator())
    }
}

#Preview("AR Container - Quadratic") {
    NavigationStack {
        ARVisualizationContainerView(
            equation: "y = x² - 2x - 3",
            equationType: .quadratic
        )
        .environmentObject(NavigationCoordinator())
    }
}
