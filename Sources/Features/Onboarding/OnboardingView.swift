//
//  OnboardingView.swift
//  QuickMathsAR
//
//  Enhanced first-launch onboarding experience with engaging animations
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            iconColors: [.blue, .cyan],
            title: "Welcome to QuickMathsAR",
            subtitle: "Math that you can see and touch",
            animationType: .pulse
        ),
        OnboardingPage(
            icon: "eye.slash",
            iconColors: [.red, .orange],
            title: "Math Doesn't Have to Be Scary",
            subtitle: "We turn confusing equations into visual stories",
            animationType: .shake
        ),
        OnboardingPage(
            icon: "scale.3d",
            iconColors: [.purple, .pink],
            title: "Every Equation Tells a Story",
            subtitle: "An equation is like a balance scale—we'll show you how",
            animationType: .balance
        ),
//        OnboardingPage(
//            icon: "camera.viewfinder",
//            iconColors: [.green, .mint],
//            title: "Scan Any Equation",
//            subtitle: "Point your camera at homework, textbooks, or whiteboards",
//            animationType: .scan
//        ),
        OnboardingPage(
            icon: "arkit",
            iconColors: [.orange, .yellow],
            title: "See Math in Your World",
            subtitle: "Visualize graphs and equations in augmented reality",
            animationType: .float
        )
    ]

    var body: some View {
        ZStack {
            // Adaptive background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))

                // Button with animation
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            currentPage += 1
                        }
                        HapticManager.shared.light()
                    } else {
                        HapticManager.shared.success()
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: pages[currentPage].iconColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                .animation(.easeInOut, value: currentPage)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding. Page \(currentPage + 1) of \(pages.count)")
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let animationType: AnimationType

    enum AnimationType {
        case pulse
        case shake
        case balance
        case scan
        case float
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    @State private var animationPhase: Double = 0
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.iconColors[0].opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)

                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: page.iconColors[0].opacity(0.4), radius: 20)
                    .modifier(IconAnimationModifier(
                        animationType: page.animationType,
                        phase: animationPhase,
                        reduceMotion: reduceMotion
                    ))
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.7)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimations()
            }
        }
        .onAppear {
            if isActive {
                startAnimations()
            }
        }
    }

    private func startAnimations() {
        if reduceMotion {
            showContent = true
            return
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showContent = true
        }

        // Start continuous animation for icon
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }
    }
}

// MARK: - Icon Animation Modifier

struct IconAnimationModifier: ViewModifier {
    let animationType: OnboardingPage.AnimationType
    let phase: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            switch animationType {
            case .pulse:
                content
                    .scaleEffect(1 + phase * 0.08)
            case .shake:
                content
                    .rotationEffect(.degrees(phase * 5 - 2.5))
            case .balance:
                content
                    .rotationEffect(.degrees(phase * 8 - 4))
            case .scan:
                content
                    .offset(x: phase * 3 - 1.5)
            case .float:
                content
                    .offset(y: -phase * 8)
            }
        }
    }
}

#Preview("Light") {
    OnboardingView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingView()
        .preferredColorScheme(.dark)
}
