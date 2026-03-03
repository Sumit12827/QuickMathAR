//
//  FactoringPuzzleView.swift
//  QuickMathsAR
//
//  Drag-and-drop puzzle for factoring quadratics
//

#if os(iOS)
import SwiftUI

/// Interactive puzzle for learning quadratic factoring
public struct FactoringPuzzleView: View {
    let puzzle: FactoringPuzzle

    @State private var leftSlot: Int? = nil
    @State private var rightSlot: Int? = nil
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var showHint = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(puzzle: FactoringPuzzle) {
        self.puzzle = puzzle
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Factoring Puzzle")
                    .font(.headline)

                Text("Find two numbers that:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Clues
            cluesView

            // Drop zones (factor slots)
            factorSlotsView

            // Available number tiles
            numberTilesView

            // Result feedback
            if showResult {
                resultFeedback
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Hint button
            if !showResult && (leftSlot == nil || rightSlot == nil) {
                Button {
                    showHint = true
                    HapticManager.shared.light()
                } label: {
                    Label("Show Hint", systemImage: "lightbulb")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            // Hint display
            if showHint && !puzzle.hint.isEmpty {
                Text(puzzle.hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.1))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .onChange(of: leftSlot) { _, _ in checkAnswer() }
        .onChange(of: rightSlot) { _, _ in checkAnswer() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Factoring puzzle. Find numbers that add to \(puzzle.targetSum) and multiply to \(puzzle.targetProduct)")
    }

    private var cluesView: some View {
        HStack(spacing: 32) {
            ClueCard(
                operation: "Add to",
                target: puzzle.targetSum,
                icon: "plus.circle.fill",
                color: .blue
            )

            ClueCard(
                operation: "Multiply to",
                target: puzzle.targetProduct,
                icon: "multiply.circle.fill",
                color: .purple
            )
        }
    }

    private var factorSlotsView: some View {
        HStack(spacing: 8) {
            Text("(x")
                .font(.system(size: 24, weight: .medium, design: .rounded))

            // Left slot
            DropSlot(
                value: leftSlot,
                label: "first",
                onDrop: { leftSlot = $0 },
                onClear: { leftSlot = nil }
            )

            Text(")(x")
                .font(.system(size: 24, weight: .medium, design: .rounded))

            // Right slot
            DropSlot(
                value: rightSlot,
                label: "second",
                onDrop: { rightSlot = $0 },
                onClear: { rightSlot = nil }
            )

            Text(")")
                .font(.system(size: 24, weight: .medium, design: .rounded))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    private var numberTilesView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 50))
        ], spacing: 12) {
            ForEach(puzzle.availableNumbers, id: \.self) { number in
                let isUsed = leftSlot == number || rightSlot == number

                NumberTile(
                    number: number,
                    isUsed: isUsed
                ) {
                    if !isUsed {
                        placeNumber(number)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var resultFeedback: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)

                Text(isCorrect ? "Correct!" : "Not quite...")
                    .font(.headline)
                    .foregroundStyle(isCorrect ? .green : .red)
            }

            if isCorrect, let left = leftSlot, let right = rightSlot {
                VStack(spacing: 4) {
                    Text("\(left) + \(right) = \(left + right) ✓")
                    Text("\(left) × \(right) = \(left * right) ✓")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else if !isCorrect {
                Button("Try Again") {
                    withAnimation {
                        leftSlot = nil
                        rightSlot = nil
                        showResult = false
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }

    private func placeNumber(_ number: Int) {
        if leftSlot == nil {
            if reduceMotion {
                leftSlot = number
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    leftSlot = number
                }
            }
            HapticManager.shared.light()
        } else if rightSlot == nil {
            if reduceMotion {
                rightSlot = number
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    rightSlot = number
                }
            }
            HapticManager.shared.light()
        }
    }

    private func checkAnswer() {
        guard let left = leftSlot, let right = rightSlot else { return }

        let correct = puzzle.correctPair
        isCorrect = (left == correct[0] && right == correct[1]) ||
                    (left == correct[1] && right == correct[0])

        if reduceMotion {
            showResult = true
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showResult = true
            }
        }

        if isCorrect {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
        }
    }
}

// MARK: - Clue Card

private struct ClueCard: View {
    let operation: String
    let target: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(operation)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(target)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Drop Slot

private struct DropSlot: View {
    let value: Int?
    let label: String
    let onDrop: (Int) -> Void
    let onClear: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(value == nil ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                .frame(width: 44, height: 44)

            if let value = value {
                Text(formatNumber(value))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.blue)
            } else {
                Text("?")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .onTapGesture {
            if value != nil {
                onClear()
            }
        }
        .accessibilityLabel("\(label) factor slot: \(value.map { String($0) } ?? "empty")")
        .accessibilityHint(value != nil ? "Double tap to clear" : "Tap a number tile to fill")
    }

    private func formatNumber(_ n: Int) -> String {
        n >= 0 ? "+\(n)" : "\(n)"
    }
}

// MARK: - Number Tile

private struct NumberTile: View {
    let number: Int
    let isUsed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(formatNumber(number))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isUsed ? Color.gray.opacity(0.2) : Color.blue.opacity(0.15))
                )
                .foregroundStyle(isUsed ? .secondary : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isUsed ? Color.gray.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                )
        }
        .disabled(isUsed)
        .accessibilityLabel("Number \(number)")
        .accessibilityHint(isUsed ? "Already used" : "Double tap to place in slot")
    }

    private func formatNumber(_ n: Int) -> String {
        n >= 0 ? "+\(n)" : "\(n)"
    }
}

// MARK: - Preview

#Preview {
    FactoringPuzzleView(
        puzzle: FactoringPuzzle(
            targetSum: 5,
            targetProduct: 6,
            availableNumbers: [1, 2, 3, 4, 6],
            correctPair: [2, 3],
            hint: "Which pair adds to 5?"
        )
    )
    .padding()
}
#endif
