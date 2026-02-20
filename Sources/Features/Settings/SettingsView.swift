//
//  SettingsView.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

#if os(iOS)
import SwiftUI

/// Settings screen for app configuration
struct SettingsView: View {

    // MARK: - Environment
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    // MARK: - State
    @StateObject private var viewModel = SettingsViewModel()

    // MARK: - App Storage
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("rememberLastType") private var rememberLastType = true
    @AppStorage("showHints") private var showHints = true
    
    // MARK: - Body
    var body: some View {
        List {
            inputPreferencesSection
         //   learningSection
            appInfoSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    // MARK: - Sections
    private var inputPreferencesSection: some View {
        Section {
            Toggle("Haptic Feedback", isOn: $hapticFeedback)
        } header: {
            Text("Input Preferences")
        } footer: {
            Text("Haptic feedback provides tactile responses when building equations.")
                .font(.caption)
        }
    }

//    private var learningSection: some View {
//        Section {
//            Toggle("Remember last equation type", isOn: $rememberLastType)
//            Toggle("Show tips and hints", isOn: $showHints)
//        } header: {
//            Text("Learning")
//        } footer: {
//            Text("Tips help you understand concepts better as you learn.")
//                .font(.caption)
//        }
//    }
    
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text(viewModel.buildNumber)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - Preview
#Preview("Light") {
    NavigationStack {
        SettingsView()
            .environmentObject(NavigationCoordinator())
            .environmentObject(DependencyContainer())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        SettingsView()
            .environmentObject(NavigationCoordinator())
            .environmentObject(DependencyContainer())
    }
    .preferredColorScheme(.dark)
}
#endif
