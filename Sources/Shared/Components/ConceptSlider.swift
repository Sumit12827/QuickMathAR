#if os(iOS)
import SwiftUI

struct ConceptSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    
    // Haptic Configuration
    var hapticStyle: HapticFeedbackStyle = .selection
    
    // Internal State
    @State private var isDragging: Bool = false
    @State private var lastHapticValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label Row
            HStack {
                Text(title)
                    .font(.designCallout)
                    .foregroundStyle(.primary)

                Spacer()

                Text(String(format: "%.1f", value))
                    .font(.designBody)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            // Custom Slider Track
            GeometryReader { geometry in
                let width = geometry.size.width
                let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                
                ZStack(alignment: .leading) {
                    // Track Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 6)

                    // Active Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: max(0, width * progress), height: 6)

                    // Knob
                    Circle()
                        .fill(Color(UIColor.systemBackground))
                        .frame(width: 24, height: 24)
                        .shadow(color: Color.primary.opacity(0.15), radius: 4)
                        .offset(x: max(0, min(width - 24, width * progress - 12)))
                        .gesture(
                            DragGesture()
                                .onChanged { drag in
                                    isDragging = true
                                    updateValue(drag: drag, width: width)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    HapticManager.shared.play(.light) // Settle
                                }
                        )
                }
                .frame(height: 24)
            }
            .frame(height: 24)
        }
        .padding(.vertical, 8)
    }
    
    private func updateValue(drag: DragGesture.Value, width: CGFloat) {
        let location = drag.location.x
        let percentage = Double(location / width)
        let totalRange = range.upperBound - range.lowerBound
        var rawValue = range.lowerBound + (totalRange * percentage)
        
        // Clamp
        rawValue = max(range.lowerBound, min(range.upperBound, rawValue))
        
        // Step logic
        if let step = step {
            rawValue = round(rawValue / step) * step
        }
        
        // Update Binding
        if rawValue != value {
            value = rawValue
            triggerHaptic(for: value)
        }
    }
    
    private func triggerHaptic(for value: Double) {
        // Integer Notch
        if abs(value - round(value)) < 0.05 && abs(value - lastHapticValue) > 0.5 {
            HapticManager.shared.play(hapticStyle)
            lastHapticValue = value
        } else {
            // Texture (Continuous)
            // Implementation note: Continuous haptics require engine update loop
            // For now, simpler selection feedback on change
            if step != nil {
                 HapticManager.shared.play(.selection)
            }
        }
    }
}

// MARK: - Preview
#Preview("Light") {
    ConceptSlider(title: "Coefficient a", value: .constant(1.5), range: -5...5, step: 0.1)
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ConceptSlider(title: "Coefficient a", value: .constant(1.5), range: -5...5, step: 0.1)
        .padding()
        .preferredColorScheme(.dark)
}
#endif
