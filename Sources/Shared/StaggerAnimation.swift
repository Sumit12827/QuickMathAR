import SwiftUI

// MARK: - Stagger Animation Modifier
public struct StaggerAppearModifier: ViewModifier {
    public let index: Int
    @State private var isVisible: Bool = false
    
    // Config
    private let baseDelay: Double = 0.0
    private let staggerDelay: Double = 0.05
    private let duration: Double = 0.4
    
    public init(index: Int) {
        self.index = index
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1 : 0.98)
            .animation(
                DesignSystem.Animations.interactiveSpring.delay(baseDelay + Double(index) * staggerDelay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    public func staggerAppear(order: Int) -> some View {
        self.modifier(StaggerAppearModifier(index: order))
    }
}

// MARK: - Navigation Transition Modifier
// Custom modifier to emulate the "Push/Pop" scale & fade described in Cinematic Spec
public struct CinematicNavigationTransition: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.8)),
                removal: .scale(scale: 0.95).combined(with: .opacity).animation(.easeOut(duration: 0.2))
            ))
    }
}

extension View {
    public func cinematicNavigation() -> some View {
        self.modifier(CinematicNavigationTransition())
    }
}
