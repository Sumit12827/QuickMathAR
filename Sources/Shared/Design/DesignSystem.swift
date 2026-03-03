#if os(iOS)

import SwiftUI

// MARK: - Design System

/// The central source of truth for Quick Maths AR design tokens.
public enum DesignSystem {
    
    // MARK: - Color System (Semantic — adapts to Light/Dark automatically)
    public enum Colors {
        public static let background = Color(UIColor.systemBackground)
        public static let cardBackground = Color(UIColor.secondarySystemBackground)

        // Text
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        public static let textTertiary = Color(UIColor.tertiaryLabel)

        // Accents
        public static let primaryGradient = LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        public static let secondary = Color.purple
        public static let success = Color.green
        public static let error = Color.red
        public static let warning = Color.orange

        // Semantic
        public static let tint = Color.accentColor
    }
    
    // MARK: - Typography
    public enum Typography {
        public static func largeTitle() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
        public static func title1() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
        public static func title2() -> Font { .system(size: 22, weight: .bold, design: .rounded) }
        public static func title3() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
        public static func body() -> Font { .system(size: 17, weight: .regular, design: .rounded) }
        public static func callout() -> Font { .system(size: 16, weight: .semibold, design: .rounded) }
        public static func subheadline() -> Font { .system(size: 15, weight: .regular, design: .rounded) }
        public static func footnote() -> Font { .system(size: 13, weight: .regular, design: .rounded) }
        public static func caption() -> Font { .system(size: 12, weight: .regular, design: .rounded) }
    }
    
    // MARK: - Spacing Tokens
    public enum Spacing {
        /// 8px - Micro spacing for related items
        public static let micro: CGFloat = 8
        /// 16px - Tight spacing for group internals
        public static let tight: CGFloat = 16
        /// 24px - Standard spacing between groups
        public static let standard: CGFloat = 24
        /// 32px - Loose spacing for distinct sections
        public static let loose: CGFloat = 32
        /// 48px+ - Air for breathability
        public static let air: CGFloat = 48
    }
    
    // MARK: - Layout Constants
    public enum Layout {
        public static let baseUnit: CGFloat = 8
        public static let cardPadding: CGFloat = 20
        public static let cardSpacing: CGFloat = 16
        public static let screenEdgePadding: CGFloat = 20
        public static let cornerRadius: CGFloat = 16
        
        // Adaptive Widths
        public static let maxReadableWidth: CGFloat = 600
        public static let sidebarWidth: CGFloat = 280
        public static let masterWidth: CGFloat = 320
    }
    
    // MARK: - Animation Tokens
    public enum Animations {
        public static let baseDuration: Double = 0.3
        public static let standardDuration: Double = 0.5
        public static let heavyDuration: Double = 0.7
        
        public static let interactiveSpring = Animation.spring(
            response: 0.4,
            dampingFraction: 0.7,
            blendDuration: 0.0
        )
        
        public static let transitionSpring = Animation.spring(
            response: 0.5,
            dampingFraction: 0.8,
            blendDuration: 0.0
        )
        
        public static let standardEase = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: baseDuration)
        
        public static let staggerDelay: Double = 0.05
    }
}

// MARK: - SwiftUI Extensions

extension Font {
    public static let designLargeTitle = DesignSystem.Typography.largeTitle()
    public static let designTitle1 = DesignSystem.Typography.title1()
    public static let designTitle2 = DesignSystem.Typography.title2()
    public static let designTitle3 = DesignSystem.Typography.title3()
    public static let designBody = DesignSystem.Typography.body()
    public static let designCallout = DesignSystem.Typography.callout()
    public static let designSubheadline = DesignSystem.Typography.subheadline()
    public static let designFootnote = DesignSystem.Typography.footnote()
    public static let designCaption = DesignSystem.Typography.caption()
}

extension Color {
    public static let designBackground = DesignSystem.Colors.background
    public static let designCard = DesignSystem.Colors.cardBackground
    public static let designPrimaryText = DesignSystem.Colors.textPrimary
    public static let designSecondaryText = DesignSystem.Colors.textSecondary
    public static let designTertiaryText = DesignSystem.Colors.textTertiary
    public static let designSecondaryAccent = DesignSystem.Colors.secondary
    public static let designSuccess = DesignSystem.Colors.success
    public static let designError = DesignSystem.Colors.error
}

// MARK: - Button Styles

public struct PrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.designCallout)
            .foregroundStyle(.white)
            .padding(.horizontal, DesignSystem.Layout.cardPadding)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(DesignSystem.Animations.interactiveSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.play(.tap)
                }
            }
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.designCallout)
            .foregroundStyle(.primary)
            .padding(.horizontal, DesignSystem.Layout.cardPadding)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(DesignSystem.Animations.interactiveSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.play(.tap)
                }
            }
    }
}

#endif
