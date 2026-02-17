//
//  InsightMessage.swift
//  QuickMathsAR
//
//  Contextual educational insights generated during equation building.
//

import Foundation

// MARK: - Insight Type

/// The tone/purpose of an insight message
enum InsightType: String {
    case guidance      // "Try this next..."
    case explanation   // "This is why..."
    case celebration   // "Great! Now you can..."
    case gentleNudge   // "Almost! But..."
}

// MARK: - Equation Shape

/// Lightweight classification of the equation as it's being built
enum EquationShape: Equatable {
    case incomplete
    case linear
    case quadratic
}

// MARK: - Insight Message

/// A contextual educational message shown during equation building
struct InsightMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let type: InsightType
    let iconName: String
    let duration: TimeInterval

    init(text: String, type: InsightType, iconName: String = "lightbulb", duration: TimeInterval? = nil) {
        self.text = text
        self.type = type
        self.iconName = iconName
        self.duration = duration ?? (type == .celebration ? 2.0 : 3.5)
    }

    static func == (lhs: InsightMessage, rhs: InsightMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Insight Engine

/// Generates contextual educational insights based on user actions
enum InsightEngine {

    /// Generate an insight for the component that was just added, given the full equation context.
    static func generateInsight(
        for component: EquationComponent,
        inContext components: [EquationComponent]
    ) -> InsightMessage {
        let count = components.count

        switch component.type {

        // --- Variable ---
        case .variable(let v):
            if count == 1 {
                return InsightMessage(
                    text: "Variable added — \(v) is the unknown we'll solve for.",
                    type: .explanation,
                    iconName: "questionmark.circle"
                )
            } else {
                return InsightMessage(
                    text: "Variable \(v) added to the expression.",
                    type: .explanation,
                    iconName: "questionmark.circle"
                )
            }

        // --- Number ---
        case .number(let n):
            // Check if previous component is a variable → this is really "variable then number" (uncommon)
            // Check if next-to-last was an operator or start → coefficient vs. constant
            let contextualRole = contextualNumberRole(in: components)
            switch contextualRole {
            case .coefficient:
                return InsightMessage(
                    text: "Coefficient \(n) — this scales the variable.",
                    type: .explanation,
                    iconName: "arrow.up.right"
                )
            case .constant:
                let isRightSide = isAfterEquals(in: components)
                if isRightSide {
                    return InsightMessage(
                        text: "Right-side value — what the expression must equal.",
                        type: .explanation,
                        iconName: "equal.circle"
                    )
                } else {
                    return InsightMessage(
                        text: "Constant \(n) — a fixed value in the expression.",
                        type: .explanation,
                        iconName: "number"
                    )
                }
            default:
                return InsightMessage(
                    text: "Number \(n) added.",
                    type: .explanation,
                    iconName: "number"
                )
            }

        // --- Operation ---
        case .operation(let op):
            switch op {
            case .equals:
                return InsightMessage(
                    text: "Equation formed — both sides must balance.",
                    type: .celebration,
                    iconName: "equal.circle",
                    duration: 3.0
                )
            case .plus:
                return InsightMessage(
                    text: "Adding another term to the expression.",
                    type: .explanation,
                    iconName: "plus.circle"
                )
            case .minus:
                return InsightMessage(
                    text: "Subtracting — removing or reducing a quantity.",
                    type: .explanation,
                    iconName: "minus.circle"
                )
            case .multiply:
                return InsightMessage(
                    text: "Multiplying — scaling a quantity.",
                    type: .explanation,
                    iconName: "multiply.circle"
                )
            case .divide:
                return InsightMessage(
                    text: "Dividing — splitting into equal parts.",
                    type: .explanation,
                    iconName: "divide.circle"
                )
            }

        // --- Power ---
        case .power(let p):
            if p == "²" {
                return InsightMessage(
                    text: "Squaring creates a curved relationship.",
                    type: .explanation,
                    iconName: "arrow.up.right.and.arrow.down.left"
                )
            } else {
                return InsightMessage(
                    text: "Power \(p) changes the shape of the graph.",
                    type: .explanation,
                    iconName: "arrow.up.right.and.arrow.down.left"
                )
            }

        // --- Parenthesis ---
        case .parenthesis(let p):
            if p == .open {
                return InsightMessage(
                    text: "Grouping started — controls order of operations.",
                    type: .guidance,
                    iconName: "parentheses"
                )
            } else {
                return InsightMessage(
                    text: "Group closed.",
                    type: .explanation,
                    iconName: "parentheses"
                )
            }
        }
    }

    /// Generate an insight for an invalid/rejected action
    static func generateRejectionInsight(
        for component: EquationComponent,
        reason: RejectionReason
    ) -> InsightMessage {
        switch reason {
        case .operatorAtStart:
            return InsightMessage(
                text: "An equation usually starts with a variable or number.",
                type: .gentleNudge,
                iconName: "hand.wave"
            )
        case .consecutiveOperators:
            return InsightMessage(
                text: "Two operators in a row — try a number or variable first.",
                type: .gentleNudge,
                iconName: "hand.wave"
            )
        case .equalsAlreadyPresent:
            return InsightMessage(
                text: "An equation can only have one equals sign.",
                type: .gentleNudge,
                iconName: "hand.wave"
            )
        case .nothingBeforeEquals:
            return InsightMessage(
                text: "Add something before the equals sign.",
                type: .gentleNudge,
                iconName: "hand.wave"
            )
        case .powerWithoutBase:
            return InsightMessage(
                text: "A power needs a variable or number before it.",
                type: .gentleNudge,
                iconName: "hand.wave"
            )
        }
    }

    // MARK: - Private Helpers

    /// Determine if a number is acting as a coefficient or constant based on context
    private static func contextualNumberRole(in components: [EquationComponent]) -> ComponentRole {
        // A number immediately before a variable acts as a coefficient.
        // But since we just added this number, we can't know what comes next.
        // Instead, check if the previous component suggests this is a coefficient:
        // - If previous is an operator or nothing (start of expression or after =), it *could* be a coefficient.
        //   We'll mark it as constant for now; the ViewModel's term-grouping logic will
        //   retroactively reclassify when a variable follows.

        guard components.count >= 2 else { return .constant }

        let prev = components[components.count - 2]
        // If the previous component is a variable, this number is a constant (e.g., x3 is unusual)
        if case .variable = prev.type { return .constant }

        return .constant
    }

    /// Check if the latest component is on the right side of an equals sign
    private static func isAfterEquals(in components: [EquationComponent]) -> Bool {
        for comp in components.dropLast() {
            if case .operation(let op) = comp.type, op == .equals {
                return true
            }
        }
        return false
    }
}

// MARK: - Rejection Reason

/// Reasons why a component was rejected (for educational feedback)
enum RejectionReason {
    case operatorAtStart
    case consecutiveOperators
    case equalsAlreadyPresent
    case nothingBeforeEquals
    case powerWithoutBase
}
