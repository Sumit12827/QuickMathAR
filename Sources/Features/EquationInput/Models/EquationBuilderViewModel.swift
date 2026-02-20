#if os(iOS)
//
//  EquationBuilderViewModel.swift
//  QuickMathsAR
//
//  Created on 2026-02-09.
//

import SwiftUI
import Combine

@MainActor
final class EquationBuilderViewModel: ObservableObject {

    // MARK: - Published State
    @Published private(set) var components: [EquationComponent] = []
    @Published private(set) var validationState: EquationValidationState = .empty
    @Published private(set) var showValidationFeedback = false

    // Educational State
    @Published var currentInsight: InsightMessage?
    @Published private(set) var equationShape: EquationShape = .incomplete
    @Published private(set) var rejectedComponent: EquationComponent?

    // MARK: - Suggestions (context-aware)
    var suggestedComponents: [EquationComponent] {
        let lastComponent = components.last

        // First component: suggest variables or numbers
        if components.isEmpty {
            return [
                .variable("x"),
                .variable("y"),
                .number("2"),
                .number("3")
            ]
        }

        // After variable or number: suggest operators
        if let last = lastComponent {
            switch last.type {
            case .variable:
                var suggestions: [EquationComponent] = [
                    .power("²"),
                    .operation(.plus),
                    .operation(.minus),
                    .operation(.multiply)
                ]
                if !hasEquals {
                    suggestions.append(.operation(.equals))
                }
                return suggestions
            case .number:
                var suggestions: [EquationComponent] = [
                    .variable("x"),
                    .operation(.plus),
                    .operation(.minus),
                    .operation(.multiply)
                ]
                if !hasEquals {
                    suggestions.append(.operation(.equals))
                }
                return suggestions
            case .power:
                var suggestions: [EquationComponent] = [
                    .operation(.plus),
                    .operation(.minus)
                ]
                if !hasEquals {
                    suggestions.append(.operation(.equals))
                }
                return suggestions
            case .operation:
                return [
                    .variable("x"),
                    .variable("y"),
                    .number("0"),
                    .number("1"),
                    .number("2"),
                    .parenthesis(.open)
                ]
            case .parenthesis(let p):
                if p == .open {
                    return [
                        .variable("x"),
                        .number("1"),
                        .number("2")
                    ]
                }
            }
        }

        // Default suggestions
        var suggestions: [EquationComponent] = [
            .variable("x"),
            .number("1"),
            .operation(.plus)
        ]
        if !hasEquals {
            suggestions.append(.operation(.equals))
        }
        return suggestions
    }

    // MARK: - Computed Helpers

    /// Whether the equation already has an equals sign
    var hasEquals: Bool {
        components.contains { comp in
            if case .operation(let op) = comp.type, op == .equals { return true }
            return false
        }
    }

    /// Index of the equals sign, if present
    var equalsIndex: Int? {
        components.firstIndex { comp in
            if case .operation(let op) = comp.type, op == .equals { return true }
            return false
        }
    }

    /// Contextual role for a component at a given index (may differ from type-default role)
    func contextualRole(for index: Int) -> ComponentRole {
        guard index < components.count else { return .constant }
        let comp = components[index]

        // A number immediately before a variable is a coefficient
        if case .number = comp.type {
            if index + 1 < components.count {
                if case .variable = components[index + 1].type {
                    return .coefficient
                }
            }
        }
        return comp.role
    }

    /// Groups of indices that form visual "terms" (e.g., [0,1] for "2x")
    var termGroups: [[Int]] {
        var groups: [[Int]] = []
        var i = 0
        while i < components.count {
            let comp = components[i]
            // Number followed by variable = coefficient term
            if case .number = comp.type, i + 1 < components.count {
                if case .variable = components[i + 1].type {
                    var group = [i, i + 1]
                    // Check if power follows
                    if i + 2 < components.count, case .power = components[i + 2].type {
                        group.append(i + 2)
                        i += 3
                    } else {
                        i += 2
                    }
                    groups.append(group)
                    continue
                }
            }
            // Variable optionally followed by power
            if case .variable = comp.type, i + 1 < components.count {
                if case .power = components[i + 1].type {
                    groups.append([i, i + 1])
                    i += 2
                    continue
                }
            }
            // Standalone
            groups.append([i])
            i += 1
        }
        return groups
    }

    // MARK: - Actions

    func add(_ component: EquationComponent) {
        // Validate the input sequence
        if let rejection = validateSequence(component) {
            // Reject: show educational feedback
            rejectedComponent = component
            currentInsight = InsightEngine.generateRejectionInsight(for: component, reason: rejection)
            triggerHaptic(.rigid)

            // Clear rejection state after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.rejectedComponent = nil
            }
            return
        }

        // Valid: add the component
        let newComponent = EquationComponent(type: component.type)
        components.append(newComponent)
        updateValidation()
        updateEquationShape()

        // Generate contextual insight
        currentInsight = InsightEngine.generateInsight(for: newComponent, inContext: components)

        triggerHaptic(.light)

        // Auto-dismiss insight
        let insightId = currentInsight?.id
        let duration = currentInsight?.duration ?? 3.5
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.currentInsight?.id == insightId {
                self?.currentInsight = nil
            }
        }
    }

    func removeLast() {
        guard !components.isEmpty else { return }
        components.removeLast()
        updateValidation()
        updateEquationShape()
        triggerHaptic(.light)
        currentInsight = nil
    }

    func clear() {
        components.removeAll()
        updateValidation()
        updateEquationShape()
        triggerHaptic(.medium)
        currentInsight = nil
    }

    func getEquationString() -> String? {
        if case .valid(let equation) = validationState {
            return equation
        }
        return nil
    }

    // MARK: - Input Validation

    /// Returns a rejection reason if the component should NOT be added, nil if it's valid.
    private func validateSequence(_ component: EquationComponent) -> RejectionReason? {
        let last = components.last

        switch component.type {

        // Operators cannot be first (except minus for negative)
        case .operation(let op):
            if components.isEmpty {
                if op == .minus {
                    return nil // Allow negative start
                }
                return .operatorAtStart
            }

            // No consecutive operators
            if let last = last, case .operation = last.type {
                return .consecutiveOperators
            }

            // Only one equals sign
            if op == .equals {
                if hasEquals {
                    return .equalsAlreadyPresent
                }
                // Must have content before equals
                if components.isEmpty {
                    return .nothingBeforeEquals
                }
            }

        // Powers need a base (variable or number before them)
        case .power:
            guard let last = last else { return .powerWithoutBase }
            switch last.type {
            case .variable, .number, .parenthesis(.close):
                return nil
            default:
                return .powerWithoutBase
            }

        default:
            break
        }

        return nil
    }

    // MARK: - Equation Shape Detection

    private func updateEquationShape() {
        let hasPower = components.contains { comp in
            if case .power = comp.type { return true }
            return false
        }
        let hasVariable = components.contains { comp in
            if case .variable = comp.type { return true }
            return false
        }

        if !hasVariable || components.count < 2 {
            equationShape = .incomplete
        } else if hasPower {
            equationShape = .quadratic
        } else {
            equationShape = .linear
        }
    }

    // MARK: - Private

    private func updateValidation() {
        let newState = EquationValidator.validate(components)

        // Show feedback on state change
        if validationState != newState {
            showValidationFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showValidationFeedback = false
            }
        }

        validationState = newState
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
#endif
