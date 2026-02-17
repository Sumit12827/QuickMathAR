//
//  View+Extensions.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import SwiftUI

// MARK: - Device Detection
extension View {
    
    /// Returns true if the current device is an iPad
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Returns true if the current device is an iPhone
    var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - Conditional Modifiers
extension View {
    
    /// Applies a modifier conditionally
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - transform: The modifier to apply if condition is true
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies different modifiers based on a condition
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - ifTrue: The modifier to apply if condition is true
    ///   - ifFalse: The modifier to apply if condition is false
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTrue: (Self) -> TrueContent,
        ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
}

// MARK: - Size Class Helpers
extension View {
    
    /// Applies a modifier only on compact width (iPhone)
    @ViewBuilder
    func onCompactWidth<Content: View>(transform: @escaping (Self) -> Content) -> some View {
        modifier(CompactWidthModifier(transform: { AnyView(transform(self)) }))
    }
    
    /// Applies a modifier only on regular width (iPad)
    @ViewBuilder
    func onRegularWidth<Content: View>(transform: @escaping (Self) -> Content) -> some View {
        modifier(RegularWidthModifier(transform: { AnyView(transform(self)) }))
    }
}

// MARK: - Private Modifiers
private struct CompactWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let transform: () -> AnyView
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            transform()
        } else {
            content
        }
    }
}

private struct RegularWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let transform: () -> AnyView
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            transform()
        } else {
            content
        }
    }
}

// MARK: - Loading State
extension View {
    
    /// Overlays a loading indicator when loading is true
    func loading(_ isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}



