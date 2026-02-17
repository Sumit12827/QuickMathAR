import SwiftUI

// MARK: - Interactive Builder View

/// Tap-to-add equation builder powered by EquationBuilderViewModel.
/// Shows context-aware suggestions, role-colored chips, live graph preview, and educational insights.
struct InteractiveEquationBuilderView: View {
    var onComplete: (String) -> Void

    @StateObject private var viewModel = EquationBuilderViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: side-by-side layout
                HStack(alignment: .top, spacing: 0) {
                    // Left: equation display + insights + preview
                    VStack(spacing: 0) {
                        equationDisplay
                            .padding(.horizontal, 40)
                            .padding(.top, DesignSystem.Spacing.standard)

                        InsightStripView(insight: viewModel.currentInsight)
                            .padding(.horizontal, 40)
                            .padding(.top, DesignSystem.Spacing.micro)

                        MiniGraphPreviewView(
                            equationShape: viewModel.equationShape,
                            components: viewModel.components
                        )
                        .padding(.horizontal, 40)
                        .padding(.top, DesignSystem.Spacing.micro)

                        Spacer()

                        actionButtons
                            .padding(.horizontal, 40)
                            .padding(.bottom, DesignSystem.Spacing.standard)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    // Right: keypad
                    VStack(spacing: 0) {
                        suggestionSection
                            .padding(.horizontal, 40)
                            .padding(.top, DesignSystem.Spacing.standard)

                        numberRow
                            .padding(.horizontal, 40)
                            .padding(.top, DesignSystem.Spacing.tight)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                // iPhone: stacked layout
                VStack(spacing: 0) {
                    equationDisplay
                        .padding(.horizontal, DesignSystem.Layout.screenEdgePadding)
                        .padding(.top, DesignSystem.Spacing.tight)

                    InsightStripView(insight: viewModel.currentInsight)
                        .padding(.horizontal, DesignSystem.Layout.screenEdgePadding)
                        .padding(.top, DesignSystem.Spacing.micro)

                    MiniGraphPreviewView(
                        equationShape: viewModel.equationShape,
                        components: viewModel.components
                    )
                    .padding(.horizontal, DesignSystem.Layout.screenEdgePadding)
                    .padding(.top, DesignSystem.Spacing.micro)

                    Spacer(minLength: DesignSystem.Spacing.tight)

                    suggestionSection
                        .padding(.horizontal, DesignSystem.Layout.screenEdgePadding)

                    numberRow
                        .padding(.horizontal, DesignSystem.Layout.screenEdgePadding)
                        .padding(.top, DesignSystem.Spacing.micro)

                    Spacer(minLength: DesignSystem.Spacing.tight)

                    actionButtons
                        .padding(.horizontal, DesignSystem.Layout.screenEdgePadding)
                        .padding(.bottom, DesignSystem.Spacing.standard)
                }
            }
        }
    }

    // MARK: - Equation Display Area

    private var equationDisplay: some View {
        VStack(spacing: DesignSystem.Spacing.micro) {
            // Validation status
            HStack {
                Image(systemName: validationIcon)
                    .font(.caption)
                    .foregroundStyle(validationColor)
                Text(viewModel.validationState.message)
                    .font(.designCaption)
                    .foregroundStyle(validationColor)
                Spacer()

                if !viewModel.components.isEmpty {
                    Button {
                        withAnimation(DesignSystem.Animations.interactiveSpring) {
                            viewModel.removeLast()
                        }
                    } label: {
                        Image(systemName: "delete.backward")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Undo last")

                    Button {
                        withAnimation(DesignSystem.Animations.interactiveSpring) {
                            viewModel.clear()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.callout)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .accessibilityLabel("Clear all")
                }
            }

            // Component chips
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: 80)

                if viewModel.components.isEmpty {
                    Text("Tap components below to build your equation")
                        .font(.designSubheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(viewModel.components.enumerated()), id: \.element.id) { index, component in
                                componentChip(component, index: index)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                }
            }
            .animation(
                reduceMotion ? .easeOut(duration: 0.15) : DesignSystem.Animations.interactiveSpring,
                value: viewModel.components.count
            )
        }
    }

    // MARK: - Component Chip

    private func componentChip(_ component: EquationComponent, index: Int) -> some View {
        let role = viewModel.contextualRole(for: index)

        return Text(component.displayText)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
            .frame(minWidth: 44, minHeight: 52)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(role.color.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(role.color.opacity(0.5), lineWidth: 1)
                    )
            )
            .accessibilityLabel(component.accessibilityLabel)
            .accessibilityHint(role.accessibilityHint)
    }

    // MARK: - Suggestion Section

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SUGGESTIONS")
                .font(.designCaption)
                .foregroundStyle(Color(UIColor.tertiaryLabel))
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(viewModel.suggestedComponents.enumerated()), id: \.offset) { _, suggestion in
                        Button {
                            withAnimation(DesignSystem.Animations.interactiveSpring) {
                                viewModel.add(suggestion)
                            }
                        } label: {
                            Text(suggestion.displayText)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .frame(minWidth: 48, minHeight: 48)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(suggestion.role.color.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(suggestion.role.color.opacity(0.4), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add \(suggestion.accessibilityLabel)")
                    }
                }
            }
        }
    }

    // MARK: - Number Row

    private var numberRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NUMBERS")
                .font(.designCaption)
                .foregroundStyle(Color(UIColor.tertiaryLabel))
                .padding(.leading, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(0...9, id: \.self) { num in
                    Button {
                        withAnimation(DesignSystem.Animations.interactiveSpring) {
                            viewModel.add(.number("\(num)"))
                        }
                    } label: {
                        Text("\(num)")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Number \(num)")
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Button {
            if let equation = viewModel.getEquationString() {
                HapticManager.shared.play(.success)
                onComplete(equation)
            }
        } label: {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Analyze")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!viewModel.validationState.isValid)
        .opacity(viewModel.validationState.isValid ? 1.0 : 0.5)
    }

    // MARK: - Validation Helpers

    private var validationIcon: String {
        switch viewModel.validationState {
        case .valid: return "checkmark.circle.fill"
        case .empty: return "circle.dashed"
        default: return "info.circle"
        }
    }

    private var validationColor: Color {
        switch viewModel.validationState {
        case .valid: return .green
        case .empty: return .secondary
        default: return .orange
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    InteractiveEquationBuilderView { equation in
        print("Completed: \(equation)")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    InteractiveEquationBuilderView { equation in
        print("Completed: \(equation)")
    }
    .preferredColorScheme(.dark)
}
