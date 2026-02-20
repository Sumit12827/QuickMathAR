
#if os(iOS)
import SwiftUI
struct EquationTypeView: View {
    let equation: String
    let equationType: EquationType

    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var analyzer = EquationAnalyzer()

    @State private var showEquation = false
    @State private var showInsight = false
    @State private var showProperties = false
    @State private var showButtons = false
    @State private var curveProgress: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                contentSection
                    .padding(.top, 32)

                Spacer(minLength: 32)

                actionButtonsSection
                    .opacity(showButtons ? 1 : 0)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? 64 : 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(equationType.isSupported ? "Equation Detected" : "Equation Recognized")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            animateAppearance()
            analyzer.analyze(equation: equation, type: equationType)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: 24) {
            equationCard
                .opacity(showEquation ? 1 : 0)
                .offset(y: showEquation ? 0 : 20)

            typeCard
                .opacity(showEquation ? 1 : 0)
                .scaleEffect(showEquation ? 1 : 0.95)

            if equationType.isSupported {
                visualPreviewCard
                    .opacity(showInsight ? 1 : 0)
                    .offset(y: showInsight ? 0 : 16)

                keyPropertiesScroll
                    .opacity(showProperties ? 1 : 0)
                    .offset(y: showProperties ? 0 : 16)
            } else {
                contextMessage
                    .opacity(showInsight ? 1 : 0)
                    .offset(y: showInsight ? 0 : 20)
            }
        }
    }

    // MARK: - Equation Card

    private var equationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .safeTitle(minScale: 0.6)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 1)
                )
        }
    }

    // MARK: - Type Card

    private var typeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Equation Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                typeIcon
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(equationType.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .safeTitle(minScale: 0.8, alignment: .leading)

                    Text(equationType.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .safeBody(alignment: .leading)
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(typeBackgroundColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(typeBackgroundColor.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Type Icon

    private var typeIcon: some View {
        ZStack {
            Circle()
                .fill(typeBackgroundColor.opacity(0.15))

            Image(systemName: equationType.iconName)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(typeBackgroundColor)
        }
    }

    private var typeBackgroundColor: Color {
        switch equationType {
        case .linear: return .blue
        case .quadratic: return .purple
        case .constant: return .gray
        case .cubicPolynomial, .higherPolynomial: return .orange
        case .circle, .ellipse, .hyperbola: return .teal
        case .trigonometric: return .cyan
        case .exponential: return .pink
        case .logarithmic: return .indigo
        case .absoluteValue: return .mint
        case .squareRoot: return .green
        case .rationalFunction: return .brown
        case .malformed: return .red
        case .unknown: return .red
        }
    }

    // MARK: - Visual Preview Card

    private var visualPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Visual Preview")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.secondary)
            }

            if case .completed(let analysis) = analyzer.state {
                ZStack(alignment: .bottom) {
                    // Graph canvas with animated curve
                    Canvas { context, size in
                        drawGraphCanvas(context: context, size: size, analysis: analysis)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Insight badges overlay
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(insightBadges(analysis), id: \.self) { badge in
                                Text(badge)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(typeBackgroundColor.opacity(0.2), lineWidth: 1)
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                        curveProgress = 1
                    }
                }
            } else {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 180)
                    .overlay {
                        ShimmerView(lineCount: 1)
                            .frame(height: 160)
                            .padding(10)
                    }
            }
        }
    }

    private func drawGraphCanvas(context: GraphicsContext, size: CGSize, analysis: EquationAnalysis) {
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

        // Extract coefficients
        let coeffs = analysis.coefficients

        // Draw curve
        var curve = Path()
        let scale: CGFloat = size.width / 8

        if equationType == .quadratic {
            let a = CGFloat(coeffs.first(where: { $0.symbol == "a" })?.value ?? 1)
            let b = CGFloat(coeffs.first(where: { $0.symbol == "b" })?.value ?? 0)
            let c = CGFloat(coeffs.first(where: { $0.symbol == "c" })?.value ?? 0)

            let step: CGFloat = 2
            for px in stride(from: CGFloat(0), through: size.width * curveProgress, by: step) {
                let x = (px - center.x) / scale
                let y = a * x * x + b * x + c
                let screenY = center.y - y * scale * 0.6

                if px == 0 {
                    curve.move(to: CGPoint(x: px, y: min(max(screenY, -20), size.height + 20)))
                } else {
                    curve.addLine(to: CGPoint(x: px, y: min(max(screenY, -20), size.height + 20)))
                }
            }
        } else {
            let m = CGFloat(coeffs.first(where: { $0.symbol == "m" })?.value ?? 1)
            let b = CGFloat(coeffs.first(where: { $0.symbol == "b" })?.value ?? 0)

            let startX: CGFloat = 0
            let endX = size.width * curveProgress
            let startY = center.y - (m * (startX - center.x) / scale + b) * scale * 0.6
            let endY = center.y - (m * (endX - center.x) / scale + b) * scale * 0.6

            curve.move(to: CGPoint(x: startX, y: startY))
            curve.addLine(to: CGPoint(x: endX, y: endY))
        }

        context.stroke(
            curve,
            with: .color(typeBackgroundColor),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }

    private func insightBadges(_ analysis: EquationAnalysis) -> [String] {
        var badges: [String] = []

        if equationType == .quadratic {
            let a = analysis.coefficients.first(where: { $0.symbol == "a" })?.value ?? 1
            badges.append(a > 0 ? "Opens upward" : "Opens downward")

            if let disc = analysis.keyFeatures.first(where: { $0.label == "Discriminant" }),
               let detail = disc.detail {
                badges.append(detail)
            }

            if let vertex = analysis.keyFeatures.first(where: { $0.label == "Vertex" }) {
                badges.append("Vertex \(vertex.value)")
            }
        } else {
            let m = analysis.coefficients.first(where: { $0.symbol == "m" })?.value ?? 0
            if m > 0 {
                badges.append("Rising line")
            } else if m < 0 {
                badges.append("Falling line")
            } else {
                badges.append("Horizontal")
            }
            badges.append("1 solution")
        }

        return badges
    }

    // MARK: - Key Properties Horizontal Scroll

    private var keyPropertiesScroll: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Key Properties")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(.secondary)
            }

            if case .completed(let analysis) = analyzer.state {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Coefficients
                        ForEach(analysis.coefficients, id: \.symbol) { coeff in
                            propertyCard(
                                title: coeff.symbol,
                                value: coeff.displayValue,
                                subtitle: coeff.meaning,
                                color: typeBackgroundColor
                            )
                        }

                        // Key features (discriminant, vertex, etc.)
                        ForEach(analysis.keyFeatures, id: \.label) { feature in
                            propertyCard(
                                title: feature.label,
                                value: feature.value,
                                subtitle: feature.detail ?? "",
                                color: typeBackgroundColor,
                                icon: feature.icon
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { _ in
                            ShimmerView(lineCount: 1)
                                .frame(width: 90, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private func propertyCard(title: String, value: String, subtitle: String, color: Color, icon: String? = nil) -> some View {
        VStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            } else {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(icon != nil ? title : subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90, height: 80)
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Context Message (Unsupported)

    private var contextMessage: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: equationType.isSupported ? "lightbulb" : "graduationcap.fill")
                .font(.body)
                .foregroundStyle(equationType.isSupported ? .yellow : .blue)
                .frame(width: 24)

            Text(equationType.educationalMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeBody(alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    (equationType.isSupported ? Color.yellow : Color.blue).opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if equationType.isSupported {
                supportedEquationActions
            } else {
                unsupportedEquationActions
            }
        }
        .frame(maxWidth: 500)
    }

    private var supportedEquationActions: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Choose your path")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .topTrailing) {
                LearningPathButton(
                    title: "Understand Visually",
                    subtitle: "See what this equation means intuitively",
                    icon: "lightbulb.fill",
                    color: .yellow
                ) {
                    let analysis = currentAnalysis
                    navigationCoordinator.push(.conceptExplanation(
                        equation: equation,
                        type: equationType,
                        analysis: analysis
                    ))
                }

                Text("Recommended")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
                    .offset(x: -8, y: -6)
            }

            LearningPathButton(
                title: "Solve Step-by-Step",
                subtitle: "Walk through solving your equation",
                icon: "list.number",
                color: typeBackgroundColor
            ) {
                navigationCoordinator.push(.learning(equation: equation, type: equationType))
            }

            LearningPathButton(
                title: "See in AR",
                subtitle: "Place the graph in your space",
                icon: "arkit",
                color: .green
            ) {
                navigationCoordinator.push(.arVisualization(equation: equation, type: equationType))
            }
        }
    }

    private var currentAnalysis: EquationAnalysis? {
        if case .completed(let analysis) = analyzer.state {
            return analysis
        }
        return nil
    }

    private var unsupportedEquationActions: some View {
        VStack(spacing: 20) {
            educationalCard

            Text("What would you like to do?")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LearningPathButton(
                title: "Try a Linear Equation",
                subtitle: "Example: 2x + 5 = 13",
                icon: "line.diagonal",
                color: .blue
            ) {
                navigationCoordinator.pop()
            }

            LearningPathButton(
                title: "Try a Quadratic Equation",
                subtitle: "Example: x\u{00B2} - 4 = 0",
                icon: "point.topleft.down.to.point.bottomright.curvepath",
                color: .purple
            ) {
                navigationCoordinator.pop()
            }

            LearningPathButton(
                title: "Explore Concepts",
                subtitle: "Learn about different equation types",
                icon: "book.fill",
                color: .orange
            ) {
                navigationCoordinator.push(.exploreConcepts)
            }

            LearningPathButton(
                title: "Enter Different Equation",
                subtitle: "Go back and try again",
                icon: "arrow.uturn.backward",
                color: .secondary
            ) {
                navigationCoordinator.pop()
            }
        }
    }

    private var educationalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.blue)
                Text("Did You Know?")
                    .font(.headline)
            }

            Text(educationalFunFact)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if equationType != .unknown {
                HStack(spacing: 6) {
                    Text("Standard form:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(equationType.standardForm)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                }
                .padding(.top, 4)
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("QuickMathsAR focuses on linear and quadratic equations to build strong foundations.")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }

    private var educationalFunFact: String {
        switch equationType {
        case .cubicPolynomial:
            return "Cubic equations were first solved in the 16th century by Italian mathematicians in a dramatic mathematical duel! They can have up to 3 real solutions."
        case .higherPolynomial:
            return "The mathematician \u{00C9}variste Galois proved at age 20 that polynomials of degree 5 or higher have no general formula solution \u{2014} a groundbreaking discovery!"
        case .circle:
            return "The circle equation x\u{00B2} + y\u{00B2} = r\u{00B2} comes from the Pythagorean theorem! Every point on a circle is exactly r units from the center."
        case .ellipse:
            return "Planets orbit the Sun in ellipses, not perfect circles! Johannes Kepler discovered this in 1609, revolutionizing astronomy."
        case .hyperbola:
            return "Hyperbolas appear in GPS navigation! The intersection of hyperbolic signals from satellites pinpoints your location."
        case .trigonometric:
            return "Trigonometric functions describe waves \u{2014} from sound and light to ocean tides. Music, radio, and WiFi all rely on these wave patterns!"
        case .exponential:
            return "Exponential growth is incredibly powerful \u{2014} if you fold a piece of paper 42 times, it would reach from Earth to the Moon!"
        case .logarithmic:
            return "The Richter scale for earthquakes uses logarithms \u{2014} each whole number increase means 10x more shaking! A magnitude 6 is 10x stronger than a magnitude 5."
        case .absoluteValue:
            return "Absolute value measures distance from zero, regardless of direction. It's used in error calculations, signal processing, and optimization!"
        case .squareRoot:
            return "The ancient Babylonians could calculate square roots over 3,000 years ago! Their method is still used in computers today."
        case .rationalFunction:
            return "Rational functions describe many real-world relationships, like how electrical resistance combines in parallel circuits or how drug concentration changes in the body."
        case .malformed:
            return "Even the greatest mathematicians made notation mistakes! Clear notation is key to solving equations correctly."
        case .unknown:
            return "Mathematics is vast \u{2014} there are equation types spanning algebra, calculus, differential equations, and beyond. Start with the fundamentals!"
        default:
            return "Every equation type has its own unique properties and real-world applications!"
        }
    }

    // MARK: - Animation

    private func animateAppearance() {
        withAnimation(.easeOut(duration: 0.4)) {
            showEquation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.4)) {
                showInsight = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.4)) {
                showProperties = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.4)) {
                showButtons = true
            }
        }
    }
}

// MARK: - Learning Path Button

struct LearningPathButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(color.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .safeTitle(minScale: 0.85, alignment: .leading)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .safeCaption(alignment: .leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Linear - Light") {
    NavigationStack {
        EquationTypeView(equation: "2x + 5 = 13", equationType: .linear)
            .environmentObject(NavigationCoordinator())
    }
    .preferredColorScheme(.light)
}

#Preview("Linear - Dark") {
    NavigationStack {
        EquationTypeView(equation: "2x + 5 = 13", equationType: .linear)
            .environmentObject(NavigationCoordinator())
    }
    .preferredColorScheme(.dark)
}

#Preview("Quadratic") {
    NavigationStack {
        EquationTypeView(equation: "x\u{00B2} + 5x + 6 = 0", equationType: .quadratic)
            .environmentObject(NavigationCoordinator())
    }
}

#Preview("Unsupported - Trig") {
    NavigationStack {
        EquationTypeView(equation: "sin(x) = 0", equationType: .trigonometric(function: "sin"))
            .environmentObject(NavigationCoordinator())
    }
}

#Preview("Unsupported - Circle") {
    NavigationStack {
        EquationTypeView(equation: "x\u{00B2} + y\u{00B2} = 25", equationType: .circle)
            .environmentObject(NavigationCoordinator())
    }
}
#endif
