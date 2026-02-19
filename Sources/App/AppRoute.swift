//
//  AppRoute.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import Foundation

/// Defines all navigable routes in the application
enum AppRoute: Hashable, Identifiable {
    case home
    case equationInput
    case equationType(equation: String, type: EquationType)
    case conceptExplanation(equation: String, type: EquationType, analysis: EquationAnalysis?)
    case learning(equation: String, type: EquationType)
    case arVisualization(equation: String, type: EquationType)
    case reflection(equationType: EquationType, insights: [String])
    case exploreConcepts
    case arithmeticConcept(conceptId: String)
    case settings

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .home: return "home"
        case .equationInput: return "equationInput"
        case .equationType(let equation, _): return "equationType-\(equation)"
        case .conceptExplanation(let equation, _, _): return "conceptExplanation-\(equation)"
        case .learning(let equation, _): return "learning-\(equation)"
        case .arVisualization(let equation, _): return "arVisualization-\(equation)"
        case .reflection(let type, _): return "reflection-\(type.id)"
        case .exploreConcepts: return "exploreConcepts"
        case .arithmeticConcept(let conceptId): return "arithmeticConcept-\(conceptId)"
        case .settings: return "settings"
        }
    }
}
