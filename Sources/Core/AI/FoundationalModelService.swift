//
//  FoundationalModelService.swift
//  QuickMathsAR
//
//  Wraps Apple's Foundation Models framework for on-device
//  conceptual explanations. Guarded behind @available(iOS 26, *)
//  so the app compiles and runs on iOS 17+ without issue.
//
//  The model NEVER solves equations or performs math. It only
//  explains WHY a step works conceptually.
//

#if os(iOS)
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Model Availability

/// Checks whether the on-device Foundation Model is available.
/// Returns false on pre-iOS 26 devices or when System Intelligence is disabled.
public func isFoundationModelAvailable() -> Bool {
    #if canImport(FoundationModels)
    if #available(iOS 26, *) {
        let result = FoundationalModelService.checkAvailability()
        return result
    } else {
        print("FoundationModel: iOS 26 not available (running older iOS)")
        return false
    }
    #else
    print("FoundationModel: FoundationModels framework not available at compile time")
    return false
    #endif
}

// MARK: - Service

/// Low-level service for interacting with the on-device Foundation Model.
/// All methods are `@available(iOS 26, *)` — callers must check availability first.
public final class FoundationalModelService: @unchecked Sendable {
    
    /// Timeout for model response in seconds.
    /// On first invocation the model loads into memory, so allow generous time.
    private let timeoutSeconds: TimeInterval = 15.0
    
    public init() {}
    
    // MARK: - Availability
    
    /// Check if the on-device model is available.
    @available(iOS 26, *)
    static func checkAvailability() -> Bool {
        #if canImport(FoundationModels)
        let availability = SystemLanguageModel.default.availability
        print("FoundationModel: SystemLanguageModel.default.availability = \(availability)")
        switch availability {
        case .available:
            return true
        case .unavailable(let reason):
            print("FoundationModel: unavailable — reason: \(reason)")
            return false
        @unknown default:
            print("FoundationModel: unknown availability state \(availability)")
            return false
        }
        #else
        return false
        #endif
    }
    
    // MARK: - Generate Explanation
    
    /// Generate a conceptual explanation for a specific solving step.
    /// Uses Guided Generation to produce structured `StepExplanation` output.
    ///
    /// - Parameters:
    ///   - context: Structured data about the step
    ///   - level: Desired explanation depth
    ///   - followUpQuestion: Optional user question about the step
    /// - Returns: A structured `StepExplanation`
    /// - Throws: If the model fails to generate or the response is invalid
    @available(iOS 26, *)
    public func generateExplanation(
        context: StepContext,
        level: ExplanationLevel,
        followUpQuestion: String? = nil
    ) async throws -> StepExplanation {
        #if canImport(FoundationModels)
        let prompt = buildPrompt(context: context, level: level, followUpQuestion: followUpQuestion)
        print("FoundationModel: generating step explanation for step \(context.stepNumber)...")

        let session = LanguageModelSession()

        // Use withThrowingTaskGroup with a timeout
        return try await withThrowingTaskGroup(of: StepExplanation.self) { group in
            // The actual generation task
            group.addTask {
                let response = try await session.respond(to: prompt)
                print("FoundationModel: step explanation received (\(response.content.count) chars)")
                return self.parseResponse(response.content)
            }

            // Timeout task
            group.addTask {
                try await Task.sleep(for: .seconds(self.timeoutSeconds))
                throw FoundationalModelError.timeout
            }

            // Return whichever finishes first; if timeout wins, it throws
            guard let result = try await group.next() else {
                throw FoundationalModelError.noResponse
            }
            group.cancelAll()
            return result
        }
        #else
        throw FoundationalModelError.unavailable
        #endif
    }
    
    // MARK: - Prompt Construction
    
    /// Builds the system + user prompt from structured context.
    /// This is intentionally NOT free-text — it's a controlled template.
    private func buildPrompt(
        context: StepContext,
        level: ExplanationLevel,
        followUpQuestion: String?
    ) -> String {
        var prompt = """
        You are a math tutor inside an educational app for students learning algebra.
        
        RULES:
        - Explain WHY the mathematical step works conceptually.
        - NEVER solve equations or perform calculations.
        - NEVER state the numerical answer directly.
        - \(level.promptGuidance)
        - Keep the concept explanation under 3 sentences.
        - Keep the analogy to 1 sentence.
        - Name the specific mathematical property used.
        
        CONTEXT:
        Equation: \(context.equationString)
        Step \(context.stepNumber) of \(context.totalSteps): \(context.action)
        Before: \(context.beforeEquation)
        After: \(context.afterEquation)
        """
        
        if let concept = context.arithmeticConceptUsed {
            prompt += "\nConcept: \(concept.replacingOccurrences(of: "_", with: " "))"
        }
        
        if let question = followUpQuestion, !question.isEmpty {
            prompt += "\n\nSTUDENT QUESTION: \(question)\nAnswer the student's question in context of this step."
        }
        
        prompt += """
        
        
        Respond with exactly this format:
        CONCEPT: [1-2 sentence conceptual explanation]
        PROPERTY: [name of mathematical property]
        ANALOGY: [1 sentence real-world analogy]
        TIP: [brief memory tip, or NONE]
        """
        
        return prompt
    }
    
    // MARK: - Response Parsing
    
    /// Parse the model's text response into a structured `StepExplanation`.
    /// Uses line-based parsing for reliability.
    private func parseResponse(_ text: String) -> StepExplanation {
        var concept = ""
        var property = ""
        var analogy = ""
        var tip: String? = nil
        
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("CONCEPT:") {
                concept = String(trimmed.dropFirst("CONCEPT:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("PROPERTY:") {
                property = String(trimmed.dropFirst("PROPERTY:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("ANALOGY:") {
                analogy = String(trimmed.dropFirst("ANALOGY:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("TIP:") {
                let tipText = String(trimmed.dropFirst("TIP:".count)).trimmingCharacters(in: .whitespaces)
                tip = (tipText.lowercased() == "none" || tipText.isEmpty) ? nil : tipText
            }
        }
        
        // Fallback if parsing fails — use the entire text as concept
        if concept.isEmpty {
            concept = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if concept.count > 200 {
                concept = String(concept.prefix(197)) + "..."
            }
        }
        
        if property.isEmpty {
            property = "Algebraic Property"
        }
        
        if analogy.isEmpty {
            analogy = "Each step preserves the balance of the equation."
        }
        
        return StepExplanation(
            conceptExplanation: concept,
            propertyUsed: property,
            analogy: analogy,
            memoryTip: tip
        )
    }
    
    // MARK: - Equation-Level Analysis
    
    /// Result of equation-level AI analysis
    public struct EquationInsight: Sendable {
        public let whatItDoes: String
        public let analogy: String
    }
    
    /// Generate a plain-English description and real-world analogy
    /// for the user's specific equation (not a single step).
    @available(iOS 26, *)
    public func generateEquationAnalysis(
        equation: String,
        type: EquationType
    ) async throws -> EquationInsight {
        #if canImport(FoundationModels)
        let prompt = buildEquationAnalysisPrompt(equation: equation, type: type)
        print("FoundationModel: generating equation analysis for '\(equation)'...")

        let session = LanguageModelSession()

        return try await withThrowingTaskGroup(of: EquationInsight.self) { group in
            group.addTask {
                let response = try await session.respond(to: prompt)
                print("FoundationModel: equation analysis received (\(response.content.count) chars)")
                return self.parseEquationAnalysisResponse(response.content)
            }

            group.addTask {
                try await Task.sleep(for: .seconds(self.timeoutSeconds))
                throw FoundationalModelError.timeout
            }

            guard let result = try await group.next() else {
                throw FoundationalModelError.noResponse
            }
            group.cancelAll()
            return result
        }
        #else
        throw FoundationalModelError.unavailable
        #endif
    }
    
    /// Builds a prompt for equation-level analysis.
    private func buildEquationAnalysisPrompt(equation: String, type: EquationType) -> String {
        """
        You are a math tutor inside an educational app for students learning algebra.
        
        RULES:
        - Explain what this specific equation represents in plain English.
        - Give a real-world analogy that uses the actual numbers in the equation.
        - Keep each response to 1-2 sentences maximum.
        - Be specific to THIS equation, not generic.
        
        EQUATION: \(equation)
        TYPE: \(type.displayName)
        
        Respond with exactly this format:
        DESCRIPTION: [1-2 sentence plain-English explanation of what this equation does]
        ANALOGY: [1 sentence real-world analogy using the actual coefficient values]
        """
    }
    
    /// Parse equation analysis response.
    private func parseEquationAnalysisResponse(_ text: String) -> EquationInsight {
        var description = ""
        var analogy = ""
        
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("DESCRIPTION:") {
                description = String(trimmed.dropFirst("DESCRIPTION:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("ANALOGY:") {
                analogy = String(trimmed.dropFirst("ANALOGY:".count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        if description.isEmpty {
            description = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if description.count > 200 {
                description = String(description.prefix(197)) + "..."
            }
        }
        
        if analogy.isEmpty {
            analogy = "Every equation tells a mathematical story."
        }
        
        return EquationInsight(whatItDoes: description, analogy: analogy)
    }
}

// MARK: - Errors

/// Errors specific to the Foundation Model service.
public enum FoundationalModelError: Error, LocalizedError {
    case unavailable
    case timeout
    case noResponse
    case invalidResponse(String)
    
    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "On-device processing is not available on this device."
        case .timeout:
            return "Explanation generation timed out."
        case .noResponse:
            return "No response received from the model."
        case .invalidResponse(let detail):
            return "Invalid model response: \(detail)"
        }
    }
}
#endif

