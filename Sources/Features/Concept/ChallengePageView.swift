//
//  ChallengePageView.swift
//  QuickMathsAR
//
//  Quiz page using QuickChallengeView component
//

import SwiftUI

/// Challenge page with quiz question
struct ChallengePageView: View {
    let page: ConceptFlowPage
    let accentColor: Color

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundStyle(accentColor)

                Text("Quick Challenge")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            Spacer(minLength: 20)

            // Challenge content
            if let question = page.question, let options = page.options {
                let challenge = QuickChallenge(
                    question: question,
                    options: options,
                    explanation: ""
                )

                QuickChallengeView(challenge: challenge)
                    .padding(.horizontal, 20)
            } else {
                Text("Challenge not available")
                    .foregroundStyle(.secondary)
                    .padding()
            }

            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Challenge page")
    }
}

// MARK: - Preview

#Preview {
    ChallengePageView(
        page: ConceptFlowPage(
            page: "challenge",
            question: "Someone solved 3x + 2 = 11 by subtracting 2 from just the left side. What went wrong?",
            options: [
                ChallengeOption(text: "Nothing, that's correct", isCorrect: false, feedback: "The scale would tip!"),
                ChallengeOption(text: "They unbalanced the equation", isCorrect: true, feedback: "Both sides must be treated equally."),
                ChallengeOption(text: "They should have added", isCorrect: false, feedback: "Subtraction is right, but on BOTH sides.")
            ]
        ),
        accentColor: .blue
    )
    .padding()
}
