//
//  TapReplicateInteraction.swift
//  QuickMathsAR
//
//  Interactive multiplication: tap to replicate groups
//

#if os(iOS)
import SwiftUI

struct TapReplicateInteraction: View {
    let config: [String: AnyCodableValue]?
    let onComplete: () -> Void

    @State private var groupSize: Int = 4
    @State private var targetGroups: Int = 3
    @State private var currentGroups: Int = 1
    @State private var groupScales: [Int: CGFloat] = [0: 1.0]

    var body: some View {
        VStack(spacing: 24) {
            // Equation display
            HStack(spacing: 6) {
                Text("\(groupSize)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .minimumScaleFactor(0.6)

                Text("x")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(currentGroups)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.6)

                Text("=")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(groupSize * currentGroups)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(isComplete ? .green : .orange)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.6)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Groups display
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<currentGroups, id: \.self) { groupIndex in
                        GroupContainer(size: groupSize, color: .blue)
                            .scaleEffect(groupScales[groupIndex] ?? 1.0)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 140)

            // Tap button
            if !isComplete {
                Button {
                    addGroup()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Tap to add another group")
                            .safeInline(minScale: 0.8)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue, in: Capsule())
                }
            } else {
                Text("\(targetGroups) groups of \(groupSize) = \(groupSize * targetGroups)")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .safeCaption()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .onAppear {
            loadConfig()
        }
    }

    private var isComplete: Bool {
        currentGroups >= targetGroups
    }

    private func loadConfig() {
        if let config = config {
            if let size = config["groupSize"]?.intValue {
                groupSize = size
            }
            if let target = config["targetGroups"]?.intValue {
                targetGroups = target
            }
        }
    }

    private func addGroup() {
        let newIndex = currentGroups

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            currentGroups += 1
            groupScales[newIndex] = 0.0
        }

        // Animate the new group appearing
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            groupScales[newIndex] = 1.0
        }

        HapticManager.shared.medium()

        if currentGroups >= targetGroups {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Group Container

private struct GroupContainer: View {
    let size: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: [GridItem(.fixed(24)), GridItem(.fixed(24))], spacing: 4) {
                ForEach(0..<min(size, 6), id: \.self) { _ in
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 20, height: 20)
                }
            }

            Text("\(size)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    TapReplicateInteraction(config: nil, onComplete: {})
        .padding()
}
#endif
