//
//  EquationTypeView.swift
//  QuickMathsAR
//
//  Displays the detected equation and its classification
//  Handles ALL equation types gracefully with educational UI
//

import SwiftUI

/// View displaying the detected equation and its classified type
/// Serves as a decision point where users choose their learning path
struct EquationTypeView: View {
    
    // MARK: - Properties
    
    /// The detected equation string from OCR
    let equation: String
    
    /// The classified equation type
    let equationType: EquationType
    
    // MARK: - Environment

    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Animation State

    @State private var showEquation = false
    @State private var showType = false
    @State private var showConcept = false
    @State private var showButtons = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Main content
                contentSection
                    .padding(.top, 32)
                
                Spacer(minLength: 32)
                
                // Action buttons section
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
        }
    }
    
    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: 32) {
            // Equation display card
            equationCard
                .opacity(showEquation ? 1 : 0)
                .offset(y: showEquation ? 0 : 20)

            // Type classification card
            typeCard
                .opacity(showType ? 1 : 0)
                .scaleEffect(showType ? 1 : 0.8)

            // Contextual message
            contextMessage
                .opacity(showConcept ? 1 : 0)
                .offset(y: showConcept ? 0 : 20)
        }
    }
    
    // MARK: - Equation Card
    
    private var equationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Label {
                Text("Your Equation")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "function")
                    .foregroundStyle(.secondary)
            }
            
            // Equation display
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
            // Section header
            Label {
                Text("Equation Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
            }
            
            // Type display
            HStack(spacing: 16) {
                // Type icon
                typeIcon
                    .frame(width: 56, height: 56)
                
                // Type information
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
    
    /// Background color based on equation type
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
    
    // MARK: - Context Message
    
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
    
    // MARK: - Supported Equation Actions
    
    private var supportedEquationActions: some View {
        VStack(spacing: 16) {
            // Step indicator
            HStack(spacing: 6) {
                Text("Your learning path")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("Step 1 of 4")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Option 1: Understand the concept (RECOMMENDED)
            ZStack(alignment: .topTrailing) {
                LearningPathButton(
                    title: "Understand the Concept",
                    subtitle: "Start here — learn what this means intuitively",
                    icon: "lightbulb.fill",
                    color: .yellow
                ) {
                    navigationCoordinator.push(.conceptExplanation(equation: equation, type: equationType))
                }
                
                // Recommended badge
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
            
            // Option 2: Learn with examples
            LearningPathButton(
                title: "Learn with Examples",
                subtitle: "Interactive step-by-step walkthrough",
                icon: "list.number",
                color: typeBackgroundColor
            ) {
                navigationCoordinator.push(.learning(equation: equation, type: equationType))
            }
            
            // Option 3: Visualize in AR
            LearningPathButton(
                title: "Visualize in AR",
                subtitle: "See the graph in your space",
                icon: "arkit",
                color: .green
            ) {
                navigationCoordinator.push(.arVisualization(equation: equation, type: equationType))
            }
        }
    }
    
    // MARK: - Unsupported Equation Actions
    
    private var unsupportedEquationActions: some View {
        VStack(spacing: 20) {
            // Educational card
            educationalCard
            
            // Alternative actions
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
    
    // MARK: - Educational Card
    
    private var educationalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.blue)
                Text("Did You Know?")
                    .font(.headline)
            }
            
            // Type-specific fun fact
            Text(educationalFunFact)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Standard form
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
            
            // Scope note
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
    
    /// Fun facts per equation type for the educational card
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

    // MARK: - Animation

    private func animateAppearance() {
        withAnimation(.easeOut(duration: 0.4)) {
            showEquation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showType = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showConcept = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(color.opacity(0.12))
                    )
                
                // Text content
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
                
                // Chevron
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

// MARK: - Preview

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
