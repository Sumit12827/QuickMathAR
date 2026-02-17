//
//  TransformationAnimator.swift
//  QuickMathsAR
//
//  Animates equation transformations for step-by-step solving
//

import SwiftUI

/// Animation phase for transformation animations
fileprivate enum TransformationAnimatorPhase {
    case before
    case operation
    case after
}

/// View that displays and animates equation transformations
public struct TransformationAnimator: View {
    let transformation: Transformation
    let isActive: Bool

    @State private var animationPhase: TransformationAnimatorPhase = .before
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(transformation: Transformation, isActive: Bool = false) {
        self.transformation = transformation
        self.isActive = isActive
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Equation display based on animation phase
            equationDisplay
                .padding(.horizontal)

            // Operation indicator
            if animationPhase == .operation || animationPhase == .after {
                operationIndicator
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .onChange(of: isActive) { _, newValue in
            if newValue {
                runAnimation()
            }
        }
        .onAppear {
            if isActive {
                runAnimation()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Transformation: \(transformation.before) becomes \(transformation.after) by \(transformation.operation)")
    }

    @ViewBuilder
    private var equationDisplay: some View {
        switch animationPhase {
        case .before:
            styledEquation(transformation.before, highlight: highlightForAnimation)
        case .operation:
            styledEquation(transformation.before, highlight: highlightForAnimation)
        case .after:
            styledEquation(transformation.after, highlight: nil)
        }
    }

    private var highlightForAnimation: String? {
        switch transformation.animation {
        case "highlight_term", "highlight_coefficient", "highlight_group", "highlight_variables", "highlight_common":
            return transformation.highlightTarget
        default:
            return nil
        }
    }

    private func styledEquation(_ equation: String, highlight: String?) -> some View {
        Text(equation)
            .font(.system(size: 24, weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .modifier(AnimationModifier(
                animationType: transformation.animation,
                phase: animationPhase
            ))
    }

    private var operationIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: iconForOperation)
                .foregroundStyle(.blue)

            Text(transformation.operation)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }

    private var iconForOperation: String {
        let op = transformation.operation.lowercased()
        if op.contains("subtract") { return "minus.circle" }
        if op.contains("add") { return "plus.circle" }
        if op.contains("divide") { return "divide.circle" }
        if op.contains("multiply") { return "multiply.circle" }
        if op.contains("factor") { return "arrow.triangle.branch" }
        if op.contains("simplify") { return "equal.circle" }
        return "arrow.right.circle"
    }

    private func runAnimation() {
        if reduceMotion {
            animationPhase = .after
            return
        }

        animationPhase = .before

        withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
            animationPhase = .operation
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
            animationPhase = .after
        }
    }
}

// MARK: - Animation Modifier

private struct AnimationModifier: ViewModifier {
    let animationType: String
    let phase: TransformationAnimatorPhase

    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleForPhase)
            .opacity(opacityForPhase)
    }

    private var scaleForPhase: CGFloat {
        switch phase {
        case .before: return 1.0
        case .operation:
            switch animationType {
            case "cancel_pair", "cancel_coefficient": return 0.95
            case "balance_subtract", "balance_add", "balance_divide", "balance_multiply": return 1.05
            default: return 1.0
            }
        case .after: return 1.0
        }
    }

    private var opacityForPhase: Double {
        switch phase {
        case .before: return 1.0
        case .operation: return 0.8
        case .after: return 1.0
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        TransformationAnimator(
            transformation: Transformation(
                before: "x + 5 = 12",
                operation: "subtract 5",
                after: "x = 7",
                animation: "cancel_pair"
            ),
            isActive: true
        )

        TransformationAnimator(
            transformation: Transformation(
                before: "3x = 21",
                operation: "divide by 3",
                after: "x = 7",
                animation: "balance_divide"
            ),
            isActive: true
        )
    }
    .padding()
}
