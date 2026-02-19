//
//  ExplanationEngine.swift
//  QuickMathsAR
//
//  Orchestrates the explanation pipeline:
//  check cache → call model → fallback → deliver to UI.
//  This is the single point of contact for views needing explanations.
//

import Foundation
import SwiftUI

/// Central orchestrator for AI-powered explanations.
/// Manages state, caching, cancellation, and fallback logic.
@Observable
public final class ExplanationEngine {
    
    // MARK: - Public State
    
    /// Per-step explanation states, keyed by (equation, step, level)
    public private(set) var explanationStates: [StepKey: ExplanationState] = [:]
    
    /// Current explanation depth level (shared across all steps)
    public var currentLevel: ExplanationLevel = .beginner
    
    /// Whether the AI model is available on this device
    public private(set) var isModelAvailable: Bool = false
    
    // MARK: - Private
    
    private let modelService: FoundationalModelService
    private let cache: ExplanationCache
    private let fallback: FallbackExplanationProvider
    
    /// Active tasks for cancellation support
    private var activeTasks: [StepKey: Task<Void, Never>] = [:]
    
    /// Debounce timers for level switching
    private var debounceTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init() {
        self.modelService = FoundationalModelService()
        self.cache = ExplanationCache()
        self.fallback = FallbackExplanationProvider()
        self.isModelAvailable = isFoundationModelAvailable()
    }
    
    // MARK: - Public API
    
    /// Request an explanation for a specific step.
    /// Checks cache first, then calls model, with fallback on failure.
    ///
    /// - Parameters:
    ///   - step: The solving step to explain
    ///   - equation: The parent equation string
    ///   - totalSteps: Total number of steps in the example
    ///   - previousStepResult: The equation before this step
    public func requestExplanation(
        for step: SolvingStep,
        equation: String,
        totalSteps: Int,
        previousStepResult: String?
    ) {
        let key = StepKey(
            equation: equation,
            stepNumber: step.stepNumber,
            level: currentLevel
        )
        
        // 1. Check cache
        if let cached = cache.get(for: key) {
            explanationStates[key] = .loaded(cached)
            return
        }
        
        // 2. Cancel any existing task for this key
        activeTasks[key]?.cancel()
        
        // 3. Set loading state
        explanationStates[key] = .loading
        
        // 4. Build context
        let context = buildContext(
            step: step,
            equation: equation,
            totalSteps: totalSteps,
            previousStepResult: previousStepResult
        )
        
        // 5. Generate (async)
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            var explanation: StepExplanation?
            var isAIGenerated = false
            
            // Try AI model first
            if self.isModelAvailable {
                explanation = await self.generateWithModel(
                    context: context,
                    level: self.currentLevel
                )
                isAIGenerated = explanation != nil
            }
            
            // Fallback to JSON-derived explanation
            if explanation == nil {
                explanation = self.fallback.explanation(from: step, level: self.currentLevel)
            }
            
            guard !Task.isCancelled, let result = explanation else { return }
            
            // Cache the result
            self.cache.set(result, for: key)
            
            // Update state on main actor
            await MainActor.run {
                if isAIGenerated {
                    self.explanationStates[key] = .loaded(result)
                } else {
                    self.explanationStates[key] = .fallback(result)
                }
            }
        }
        
        activeTasks[key] = task
    }
    
    /// Request a follow-up explanation for a user's question about a step.
    public func requestFollowUp(
        question: String,
        for step: SolvingStep,
        equation: String,
        totalSteps: Int,
        previousStepResult: String?
    ) {
        // Follow-ups are not cached (unique questions)
        let key = StepKey(
            equation: equation,
            stepNumber: step.stepNumber,
            level: currentLevel
        )
        
        activeTasks[key]?.cancel()
        explanationStates[key] = .loading
        
        let context = buildContext(
            step: step,
            equation: equation,
            totalSteps: totalSteps,
            previousStepResult: previousStepResult
        )
        
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            var explanation: StepExplanation?
            
            if self.isModelAvailable {
                explanation = await self.generateWithModel(
                    context: context,
                    level: self.currentLevel,
                    followUpQuestion: question
                )
            }
            
            if explanation == nil {
                // For follow-ups, fallback to the standard explanation
                explanation = self.fallback.explanation(from: step, level: self.currentLevel)
            }
            
            guard !Task.isCancelled, let result = explanation else { return }
            
            await MainActor.run {
                self.explanationStates[key] = self.isModelAvailable ? .loaded(result) : .fallback(result)
            }
        }
        
        activeTasks[key] = task
    }
    
    /// Switch explanation level with debounce.
    /// If the user switches levels rapidly, only the final level triggers a fetch.
    public func switchLevel(
        to newLevel: ExplanationLevel,
        for step: SolvingStep,
        equation: String,
        totalSteps: Int,
        previousStepResult: String?
    ) {
        currentLevel = newLevel
        
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.requestExplanation(
                for: step,
                equation: equation,
                totalSteps: totalSteps,
                previousStepResult: previousStepResult
            )
        }
    }
    
    /// Get the current state for a specific step at the current level.
    public func state(for step: SolvingStep, equation: String) -> ExplanationState {
        let key = StepKey(
            equation: equation,
            stepNumber: step.stepNumber,
            level: currentLevel
        )
        return explanationStates[key] ?? .idle
    }
    
    /// Cancel all active generation tasks. Call on view disappear.
    public func cancelAll() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        debounceTask?.cancel()
    }
    
    // MARK: - Private
    
    private func buildContext(
        step: SolvingStep,
        equation: String,
        totalSteps: Int,
        previousStepResult: String?
    ) -> StepContext {
        // Determine "before" equation for this step
        let before: String
        if let transformation = step.transformation {
            before = transformation.before
        } else if let prev = previousStepResult {
            before = prev
        } else {
            before = equation
        }
        
        // Determine "after" equation
        let after: String
        if let transformation = step.transformation {
            after = transformation.after
        } else {
            after = step.result ?? equation
        }
        
        return StepContext(
            equationString: equation,
            stepNumber: step.stepNumber,
            totalSteps: totalSteps,
            action: step.action,
            beforeEquation: before,
            afterEquation: after,
            arithmeticConceptUsed: step.arithmeticConceptUsed,
            briefReasoning: step.reasoning.text
        )
    }
    
    @available(iOS 26, *)
    private func generateWithModelAsync(
        context: StepContext,
        level: ExplanationLevel,
        followUpQuestion: String? = nil
    ) async -> StepExplanation? {
        do {
            return try await modelService.generateExplanation(
                context: context,
                level: level,
                followUpQuestion: followUpQuestion
            )
        } catch {
            print("ExplanationEngine: Model generation failed — \(error.localizedDescription)")
            return nil
        }
    }
    
    private func generateWithModel(
        context: StepContext,
        level: ExplanationLevel,
        followUpQuestion: String? = nil
    ) async -> StepExplanation? {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return await generateWithModelAsync(
                context: context,
                level: level,
                followUpQuestion: followUpQuestion
            )
        }
        #endif
        return nil
    }
}
