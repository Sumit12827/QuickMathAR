#if os(iOS)
//
//  SettingsViewModel.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import Foundation
import Combine

/// ViewModel for the Settings screen
final class SettingsViewModel: ObservableObject, ViewModelProtocol {
    
    // MARK: - Types
    enum Difficulty: String, CaseIterable, Identifiable {
        case easy
        case medium
        case hard
        
        var id: Self { self }
    }
    
    // MARK: - Published Properties
    @Published var soundEnabled: Bool = true
    @Published var hapticEnabled: Bool = true
    @Published var difficulty: Difficulty = .medium
    
    // MARK: - Computed Properties
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadSettings()
        setupBindings()
    }
    
    // MARK: - Lifecycle
    func onAppear() {
        // Refresh settings when view appears
    }
    
    func onDisappear() {
        // Save settings when view disappears
        saveSettings()
    }
    
    // MARK: - Private Methods
    private func loadSettings() {
        // TODO: Load from UserDefaults or other persistence
    }
    
    private func saveSettings() {
        // TODO: Save to UserDefaults or other persistence
    }
    
    private func setupBindings() {
        // Auto-save when settings change
        $soundEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        
        $hapticEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        
        $difficulty
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
    }
}
#endif
