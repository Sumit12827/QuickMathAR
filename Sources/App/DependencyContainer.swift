#if os(iOS)
//
//  DependencyContainer.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import SwiftUI
import Combine

/// Centralized dependency injection container for managing app services
@MainActor
final class DependencyContainer: ObservableObject {
    
    // MARK: - Services

    /// Content loader for learning material
    lazy var contentLoader: ContentLoader = ContentLoader.shared
    
    // MARK: - Initialization
    init() {
        // Initialize services here
        configureServices()
    }
    
    // MARK: - Configuration
    private func configureServices() {
        // Configure any initial service setup
    }
    
    // MARK: - Factory Methods
    
    /// Creates a HomeViewModel with injected dependencies
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel()
    }
    
    /// Creates a SettingsViewModel with injected dependencies
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel()
    }
}
#endif
