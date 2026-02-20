#if os(iOS)
//
//  LearningExample.swift
//  QuickMathsAR
//
//  Models for step-by-step learning examples with interactive features
//

import Foundation

/// Layered reasoning for a solving step
public struct StepReasoning: Codable, Sendable {
    public let brief: String
    public let detailed: String
    public let metaphor: String?

    /// Initialize from components
    public init(brief: String, detailed: String, metaphor: String? = nil) {
        self.brief = brief
        self.detailed = detailed
        self.metaphor = metaphor
    }
}

/// Transformation visualization for a step
public struct Transformation: Codable, Sendable {
    public let before: String
    public let operation: String
    public let after: String
    public let animation: String
    public let highlightTarget: String?

    public init(before: String, operation: String, after: String, animation: String, highlightTarget: String? = nil) {
        self.before = before
        self.operation = operation
        self.after = after
        self.animation = animation
        self.highlightTarget = highlightTarget
    }
}

/// Tooltip for additional help
public struct Tooltip: Codable, Sendable {
    public let trigger: String
    public let content: String

    public init(trigger: String, content: String) {
        self.trigger = trigger
        self.content = content
    }
}

/// Wrapper to handle both string and object reasoning formats
public enum StepReasoningWrapper: Codable, Sendable {
    case simple(String)
    case detailed(StepReasoning)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as StepReasoning object first
        if let reasoning = try? container.decode(StepReasoning.self) {
            self = .detailed(reasoning)
        } else if let string = try? container.decode(String.self) {
            // Fallback to simple string
            self = .simple(string)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode reasoning")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .simple(let string):
            try container.encode(string)
        case .detailed(let reasoning):
            try container.encode(reasoning)
        }
    }

    /// Get the brief/main reasoning text
    public var text: String {
        switch self {
        case .simple(let string): return string
        case .detailed(let reasoning): return reasoning.brief
        }
    }

    /// Get detailed reasoning if available
    public var detailedText: String? {
        switch self {
        case .simple: return nil
        case .detailed(let reasoning): return reasoning.detailed
        }
    }

    /// Get metaphor if available
    public var metaphorText: String? {
        switch self {
        case .simple: return nil
        case .detailed(let reasoning): return reasoning.metaphor
        }
    }
}

/// Represents a single step in solving an equation
public struct SolvingStep: Codable, Identifiable, Sendable {
    public var id: Int { stepNumber }

    public let stepNumber: Int
    public let action: String
    public let reasoning: StepReasoningWrapper
    public let result: String?
    public let arithmeticConceptUsed: String?

    // New interactive properties
    public let transformation: Transformation?
    public let tooltip: Tooltip?

    enum CodingKeys: String, CodingKey {
        case stepNumber, action, reasoning, result, arithmeticConceptUsed
        case transformation, tooltip
    }

    public init(
        stepNumber: Int,
        action: String,
        reasoning: StepReasoningWrapper,
        result: String? = nil,
        arithmeticConceptUsed: String? = nil,
        transformation: Transformation? = nil,
        tooltip: Tooltip? = nil
    ) {
        self.stepNumber = stepNumber
        self.action = action
        self.reasoning = reasoning
        self.result = result
        self.arithmeticConceptUsed = arithmeticConceptUsed
        self.transformation = transformation
        self.tooltip = tooltip
    }

    /// Convenience initializer with simple string reasoning (backward compatible)
    public init(
        stepNumber: Int,
        action: String,
        reasoning: String,
        result: String,
        arithmeticConceptUsed: String? = nil
    ) {
        self.stepNumber = stepNumber
        self.action = action
        self.reasoning = .simple(reasoning)
        self.result = result
        self.arithmeticConceptUsed = arithmeticConceptUsed
        self.transformation = nil
        self.tooltip = nil
    }
}

/// Mission statement for framing the problem
public struct MissionStatement: Codable, Sendable {
    public let before: String
    public let after: String
    public let narrative: String

    public init(before: String, after: String, narrative: String) {
        self.before = before
        self.after = after
        self.narrative = narrative
    }
}

/// Factoring puzzle configuration for quadratics
public struct FactoringPuzzle: Codable, Sendable {
    public let targetSum: Int
    public let targetProduct: Int
    public let availableNumbers: [Int]
    public let correctPair: [Int]
    public let hint: String

    enum CodingKeys: String, CodingKey {
        case targetSum = "target_sum"
        case targetProduct = "target_product"
        case availableNumbers = "available_numbers"
        case correctPair = "correct_pair"
        case hint
    }

    public init(targetSum: Int, targetProduct: Int, availableNumbers: [Int], correctPair: [Int], hint: String) {
        self.targetSum = targetSum
        self.targetProduct = targetProduct
        self.availableNumbers = availableNumbers
        self.correctPair = correctPair
        self.hint = hint
    }
}

/// Represents a complete worked example with step-by-step walkthrough
public struct LearningExample: Codable, Identifiable, Sendable {
    public var id: String { equation }

    // Core properties
    public let equation: String
    public let difficulty: String
    public let description: String
    public let steps: [SolvingStep]

    // New interactive properties
    public let missionStatement: MissionStatement?
    public let thinkingPath: [String]?
    public let factoringPuzzle: FactoringPuzzle?

    public init(
        equation: String,
        difficulty: String,
        description: String,
        steps: [SolvingStep],
        missionStatement: MissionStatement? = nil,
        thinkingPath: [String]? = nil,
        factoringPuzzle: FactoringPuzzle? = nil
    ) {
        self.equation = equation
        self.difficulty = difficulty
        self.description = description
        self.steps = steps
        self.missionStatement = missionStatement
        self.thinkingPath = thinkingPath
        self.factoringPuzzle = factoringPuzzle
    }
}

/// Difficulty level for learning examples
public enum ExampleDifficulty: String, Codable, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}
#endif
