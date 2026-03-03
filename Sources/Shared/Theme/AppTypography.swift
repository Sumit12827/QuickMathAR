//
//  AppTypography.swift
//  QuickMathsAR
//
//  Defines typography hierarchy using system fonts
//  Supports Dynamic Type for accessibility
//

#if os(iOS)
import SwiftUI

// MARK: - App Typography

/// Typography hierarchy using system fonts only
/// All styles support Dynamic Type automatically
public enum AppTypography {
    
    // MARK: - Display Styles (Large Headers)
    
    /// Large title - main screen headers
    /// Use for: Navigation titles, welcome screens
    public static let largeTitle = Font.largeTitle
    
    /// Title 1 - prominent section headers
    /// Use for: Major content divisions
    public static let title1 = Font.title
    
    /// Title 2 - medium section headers
    /// Use for: Card titles, feature sections
    public static let title2 = Font.title2
    
    /// Title 3 - smaller section headers
    /// Use for: Subsections within cards
    public static let title3 = Font.title3
    
    // MARK: - Content Styles
    
    /// Headline - emphasized section titles
    /// Use for: Card headers, important labels
    public static let headline = Font.headline
    
    /// Subheadline - secondary emphasis
    /// Use for: Supporting titles, timestamps
    public static let subheadline = Font.subheadline
    
    /// Body - main educational content
    /// Use for: Explanations, descriptions, definitions
    public static let body = Font.body
    
    /// Callout - slightly smaller body text
    /// Use for: Callout boxes, secondary explanations
    public static let callout = Font.callout
    
    // MARK: - Supporting Styles
    
    /// Footnote - small supporting text
    /// Use for: Hints, disclaimers, attribution
    public static let footnote = Font.footnote
    
    /// Caption 1 - small labels
    /// Use for: Labels, tags, badges
    public static let caption1 = Font.caption
    
    /// Caption 2 - smallest text
    /// Use for: Fine print, very minor labels
    public static let caption2 = Font.caption2
    
    // MARK: - Mathematical Content
    
    /// Equation display - for showing equations prominently
    /// Rounded design for friendly feel
    public static let equation = Font.system(size: 28, weight: .medium, design: .rounded)
    
    /// Equation inline - for equations within text
    public static let equationInline = Font.system(.body, design: .rounded).weight(.medium)
    
    /// Step result - for solved values
    public static let stepResult = Font.system(.subheadline, design: .rounded).weight(.semibold)
}

// MARK: - Text Style Modifiers

public extension View {
    
    /// Applies primary content text style
    func primaryText() -> some View {
        self
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textPrimary)
    }
    
    /// Applies secondary content text style
    func secondaryText() -> some View {
        self
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.textSecondary)
    }
    
    /// Applies caption text style
    func captionText() -> some View {
        self
            .font(AppTypography.caption1)
            .foregroundStyle(AppColors.textTertiary)
    }
    
    /// Applies section header style
    func sectionHeader() -> some View {
        self
            .font(AppTypography.headline)
            .foregroundStyle(AppColors.textPrimary)
    }
}

// MARK: - Text Components

/// A text view styled for educational body content
public struct EducationalText: View {
    let content: String
    
    public init(_ content: String) {
        self.content = content
    }
    
    public var body: some View {
        Text(content)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textPrimary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A text view styled for equation display
public struct EquationText: View {
    let equation: String
    
    public init(_ equation: String) {
        self.equation = equation
    }
    
    public var body: some View {
        Text(equation)
            .font(AppTypography.equation)
            .foregroundStyle(AppColors.textPrimary)
    }
}
#endif
