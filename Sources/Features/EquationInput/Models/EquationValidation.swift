//
//  EquationValidation.swift
//  QuickMathsAR
//
//  Created on 2026-02-09.
//

#if os(iOS)

import Foundation

/// Validation state for equations
enum EquationValidationState: Equatable {
    case empty
    case missingVariable
    case missingEquals
    case incomplete
    case valid(String)
    case invalid(message: String)
    case unsupportedType(type: EquationType, message: String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    /// Whether the user can proceed (only for valid supported equations)
    var canProceed: Bool {
        if case .valid = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .empty: return "Start building your equation"
        case .missingVariable: return "Add a variable (x or y)"
        case .missingEquals: return "Add an equals sign (=)"
        case .incomplete: return "Complete the equation"
        case .valid(let eq): return "Ready: \(eq)"
        case .invalid(let msg): return msg
        case .unsupportedType(_, let msg): return msg
        }
    }

    var color: String {
        switch self {
        case .empty: return "secondary"
        case .missingVariable, .missingEquals, .incomplete: return "orange"
        case .valid: return "green"
        case .invalid: return "red"
        case .unsupportedType: return "blue"
        }
    }
}

/// Validates equation structure
struct EquationValidator {

    static func validate(_ components: [EquationComponent]) -> EquationValidationState {
        // Empty check
        guard !components.isEmpty else {
            return .empty
        }

        let equation = buildString(from: components)

        // Variable check
        let hasVariable = components.contains { component in
            if case .variable = component.type { return true }
            return false
        }
        guard hasVariable else {
            return .missingVariable
        }

        // Equals check
        let hasEquals = components.contains { component in
            if case .operation(let op) = component.type, op == .equals { return true }
            return false
        }
        guard hasEquals else {
            return .missingEquals
        }

        // Completeness check
        guard isComplete(components) else {
            return .incomplete
        }
        
        // Classify the built equation to check for unsupported types
        let classifier = EquationClassifier()
        let result = classifier.classifyWithConfidence(equation)
        
        if !result.type.isSupported && result.type != .unknown {
            return .unsupportedType(type: result.type, message: result.type.educationalMessage)
        }

        return .valid(equation)
    }

    static func buildString(from components: [EquationComponent]) -> String {
        components.map { $0.displayText }.joined()
    }

    private static func isComplete(_ components: [EquationComponent]) -> Bool {
        // Must have at least 3 components: variable, equals, something
        guard components.count >= 3 else { return false }

        // Last component should not be an operator (except equals in single-var case)
        if let last = components.last, case .operation(let op) = last.type, op != .equals {
            return false
        }

        // Check balanced parentheses
        var openCount = 0
        for component in components {
            if case .parenthesis(let p) = component.type {
                if p == .open { openCount += 1 }
                else { openCount -= 1 }
            }
        }
        guard openCount == 0 else { return false }

        // Must have content on both sides of equals
        guard let equalsIndex = components.firstIndex(where: { comp in
            if case .operation(let op) = comp.type, op == .equals { return true }
            return false
        }) else { return false }

        let leftSide = components[..<equalsIndex]
        let rightSide = components[(equalsIndex + 1)...]

        return !leftSide.isEmpty && !rightSide.isEmpty
    }
}

#endif
