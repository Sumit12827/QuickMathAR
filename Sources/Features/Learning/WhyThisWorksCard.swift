//
//  WhyThisWorksCard.swift
//  QuickMathsAR
//
//  The "Why This Works" expandable explanation card that appears
//  below each StepCard in Learning Examples. Integrates with
//  ExplanationEngine for AI-powered or fallback explanations.
//
//  Collapsed: 🧠 one-line teaser
//  Expanded: concept + property + analogy + "Ask Why" field
//

#if os(iOS)
import SwiftUI

/// An expandable card showing a conceptual explanation for a solving step.
/// Supports AI-generated and fallback explanations, adaptive depth levels,
/// and follow-up questions.
struct WhyThisWorksCard: View {
    
    // MARK: - Properties
    
    let step: SolvingStep
    let equation: String
    let totalSteps: Int
    let previousStepResult: String?
    let accentColor: Color
    var explanationEngine: ExplanationEngine
    
    // MARK: - State
    
    @State private var isExpanded = false
    @State private var followUpText = ""
    @State private var showFollowUpField = false
    @State private var hasShownFirstTimeHint = false
    
    // MARK: - Environment
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @AppStorage("hasSeenAIExplanationHint") private var hasSeenHint = false
    
    // MARK: - Computed
    
    private var currentState: ExplanationState {
        explanationEngine.state(for: step, equation: equation)
    }
    
    private var animation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.2)
            : .spring(response: 0.35, dampingFraction: 0.85)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed header — always visible
            collapsedHeader
            
            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .move(edge: .top))
                    )
            }
        }
        .padding(14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: .black.opacity(isExpanded ? 0.08 : 0.04),
            radius: isExpanded ? 10 : 6,
            y: isExpanded ? 6 : 3
        )
        .accessibilityElement(children: isExpanded ? .contain : .ignore)
        .accessibilityLabel(isExpanded ? "Why this works, expanded" : "Why this works")
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to see explanation")
        .accessibilityAction {
            toggleExpanded()
        }
    }
    
    // MARK: - Collapsed Header
    
    private var collapsedHeader: some View {
        Button(action: toggleExpanded) {
            HStack(spacing: 10) {
                // Brain icon
                Text("🧠")
                    .font(.body)
                
                // Title + teaser
                VStack(alignment: .leading, spacing: 2) {
                    Text("Why This Works")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if !isExpanded {
                        Text(teaserText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Expand/collapse chevron
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Expanded Content
    
    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .padding(.vertical, 4)
            
            // Level picker
            levelPicker
            
            // Content based on state
            switch currentState {
            case .idle:
                // Should not normally be visible; request sent on expand
                ShimmerView(lineCount: 3)
                
            case .loading:
                ShimmerView(lineCount: 4)
                
            case .loaded(let explanation), .fallback(let explanation):
                explanationContent(explanation)
                
            case .error:
                errorContent
            }
            
            // "Ask Why" follow-up section
            if showFollowUpField {
                followUpSection
            } else if explanationEngine.isModelAvailable, currentState.hasContent {
                askWhyButton
            }
            
            // Transparency badge
            if currentState.hasContent {
                transparencyBadge
            }
        }
    }
    
    // MARK: - Level Picker
    
    private var levelPicker: some View {
        Picker("Explanation Depth", selection: Binding(
            get: { explanationEngine.currentLevel },
            set: { newLevel in
                explanationEngine.switchLevel(
                    to: newLevel,
                    for: step,
                    equation: equation,
                    totalSteps: totalSteps,
                    previousStepResult: previousStepResult
                )
            }
        )) {
            ForEach(ExplanationLevel.allCases, id: \.self) { level in
                Text(level.displayName).tag(level)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Explanation depth level")
    }
    
    // MARK: - Explanation Content
    
    private func explanationContent(_ explanation: StepExplanation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Concept explanation
            Text(explanation.conceptExplanation)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Concept explanation")
                .accessibilityValue(explanation.conceptExplanation)
            
            // Mathematical property
            HStack(spacing: 8) {
                Image(systemName: "function")
                    .font(.caption)
                    .foregroundStyle(accentColor)
                
                Text(explanation.propertyUsed)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(accentColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Mathematical property: \(explanation.propertyUsed)")
            
            // Analogy
            if !explanation.analogy.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    
                    Text(explanation.analogy)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.yellow.opacity(0.08))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Analogy: \(explanation.analogy)")
            }
            
            // Memory tip (advanced level)
            if let tip = explanation.memoryTip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "cpu")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    
                    Text(tip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Memory tip: \(tip)")
            }
        }
    }
    
    // MARK: - Error Content
    
    private var errorContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .font(.caption)
                .foregroundStyle(.orange)
            
            Text("Full explanation unavailable. Showing summary.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Ask Why Button
    
    private var askWhyButton: some View {
        Button {
            withAnimation(animation) {
                showFollowUpField = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.caption)
                Text("Ask why…")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask a follow-up question about this step")
    }
    
    // MARK: - Follow-Up Section
    
    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask about this step")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                TextField("Why can't we divide first?", text: $followUpText)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit(submitFollowUp)
                
                Button(action: submitFollowUp) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(followUpText.isEmpty ? Color.gray.opacity(0.3) : accentColor)
                }
                .buttonStyle(.plain)
                .disabled(followUpText.isEmpty)
                .accessibilityLabel("Send question")
            }
        }
    }
    
    // MARK: - Transparency Badge
    
    private var transparencyBadge: some View {
        HStack(spacing: 4) {
            if currentState.isAIGenerated {
                Image(systemName: "sparkle")
                    .font(.caption2)
                Text("Powered by on-device intelligence")
                    .font(.caption2)
            } else {
                Image(systemName: "doc.text")
                    .font(.caption2)
                Text("From learning content")
                    .font(.caption2)
            }
        }
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityLabel(
            currentState.isAIGenerated
                ? "Explanation powered by on-device intelligence"
                : "Explanation from learning content"
        )
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var cardBackground: some View {
        if contrast == .increased {
            // High contrast: solid background
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemGroupedBackground))
        } else {
            // Standard: material background
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Actions
    
    private func toggleExpanded() {
        withAnimation(animation) {
            isExpanded.toggle()
        }
        
        if isExpanded {
            // Trigger explanation request on first expand
            explanationEngine.requestExplanation(
                for: step,
                equation: equation,
                totalSteps: totalSteps,
                previousStepResult: previousStepResult
            )
            
            // Show first-time hint
            if !hasSeenHint {
                hasSeenHint = true
            }
            
            // Haptic
            HapticManager.shared.light()
        }
    }
    
    private func submitFollowUp() {
        guard !followUpText.isEmpty else { return }
        
        explanationEngine.requestFollowUp(
            question: followUpText,
            for: step,
            equation: equation,
            totalSteps: totalSteps,
            previousStepResult: previousStepResult
        )
        
        followUpText = ""
        HapticManager.shared.light()
    }
    
    /// Teaser text for collapsed state — derived from existing step reasoning
    private var teaserText: String {
        "Tap to understand this step"
    }
}

// MARK: - Preview

#Preview("Why This Works — Expanded") {
    let engine = ExplanationEngine()
    
    VStack(spacing: 16) {
        WhyThisWorksCard(
            step: SolvingStep(
                stepNumber: 2,
                action: "Subtract 5 from both sides",
                reasoning: .detailed(StepReasoning(
                    brief: "Undo the +5",
                    detailed: "Subtraction is the inverse of addition. Apply to both sides.",
                    metaphor: "Remove equal weight from both sides of the scale."
                )),
                result: "2x = 8",
                arithmeticConceptUsed: "subtraction"
            ),
            equation: "2x + 5 = 13",
            totalSteps: 3,
            previousStepResult: "2x + 5 = 13",
            accentColor: .blue,
            explanationEngine: engine
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
