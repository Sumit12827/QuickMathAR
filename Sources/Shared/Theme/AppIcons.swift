//
//  AppIcons.swift
//  QuickMathsAR
//
//  SF Symbols usage guidelines and icon helpers
//  All icons use SF Symbols only - no custom icons
//

import SwiftUI

// MARK: - App Icons

/// Centralized SF Symbol definitions for consistent icon usage
/// Use these constants instead of hardcoding symbol names
public enum AppIcons {
    
    // MARK: - Navigation & Actions
    
    /// Back/return action
    public static let back = "chevron.left"
    
    /// Forward/continue action
    public static let forward = "chevron.right"
    
    /// Close/dismiss action
    public static let close = "xmark"
    
    /// Close with circle background
    public static let closeCircle = "xmark.circle.fill"
    
    /// Done/complete action
    public static let done = "checkmark"
    
    /// Done with circle background
    public static let doneCircle = "checkmark.circle.fill"
    
    // MARK: - Camera & AR
    
    /// Camera/scan action
    public static let camera = "camera"
    
    /// Camera with fill style
    public static let cameraFill = "camera.fill"
    
    /// AR/augmented reality
    public static let ar = "arkit"
    
    /// View in AR action
    public static let viewInAR = "arkit"
    
    // MARK: - Learning & Education
    
    /// Information/help
    public static let info = "info.circle"
    
    /// Information with fill
    public static let infoFill = "info.circle.fill"
    
    /// Lightbulb/idea/tip
    public static let lightbulb = "lightbulb"
    
    /// Lightbulb with fill
    public static let lightbulbFill = "lightbulb.fill"
    
    /// Brain/thinking
    public static let brain = "brain.head.profile"
    
    /// Book/learning
    public static let book = "book"
    
    /// List with numbers
    public static let numberedList = "list.number"
    
    /// Bookmark/concept tag
    public static let bookmark = "bookmark"
    
    /// Bookmark with fill
    public static let bookmarkFill = "bookmark.fill"
    
    // MARK: - Graph & Math
    
    /// Linear equation/line
    public static let linearGraph = "line.diagonal"
    
    /// Quadratic equation/curve
    public static let quadraticGraph = "point.topleft.down.to.point.bottomright.curvepath"
    
    /// Function/math
    public static let function = "function"
    
    /// Chart/graph
    public static let chart = "chart.xyaxis.line"
    
    // MARK: - Gestures & Interaction
    
    /// Tap gesture
    public static let tap = "hand.tap"
    
    /// Pinch gesture
    public static let pinch = "arrow.up.left.and.arrow.down.right"
    
    /// Drag gesture
    public static let drag = "hand.draw"
    
    // MARK: - Status & Feedback
    
    /// Success/correct
    public static let success = "checkmark.circle"
    
    /// Warning/caution
    public static let warning = "exclamationmark.triangle"
    
    /// Error/incorrect
    public static let error = "xmark.circle"
    
    /// Arrow right (result indicator)
    public static let arrowRight = "arrow.right"
}

// MARK: - Icon View Component

/// A consistent icon component using SF Symbols
public struct AppIcon: View {
    let name: String
    let size: IconSize
    let color: Color?
    
    public enum IconSize {
        case small      // caption
        case medium     // body
        case large      // title3
        case extraLarge // title
        
        var font: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title3
            case .extraLarge: return .title
            }
        }
    }
    
    public init(_ name: String, size: IconSize = .medium, color: Color? = nil) {
        self.name = name
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        Image(systemName: name)
            .font(size.font)
            .foregroundStyle(color ?? AppColors.textSecondary)
    }
}

// MARK: - Icon Style Guidelines

/// Guidelines for SF Symbols usage (for documentation)
///
/// ## Consistency Rules
/// 1. Use outlined style by default
/// 2. Use filled style only for selected/active states
/// 3. Match icon weight to nearby text weight
/// 4. Keep icon sizes consistent within context
///
/// ## Usage Principles
/// - Icons should **support meaning**, never replace text labels
/// - Icons should feel **quiet and intentional**
/// - Never use icons purely for **visual decoration**
/// - Always pair action icons with **accessible labels**
///
/// ## Do's
/// - ✓ Use icons to indicate actions (scan, continue, view in AR)
/// - ✓ Use icons to reinforce meaning (info, graph, camera)
/// - ✓ Keep icons simple and recognizable
///
/// ## Don'ts
/// - ✗ Mix filled and outlined styles inconsistently
/// - ✗ Use overly complex or detailed icons
/// - ✗ Use icons without semantic meaning
public enum IconStyleGuidelines {}
