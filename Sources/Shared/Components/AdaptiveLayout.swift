//
//  AdaptiveLayout.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

#if os(iOS)
import SwiftUI

// MARK: - Device Size Tier

/// Three-tier breakpoint system per design spec.
public enum DeviceSizeTier {
    /// iPhone / compact width (< 600pt)
    case compact
    /// iPad portrait / regular width (600–900pt)
    case regular
    /// iPad landscape / expanded width (> 900pt)
    case expanded

    public init(width: CGFloat) {
        if width < 600 {
            self = .compact
        } else if width <= 900 {
            self = .regular
        } else {
            self = .expanded
        }
    }
}

// MARK: - Binary Adaptive Layout (existing)

/// A container view that renders different layouts based on device size class
public struct AdaptiveLayout<Compact: View, Regular: View>: View {
    
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Properties
    private let compact: Compact
    private let regular: Regular
    
    // MARK: - Initialization
    public init(
        @ViewBuilder compact: () -> Compact,
        @ViewBuilder regular: () -> Regular
    ) {
        self.compact = compact()
        self.regular = regular()
    }
    
    // MARK: - Body
    public var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compact
            } else {
                regular
            }
        }
    }
}

// MARK: - Convenience Initializer
extension AdaptiveLayout where Compact == Regular {
    public init(@ViewBuilder content: () -> Compact) {
        self.compact = content()
        self.regular = content()
    }
}

// MARK: - Triple Adaptive Layout (3-tier)

/// Renders one of three layouts based on actual viewport width.
/// | Breakpoint | Width      | Strategy                         |
/// |------------|------------|----------------------------------|
/// | Compact    | < 600pt    | Single column, full-width cards  |
/// | Regular    | 600–900pt  | 2-column grid, sidebar nav       |
/// | Expanded   | > 900pt    | 3-column + persistent sidebar    |
public struct TripleAdaptiveLayout<Compact: View, Regular: View, Expanded: View>: View {

    private let compact: Compact
    private let regular: Regular
    private let expanded: Expanded

    public init(
        @ViewBuilder compact: () -> Compact,
        @ViewBuilder regular: () -> Regular,
        @ViewBuilder expanded: () -> Expanded
    ) {
        self.compact = compact()
        self.regular = regular()
        self.expanded = expanded()
    }

    public var body: some View {
        GeometryReader { geometry in
            let tier = DeviceSizeTier(width: geometry.size.width)
            Group {
                switch tier {
                case .compact:
                    compact
                case .regular:
                    regular
                case .expanded:
                    expanded
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Convenience (same view for regular & expanded)

extension TripleAdaptiveLayout where Regular == Expanded {
    public init(
        @ViewBuilder compact: () -> Compact,
        @ViewBuilder regular: () -> Regular
    ) {
        self.compact = compact()
        self.regular = regular()
        self.expanded = regular()
    }
}

// MARK: - Three Column Navigation Layout

/// A specialized layout for iPad 3-column navigation that adapts to smaller screens.
public struct ThreeColumnNavigationLayout<Sidebar: View, Middle: View, Detail: View>: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private let sidebar: Sidebar
    private let middle: Middle
    private let detail: Detail

    public init(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder middle: () -> Middle,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.middle = middle()
        self.detail = detail()
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } content: {
            middle
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Previews

#Preview("Compact") {
    AdaptiveLayout {
        Text("iPhone Layout")
    } regular: {
        Text("iPad Layout")
    }
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Regular") {
    AdaptiveLayout {
        Text("iPhone Layout")
    } regular: {
        Text("iPad Layout")
    }
    .environment(\.horizontalSizeClass, .regular)
}
#endif
