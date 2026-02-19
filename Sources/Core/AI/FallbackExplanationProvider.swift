//
//  FallbackExplanationProvider.swift
//  QuickMathsAR
//
//  Provides explanations from existing JSON content when
//  the Foundation Model is unavailable (offline, pre-iOS 26,
//  or on timeout). This ensures zero degradation — the app
//  is always functional.
//

import Foundation

/// Maps existing JSON `SolvingStep` reasoning data into
/// the `StepExplanation` format used by the UI.
/// Always available, no AI dependency.
public struct FallbackExplanationProvider: Sendable {
    
    public init() {}
    
    /// Build a `StepExplanation` from the existing JSON step data.
    /// Maps brief → conceptExplanation, detailed → propertyUsed,
    /// metaphor → analogy.
    public func explanation(
        from step: SolvingStep,
        level: ExplanationLevel
    ) -> StepExplanation {
        let reasoning = step.reasoning
        
        switch level {
        case .beginner:
            return StepExplanation(
                conceptExplanation: reasoning.text,
                propertyUsed: conceptLabel(for: step.arithmeticConceptUsed),
                analogy: reasoning.metaphorText ?? defaultAnalogy(for: step),
                memoryTip: nil
            )
            
        case .intermediate:
            let detailed = reasoning.detailedText ?? reasoning.text
            return StepExplanation(
                conceptExplanation: detailed,
                propertyUsed: conceptLabel(for: step.arithmeticConceptUsed),
                analogy: reasoning.metaphorText ?? defaultAnalogy(for: step),
                memoryTip: nil
            )
            
        case .advanced:
            let detailed = reasoning.detailedText ?? reasoning.text
            let property = formalProperty(for: step.arithmeticConceptUsed)
            return StepExplanation(
                conceptExplanation: detailed,
                propertyUsed: property,
                analogy: reasoning.metaphorText ?? "",
                memoryTip: advancedTip(for: step.arithmeticConceptUsed)
            )
        }
    }
    
    // MARK: - Private Helpers
    
    /// Readable label for the arithmetic concept tag.
    private func conceptLabel(for concept: String?) -> String {
        guard let concept = concept else { return "General Algebraic Reasoning" }
        switch concept {
        case "addition": return "Addition Property"
        case "subtraction": return "Subtraction Property"
        case "multiplication": return "Multiplication Property"
        case "division": return "Division Property"
        case "order_of_operations": return "Order of Operations"
        default: return concept.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    /// Formal mathematical property name for advanced level.
    private func formalProperty(for concept: String?) -> String {
        guard let concept = concept else { return "Algebraic Equivalence" }
        switch concept {
        case "addition": return "Addition Property of Equality"
        case "subtraction": return "Additive Inverse Property"
        case "multiplication": return "Multiplication Property of Equality"
        case "division": return "Multiplicative Inverse Property"
        case "order_of_operations": return "Operator Precedence (Reverse PEMDAS)"
        default: return concept.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    /// Default analogy when JSON metaphor is missing.
    private func defaultAnalogy(for step: SolvingStep) -> String {
        guard let concept = step.arithmeticConceptUsed else {
            return "Each step gets us closer to finding what x equals."
        }
        switch concept {
        case "addition":
            return "Like adding the same weight to both sides of a balanced scale."
        case "subtraction":
            return "Like removing equal weight from both sides of a scale."
        case "multiplication":
            return "Like giving everyone the same number of copies."
        case "division":
            return "Like sharing equally among groups."
        default:
            return "Each operation has an opposite that undoes it."
        }
    }
    
    /// Advanced-level memory tip.
    private func advancedTip(for concept: String?) -> String? {
        guard let concept = concept else { return nil }
        switch concept {
        case "addition", "subtraction":
            return "a + (-a) = 0 — every number has an additive inverse."
        case "multiplication", "division":
            return "a × (1/a) = 1 — every nonzero number has a multiplicative inverse."
        case "order_of_operations":
            return "To undo composed operations, reverse the order: undo the outermost operation first."
        default:
            return nil
        }
    }
}
