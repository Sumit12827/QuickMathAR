//
//  EquationAnalysis.swift
//  QuickMathsAR
//
//  Equation-level analysis model — holds AI insights and
//  computed mathematical properties for the user's specific equation.
//

#if os(iOS)
import Foundation

// MARK: - Coefficient Info

/// Describes a single coefficient in the equation with its mathematical meaning
public struct CoefficientInfo: Hashable, Sendable {
    public let symbol: String       // "a", "b", "c", "m", etc.
    public let value: Float
    public let meaning: String      // "Opens upward", "Shifts graph right", etc.
    
    public init(symbol: String, value: Float, meaning: String) {
        self.symbol = symbol
        self.value = value
        self.meaning = meaning
    }
    
    /// Formatted display value (e.g. "2", "-3", "0.5")
    public var displayValue: String {
        if value == Float(Int(value)) {
            return "\(Int(value))"
        }
        return String(format: "%.2g", value)
    }
}

// MARK: - Key Feature

/// A notable mathematical feature of the equation
public struct KeyFeature: Hashable, Sendable {
    public let label: String        // "Vertex", "Discriminant", "Slope", etc.
    public let value: String        // "(−2.5, −0.25)", "1", "2/3", etc.
    public let icon: String         // SF Symbol name
    public let detail: String?      // Optional extra explanation
    
    public init(label: String, value: String, icon: String, detail: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
        self.detail = detail
    }
}

// MARK: - Equation Analysis

/// Complete analysis of the user's specific equation.
/// Contains both deterministic mathematical properties and AI-generated insights.
public struct EquationAnalysis: Hashable, Sendable {
    
    // Identity
    public let equation: String
    public let type: EquationType
    
    // Deterministic properties (always available)
    public let coefficients: [CoefficientInfo]
    public let graphOrientation: String
    public let keyFeatures: [KeyFeature]
    
    // AI-generated insights (may use fallback templates)
    public let whatThisEquationDoes: String
    public let realWorldAnalogy: String
    public let solutionPreview: String
    
    public init(
        equation: String,
        type: EquationType,
        coefficients: [CoefficientInfo],
        graphOrientation: String,
        keyFeatures: [KeyFeature],
        whatThisEquationDoes: String,
        realWorldAnalogy: String,
        solutionPreview: String
    ) {
        self.equation = equation
        self.type = type
        self.coefficients = coefficients
        self.graphOrientation = graphOrientation
        self.keyFeatures = keyFeatures
        self.whatThisEquationDoes = whatThisEquationDoes
        self.realWorldAnalogy = realWorldAnalogy
        self.solutionPreview = solutionPreview
    }
}

// MARK: - Analysis State

/// Observable state for the equation analysis loading flow
public enum EquationAnalysisState: Equatable {
    case idle
    case analyzing
    case completed(EquationAnalysis)
    case failed(String)
    
    public static func == (lhs: EquationAnalysisState, rhs: EquationAnalysisState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.analyzing, .analyzing): return true
        case (.completed(let a), .completed(let b)): return a == b
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}
#endif
