//
//  FixedBottomActionBar.swift
//  QuickMathsAR
//
//  Reusable fixed bottom action bar for always-visible CTAs
//

import SwiftUI

/// A fixed bottom action bar that keeps primary CTAs always visible
/// regardless of scroll position. Uses a subtle top divider and
/// safe area aware padding.
public struct FixedBottomActionBar<PrimaryLabel: View, SecondaryLabel: View>: View {

    private let primaryAction: () -> Void
    private let primaryLabel: PrimaryLabel
    private let secondaryLabel: SecondaryLabel?
    private let secondaryAction: (() -> Void)?
    private let accentColor: Color

    public init(
        accentColor: Color = .blue,
        @ViewBuilder primaryLabel: () -> PrimaryLabel,
        primaryAction: @escaping () -> Void,
        @ViewBuilder secondaryLabel: () -> SecondaryLabel,
        secondaryAction: @escaping () -> Void
    ) {
        self.accentColor = accentColor
        self.primaryLabel = primaryLabel()
        self.primaryAction = primaryAction
        self.secondaryLabel = secondaryLabel()
        self.secondaryAction = secondaryAction
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Subtle top divider
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5)

            VStack(spacing: 10) {
                // Primary button
                Button(action: {
                    HapticManager.shared.medium()
                    primaryAction()
                }) {
                    primaryLabel
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: accentColor.opacity(0.25), radius: 8, y: 4)
                }
                .buttonStyle(.plain)

                // Secondary button (if provided)
                if let secondaryLabel = secondaryLabel, let secondaryAction = secondaryAction {
                    Button(action: {
                        HapticManager.shared.light()
                        secondaryAction()
                    }) {
                        secondaryLabel
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 400)
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// Convenience initializer with no secondary action
extension FixedBottomActionBar where SecondaryLabel == EmptyView {
    public init(
        accentColor: Color = .blue,
        @ViewBuilder primaryLabel: () -> PrimaryLabel,
        primaryAction: @escaping () -> Void
    ) {
        self.accentColor = accentColor
        self.primaryLabel = primaryLabel()
        self.primaryAction = primaryAction
        self.secondaryLabel = nil
        self.secondaryAction = nil
    }
}

// MARK: - Preview

#Preview("With Secondary") {
    VStack {
        Spacer()
        FixedBottomActionBar(accentColor: .blue) {
            HStack(spacing: 8) {
                Text("See It Step by Step")
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.semibold))
            }
        } primaryAction: {
        } secondaryLabel: {
            HStack(spacing: 6) {
                Image(systemName: "arkit")
                Text("Skip to AR")
            }
        } secondaryAction: {
        }
    }
}

#Preview("Primary Only") {
    VStack {
        Spacer()
        FixedBottomActionBar(accentColor: .purple) {
            HStack(spacing: 8) {
                Image(systemName: "arkit")
                Text("Place in Your Space")
            }
        } primaryAction: {
        }
    }
}
