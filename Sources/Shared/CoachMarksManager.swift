//
//  CoachMarksManager.swift
//  QuickMathsAR
//
//  Manages feature discovery hints using AppStorage
//

import SwiftUI

/// Manages coach marks and feature discovery hints
public class CoachMarksManager: ObservableObject {
    public static let shared = CoachMarksManager()

    // MARK: - Coach Mark Keys

    private enum Key {
        static let hasSeenInteractiveOperator = "coachMark_interactiveOperator"
        static let hasSeenConceptFlow = "coachMark_conceptFlow"
        static let hasSeenFactoringPuzzle = "coachMark_factoringPuzzle"
        static let hasSeenARVisualization = "coachMark_arVisualization"
        static let hasSeenParabolaPlayground = "coachMark_parabolaPlayground"
    }

    // MARK: - AppStorage Properties

    @AppStorage(Key.hasSeenInteractiveOperator) public var hasSeenInteractiveOperator = false
    @AppStorage(Key.hasSeenConceptFlow) public var hasSeenConceptFlow = false
    @AppStorage(Key.hasSeenFactoringPuzzle) public var hasSeenFactoringPuzzle = false
    @AppStorage(Key.hasSeenARVisualization) public var hasSeenARVisualization = false
    @AppStorage(Key.hasSeenParabolaPlayground) public var hasSeenParabolaPlayground = false

    // MARK: - Public Methods

    /// Mark a coach mark as seen
    public func markAsSeen(_ coachMark: CoachMark) {
        switch coachMark {
        case .interactiveOperator:
            hasSeenInteractiveOperator = true
        case .conceptFlow:
            hasSeenConceptFlow = true
        case .factoringPuzzle:
            hasSeenFactoringPuzzle = true
        case .arVisualization:
            hasSeenARVisualization = true
        case .parabolaPlayground:
            hasSeenParabolaPlayground = true
        }
    }

    /// Check if a coach mark should be shown
    public func shouldShow(_ coachMark: CoachMark) -> Bool {
        switch coachMark {
        case .interactiveOperator:
            return !hasSeenInteractiveOperator
        case .conceptFlow:
            return !hasSeenConceptFlow
        case .factoringPuzzle:
            return !hasSeenFactoringPuzzle
        case .arVisualization:
            return !hasSeenARVisualization
        case .parabolaPlayground:
            return !hasSeenParabolaPlayground
        }
    }

    /// Reset all coach marks (for testing)
    public func resetAll() {
        hasSeenInteractiveOperator = false
        hasSeenConceptFlow = false
        hasSeenFactoringPuzzle = false
        hasSeenARVisualization = false
        hasSeenParabolaPlayground = false
    }
}

// MARK: - Coach Mark Enum

public enum CoachMark: String, CaseIterable {
    case interactiveOperator
    case conceptFlow
    case factoringPuzzle
    case arVisualization
    case parabolaPlayground

    public var title: String {
        switch self {
        case .interactiveOperator:
            return "Interactive Learning"
        case .conceptFlow:
            return "Discover the Concept"
        case .factoringPuzzle:
            return "Factoring Puzzle"
        case .arVisualization:
            return "AR Visualization"
        case .parabolaPlayground:
            return "Parabola Playground"
        }
    }

    public var message: String {
        switch self {
        case .interactiveOperator:
            return "Drag, tap, or swipe to explore math operations"
        case .conceptFlow:
            return "Swipe through pages to understand the concept"
        case .factoringPuzzle:
            return "Tap numbers to find the factors"
        case .arVisualization:
            return "Point your camera to see the equation in 3D"
        case .parabolaPlayground:
            return "Drag the sliders to change the parabola"
        }
    }

    public var icon: String {
        switch self {
        case .interactiveOperator:
            return "hand.point.up.left.fill"
        case .conceptFlow:
            return "hand.draw.fill"
        case .factoringPuzzle:
            return "puzzlepiece.fill"
        case .arVisualization:
            return "arkit"
        case .parabolaPlayground:
            return "slider.horizontal.3"
        }
    }
}

// MARK: - Coach Mark View Modifier

public struct CoachMarkModifier: ViewModifier {
    let coachMark: CoachMark
    @ObservedObject private var manager = CoachMarksManager.shared
    @State private var isShowing = false

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isShowing {
                    CoachMarkBubble(coachMark: coachMark) {
                        dismiss()
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .padding(.bottom, 80)
                }
            }
            .onAppear {
                if manager.shouldShow(coachMark) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isShowing = true
                        }
                    }
                }
            }
    }

    private func dismiss() {
        withAnimation {
            isShowing = false
        }
        manager.markAsSeen(coachMark)
    }
}

// MARK: - Coach Mark Bubble

struct CoachMarkBubble: View {
    let coachMark: CoachMark
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: coachMark.icon)
                .foregroundStyle(.blue)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(coachMark.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(coachMark.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(coachMark.title). \(coachMark.message)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to dismiss")
    }
}

// MARK: - View Extension

public extension View {
    func coachMark(_ coachMark: CoachMark) -> some View {
        modifier(CoachMarkModifier(coachMark: coachMark))
    }
}
