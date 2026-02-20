//
//  DetailLevelSelectorView.swift
//  QuickMathsAR
//
//  Global 3-level detail selector for step-by-step explanations.
//  Sticky at the top of the learning flow, controls all cards below.
//

#if os(iOS)
import SwiftUI

struct DetailLevelSelectorView: View {
    
    @Binding var selectedLevel: ExplanationLevel
    
    /// Optional: shows an AI badge when Apple Intelligence is powering explanations
    var isAIAvailable: Bool = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Label {
                    Text("Explanation Detail")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isAIAvailable {
                    Label("On-Device", systemImage: "cpu")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.purple.opacity(0.8))
                }
            }
            
            // Segmented control
            HStack(spacing: 0) {
                ForEach(ExplanationLevel.allCases, id: \.self) { level in
                    levelButton(level)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
    }
    
    private func levelButton(_ level: ExplanationLevel) -> some View {
        let isSelected = selectedLevel == level
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedLevel = level
            }
            HapticManager.shared.light()
        } label: {
            VStack(spacing: 3) {
                Text(level.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? .white : .secondary)
                
                Text(levelSubtitle(level))
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? AnyShapeStyle(Color.white.opacity(0.7)) : AnyShapeStyle(.tertiary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? levelColor(level) : .clear)
            )
            .padding(2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(level.displayName) explanation level")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private func levelSubtitle(_ level: ExplanationLevel) -> String {
        switch level {
        case .beginner: return "Simple words"
        case .intermediate: return "Math terms"
        case .advanced: return "Full detail"
        }
    }
    
    private func levelColor(_ level: ExplanationLevel) -> Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .purple
        }
    }
}

// MARK: - Preview

#Preview("Detail Level Selector") {
    struct PreviewWrapper: View {
        @State var level: ExplanationLevel = .intermediate
        
        var body: some View {
            VStack {
                DetailLevelSelectorView(selectedLevel: $level, isAIAvailable: true)
                
                Spacer()
                
                Text("Selected: \(level.displayName)")
                    .font(.title2)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    return PreviewWrapper()
}
#endif
