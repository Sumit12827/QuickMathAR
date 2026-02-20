//
//  QuickMathsARApp.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

#if os(iOS)
import SwiftUI

@main
struct QuickMathsARApp: App {

    // MARK: - State Objects
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var dependencyContainer = DependencyContainer()

    // MARK: - App Storage
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - Initialization
    init() {
        // Set default haptic feedback preference if not already set
        if UserDefaults.standard.object(forKey: "hapticFeedback") == nil {
            UserDefaults.standard.set(true, forKey: "hapticFeedback")
        }
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                AppRouter()
                    .environmentObject(navigationCoordinator)
                    .environmentObject(dependencyContainer)
            } else {
                OnboardingView()
            }
        }
    }
}
#endif
