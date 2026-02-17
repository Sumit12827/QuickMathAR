//
//  SwipeRemoveInteraction.swift
//  QuickMathsAR
//
//  Interactive subtraction: swipe items away to remove them
//

import SwiftUI
import UIKit

struct SwipeRemoveInteraction: View {
    let config: [String: AnyCodableValue]?
    let onComplete: () -> Void

    @State private var totalItems: Int = 8
    @State private var itemsToRemove: Int = 3
    @State private var removedCount: Int = 0
    @State private var itemOffsets: [Int: CGSize] = [:]
    @State private var removedItems: Set<Int> = []

    var body: some View {
        VStack(spacing: 24) {
            // Equation display
            HStack(spacing: 6) {
                Text("\(totalItems)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                    .minimumScaleFactor(0.6)

                Text("-")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(itemsToRemove)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .minimumScaleFactor(0.6)

                Text("=")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(isComplete ? "\(totalItems - itemsToRemove)" : "?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(isComplete ? .green : .secondary)
                    .minimumScaleFactor(0.6)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Progress indicator
            HStack(spacing: 4) {
                ForEach(0..<itemsToRemove, id: \.self) { index in
                    Circle()
                        .fill(index < removedCount ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // Interactive area
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 44, maximum: 60), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(0..<totalItems, id: \.self) { index in
                        if !removedItems.contains(index) {
                            ItemBubble(index: index)
                                .offset(itemOffsets[index] ?? .zero)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            itemOffsets[index] = value.translation
                                        }
                                        .onEnded { value in
                                            handleSwipeEnd(index: index, translation: value.translation)
                                        }
                                )
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 180)

            // Instruction
            Text(isComplete ? "You removed \(itemsToRemove)!" : "Swipe \(itemsToRemove - removedCount) more away")
                .font(.subheadline)
                .foregroundStyle(isComplete ? .green : .secondary)
                .safeCaption()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .onAppear {
            loadConfig()
        }
    }

    private var isComplete: Bool {
        removedCount >= itemsToRemove
    }

    private func loadConfig() {
        if let config = config {
            if let total = config["totalItems"]?.intValue {
                totalItems = total
            }
            if let remove = config["removeCount"]?.intValue {
                itemsToRemove = remove
            }
        }
    }

    private func handleSwipeEnd(index: Int, translation: CGSize) {
        let threshold: CGFloat = 100

        if abs(translation.width) > threshold || abs(translation.height) > threshold {
            // Item swiped away
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                removedItems.insert(index)
                removedCount += 1
            }

            HapticManager.shared.light()

            if removedCount >= itemsToRemove {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        } else {
            // Snap back
            withAnimation(.spring()) {
                itemOffsets[index] = .zero
            }
        }
    }
}

// MARK: - Item Bubble

private struct ItemBubble: View {
    let index: Int

    var body: some View {
        Circle()
            .fill(Color.orange.gradient)
            .frame(width: 36, height: 36)
            .shadow(color: .orange.opacity(0.3), radius: 4, y: 2)
            .overlay(
                Text("\(index + 1)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            )
    }
}

#Preview {
    SwipeRemoveInteraction(config: nil, onComplete: {})
        .padding()
}
