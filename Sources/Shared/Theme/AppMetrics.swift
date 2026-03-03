//
//  AppMetrics.swift
//  QuickMathsAR
//
//  Defines consistent spacing, sizing, and layout metrics
//

#if os(iOS)

import SwiftUI

// MARK: - App Metrics

/// Layout constants using an 8px base spatial grid.
/// Semantic names encode the *relationship* between elements.
public enum AppMetrics {
    
    // MARK: - 8px Base Spatial Grid
    
    /// Base spatial unit (8pt)
    public static let baseUnit: CGFloat = 8
    
    /// Micro spacing — icon/text pairs (8pt)
    public static let spacingMicro: CGFloat = 8
    
    /// Tight spacing — related elements (16pt)
    public static let spacingTight: CGFloat = 16
    
    /// Standard spacing — section breaks (24pt)
    public static let spacingStandard: CGFloat = 24
    
    /// Loose spacing — major divisions (32pt)
    public static let spacingLoose: CGFloat = 32
    
    /// Air spacing — breathing room (48pt+)
    public static let spacingAir: CGFloat = 48
    
    // MARK: - Legacy Spacing Aliases (avoid in new code)
    
    /// @available(*, deprecated, renamed: "spacingMicro")
    public static let spacingXS: CGFloat = 4
    /// @available(*, deprecated, renamed: "spacingMicro")
    public static let spacingSmall: CGFloat = 8
    /// @available(*, deprecated, renamed: "spacingTight")
    public static let spacingMedium: CGFloat = 12
    /// @available(*, deprecated, renamed: "spacingTight")
    public static let spacing: CGFloat = 16
    /// @available(*, deprecated, renamed: "spacingStandard")
    public static let spacingLarge: CGFloat = 20
    /// @available(*, deprecated, renamed: "spacingStandard")
    public static let spacingXL: CGFloat = 24
    /// @available(*, deprecated, renamed: "spacingLoose")
    public static let spacingSection: CGFloat = 32
    
    // MARK: - Corner Radius
    
    /// Small corner radius (8pt) — buttons, tags
    public static let cornerRadiusSmall: CGFloat = 8
    
    /// Medium corner radius (12pt) — cards (content hierarchy signal)
    public static let cornerRadiusMedium: CGFloat = 12
    
    /// Large corner radius (20pt) — sheets, modals
    public static let cornerRadiusLarge: CGFloat = 20
    
    /// Full corner radius for pills/capsules
    public static let cornerRadiusFull: CGFloat = .infinity
    
    // MARK: - Button Sizing
    
    /// Standard button height (44pt min touch target)
    public static let buttonHeight: CGFloat = 44
    
    /// Small button height
    public static let buttonHeightSmall: CGFloat = 36
    
    /// Large button height
    public static let buttonHeightLarge: CGFloat = 50
    
    /// Button horizontal padding
    public static let buttonPaddingH: CGFloat = 16
    
    /// Button vertical padding
    public static let buttonPaddingV: CGFloat = 12
    
    // MARK: - Card Architecture
    
    /// Internal card padding (20pt — consistent across all cards)
    public static let cardPadding: CGFloat = 20
    
    /// Compact card padding
    public static let cardPaddingCompact: CGFloat = 16
    
    /// Card-to-card gap (16pt)
    public static let cardGap: CGFloat = 16
    
    /// Card-to-edge gap — iPhone (20pt)
    public static let cardEdgeInset: CGFloat = 20
    
    // MARK: - Icon Sizing
    
    /// Small icon size
    public static let iconSmall: CGFloat = 16
    
    /// Medium icon size
    public static let iconMedium: CGFloat = 20
    
    /// Large icon size
    public static let iconLarge: CGFloat = 28
    
    // MARK: - Content Width
    
    /// Maximum readable content width (≤ 70% viewport for comfort)
    public static let maxReadableWidth: CGFloat = 680
    
    /// Minimum touch target size (Apple HIG — 44pt)
    public static let minTouchTarget: CGFloat = 44
}

// MARK: - Spacing Helpers

public extension View {
    
    /// Applies standard horizontal padding
    func horizontalPadding() -> some View {
        self.padding(.horizontal, AppMetrics.spacing)
    }
    
    /// Applies standard card padding
    func cardPadding() -> some View {
        self.padding(AppMetrics.cardPadding)
    }
    
    /// Constrains view to readable width
    func readableWidth() -> some View {
        self.frame(maxWidth: AppMetrics.maxReadableWidth)
    }
}

#endif
