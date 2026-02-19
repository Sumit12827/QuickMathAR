
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
    
   
    
    private var contentSection: some View {
        VStack(spacing: 24) {
          
            equationCard
                .opacity(showEquation ? 1 : 0)
                .offset(y: showEquation ? 0 : 20)
            
           
            typeCard
                .opacity(showEquation ? 1 : 0)
                .scaleEffect(showEquation ? 1 : 0.95)
            
           
            if equationType.isSupported {
                aiInsightCard
                    .opacity(showInsight ? 1 : 0)
                    .offset(y: showInsight ? 0 : 16)
                
                
                keyPropertiesGrid
                    .opacity(showProperties ? 1 : 0)
                    .offset(y: showProperties ? 0 : 16)
            } else {
               
                contextMessage
                    .opacity(showInsight ? 1 : 0)
                    .offset(y: showInsight ? 0 : 20)
            }
        }
    }
    

    
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
   
    
    private var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: 16) {
         
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.body)
                    .foregroundStyle(.purple)
                
                Text("AI Insight")
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
            
            switch analyzer.state {
            case .idle, .analyzing:
               
                VStack(alignment: .leading, spacing: 10) {
                    ShimmerView(lineCount: 1)
                        .frame(height: 16)
                    ShimmerView(lineCount: 1)
                        .frame(height: 16)
                        .frame(maxWidth: 240)
                    ShimmerView(lineCount: 1)
                        .frame(height: 16)
                        .frame(maxWidth: 180)
                }
                .padding(.vertical, 4)
                
            case .completed(let analysis):
                VStack(alignment: .leading, spacing: 12) {
                   
                    Text(analysis.whatThisEquationDoes)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .safeBody(alignment: .leading)
                    
                   
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .frame(width: 20)
                        
                        Text(analysis.realWorldAnalogy)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .safeCaption(alignment: .leading)
                    }
            
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        Text(analysis.solutionPreview)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                
            case .failed:
                Text("Analysis unavailable")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
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
    
    // MARK: - Key Properties Grid
    
    private var keyPropertiesGrid: some View {
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
                // Coefficients row
                if !analysis.coefficients.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(analysis.coefficients, id: \.symbol) { coeff in
                            coefficientBadge(coeff)
                        }
                    }
                }
                
                // Key features grid (2 columns)
                let columns = [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ]
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(analysis.keyFeatures, id: \.label) { feature in
                        featureCell(feature)
                    }
                }
                
                // Graph orientation
                HStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.caption)
                        .foregroundStyle(typeBackgroundColor)
                    
                    Text(analysis.graphOrientation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
                
            } else {
                // Loading placeholder
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerView(lineCount: 1)
                            .frame(height: 48)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func coefficientBadge(_ coeff: CoefficientInfo) -> some View {
        VStack(spacing: 4) {
            Text(coeff.symbol)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(typeBackgroundColor)
            
            Text(coeff.displayValue)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
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
            RoundedRectangle(cornerRadius: 12)
                .fill(typeBackgroundColor.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(typeBackgroundColor.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func featureCell(_ feature: KeyFeature) -> some View {
        HStack(spacing: 10) {
            Image(systemName: feature.icon)
                .font(.caption)
                .foregroundStyle(typeBackgroundColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(typeBackgroundColor.opacity(0.08))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Text(feature.value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if let detail = feature.detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemGroupedBackground))
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
            
            // Option 3: See in AR
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
                subtitle: "Example: x² - 4 = 0",
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
            return "The mathematician Évariste Galois proved at age 20 that polynomials of degree 5 or higher have no general formula solution — a groundbreaking discovery!"
        case .circle:
            return "The circle equation x² + y² = r² comes from the Pythagorean theorem! Every point on a circle is exactly r units from the center."
        case .ellipse:
            return "Planets orbit the Sun in ellipses, not perfect circles! Johannes Kepler discovered this in 1609, revolutionizing astronomy."
        case .hyperbola:
            return "Hyperbolas appear in GPS navigation! The intersection of hyperbolic signals from satellites pinpoints your location."
        case .trigonometric:
            return "Trigonometric functions describe waves — from sound and light to ocean tides. Music, radio, and WiFi all rely on these wave patterns!"
        case .exponential:
            return "Exponential growth is incredibly powerful — if you fold a piece of paper 42 times, it would reach from Earth to the Moon!"
        case .logarithmic:
            return "The Richter scale for earthquakes uses logarithms — each whole number increase means 10x more shaking! A magnitude 6 is 10x stronger than a magnitude 5."
        case .absoluteValue:
            return "Absolute value measures distance from zero, regardless of direction. It's used in error calculations, signal processing, and optimization!"
        case .squareRoot:
            return "The ancient Babylonians could calculate square roots over 3,000 years ago! Their method is still used in computers today."
        case .rationalFunction:
            return "Rational functions describe many real-world relationships, like how electrical resistance combines in parallel circuits or how drug concentration changes in the body."
        case .malformed:
            return "Even the greatest mathematicians made notation mistakes! Clear notation is key to solving equations correctly."
        case .unknown:
            return "Mathematics is vast — there are equation types spanning algebra, calculus, differential equations, and beyond. Start with the fundamentals!"
        default:
            return "Every equation type has its own unique properties and real-world applications!"
        }
    }
    

    
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
        EquationTypeView(equation: "x² + 5x + 6 = 0", equationType: .quadratic)
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
        EquationTypeView(equation: "x² + y² = 25", equationType: .circle)
            .environmentObject(NavigationCoordinator())
    }
}
