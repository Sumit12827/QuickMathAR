//
//  AppConstants.swift
//  QuickMathsAR
//
//  App-wide constants for consistent values across the codebase
//

#if os(iOS)

import Foundation
import SwiftUI

/// Central repository for app-wide constants
enum AppConstants {

    // MARK: - Animation Durations (Temporal Design)

    /// Base duration range: 0.3–0.5s (perceptible but never waiting)
    static let defaultAnimationDuration: TimeInterval = 0.35

    /// Quick animation duration
    static let quickAnimationDuration: TimeInterval = 0.2

    /// Slow animation duration for emphasis
    static let slowAnimationDuration: TimeInterval = 0.5

    /// Exit animations are 20% faster than entry
    static let exitDurationMultiplier: Double = 0.8

    // MARK: - Spring Physics

    /// Spring response (tuned for organic feel)
    static let springResponse: Double = 0.4

    /// Spring damping: 0.7–0.8 range → organic, not robotic
    static let springDamping: Double = 0.75

    /// Spring stiffness (200–300 range)
    static let springStiffness: Double = 250

    // MARK: - Stagger Cascade

    /// 30–50ms cascades — creates "breathing" rhythm
    static let staggerDelay: TimeInterval = 0.04

    // MARK: - Micro-Delay Architecture

    /// Primary action: immediate
    static let delayPrimary: TimeInterval = 0.0
    /// Secondary elements: +40ms
    static let delaySecondary: TimeInterval = 0.04
    /// Tertiary / contextual: +80ms
    static let delayTertiary: TimeInterval = 0.08
    /// Background ambience: +120ms
    static let delayBackground: TimeInterval = 0.12

    // MARK: - Opacity States

    /// Active / default state
    static let opacityActive: Double = 1.0
    /// Pressed state (never 0.8 — too dramatic)
    static let opacityPressed: Double = 0.92
    /// Disabled state (never 0.50 — that's uncertainty)
    static let opacityDisabled: Double = 0.38

    // MARK: - Graph Configuration

    /// Number of points per unit on graph
    static let graphPointsPerUnit: Int = 50

    /// Default graph range
    static let graphDefaultRange: ClosedRange<Float> = -10...10

    /// Graph line width
    static let graphLineWidth: CGFloat = 3

    /// Axis line width
    static let axisLineWidth: CGFloat = 1

    // MARK: - UI Metrics

    /// Standard card corner radius
    static let cardCornerRadius: CGFloat = 16

    /// Button corner radius
    static let buttonCornerRadius: CGFloat = 14

    /// Minimum touch target size (Apple HIG)
    static let minimumTouchTarget: CGFloat = 44

    /// Standard horizontal padding
    static let horizontalPadding: CGFloat = 20

    /// iPad horizontal padding
    static let iPadHorizontalPadding: CGFloat = 48

    /// Standard vertical spacing
    static let verticalSpacing: CGFloat = 24

    // MARK: - Feature Flags

    /// Enable haptic feedback
    static let enableHaptics: Bool = true

    // MARK: - Validation

    /// Minimum equation length for validation
    static let minimumEquationLength: Int = 3

    /// Maximum equation length
    static let maximumEquationLength: Int = 100
}

// MARK: - Convenience Extensions

extension AppConstants {

    /// Returns appropriate horizontal padding based on size class
    static func horizontalPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? iPadHorizontalPadding : horizontalPadding
    }
}

#endif
