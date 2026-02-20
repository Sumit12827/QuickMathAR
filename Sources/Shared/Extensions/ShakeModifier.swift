//
//  ShakeModifier.swift
//  QuickMathsAR
//
//  Spec-compliant error shake: 3° rotation oscillation (gentle correction).
//

#if os(iOS)
import SwiftUI

// MARK: - Shake Geometry Effect

/// Animatable geometry effect that oscillates rotation by ±3°.
/// Usage: `.modifier(ShakeEffect(shakes: trigger))` where trigger
/// is animated from 0 → 3 on error.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let angle = Angle.degrees(3 * sin(shakes * .pi * 2)).radians
        let transform = CGAffineTransform(translationX: size.width / 2, y: size.height / 2)
            .rotated(by: angle)
            .translatedBy(x: -size.width / 2, y: -size.height / 2)
        return ProjectionTransform(transform)
    }
}

// MARK: - View Extension

public extension View {
    /// Triggers a gentle 3° rotation shake. Bind `trigger` to a counter
    /// and increment it on error — the animation handles the rest.
    func shake(trigger: Int) -> some View {
        modifier(ShakeViewModifier(trigger: trigger))
    }
}

/// Internal modifier that drives the `ShakeEffect` from a trigger counter.
struct ShakeViewModifier: ViewModifier {
    let trigger: Int
    @State private var shakeAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(shakes: shakeAmount))
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                    shakeAmount = 3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        shakeAmount = 0
                    }
                }
            }
    }
}
#endif
