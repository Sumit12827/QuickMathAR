//
//  ConceptExplorerView.swift
//  QuickMathsAR
//
//  Allows users to browse and learn concepts from scratch
//

import SwiftUI

/// A view for exploring equation types and concepts from scratch
/// Entry point for users who want to learn without scanning
public struct ConceptExplorerView: View {
    
    public init() {}

    
    // MARK: - Environment
    
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - State
    
    @State private var selectedCategory: ExplorerCategory = .equationTypes
    
    // MARK: - Computed Properties
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : 20
    }
    
    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Category picker
                categoryPicker
                
                // Content based on category
                switch selectedCategory {
                case .equationTypes:
                    equationTypesSection
                case .foundations:
                    foundationsSection
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Explore Concepts")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text("Learn at Your Own Pace")
                .font(.headline)
                .safeTitle(minScale: 0.85)

            Text("Choose a topic to begin your mathematical journey")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeBody()
        }
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(ExplorerCategory.allCases) { category in
                Text(category.displayName).tag(category)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Equation Types Section
    
    private var equationTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Equation Types")
                .font(.headline)
            
            // Linear Equations Card
            ExplorerCard(
                title: "Linear Equations",
                subtitle: "First-degree equations with straight-line graphs",
                icon: "line.diagonal",
                color: .blue,
                examples: ["2x + 5 = 13", "y = 3x - 2", "x - 4 = 0"]
            ) {
                navigationCoordinator.push(.conceptExplanation(equation: "2x + 5 = 13", type: .linear, analysis: nil))
            }
            
            // Quadratic Equations Card
            ExplorerCard(
                title: "Quadratic Equations",
                subtitle: "Second-degree equations with parabolic graphs",
                icon: "point.topleft.down.to.point.bottomright.curvepath",
                color: .purple,
                examples: ["x² + 5x + 6 = 0", "y = x² - 4", "2x² - 3x + 1 = 0"]
            ) {
                navigationCoordinator.push(.conceptExplanation(equation: "x² + 5x + 6 = 0", type: .quadratic, analysis: nil))
            }
            
            // Coming Soon Card
            ComingSoonCard(
                title: "More Coming Soon",
                items: ["Cubic Equations", "Exponential Functions", "Trigonometric Equations"]
            )
        }
    }
    
    // MARK: - Foundations Section

    private var foundationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mathematical Foundations")
                .font(.headline)

            Text("Master these building blocks before tackling equations")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Foundation cards
            FoundationExplorerCard(
                concept: "Addition",
                symbol: "+",
                description: "Combining quantities",
                color: .green
            ) {
                navigationCoordinator.push(.arithmeticConcept(conceptId: "addition"))
            }

            FoundationExplorerCard(
                concept: "Subtraction",
                symbol: "−",
                description: "Finding differences",
                color: .orange
            ) {
                navigationCoordinator.push(.arithmeticConcept(conceptId: "subtraction"))
            }

            FoundationExplorerCard(
                concept: "Multiplication",
                symbol: "×",
                description: "Repeated addition and scaling",
                color: .blue
            ) {
                navigationCoordinator.push(.arithmeticConcept(conceptId: "multiplication"))
            }

            FoundationExplorerCard(
                concept: "Division",
                symbol: "÷",
                description: "Splitting into equal parts",
                color: .purple
            ) {
                navigationCoordinator.push(.arithmeticConcept(conceptId: "division"))
            }

            FoundationExplorerCard(
                concept: "Order of Operations",
                symbol: "( )",
                description: "PEMDAS: The rules of calculation",
                color: .pink
            ) {
                navigationCoordinator.push(.arithmeticConcept(conceptId: "order_of_operations"))
            }
        }
    }
}

// MARK: - Explorer Category

enum ExplorerCategory: String, CaseIterable, Identifiable {
    case equationTypes = "equations"
    case foundations = "foundations"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .equationTypes: return "Equation Types"
        case .foundations: return "Foundations"
        }
    }
}

// MARK: - Explorer Card

struct ExplorerCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let examples: [String]
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.medium()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(color.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .safeInline()

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .safeCaption(alignment: .leading)
                    }

                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                
                // Examples
                VStack(alignment: .leading, spacing: 6) {
                    Text("Examples:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(examples, id: \.self) { example in
                            Text(example)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(color.opacity(0.1))
                                )
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Learn about \(title)")
        .accessibilityHint("\(subtitle). Examples include \(examples.joined(separator: ", "))")
    }
}

// MARK: - Foundation Explorer Card

struct FoundationExplorerCard: View {
    let concept: String
    let symbol: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.light()
            action()
        } label: {
            HStack(spacing: 16) {
                // Symbol
                Text(symbol)
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(concept)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Learn about \(concept)")
        .accessibilityHint(description)
    }
}

// MARK: - Coming Soon Card

struct ComingSoonCard: View {
    let title: String
    let items: [String]

    private let comingSoonItems: [(name: String, icon: String)] = [
        ("Cubic Equations", "function"),
        ("Exponential", "chart.line.uptrend.xyaxis"),
        ("Trigonometry", "waveform"),
        ("Logarithms", "number"),
        ("Systems", "square.grid.2x2"),
        ("Inequalities", "lessthan.circle")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.yellow)

                Text("Coming Soon")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Text("We're working on adding more equation types to help you learn.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeBody(alignment: .leading)

            // Grid of upcoming types
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(comingSoonItems, id: \.name) { item in
                    ComingSoonBadge(title: item.name, icon: item.icon)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Coming Soon Badge

struct ComingSoonBadge: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Light") {
    NavigationStack {
        ConceptExplorerView()
            .environmentObject(NavigationCoordinator())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ConceptExplorerView()
            .environmentObject(NavigationCoordinator())
    }
    .preferredColorScheme(.dark)
}
