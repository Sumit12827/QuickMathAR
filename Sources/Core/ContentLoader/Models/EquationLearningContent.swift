#if os(iOS)
//
//  EquationLearningContent.swift
//  QuickMathsAR
//
//  Model for equation type learning content with concept flow
//

import Foundation

/// Visual metaphor for an equation type
public struct EquationVisualMetaphor: Codable, Sendable {
    public let type: String
    public let description: String
    public let animationPreset: String

    public init(type: String, description: String, animationPreset: String) {
        self.type = type
        self.description = description
        self.animationPreset = animationPreset
    }
}

/// A scenario showing real-world application
public struct ConnectionScenario: Codable, Sendable {
    public let icon: String
    public let title: String
    public let equation: String?
    public let description: String?

    public init(icon: String, title: String, equation: String? = nil, description: String? = nil) {
        self.icon = icon
        self.title = title
        self.equation = equation
        self.description = description
    }
}

/// A page in the concept flow
public struct ConceptFlowPage: Codable, Sendable {
    public let page: String
    public let title: String?
    public let visual: String?
    public let interaction: String?
    public let insight: String?
    public let scenarios: [ConnectionScenario]?
    public let question: String?
    public let options: [ChallengeOption]?

    public init(
        page: String,
        title: String? = nil,
        visual: String? = nil,
        interaction: String? = nil,
        insight: String? = nil,
        scenarios: [ConnectionScenario]? = nil,
        question: String? = nil,
        options: [ChallengeOption]? = nil
    ) {
        self.page = page
        self.title = title
        self.visual = visual
        self.interaction = interaction
        self.insight = insight
        self.scenarios = scenarios
        self.question = question
        self.options = options
    }
}

/// Represents the complete learning content for an equation type
public struct EquationLearningContent: Codable, Sendable {

    // MARK: - Core Properties
    public let version: String
    public let equationType: String
    public let displayName: String
    public let definition: String
    public let solvingMethodConcept: String
    public let prerequisites: [String]
    public let examples: [LearningExample]
    public let arAvailable: Bool

    // MARK: - New Interactive Properties
    public let visualMetaphor: EquationVisualMetaphor?
    public let conceptFlow: [ConceptFlowPage]?

    public init(
        version: String,
        equationType: String,
        displayName: String,
        definition: String,
        solvingMethodConcept: String,
        prerequisites: [String],
        examples: [LearningExample],
        arAvailable: Bool,
        visualMetaphor: EquationVisualMetaphor? = nil,
        conceptFlow: [ConceptFlowPage]? = nil
    ) {
        self.version = version
        self.equationType = equationType
        self.displayName = displayName
        self.definition = definition
        self.solvingMethodConcept = solvingMethodConcept
        self.prerequisites = prerequisites
        self.examples = examples
        self.arAvailable = arAvailable
        self.visualMetaphor = visualMetaphor
        self.conceptFlow = conceptFlow
    }
}
#endif
