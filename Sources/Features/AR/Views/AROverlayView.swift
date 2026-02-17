import SwiftUI

struct AROverlayView: View {
    @Binding var state: LegacyARPlacementState
    @Binding var isTheaterMode: Bool
    
    // Legend State
    @State private var isLegendExpanded: Bool = true
    
    var body: some View {
        ZStack {
            // Top Controls (Status & Mode)
            VStack {
                HStack(alignment: .top) {
                    // Equation Display
                    if state == .postPlacement {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("y = x² - 2x + 2") // Dynamic binding needed
                                .font(.designTitle3)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2)
                            
                            HStack {
                                Text("Standard Form")
                                    .font(.designCaption)
                                    .foregroundColor(.designSecondaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Material.ultraThinMaterial)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Mode Toggles
                    VStack(spacing: 12) {
                        Button(action: { 
                            withAnimation { isTheaterMode.toggle() }
                            HapticManager.shared.play(.selection)
                        }) {
                            Image(systemName: isTheaterMode ? "theatermasks.fill" : "theatermasks")
                                .font(.title2)
                                .foregroundColor(isTheaterMode ? .yellow : .white)
                                .frame(width: 44, height: 44)
                                .background(Material.thinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, DesignSystem.Layout.screenEdgePadding)
                
                Spacer()
            }
            
            // Legend (Collapsible)
            if state == .postPlacement && !isTheaterMode {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                withAnimation { isLegendExpanded.toggle() }
                                HapticManager.shared.play(.tap)
                            }) {
                                HStack {
                                    Text("Legend")
                                        .font(.designCallout)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(isLegendExpanded ? 90 : 0))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            if isLegendExpanded {
                                Divider().background(Color.white.opacity(0.3))
                                
                                LegendItem(color: .red, label: "Vertex")
                                LegendItem(color: .green, label: "Roots")
                                LegendItem(color: .cyan, label: "Tangent")
                            }
                        }
                        .padding()
                        .frame(width: 160)
                        .background(Material.regularMaterial)
                        .cornerRadius(DesignSystem.Layout.cornerRadius)
                        .shadow(radius: 10)
                    }
                    .padding(.bottom, 100)
                    .padding(.trailing, DesignSystem.Layout.screenEdgePadding)
                }
                .transition(.opacity.combined(with: .scale))
            }
            
            // Bottom Controls (Persistent)
            VStack {
                Spacer()
                HStack(spacing: 32) {
                    ControlButton(icon: "arrow.counterclockwise") {
                        // Reset Action
                        HapticManager.shared.play(.medium)
                    }
                    
                    ControlButton(icon: "camera.fill", size: 64) {
                        // Snapshot Action
                        HapticManager.shared.play(.heavy)
                    }
                    
                    ControlButton(icon: "square.and.arrow.up") {
                        // Share Action
                        HapticManager.shared.play(.light)
                    }
                }
                .padding(.bottom, 40)
            }
            
            // Scanning Overlay
            if state == .scanning {
                VStack {
                    Spacer()
                    Text("Move device to find a surface")
                        .font(.designTitle3)
                        .foregroundColor(.white)
                        .padding()
                        .background(Material.thinMaterial)
                        .cornerRadius(20)
                        .padding(.bottom, 100)
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Subviews

struct ControlButton: View {
    let icon: String
    var size: CGFloat = 50
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(Material.regularMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(radius: 4)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.designCaption)
                .foregroundColor(.designSecondaryText)
        }
    }
}
