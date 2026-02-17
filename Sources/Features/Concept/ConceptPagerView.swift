//
//  ConceptPagerView.swift
//  QuickMathsAR
//
//  Horizontal paging container for concept flow pages
//

import SwiftUI

/// A view that displays concept flow pages in a horizontal pager
public struct ConceptPagerView: View {
    let pages: [ConceptFlowPage]
    let accentColor: Color

    @State private var currentPage = 0

    public init(pages: [ConceptFlowPage], accentColor: Color = .blue) {
        self.pages = pages
        self.accentColor = accentColor
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        ConceptPageView(page: page, accentColor: accentColor)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, _ in
                    HapticManager.shared.light()
                }

                // Custom progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Concept exploration. Page \(currentPage + 1) of \(pages.count)")
    }
}

// MARK: - Page View Router

/// Routes to the appropriate page view based on page type
struct ConceptPageView: View {
    let page: ConceptFlowPage
    let accentColor: Color

    var body: some View {
        Group {
            switch page.page.lowercased() {
            case "hook":
                HookPageView(page: page, accentColor: accentColor)
            case "discovery":
                DiscoveryPageView(page: page, accentColor: accentColor)
            case "connection":
                ConnectionPageView(page: page, accentColor: accentColor)
            case "challenge":
                ChallengePageView(page: page, accentColor: accentColor)
            default:
                // Fallback for unknown page types
                GenericPageView(page: page, accentColor: accentColor)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Generic Fallback

private struct GenericPageView: View {
    let page: ConceptFlowPage
    let accentColor: Color

    var body: some View {
        VStack(spacing: 16) {
            if let title = page.title {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }

            if let insight = page.insight {
                Text(insight)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ConceptPagerView(
        pages: [
            ConceptFlowPage(
                page: "hook",
                title: "Whatever you do, do it on both sides",
                visual: "animated_balance_scale",
                interaction: "tap_to_reveal"
            ),
            ConceptFlowPage(
                page: "discovery",
                title: "Keep it balanced",
                visual: "interactive_scale",
                interaction: "add_remove_weights",
                insight: "Whatever you do to one side, you must do to the other."
            ),
            ConceptFlowPage(
                page: "connection",
                scenarios: [
                    ConnectionScenario(icon: "🚗", title: "Road trip", equation: "distance = speed × time"),
                    ConnectionScenario(icon: "💰", title: "Savings", equation: "total = deposit + interest")
                ]
            ),
            ConceptFlowPage(
                page: "challenge",
                question: "What went wrong?",
                options: [
                    ChallengeOption(text: "Nothing", isCorrect: false, feedback: "Try again!"),
                    ChallengeOption(text: "Unbalanced", isCorrect: true, feedback: "Correct!")
                ]
            )
        ],
        accentColor: .blue
    )
}
