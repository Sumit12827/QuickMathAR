//
//  DragCombineInteraction.swift
//  QuickMathsAR
//
//  Interactive addition: drag two groups together to combine them
//

#if os(iOS)
import SwiftUI

struct DragCombineInteraction: View {
    let config: [String: AnyCodableValue]?
    let onComplete: () -> Void

    @State private var leftGroupOffset: CGSize = .zero
    @State private var rightGroupOffset: CGSize = .zero
    @State private var isMerged = false
    @State private var leftCount: Int = 3
    @State private var rightCount: Int = 5

    private let mergeThreshold: CGFloat = 80

    var body: some View {
        VStack(spacing: 24) {
            // Equation display
            HStack(spacing: 6) {
                Text("\(leftCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .minimumScaleFactor(0.6)

                Text("+")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(rightCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .minimumScaleFactor(0.6)

                Text("=")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(isMerged ? "\(leftCount + rightCount)" : "?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(isMerged ? .purple : .secondary)
                    .minimumScaleFactor(0.6)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Interactive area
            ZStack {
                if isMerged {
                    // Merged state
                    MergedGroupView(count: leftCount + rightCount)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Separate groups
                    HStack(spacing: 40) {
                        // Left group (draggable)
                        GroupView(count: leftCount, color: .blue)
                            .offset(leftGroupOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        leftGroupOffset = value.translation
                                        checkMerge(groupSpacing: 40)
                                    }
                                    .onEnded { _ in
                                        if !isMerged {
                                            withAnimation(.spring()) {
                                                leftGroupOffset = .zero
                                            }
                                        }
                                    }
                            )

                        // Right group (draggable)
                        GroupView(count: rightCount, color: .green)
                            .offset(rightGroupOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        rightGroupOffset = value.translation
                                        checkMerge(groupSpacing: 40)
                                    }
                                    .onEnded { _ in
                                        if !isMerged {
                                            withAnimation(.spring()) {
                                                rightGroupOffset = .zero
                                            }
                                        }
                                    }
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 200)

            // Instruction
            if !isMerged {
                Text("Drag the groups together")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .safeCaption()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .onAppear {
            loadConfig()
        }
    }

    private func loadConfig() {
        if let config = config {
            if let counts = config["itemCounts"]?.arrayValue,
               counts.count >= 2 {
                leftCount = counts[0].intValue ?? 3
                rightCount = counts[1].intValue ?? 5
            }
        }
    }

    private func checkMerge(groupSpacing: CGFloat = 60) {
        let initialSeparation = groupSpacing + 100 // groupSpacing + approximate group width
        let distance = sqrt(
            pow(leftGroupOffset.width - rightGroupOffset.width + initialSeparation, 2) +
            pow(leftGroupOffset.height - rightGroupOffset.height, 2)
        )

        if distance < mergeThreshold {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isMerged = true
            }
            HapticManager.shared.success()
            onComplete()
        }
    }
}

// MARK: - Group View

private struct GroupView: View {
    let count: Int
    let color: Color

    var body: some View {
        ZStack {
            // Container
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.1))
                .frame(width: 100, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(color.opacity(0.3), lineWidth: 2)
                )

            // Spheres
            VStack(spacing: 8) {
                ForEach(0..<min(count, 6), id: \.self) { _ in
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 24, height: 24)
                        .shadow(color: color.opacity(0.3), radius: 4, y: 2)
                }
            }
        }
    }
}

// MARK: - Merged Group View

private struct MergedGroupView: View {
    let count: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.purple.opacity(0.1))
                .frame(width: 140, height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(.purple.opacity(0.3), lineWidth: 2)
                )

            LazyVGrid(columns: [
                GridItem(.fixed(28)),
                GridItem(.fixed(28)),
                GridItem(.fixed(28))
            ], spacing: 8) {
                ForEach(0..<count, id: \.self) { index in
                    Circle()
                        .fill(
                            index < 3 ? Color.blue.gradient : Color.green.gradient
                        )
                        .frame(width: 24, height: 24)
                        .shadow(color: .purple.opacity(0.2), radius: 4, y: 2)
                }
            }
            .padding()
        }
    }
}

#Preview {
    DragCombineInteraction(config: nil, onComplete: {})
        .padding()
}
#endif
