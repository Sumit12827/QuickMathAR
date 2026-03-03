//
//  AppColors.swift
//  QuickMathsAR
//
//  Defines the app's color palette using system colors only
//  Follows Apple Human Interface Guidelines for educational clarity
//
#if os(iOS)


import SwiftUI

// MARK: - App Colors

/// Semantic color definitions using system colors
/// All colors adapt automatically to Light/Dark mode
public enum AppColors {
    
    // MARK: - Text Colors
    
    /// Primary text color - highest contrast, main content
    public static let textPrimary = Color.primary
    
    /// Secondary text color - supporting content, hints
    public static let textSecondary = Color.secondary
    
    /// Tertiary text color - subtle hints, captions
    public static let textTertiary = Color(UIColor.tertiaryLabel)
    
    // MARK: - Background Colors
    
    /// Primary background - main screen background
    public static let backgroundPrimary = Color(UIColor.systemBackground)
    
    /// Secondary background - cards, grouped content
    public static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    
    /// Tertiary background - nested cards, subtle layers
    public static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    
    /// Grouped background - for grouped table views
    public static let backgroundGrouped = Color(UIColor.systemGroupedBackground)
    
    /// Secondary grouped background - cards within grouped views
    public static let backgroundGroupedSecondary = Color(UIColor.secondarySystemGroupedBackground)
    
    // MARK: - Accent Colors (Use Sparingly)
    
    /// App tint color - primary actions, key highlights
    public static let accent = Color.accentColor
    
    /// Linear equation accent - blue
    public static let accentLinear = Color.blue
    
    /// Quadratic equation accent - purple
    public static let accentQuadratic = Color.purple
    
    // MARK: - Semantic Colors
    
    /// Success state - correct answers, positive feedback
    public static let success = Color.green
    
    /// Warning state - caution, attention needed
    public static let warning = Color.orange
    
    /// Error state - mistakes, problems
    public static let error = Color.red
    
    /// Info state - hints, additional context
    public static let info = Color.blue
    
    // MARK: - Separator Colors
    
    /// Standard separator
    public static let separator = Color(UIColor.separator)
    
    /// Opaque separator for solid backgrounds
    public static let separatorOpaque = Color(UIColor.opaqueSeparator)
    
    // MARK: - Fill Colors
    
    /// Primary fill - UI elements like buttons
    public static let fillPrimary = Color(UIColor.systemFill)
    
    /// Secondary fill - less prominent UI elements
    public static let fillSecondary = Color(UIColor.secondarySystemFill)
    
    /// Tertiary fill - subtle UI elements
    public static let fillTertiary = Color(UIColor.tertiarySystemFill)
}

// MARK: - Color Extensions

public extension Color {
    
    /// Returns an appropriate equation accent color
    static func equationAccent(for type: String) -> Color {
        switch type.lowercased() {
        case "linear":
            return AppColors.accentLinear
        case "quadratic":
            return AppColors.accentQuadratic
        default:
            return AppColors.accent
        }
    }
}

// MARK: - View Modifiers for Backgrounds

public extension View {
    
    /// Applies the primary card background style
    func cardBackground() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusMedium)
                    .fill(AppColors.backgroundGroupedSecondary)
            )
    }
    
    /// Applies a subtle card background with border
    func subtleCardBackground() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusMedium)
                    .fill(AppColors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusMedium)
                    .strokeBorder(AppColors.separator.opacity(0.3), lineWidth: 1)
            )
    }
}

#endif
