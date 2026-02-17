//
//  ArithmeticConcept.swift
//  QuickMathsAR
//
//  Model for foundational arithmetic concepts with interactive features
//

import Foundation

/// Represents a single conceptual example for an arithmetic operation
public struct ConceptualExample: Codable, Identifiable, Sendable {
    public var id: String { expression }
    public let expression: String
    public let explanation: String
    public let visualHint: String?

    enum CodingKeys: String, CodingKey {
        case expression, explanation
        case visualHint = "visualHint"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expression = try container.decode(String.self, forKey: .expression)
        explanation = try container.decode(String.self, forKey: .explanation)
        visualHint = try container.decodeIfPresent(String.self, forKey: .visualHint)
    }

    public init(expression: String, explanation: String, visualHint: String? = nil) {
        self.expression = expression
        self.explanation = explanation
        self.visualHint = visualHint
    }
}

/// Type of interaction for the arithmetic concept
public enum InteractionType: String, Codable, Sendable {
    case dragCombine = "drag_combine"
    case swipeRemove = "swipe_remove"
    case tapReplicate = "tap_replicate"
    case dragDistribute = "drag_distribute"
    case stepThrough = "step_through"
}

/// Visual metaphor configuration
public struct VisualMetaphor: Codable, Sendable {
    public let type: String
    public let config: [String: AnyCodableValue]?

    public init(type: String, config: [String: AnyCodableValue]? = nil) {
        self.type = type
        self.config = config
    }
}

/// A single option in a quick challenge
public struct ChallengeOption: Codable, Identifiable, Sendable {
    public var id: String { text }
    public let text: String
    public let isCorrect: Bool
    public let feedback: String

    public init(text: String, isCorrect: Bool, feedback: String) {
        self.text = text
        self.isCorrect = isCorrect
        self.feedback = feedback
    }
}

/// Quick challenge for testing understanding
public struct QuickChallenge: Codable, Sendable {
    public let question: String
    public let options: [ChallengeOption]
    public let explanation: String

    public init(question: String, options: [ChallengeOption], explanation: String) {
        self.question = question
        self.options = options
        self.explanation = explanation
    }
}

/// Represents a foundational arithmetic concept with optional interactive features
public struct ArithmeticConcept: Codable, Identifiable, Sendable {

    // MARK: - Core Properties (existing)
    public let id: String
    public let name: String
    public let symbol: String
    public let definition: String
    public let whyItMatters: String
    public let conceptualExamples: [ConceptualExample]

    // MARK: - Interactive Properties (new - all optional for backward compatibility)
    public let interactionType: InteractionType?
    public let visualMetaphor: VisualMetaphor?
    public let microAnimation: String?
    public let insightReveal: String?
    public let quickChallenge: QuickChallenge?

    public init(
        id: String,
        name: String,
        symbol: String,
        definition: String,
        whyItMatters: String,
        conceptualExamples: [ConceptualExample],
        interactionType: InteractionType? = nil,
        visualMetaphor: VisualMetaphor? = nil,
        microAnimation: String? = nil,
        insightReveal: String? = nil,
        quickChallenge: QuickChallenge? = nil
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.definition = definition
        self.whyItMatters = whyItMatters
        self.conceptualExamples = conceptualExamples
        self.interactionType = interactionType
        self.visualMetaphor = visualMetaphor
        self.microAnimation = microAnimation
        self.insightReveal = insightReveal
        self.quickChallenge = quickChallenge
    }
}

/// Wrapper for the entire foundations content file
public struct FoundationsContent: Codable, Sendable {
    public let version: String
    public let lastUpdated: String
    public let description: String
    public let concepts: [ArithmeticConcept]
}

/// Type-erased codable value for flexible JSON config
public enum AnyCodableValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodableValue].self) {
            self = .array(array)
        } else if let dictionary = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dictionary)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    // Helper accessors
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    public var doubleValue: Double? {
        if case .double(let value) = self { return value }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    public var arrayValue: [AnyCodableValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    public var dictionaryValue: [String: AnyCodableValue]? {
        if case .dictionary(let value) = self { return value }
        return nil
    }
}
