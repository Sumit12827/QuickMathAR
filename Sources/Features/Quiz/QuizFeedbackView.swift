import SwiftUI

struct QuizFeedbackView: View {
    let options: [String]
    let correctOptionIndex: Int
    @Binding var selectedIndex: Int?
    
    // Animation State
    @State private var shakeAmount: CGFloat = 0
    @State private var waveProgress: CGFloat = 0
    @State private var showCheckmark: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<options.count, id: \.self) { index in
                QuizOptionButton(
                    text: options[index],
                    isSelected: selectedIndex == index,
                    isCorrect: index == correctOptionIndex,
                    isRevealed: selectedIndex != nil,
                    waveProgress: waveProgress
                ) {
                    handleSelection(index)
                }
                .modifier(ShakeEffect(shakes: index == selectedIndex && index != correctOptionIndex ? shakeAmount : 0))
            }
        }
    }
    
    private func handleSelection(_ index: Int) {
        guard selectedIndex == nil else { return } // Lock after selection
        selectedIndex = index
        
        if index == correctOptionIndex {
            // Success Sequence
            HapticManager.shared.play(.success)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                waveProgress = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                showCheckmark = true
            }
        } else {
            // Error Sequence
            HapticManager.shared.play(.error)
            withAnimation(.default) {
                shakeAmount = 10
            }
            // Reset shake
            withAnimation(.default.delay(0.4)) {
                shakeAmount = 0
            }
        }
    }
}

// MARK: - Option Button
struct QuizOptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isRevealed: Bool
    let waveProgress: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        // Green Wave (Correct)
                        GeometryReader { proxy in
                            if isCorrect && isRevealed {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: proxy.size.width * 2, height: proxy.size.width * 2)
                                    .scaleEffect(waveProgress)
                                    .opacity(waveProgress > 0 ? 1 : 0)
                                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )
                
                // Content
                HStack {
                    Text(text)
                        .font(.designBody)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if isCorrect && isRevealed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .transition(.scale)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .transition(.scale)
                    }
                }
                .padding()

            }
            .frame(height: 56)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .opacity(isRevealed && !isSelected && !isCorrect ? 0.5 : 1.0) // Fade others
    }
    
    private var backgroundColor: Color {
        if isRevealed {
            if isCorrect { return Color.green.opacity(0.2) }
            if isSelected && !isCorrect { return Color.red.opacity(0.1) }
        }
        return DesignSystem.Colors.cardBackground
    }
    
    private var borderColor: Color {
        if isRevealed {
            if isCorrect { return Color.green }
            if isSelected && !isCorrect { return Color.red }
        }
        return isSelected ? DesignSystem.Colors.tint : .clear
    }
}
