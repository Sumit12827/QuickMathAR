//
//  QuickChallengeView.swift
//  QuickMathsAR
//
//  Mini-quiz component for testing understanding
//

#if os(iOS)
import SwiftUI
import UIKit

struct QuickChallengeView: View {
    let challenge: QuickChallenge

    @State private var selectedOption: ChallengeOption?
    @State private var showFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Label {
                Text("Quick Check")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.orange)
            }

            // Question
            Text(challenge.question)
                .font(.body)
                .foregroundStyle(.primary)
                .safeBody(alignment: .leading)

            // Options
            VStack(spacing: 10) {
                ForEach(challenge.options) { option in
                    ChallengeOptionButton(
                        option: option,
                        isSelected: selectedOption?.text == option.text,
                        showResult: showFeedback,
                        onTap: {
                            selectOption(option)
                        }
                    )
                }
            }

            // Feedback
            if showFeedback, let selected = selectedOption {
                FeedbackBanner(
                    isCorrect: selected.isCorrect,
                    feedback: selected.feedback
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFeedback)
    }

    private func selectOption(_ option: ChallengeOption) {
        guard !showFeedback else { return }

        selectedOption = option

        HapticManager.shared.light()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showFeedback = true

            if option.isCorrect {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.error()
            }
        }
    }
}

// MARK: - Option Button

private struct ChallengeOptionButton: View {
    let option: ChallengeOption
    let isSelected: Bool
    let showResult: Bool
    let onTap: () -> Void

    private var backgroundColor: Color {
        if !showResult {
            return isSelected ? .blue.opacity(0.1) : Color(UIColor.tertiarySystemGroupedBackground)
        }

        if isSelected {
            return option.isCorrect ? .green.opacity(0.15) : .red.opacity(0.15)
        }

        if option.isCorrect {
            return .green.opacity(0.1)
        }

        return Color(UIColor.tertiarySystemGroupedBackground)
    }

    private var borderColor: Color {
        if !showResult {
            return isSelected ? .blue.opacity(0.5) : .clear
        }

        if isSelected {
            return option.isCorrect ? .green : .red
        }

        if option.isCorrect {
            return .green.opacity(0.5)
        }

        return .clear
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option.text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .safeBody(alignment: .leading)

                Spacer()

                if showResult {
                    Image(systemName: option.isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : ""))
                        .foregroundStyle(option.isCorrect ? .green : .red)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(showResult)
    }
}

// MARK: - Feedback Banner

private struct FeedbackBanner: View {
    let isCorrect: Bool
    let feedback: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                .font(.title3)
                .foregroundStyle(isCorrect ? .green : .orange)

            Text(feedback)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeBody(alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill((isCorrect ? Color.green : Color.orange).opacity(0.1))
        )
    }
}

#Preview {
    QuickChallengeView(
        challenge: QuickChallenge(
            question: "If you combine a group of 4 apples with a group of 6 apples, what operation did you do?",
            options: [
                ChallengeOption(text: "Subtraction", isCorrect: false, feedback: "Subtraction takes away. Here we brought groups together."),
                ChallengeOption(text: "Addition", isCorrect: true, feedback: "Exactly! Combining groups is addition."),
                ChallengeOption(text: "Division", isCorrect: false, feedback: "Division splits things into equal parts.")
            ],
            explanation: "When you bring separate groups together, you're adding them."
        )
    )
    .padding()
}

#endif
