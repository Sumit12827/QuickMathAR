#if os(iOS)
//
//  HomeViewModel.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import Foundation
import Combine

/// ViewModel for the Home screen
final class HomeViewModel: ObservableObject, ViewModelProtocol {
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Initialize any required dependencies
    }
    
    // MARK: - Lifecycle
    func onAppear() {
        // Perform any setup when view appears
    }
    
    func onDisappear() {
        // Cleanup when view disappears
    }
}
#endif
