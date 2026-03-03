//
//  ExplanationModels.swift
//  QuickMathsAR
//
//  Models for the AI-powered explanation system.
//  Defines structured types for requesting and receiving
//  conceptual explanations from the Foundation Model.
//

#if os(iOS)
import Foundation

// MARK: - Explanation Level

/// Controls the depth and tone of AI-generated explanations.
/// Each level targets a different learner maturity.
public enum ExplanationLevel: String, Codable, CaseIterable, Sendable, Hashable {
    case beginner
    case intermediate
    case advanced
    
    /// Human-readable display label
    public var displayName: String {
        switch self {
        case .beginner: return "Basic"
        case .intermediate: return "Standard"
        case .advanced: return "Detailed"
        }
    }
    
    /// System prompt fragment describing tone and vocabulary
    var promptGuidance: String {
        switch self {
        case .beginner:
            return "Use everyday language and relatable metaphors. Keep sentences short and encouraging. Explain like you would to someone seeing algebra for the first time."
        case .intermediate:
            return "Use standard mathematical vocabulary like 'inverse operation' and 'isolate'. Be explanatory and clear. Connect steps to mathematical properties."
        case .advanced:
            return "Use formal mathematical property names like 'Additive Inverse Property' and 'equivalence preservation'. Be precise and include brief generalization of why this always works."
        }
    }
}

// MARK: - Step Context

/// Structured context about a specific solving step, passed to the model.
/// This is NOT a free-text prompt — it is machine-readable data.
public struct StepContext: Sendable {
    public let equationString: String
    public let stepNumber: Int
    public let totalSteps: Int
    public let action: String
    public let beforeEquation: String
    public let afterEquation: String
    public let arithmeticConceptUsed: String?
    public let briefReasoning: String
    
    public init(
        equationString: String,
        stepNumber: Int,
        totalSteps: Int,
        action: String,
        beforeEquation: String,
        afterEquation: String,
        arithmeticConceptUsed: String?,
        briefReasoning: String
    ) {
        self.equationString = equationString
        self.stepNumber = stepNumber
        self.totalSteps = totalSteps
        self.action = action
        self.beforeEquation = beforeEquation
        self.afterEquation = afterEquation
        self.arithmeticConceptUsed = arithmeticConceptUsed
        self.briefReasoning = briefReasoning
    }
}

// MARK: - Step Explanation (Output)

/// The structured explanation returned by the model (or fallback).
/// All fields are deterministic in shape — the model fills them with
/// conceptual content, never with math solutions.
public struct StepExplanation: Codable, Sendable, Equatable {
    /// 1-2 sentence conceptual explanation of why this step works
    public let conceptExplanation: String
    
    /// The mathematical property being applied (e.g., "Additive Inverse Property")
    public let propertyUsed: String
    
    /// A relatable real-world analogy, max 1 sentence
    public let analogy: String
    
    /// Brief tip for remembering this concept (optional)
    public let memoryTip: String?
    
    public init(
        conceptExplanation: String,
        propertyUsed: String,
        analogy: String,
        memoryTip: String? = nil
    ) {
        self.conceptExplanation = conceptExplanation
        self.propertyUsed = propertyUsed
        self.analogy = analogy
        self.memoryTip = memoryTip
    }
}

// MARK: - Cache Key

/// Unique key for caching explanations. An explanation is uniquely
/// identified by the equation, the step number, and the depth level.
public struct StepKey: Hashable, Sendable {
    public let equation: String
    public let stepNumber: Int
    public let level: ExplanationLevel
    
    public init(equation: String, stepNumber: Int, level: ExplanationLevel) {
        self.equation = equation
        self.stepNumber = stepNumber
        self.level = level
    }
}

// MARK: - Explanation State

/// Represents the current state of an explanation for a given step.
/// Used by the UI to show the appropriate view.
public enum ExplanationState: Sendable, Equatable {
    /// No explanation requested yet
    case idle
    /// Waiting for model response
    case loading
    /// Successfully loaded (from model or cache)
    case loaded(StepExplanation)
    /// Fell back to JSON-derived explanation (model unavailable)
    case fallback(StepExplanation)
    /// Error occurred (message for debugging, user sees fallback)
    case error(String)
    
    /// Whether content is available to display
    public var hasContent: Bool {
        switch self {
        case .loaded, .fallback: return true
        default: return false
        }
    }
    
    /// The explanation if available
    public var explanation: StepExplanation? {
        switch self {
        case .loaded(let exp), .fallback(let exp): return exp
        default: return nil
        }
    }
    
    /// Whether this came from AI or fallback
    public var isAIGenerated: Bool {
        if case .loaded = self { return true }
        return false
    }
}
#endif
