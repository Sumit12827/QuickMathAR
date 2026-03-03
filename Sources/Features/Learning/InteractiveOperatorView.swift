//
//  InteractiveOperatorView.swift
//  QuickMathsAR
//
//  Container view that renders the appropriate interaction based on concept type
//

#if os(iOS)
import SwiftUI

struct InteractiveOperatorView: View {
    let concept: ArithmeticConcept

    @State private var hasCompleted = false
    @State private var showInsight = false

    var body: some View {
        VStack(spacing: 20) {
            // Interaction area
            interactionContent
                .frame(maxWidth: .infinity)
                .frame(minHeight: 300)

            // Insight reveal
            if showInsight, let insight = concept.insightReveal {
                InsightRevealView(text: insight)
                    .frame(maxWidth: .infinity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            }

            // Quick challenge
            if hasCompleted, let challenge = concept.quickChallenge {
                QuickChallengeView(challenge: challenge)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsight)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: hasCompleted)
    }

    @ViewBuilder
    private var interactionContent: some View {
        if let interactionType = concept.interactionType {
            switch interactionType {
            case .dragCombine:
                DragCombineInteraction(
                    config: concept.visualMetaphor?.config,
                    onComplete: handleCompletion
                )
            case .swipeRemove:
                SwipeRemoveInteraction(
                    config: concept.visualMetaphor?.config,
                    onComplete: handleCompletion
                )
            case .tapReplicate:
                TapReplicateInteraction(
                    config: concept.visualMetaphor?.config,
                    onComplete: handleCompletion
                )
            case .dragDistribute:
                DragDistributeInteraction(
                    config: concept.visualMetaphor?.config,
                    onComplete: handleCompletion
                )
            case .stepThrough:
                StepThroughInteraction(
                    config: concept.visualMetaphor?.config,
                    onComplete: handleCompletion
                )
            }
        } else {
            // Fallback: static display
            StaticConceptDisplay(concept: concept)
        }
    }

    private func handleCompletion() {
        HapticManager.shared.success()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showInsight = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                hasCompleted = true
            }
        }
    }
}

// MARK: - Static Fallback

private struct StaticConceptDisplay: View {
    let concept: ArithmeticConcept

    var body: some View {
        VStack(spacing: 16) {
            Text(concept.symbol)
                .font(.system(size: 80, weight: .medium, design: .rounded))
                .foregroundStyle(.blue)
                .safeTitle(minScale: 0.6)

            Text(concept.definition)
                .font(.body)
                .foregroundStyle(.secondary)
                .safeBody()
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    InteractiveOperatorView(
        concept: ArithmeticConcept(
            id: "addition",
            name: "Addition",
            symbol: "+",
            definition: "Combining quantities",
            whyItMatters: "Foundation of equations",
            conceptualExamples: [],
            interactionType: .dragCombine,
            visualMetaphor: nil,
            microAnimation: nil,
            insightReveal: "Addition combines groups into one total!",
            quickChallenge: nil
        )
    )
    .padding()
}
#endif
