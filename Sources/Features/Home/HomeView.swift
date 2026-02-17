//
//  HomeView.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import SwiftUI

/// Main landing screen of the app
struct HomeView: View {
    
    // MARK: - Environment
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    // MARK: - State
    @StateObject private var viewModel = HomeViewModel()
    
    // MARK: - Environment Values
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Animation State
    @State private var headerOpacity: Double = 0.0
    @State private var headerScale: Double = 0.8
    @State private var buttonsOpacity: Double = 0.0
    @State private var buttonsOffset: CGFloat = 30
    
    // MARK: - Body
    var body: some View {
        AdaptiveLayout(
            compact: { compactLayout },
            regular: { regularLayout }
        )
        .background(Color(.systemBackground))
        .navigationTitle("Quick Maths AR")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                settingsButton
            }
        }
        .onAppear {
            viewModel.onAppear()
            HapticManager.shared.prepare()
            animateAppearance()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    // MARK: - Compact Layout (iPhone)
    private var compactLayout: some View {
        VStack(spacing: AppMetrics.spacingStandard) {
            Spacer()

            headerSection

            Spacer()

            VStack(spacing: AppMetrics.spacingTight) {
                buildEquationButton
                exploreConceptsButton
            }
            .opacity(buttonsOpacity)
            .offset(y: buttonsOffset)

            Spacer(minLength: AppMetrics.spacingLarge)
        }
        .padding(.horizontal, AppMetrics.cardEdgeInset)
        .padding(.top)
        .padding(.bottom, AppMetrics.spacingAir)
    }

    // MARK: - Regular Layout (iPad)
    private var regularLayout: some View {
        HStack(spacing: AppMetrics.spacingAir) {
            VStack(spacing: AppMetrics.spacingStandard) {
                headerSection
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: AppMetrics.spacingLarge) {
                buildEquationButton
                exploreConceptsButton
            }
            .opacity(buttonsOpacity)
            .offset(y: buttonsOffset)
            .frame(maxWidth: .infinity)
        }
        .padding(AppMetrics.spacingAir)
    }
    
    // MARK: - Components
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            Text("Quick Maths AR")
                .font(.largeTitle)
                .fontWeight(.bold)
                .safeTitle(minScale: 0.8)

            Text("Understand math visually, not just solve it")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeBody()
                .padding(.horizontal, 24)
        }
        .opacity(headerOpacity)
        .scaleEffect(headerScale)
    }

    // MARK: - Animation (Spec: staggered spring cascade)
    private func animateAppearance() {
        // Primary: header (immediate)
        withAnimation(.specSpring.delay(AppConstants.delayPrimary)) {
            headerOpacity = 1.0
            headerScale = 1.0
        }
        // Secondary: buttons (+40ms per spec micro-delay)
        withAnimation(.specSpring.delay(AppConstants.delaySecondary + 0.15)) {
            buttonsOpacity = 1.0
            buttonsOffset = 0
        }
    }
    
    private var buildEquationButton: some View {
        Button {
            HapticManager.shared.tap()
            navigationCoordinator.push(.equationInput)
        } label: {
            VStack(spacing: AppMetrics.spacingMicro) {
                Image(systemName: "plus.square.fill.on.square.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)

                Text("Build an Equation")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppMetrics.spacingLarge)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
        .pressable()
        .frame(maxWidth: 400)
        .accessibilityLabel("Build an equation")
        .accessibilityHint("Opens interactive equation builder")
    }
    
    private var exploreConceptsButton: some View {
        Button {
            HapticManager.shared.tap()
            navigationCoordinator.push(.exploreConcepts)
        } label: {
            Label("Explore Concepts", systemImage: "book.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
        .pressable()
        .frame(maxWidth: 400)
        .accessibilityLabel("Explore concepts")
        .accessibilityHint("Browse equation types and mathematical foundations")
    }
    
    private var settingsButton: some View {
        Button {
            navigationCoordinator.push(.settings)
        } label: {
            Image(systemName: "gear")
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Open app settings")
    }
}

// MARK: - Preview

#Preview("Light") {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationCoordinator())
            .environmentObject(DependencyContainer())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationCoordinator())
            .environmentObject(DependencyContainer())
    }
    .preferredColorScheme(.dark)
}
