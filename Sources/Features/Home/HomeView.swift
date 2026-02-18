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
            
            // Journey steps indicator
            journeySteps
                .opacity(headerOpacity)

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
            // App icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
            }

            Text("Quick Maths AR")
                .font(.largeTitle)
                .fontWeight(.bold)
                .safeTitle(minScale: 0.8)

            Text("Build it. Understand it. See it in AR.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .safeBody()
                .padding(.horizontal, 24)
        }
        .opacity(headerOpacity)
        .scaleEffect(headerScale)
    }
    
    // MARK: - Journey Steps
    private var journeySteps: some View {
        HStack(spacing: 0) {
            JourneyStepPill(icon: "hammer.fill", label: "Build", color: .blue)
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            JourneyStepPill(icon: "lightbulb.fill", label: "Learn", color: .yellow)
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            JourneyStepPill(icon: "arkit", label: "Visualize", color: .green)
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            JourneyStepPill(icon: "checkmark.circle.fill", label: "Reflect", color: .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
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
            HStack(spacing: 12) {
                Image(systemName: "plus.square.fill.on.square.fill")
                    .font(.title2)
                
                Text("Start Building")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusMedium)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.accentColor.opacity(0.25), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .pressable()
        .frame(maxWidth: 400)
        .accessibilityLabel("Start building an equation")
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

// MARK: - Journey Step Pill

private struct JourneyStepPill: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
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
