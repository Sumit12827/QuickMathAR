//
//  Animation+Custom.swift
//  QuickMathsAR
//
//  Created on 2026-02-09.
//

import SwiftUI

extension Animation {

    // MARK: - Spec-Aligned Presets

    /// Primary spec spring — damping 0.75, response 0.4s (organic, not robotic)
    static let specSpring = Animation.spring(
        response: AppConstants.springResponse,
        dampingFraction: AppConstants.springDamping
    )

    /// Staggered entry — each element delayed by index × 40ms
    static func staggered(index: Int) -> Animation {
        specSpring.delay(Double(index) * AppConstants.staggerDelay)
    }

    /// Spec entry — easeInOut at base duration
    static let specEntry = Animation.easeInOut(duration: AppConstants.defaultAnimationDuration)

    /// Spec exit — 20% faster than entry (brain processes disappearance quicker)
    static let specExit = Animation.easeInOut(
        duration: AppConstants.defaultAnimationDuration * AppConstants.exitDurationMultiplier
    )

    // MARK: - Existing Presets (Updated)

    /// Calm, confident spring for component additions
    static let componentAdd = Animation.spring(response: 0.3, dampingFraction: 0.75)

    /// Smooth removal animation (exit timing)
    static let componentRemove = Animation.easeOut(
        duration: 0.25 * AppConstants.exitDurationMultiplier
    )

    /// Clear all with stagger
    static let staggeredClear = Animation.easeOut(duration: 0.2)

    /// Validation feedback pulse
    static let validationPulse = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Screen transition
    static let screenTransition = Animation.spring(
        response: AppConstants.springResponse,
        dampingFraction: 0.82
    )

    /// Respects reduce motion setting
    static func respectingReduceMotion(_ animation: Animation) -> Animation {
        UIAccessibility.isReduceMotionEnabled ? .linear(duration: 0.1) : animation
    }
}

// MARK: - Stagger Animation Modifier


