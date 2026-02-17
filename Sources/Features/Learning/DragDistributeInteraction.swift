//
//  DragDistributeInteraction.swift
//  QuickMathsAR
//
//  Interactive division: drag items into equal groups
//

import SwiftUI
import UIKit

struct DragDistributeInteraction: View {
    let config: [String: AnyCodableValue]?
    let onComplete: () -> Void

    @State private var totalItems: Int = 12
    @State private var numberOfGroups: Int = 4
    @State private var groupContents: [[Int]] = [[], [], [], []]
    @State private var unassignedItems: [Int] = []
    @State private var draggedItem: Int?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 24) {
            // Equation display
            HStack(spacing: 6) {
                Text("\(totalItems)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
                    .minimumScaleFactor(0.6)

                Text("/")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(numberOfGroups)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .minimumScaleFactor(0.6)

                Text("=")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(isComplete ? "\(totalItems / numberOfGroups)" : "?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(isComplete ? .green : .secondary)
                    .minimumScaleFactor(0.6)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Groups area
            HStack(spacing: 8) {
                ForEach(0..<numberOfGroups, id: \.self) { groupIndex in
                    GroupBucket(
                        items: groupContents[groupIndex],
                        targetCount: totalItems / numberOfGroups,
                        color: .blue
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)

            // Unassigned items
            if !unassignedItems.isEmpty {
                VStack(spacing: 8) {
                    Text("Drag items into groups")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .safeCaption()

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 32, maximum: 40), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(unassignedItems, id: \.self) { item in
                            DraggableItem(item: item, color: .purple)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            draggedItem = item
                                            dragOffset = value.translation
                                        }
                                        .onEnded { value in
                                            handleDrop(item: item, location: value.location)
                                        }
                                )
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }

            // Status
            if isComplete {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Each group has \(totalItems / numberOfGroups) items!")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .safeCaption()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .onAppear {
            loadConfig()
            setupItems()
        }
    }

    private var isComplete: Bool {
        unassignedItems.isEmpty && groupContents.allSatisfy { $0.count == totalItems / numberOfGroups }
    }

    private func loadConfig() {
        if let config = config {
            if let total = config["totalItems"]?.intValue {
                totalItems = total
            }
            if let groups = config["numberOfGroups"]?.intValue {
                numberOfGroups = groups
                groupContents = Array(repeating: [], count: groups)
            }
        }
    }

    private func setupItems() {
        unassignedItems = Array(1...totalItems)
    }

    private func handleDrop(item: Int, location: CGPoint) {
        // Simple distribution: add to the group with fewest items
        if let minIndex = groupContents.indices.min(by: { groupContents[$0].count < groupContents[$1].count }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                unassignedItems.removeAll { $0 == item }
                groupContents[minIndex].append(item)
            }

            HapticManager.shared.light()

            if isComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }

        draggedItem = nil
        dragOffset = .zero
    }
}

// MARK: - Group Bucket

private struct GroupBucket: View {
    let items: [Int]
    let targetCount: Int
    let color: Color
    var width: CGFloat = 70

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: width, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                items.count == targetCount ? Color.green : color.opacity(0.3),
                                lineWidth: items.count == targetCount ? 2 : 1
                            )
                    )

                VStack(spacing: 2) {
                    ForEach(items.prefix(4), id: \.self) { _ in
                        Circle()
                            .fill(Color.purple.gradient)
                            .frame(width: 12, height: 12)
                    }
                }
            }

            Text("\(items.count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(items.count == targetCount ? .green : color)
        }
    }
}

// MARK: - Draggable Item

private struct DraggableItem: View {
    let item: Int
    let color: Color

    var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: 32, height: 32)
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
    }
}

#Preview {
    DragDistributeInteraction(config: nil, onComplete: {})
        .padding()
}
