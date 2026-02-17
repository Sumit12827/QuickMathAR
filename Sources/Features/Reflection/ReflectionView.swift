//
//  ReflectionView.swift
//  QuickMathsAR
//
//  Closes the learning loop with key takeaways and insights
//

import SwiftUI

/// A view that presents key takeaways after learning/AR interaction
/// Converts interaction into long-term understanding
/// A view that presents key takeaways after learning/AR interaction
/// Converts interaction into long-term understanding
public struct ReflectionView: View {
    
    // MARK: - Properties
    
    public let equationType: EquationType
    public let insights: [String]
    
    public init(equationType: EquationType, insights: [String]) {
        self.equationType = equationType
        self.insights = insights
    }

    
    // MARK: - Environment
    
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - State

    @State private var revealedCards: Set<Int> = []
    @State private var showAllCards: Bool = false
    @State private var headerOpacity: Double = 0
    @State private var headerScale: Double = 0.8
    
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
    
    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Key takeaway cards
                takeawayCardsSection
                
                // Connection section
                connectionSection
                
                // Action buttons
                actionButtonsSection

                Spacer(minLength: 48)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("What You Learned")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            animateHeader()
            animateCards()
        }
    }
    
    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Success icon with outer glow
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.05))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
            }
            .scaleEffect(headerScale)

            Text("Great Work! 🎉")
                .font(.title2)
                .fontWeight(.bold)

            Text("Here's what you've discovered about \(equationType.displayName.lowercased())s")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeBody()
        }
        .opacity(headerOpacity)
    }
    
    // MARK: - Takeaway Cards Section
    
    private var takeawayCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Key Takeaways")
                    .font(.headline)
            } icon: {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                    TakeawayCard(
                        number: index + 1,
                        text: insight,
                        color: accentColor,
                        isRevealed: showAllCards || revealedCards.contains(index)
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.15), value: revealedCards)
                }
            }
        }
    }
    
    // MARK: - Connection Section
    
    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("The Big Picture")
                    .font(.headline)
            } icon: {
                Image(systemName: "puzzlepiece.fill")
                    .foregroundStyle(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(bigPictureText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                
                // Visual connection
                HStack(spacing: 16) {
                    ConnectionBubble(
                        icon: equationType == .linear ? "line.diagonal" : "point.topleft.down.to.point.bottomright.curvepath",
                        label: "Shape",
                        color: accentColor
                    )
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    
                    ConnectionBubble(
                        icon: "slider.horizontal.3",
                        label: "Control",
                        color: .orange
                    )
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    
                    ConnectionBubble(
                        icon: "brain.head.profile",
                        label: "Intuition",
                        color: .green
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    private var bigPictureText: String {
        switch equationType {
        case .linear:
            return "Every linear equation tells a story of constant change. The slope is the rate of that change, and the intercept is where your story begins. When you see y = mx + b, you now see a line in your mind!"
        case .quadratic:
            return "Quadratic equations capture motion and optimization. The parabola's shape helps us find maximums and minimums, predict trajectories, and model curved relationships. The vertex is always the key!"
        case .constant:
            return "Constant equations represent unchanging values. No matter what x is, y stays the same. This simplicity is powerful—it's the foundation for understanding how other equations change."
        default:
            return "You've explored an advanced equation type! While this goes beyond our current AR visualizations, the thinking skills you've developed apply to all mathematical problem-solving."
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Primary: Return Home
            Button {
                navigationCoordinator.popToRoot()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                    Text("Return Home")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Return home")
            .accessibilityHint("Goes back to the main screen")
            
            // Secondary: Explore more
            Button {
                navigationCoordinator.replaceAll(with: .exploreConcepts)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                    Text("Explore More Concepts")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Explore more concepts")
            .accessibilityHint("Browse additional equation types and concepts")
            
            // Tertiary: Build another equation
            Button {
                navigationCoordinator.replaceAll(with: .equationInput)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.square.fill.on.square.fill")
                    Text("Build Another Equation")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Scan another equation")
            .accessibilityHint("Opens camera to scan a new equation")
        }
        .frame(maxWidth: 400)
    }
    
    // MARK: - Animation

    private func animateHeader() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            headerOpacity = 1
            headerScale = 1
        }
    }

    private func animateCards() {
        for index in 0..<insights.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2 + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    _ = revealedCards.insert(index)
                }

                // Haptic feedback for each card reveal
                if index < insights.count - 1 {
                    HapticManager.shared.light()
                } else {
                    HapticManager.shared.medium()
                }
            }
        }

        // Show all after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(insights.count) * 0.2 + 0.5) {
            showAllCards = true
        }
    }
}

// MARK: - Takeaway Card

struct TakeawayCard: View {
    let number: Int
    let text: String
    let color: Color
    let isRevealed: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number badge
            Text("\(number)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color)
                )
            
            // Text
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .safeBody(alignment: .leading)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : 20)
    }
}

// MARK: - Connection Bubble

struct ConnectionBubble: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .safeInline()
        }
    }
}

// MARK: - Preview

#Preview("Reflection - Linear") {
    NavigationStack {
        ReflectionView(
            equationType: .linear,
            insights: [
                "The slope controls how steep the line is",
                "A positive slope means the line goes up from left to right",
                "The y-intercept is where the line crosses the y-axis",
                "Linear equations always have exactly one solution"
            ]
        )
        .environmentObject(NavigationCoordinator())
    }
}

#Preview("Reflection - Quadratic") {
    NavigationStack {
        ReflectionView(
            equationType: .quadratic,
            insights: [
                "The 'a' coefficient determines if the parabola opens up or down",
                "The vertex is the highest or lowest point",
                "Quadratic equations can have 0, 1, or 2 solutions",
                "The axis of symmetry passes through the vertex"
            ]
        )
        .environmentObject(NavigationCoordinator())
    }
}
