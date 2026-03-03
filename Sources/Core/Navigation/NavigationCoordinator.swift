#if os(iOS)
//
//  NavigationCoordinator.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import SwiftUI
import Combine

/// Observable navigation coordinator managing the app's navigation state
final class NavigationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var path = NavigationPath()
    
    // MARK: - Navigation Methods
    
    /// Pushes a new route onto the navigation stack
    /// - Parameter route: The route to navigate to
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    /// Pops the top route from the navigation stack
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    /// Pops all routes and returns to the root view
    func popToRoot() {
        path = NavigationPath()
    }
    
    /// Pops a specific number of views from the stack
    /// - Parameter count: Number of views to pop
    func pop(_ count: Int) {
        guard path.count >= count else {
            popToRoot()
            return
        }
        path.removeLast(count)
    }
    
    /// Replaces the current navigation stack with a new route
    /// - Parameter route: The route to replace with
    func replaceAll(with route: AppRoute) {
        path = NavigationPath()
        path.append(route)
    }
}
#endif
