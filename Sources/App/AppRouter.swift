//
//  AppRouter.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import SwiftUI

/// Main navigation coordinator view that handles app-level routing
struct AppRouter: View {
    
    // MARK: - Environment
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
        }
    }
    
    // MARK: - Route Mapping
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        Group {
            switch route {
            case .home:
                HomeView()
            case .equationInput:
                EquationInputView()
            case .equationType(let equation, let type):
                EquationTypeView(equation: equation, equationType: type)
            case .conceptExplanation(let equation, let type):
                ConceptExplanationView(equation: equation, equationType: type)
            case .learning(let equation, let type):
                LearningContainerView(equation: equation, equationType: type)
            case .arVisualization(let equation, let type):
                ARVisualizationContainerView(equation: equation, equationType: type)
            case .reflection(let type, let insights):
                ReflectionView(equationType: type, insights: insights)
            case .exploreConcepts:
                ConceptExplorerView()
            case .arithmeticConcept(let conceptId):
                if let concept = ContentLoader.shared.getArithmeticConcept(conceptId) {
                    ArithmeticConceptView(concept: concept)
                } else {
                    // Fallback if concept not found
                    ConceptExplorerView()
                }
            case .settings:
                SettingsView()
            }
        }
        .cinematicNavigation() // Apply custom transition
    }
}

// MARK: - Preview
#Preview {
    AppRouter()
        .environmentObject(NavigationCoordinator())
        .environmentObject(DependencyContainer())
}
