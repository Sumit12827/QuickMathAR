//
//  Theme.swift
//  QuickMathsAR
//
//  Central theme export and component styles
//  Import this file to access the entire design system
//

import SwiftUI

// MARK: - Theme

/// Central namespace for theme access
/// Use `Theme.colors`, `Theme.typography`, etc.
public enum Theme {
    public typealias Colors = AppColors
    public typealias Typography = AppTypography
    public typealias Icons = AppIcons
    public typealias Metrics = AppMetrics
}



// MARK: - Card Components

/// Standard learning content card
public struct LearningContentCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    public init(
        title: String,
        icon: String,
        iconColor: Color = AppColors.accent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacingMedium) {
            // Header
            Label {
                Text(title)
                    .font(AppTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textSecondary)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            
            // Content
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppMetrics.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusMedium)
                .fill(AppColors.backgroundGroupedSecondary)
        )
    }
}

// MARK: - Badge Components

/// Difficulty badge for examples
public struct DifficultyIndicator: View {
    let level: String
    
    public init(_ level: String) {
        self.level = level
    }
    
    private var color: Color {
        switch level.lowercased() {
        case "beginner": return AppColors.success
        case "intermediate": return AppColors.warning
        case "advanced": return AppColors.error
        default: return AppColors.textSecondary
        }
    }
    
    public var body: some View {
        Text(level.capitalized)
            .font(AppTypography.caption1)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
    }
}

/// Tag component for concepts
public struct ConceptTagView: View {
    let concept: String
    
    public init(_ concept: String) {
        self.concept = concept
    }
    
    private var formattedConcept: String {
        concept.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: AppIcons.bookmarkFill)
                .font(AppTypography.caption2)
            
            Text(formattedConcept)
                .font(AppTypography.caption1)
                .fontWeight(.medium)
        }
        .foregroundStyle(AppColors.warning)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(AppColors.warning.opacity(0.1))
        )
    }
}

// MARK: - Button Style Extensions

public extension View {
    
    /// Applies primary button styling
    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    /// Applies secondary button styling
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}
