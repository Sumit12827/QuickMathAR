//
//  EquationAnalyzer.swift
//  QuickMathsAR
//
//  Produces an EquationAnalysis for the user's specific equation.
//  Combines deterministic math (coefficients, discriminant, vertex)
//  with AI-generated insights (what it does, real-world analogy).
//

#if os(iOS)
import Foundation
import SwiftUI

// MARK: - Equation Analyzer

/// Analyzes a specific equation and produces a complete `EquationAnalysis`.
/// Uses `EquationParser` for coefficient extraction and
/// `FoundationalModelService` for AI-generated insights.
@MainActor
public final class EquationAnalyzer: ObservableObject {
    
    @Published public var state: EquationAnalysisState = .idle
    
    // MARK: - Public API
    
    /// Analyze the given equation asynchronously using on-device processing.
    /// Updates `state` through `.analyzing` → `.completed` or `.failed`.
    public func analyze(equation: String, type: EquationType) {
        guard case .idle = state else { return }
        state = .analyzing
        
        Task {
            do {
                let analysis = try await buildAnalysis(equation: equation, type: type)
                state = .completed(analysis)
            } catch {
                // Fall back to deterministic-only analysis
                let fallback = buildFallbackAnalysis(equation: equation, type: type)
                state = .completed(fallback)
            }
        }
    }
    
    // MARK: - Analysis Builder
    
    private func buildAnalysis(equation: String, type: EquationType) async throws -> EquationAnalysis {
        // Step 1: Parse coefficients (deterministic)
        let parsed = EquationParser.parse(equation)
        
        // Step 2: Build deterministic properties
        let coefficients: [CoefficientInfo]
        let graphOrientation: String
        let keyFeatures: [KeyFeature]
        let solutionPreview: String
        
        switch parsed {
        case .quadratic(let q):
            coefficients = quadraticCoefficients(q)
            graphOrientation = q.a > 0 ? "Opens upward (U-shape)" : "Opens downward (∩-shape)"
            keyFeatures = quadraticFeatures(q)
            solutionPreview = quadraticSolutionPreview(q)
            
        case .linear(let l):
            coefficients = linearCoefficients(l)
            graphOrientation = l.slope > 0 ? "Slopes upward (left to right)"
                : l.slope < 0 ? "Slopes downward (left to right)"
                : "Horizontal line"
            keyFeatures = linearFeatures(l)
            solutionPreview = "This equation has exactly 1 solution"
            
        case .none:
            // Can't parse — use pure fallback
            return buildFallbackAnalysis(equation: equation, type: type)
        }
        
        // Step 3: Try AI insights
        let aiInsights = await generateAIInsights(equation: equation, type: type, parsed: parsed)
        
        return EquationAnalysis(
            equation: equation,
            type: type,
            coefficients: coefficients,
            graphOrientation: graphOrientation,
            keyFeatures: keyFeatures,
            whatThisEquationDoes: aiInsights.whatItDoes,
            realWorldAnalogy: aiInsights.analogy,
            solutionPreview: solutionPreview
        )
    }
    
    // MARK: - AI Insights
    
    private struct AIInsights {
        let whatItDoes: String
        let analogy: String
    }
    
    private func generateAIInsights(equation: String, type: EquationType, parsed: ParsedEquation?) async -> AIInsights {
        // Try System Intelligence first (iOS 26+)
        let modelAvailable = isFoundationModelAvailable()
        print("EquationAnalyzer: generating insights, model available = \(modelAvailable)")

        if #available(iOS 26, *), modelAvailable {
            do {
                let service = FoundationalModelService()
                let result = try await service.generateEquationAnalysis(
                    equation: equation,
                    type: type
                )
                print("EquationAnalyzer: AI insights generated successfully")
                return AIInsights(whatItDoes: result.whatItDoes, analogy: result.analogy)
            } catch {
                print("EquationAnalyzer: AI generation failed — \(error.localizedDescription), using template")
            }
        }

        // Template fallback
        return templateInsights(equation: equation, type: type, parsed: parsed)
    }
    
    private func templateInsights(equation: String, type: EquationType, parsed: ParsedEquation?) -> AIInsights {
        switch parsed {
        case .quadratic(let q):
            let direction = q.a > 0 ? "upward" : "downward"
            let rootCount = q.xIntercepts.count
            let rootText = rootCount == 0 ? "never crosses the x-axis"
                : rootCount == 1 ? "touches the x-axis at exactly one point"
                : "crosses the x-axis at two points"
            
            return AIInsights(
                whatItDoes: "This equation describes a parabola that opens \(direction). It \(rootText), with its vertex at (\(formatFloat(q.vertex.x)), \(formatFloat(q.vertex.y))).",
                analogy: q.a > 0
                    ? "Think of it like the path of a ball thrown upward — it rises, peaks at the vertex, then falls back down."
                    : "Think of it like the shape of a hill — it rises to a peak at the vertex, then slopes back down on both sides."
            )
            
        case .linear(let l):
            let slopeDesc = abs(l.slope) < 0.01 ? "stays flat"
                : l.slope > 0 ? "increases by \(formatFloat(l.slope)) for every 1 unit to the right"
                : "decreases by \(formatFloat(abs(l.slope))) for every 1 unit to the right"
            
            return AIInsights(
                whatItDoes: "This equation describes a straight line that \(slopeDesc). It crosses the y-axis at \(formatFloat(l.yIntercept)).",
                analogy: "Think of the slope like a hill's steepness — \(formatFloat(abs(l.slope))) means for every step forward, you go \(formatFloat(abs(l.slope))) steps \(l.slope >= 0 ? "up" : "down")."
            )
            
        case .none:
            return AIInsights(
                whatItDoes: "This \(type.displayName.lowercased()) equation can be explored step by step.",
                analogy: "Every equation is like a puzzle — each operation gets you closer to finding the unknown value."
            )
        }
    }
    
    // MARK: - Quadratic Helpers

    private func quadraticCoefficients(_ q: QuadraticEquation) -> [CoefficientInfo] {
        [
            CoefficientInfo(
                symbol: "a",
                value: q.a,
                meaning: q.a > 0 ? "Opens upward" : "Opens downward"
            ),
            CoefficientInfo(
                symbol: "b",
                value: q.b,
                meaning: q.b == 0 ? "Symmetric about y-axis"
                    : q.b > 0 ? "Shifts vertex left" : "Shifts vertex right"
            ),
            CoefficientInfo(
                symbol: "c",
                value: q.c,
                meaning: "y-intercept at \(formatFloat(q.c))"
            )
        ]
    }
    
    private func quadraticFeatures(_ q: QuadraticEquation) -> [KeyFeature] {
        var features: [KeyFeature] = []
        
        features.append(KeyFeature(
            label: "Vertex",
            value: "(\(formatFloat(q.vertex.x)), \(formatFloat(q.vertex.y)))",
            icon: "scope",
            detail: q.a > 0 ? "Lowest point" : "Highest point"
        ))
        
        let disc = q.discriminant
        features.append(KeyFeature(
            label: "Discriminant",
            value: formatFloat(disc),
            icon: "number.square",
            detail: disc > 0 ? "2 real roots" : disc == 0 ? "1 repeated root" : "No real roots"
        ))
        
        let roots = q.xIntercepts
        if !roots.isEmpty {
            let rootStr = roots.map { formatFloat($0) }.joined(separator: ", ")
            features.append(KeyFeature(
                label: roots.count == 1 ? "Root" : "Roots",
                value: "x = \(rootStr)",
                icon: "xmark.circle",
                detail: nil
            ))
        }
        
        features.append(KeyFeature(
            label: "Y-Intercept",
            value: formatFloat(q.yIntercept),
            icon: "arrow.down.to.line",
            detail: nil
        ))
        
        return features
    }
    
    private func quadraticSolutionPreview(_ q: QuadraticEquation) -> String {
        let disc = q.discriminant
        if disc > 0 {
            let roots = q.xIntercepts
            return "This equation has 2 solutions: x = \(formatFloat(roots[0])) and x = \(formatFloat(roots[1]))"
        } else if disc == 0 {
            let root = q.xIntercepts.first ?? 0
            return "This equation has 1 repeated solution: x = \(formatFloat(root))"
        } else {
            return "This equation has no real solutions (discriminant < 0)"
        }
    }
    
    // MARK: - Linear Helpers
    
    private func linearCoefficients(_ l: LinearEquation) -> [CoefficientInfo] {
        [
            CoefficientInfo(
                symbol: "m",
                value: l.slope,
                meaning: l.slope > 0 ? "Line goes up" : l.slope < 0 ? "Line goes down" : "Horizontal"
            ),
            CoefficientInfo(
                symbol: "b",
                value: l.yIntercept,
                meaning: "Crosses y-axis at \(formatFloat(l.yIntercept))"
            )
        ]
    }
    
    private func linearFeatures(_ l: LinearEquation) -> [KeyFeature] {
        var features: [KeyFeature] = []
        
        features.append(KeyFeature(
            label: "Slope",
            value: formatFloat(l.slope),
            icon: "line.diagonal",
            detail: "Rise over run"
        ))
        
        features.append(KeyFeature(
            label: "Y-Intercept",
            value: formatFloat(l.yIntercept),
            icon: "arrow.down.to.line",
            detail: nil
        ))
        
        if let xInt = l.xIntercept {
            features.append(KeyFeature(
                label: "X-Intercept",
                value: formatFloat(xInt),
                icon: "xmark.circle",
                detail: nil
            ))
        }
        
        return features
    }
    
    // MARK: - Fallback (unparseable)
    
    private func buildFallbackAnalysis(equation: String, type: EquationType) -> EquationAnalysis {
        EquationAnalysis(
            equation: equation,
            type: type,
            coefficients: [],
            graphOrientation: type == .quadratic ? "Parabola" : "Straight line",
            keyFeatures: [],
            whatThisEquationDoes: "This \(type.displayName.lowercased()) equation can be explored step by step.",
            realWorldAnalogy: "Every equation is like a puzzle — each operation gets you closer to finding the unknown value.",
            solutionPreview: "Solve this equation to find x."
        )
    }
    
    // MARK: - Formatting
    
    private func formatFloat(_ value: Float) -> String {
        if value == Float(Int(value)) {
            return "\(Int(value))"
        }
        return String(format: "%.2g", value)
    }
}
#endif
