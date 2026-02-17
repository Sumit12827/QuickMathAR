//
//  PressableModifier.swift
//  QuickMathsAR
//
//  Universal press-feedback modifier conforming to the design spec:
//  Tap → Scale 0.96, opacity 0.92.  Long-press → Scale 0.92, opacity 0.90.
//

import SwiftUI

// MARK: - Pressable Modifier

/// Adds spec-compliant press feedback to any view.
/// Tap compresses to 0.96, long-press to 0.92. Respects Reduce Motion.
struct PressableModifier: ViewModifier {
    @GestureState private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? AppConstants.opacityPressed : AppConstants.opacityActive)
            .animation(reduceMotion ? .none : .specSpring, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

/// Adds deeper long-press feedback (scale 0.92, opacity 0.90).
struct DeepPressableModifier: ViewModifier {
    @GestureState private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .opacity(isPressed ? 0.90 : AppConstants.opacityActive)
            .animation(reduceMotion ? .none : .specSpring, value: isPressed)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.3)
                    .updating($isPressed) { value, state, _ in
                        state = value
                    }
            )
    }
}

// MARK: - View Extension

public extension View {
    /// Applies spec-compliant tap press feedback (scale 0.96).
    func pressable() -> some View {
        modifier(PressableModifier())
    }

    /// Applies deeper long-press feedback (scale 0.92).
    func deepPressable() -> some View {
        modifier(DeepPressableModifier())
    }
}
