//
//  EquationComponent.swift
//  QuickMathsAR
//
//  Created on 2026-02-09.
//

import SwiftUI

// MARK: - Component Role (Semantic Meaning)

/// The semantic role a component plays in an equation.
/// Each role carries educational meaning that the UI uses to teach.
enum ComponentRole: String, CaseIterable {
    case variable       // Unknown value we're solving for
    case coefficient    // Scales a variable
    case constant       // Fixed value that shifts the result
    case addSubtract    // Combines or separates terms
    case multiplyDivide // Scales quantities
    case equals         // Balance point between expressions
    case power          // Changes the shape of the relationship
    case grouping       // Controls order of operations

    /// Color associated with this role (for chip tinting)
    var color: Color {
        switch self {
        case .variable:       return .blue
        case .coefficient:    return .indigo
        case .constant:       return .indigo
        case .addSubtract:    return .orange
        case .multiplyDivide: return .orange
        case .equals:         return .green
        case .power:          return .purple
        case .grouping:       return .gray
        }
    }

    /// Short educational hint for VoiceOver
    var accessibilityHint: String {
        switch self {
        case .variable:       return "Represents the unknown value to solve for"
        case .coefficient:    return "Scales the variable"
        case .constant:       return "A fixed numerical value"
        case .addSubtract:    return "Combines or separates terms"
        case .multiplyDivide: return "Scales quantities"
        case .equals:         return "Creates balance between two expressions"
        case .power:          return "Changes the shape of the relationship"
        case .grouping:       return "Controls the order of operations"
        }
    }
}

// MARK: - Equation Component

/// Represents a component in an equation
struct EquationComponent: Identifiable, Hashable {
    let id: UUID
    let type: ComponentType

    init(type: ComponentType, id: UUID = UUID()) {
        self.type = type
        self.id = id
    }

    // MARK: - Compatibility Factories
    static func variable(_ v: String) -> EquationComponent {
        EquationComponent(type: .variable(v))
    }

    static func number(_ n: String) -> EquationComponent {
        EquationComponent(type: .number(n))
    }

    static func operation(_ op: Operation) -> EquationComponent {
        EquationComponent(type: .operation(op))
    }

    static func power(_ p: String) -> EquationComponent {
        EquationComponent(type: .power(p))
    }

    static func parenthesis(_ p: Parenthesis) -> EquationComponent {
        EquationComponent(type: .parenthesis(p))
    }

    // MARK: - Proxy Properties
    var displayText: String { type.displayText }
    var accessibilityLabel: String { type.accessibilityLabel }

    /// The semantic role of this component in the equation
    var role: ComponentRole { type.role }
}

// MARK: - Component Type

/// The type of equation component
enum ComponentType: Hashable {
    case variable(String)
    case number(String)
    case operation(Operation)
    case power(String)
    case parenthesis(Parenthesis)

    var displayText: String {
        switch self {
        case .variable(let v): return v
        case .number(let n): return n
        case .operation(let op): return op.symbol
        case .power(let p): return p
        case .parenthesis(let p): return p.symbol
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .variable(let v): return "Variable \(v)"
        case .number(let n): return "Number \(n)"
        case .operation(let op): return op.accessibilityLabel
        case .power(let p): return "Power \(p)"
        case .parenthesis(let p): return p.accessibilityLabel
        }
    }

    /// Determine the semantic role based on component type
    var role: ComponentRole {
        switch self {
        case .variable:
            return .variable
        case .number:
            // Note: whether a number is a coefficient or constant depends on context.
            // Default to constant; the ViewModel upgrades to coefficient when adjacent to a variable.
            return .constant
        case .operation(let op):
            switch op {
            case .plus, .minus:
                return .addSubtract
            case .multiply, .divide:
                return .multiplyDivide
            case .equals:
                return .equals
            }
        case .power:
            return .power
        case .parenthesis:
            return .grouping
        }
    }
}

// MARK: - Operation

enum Operation: String, CaseIterable {
    case plus = "+"
    case minus = "-"
    case multiply = "×"
    case divide = "÷"
    case equals = "="

    var symbol: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .plus: return "Plus"
        case .minus: return "Minus"
        case .multiply: return "Multiply"
        case .divide: return "Divide"
        case .equals: return "Equals"
        }
    }
}

// MARK: - Parenthesis

enum Parenthesis: String, CaseIterable {
    case open = "("
    case close = ")"

    var symbol: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .open: return "Open parenthesis"
        case .close: return "Close parenthesis"
        }
    }
}
