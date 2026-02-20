//
//  ARGraphView.swift
//  QuickMathsAR
//
//  SwiftUI wrapper for AR graph visualization
//  Provides a calm, intentional gateway into AR-based visualization
//

#if os(iOS)
import SwiftUI
import RealityKit

// MARK: - AR Graph View (UIViewControllerRepresentable)

/// SwiftUI wrapper that displays an AR graph visualization
/// Wraps ARGraphViewController for use in SwiftUI
public struct ARGraphView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// The interactive view model
    @ObservedObject var viewModel: GraphInteractionViewModel
    
    /// Callback when graph is placed in AR
    var onGraphPlaced: (() -> Void)?
    
    /// Callback for AR errors
    var onError: ((ARGraphError) -> Void)?
    
    /// Callback for AR status updates
    var onStatusUpdate: ((String) -> Void)?
    
    // MARK: - UIViewControllerRepresentable
    
    public func makeUIViewController(context: Context) -> ARGraphViewController {
        let controller = ARGraphViewController()
        controller.configure(with: viewModel)
        controller.onGraphPlaced = onGraphPlaced
        controller.onError = onError
        controller.onStatusUpdate = onStatusUpdate
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: ARGraphViewController, context: Context) {
        // ViewModel updates are handled via Combine in the controller
        // No need to reconfigure on every SwiftUI update unless VM instance changes
        // uiViewController.configure(with: viewModel) 
    }
    
    public static func dismantleUIViewController(_ uiViewController: ARGraphViewController, coordinator: ()) {
        // Clean up AR session when view is removed
        uiViewController.reset()
    }
}

// MARK: - AR Graph Screen

/// Full-screen AR graph experience with minimal, educational UI overlay
/// Provides a calm, focused visual learning mode
public struct ARGraphScreen: View {
    
    // MARK: - Properties
    
    /// The equation type being visualized
    let equationType: GraphEquationType
    
    /// Initial graph data
    let initialGraphData: GraphData
    
    /// Dismiss action (return to learning)
    var onDismiss: (() -> Void)?
    
    // MARK: - State
    
    @StateObject private var viewModel: GraphInteractionViewModel
    
    @State private var isGraphPlaced = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showControls = false
    @State private var arStatusMessage = "Point your camera at a flat surface"
    
    // MARK: - Environment
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Initialization
    
    public init(equationType: GraphEquationType, graphData: GraphData, onDismiss: (() -> Void)? = nil) {
        self.equationType = equationType
        self.initialGraphData = graphData
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: GraphInteractionViewModel(initialData: graphData))
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // AR View - Full screen
            ARGraphView(
                viewModel: viewModel,
                onGraphPlaced: handleGraphPlaced,
                onError: handleError,
                onStatusUpdate: { status in
                    arStatusMessage = status
                }
            )
            .ignoresSafeArea()
            
            // UI Overlay
            overlayContent
        }
        .alert("AR Unavailable", isPresented: $showError) {
            Button("Back to Learning") {
                onDismiss?()
            }
        } message: {
            Text(errorMessage)
        }
        .statusBarHidden(true)
    }
    
    // MARK: - Overlay Content
    
    private var overlayContent: some View {
        ZStack {
            // Placement overlay — full screen, centered
            if !isGraphPlaced {
                placementInstructions
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }

            // Top bar + bottom controls
            VStack(spacing: 0) {
                topBar

                Spacer()

                if isGraphPlaced {
                    controlsView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Top Bar
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        ZStack {
            // Centered Title
            VStack(alignment: .center, spacing: 2) {
                Text(equationType == .linear ? "Linear Graph" : "Quadratic Graph")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("AR Visualization")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Right-aligned Buttons
            HStack {
                Spacer()
                
                Button(action: { 
                    viewModel.reset() 
                    // Optional: Provide haptic feedback for reset
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .opacity(isGraphPlaced ? 1 : 0)
                
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Placement Instructions

    private var placementInstructions: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(spacing: 8) {
                    Text("Tap Surface to Place")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(arStatusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )

            Spacer()
                .frame(height: horizontalSizeClass == .compact ? 80 : 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Interactive Controls
    
    private var controlsView: some View {
        VStack(spacing: 20) {
            // Drag handle / Title
            Capsule()
                .fill(.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            Text("Adjust Parameters")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            if equationType == .linear {
                LinearControls(viewModel: viewModel)
            } else {
                QuadraticControls(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, horizontalSizeClass == .compact ? 40 : 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Event Handlers
    
    private func handleGraphPlaced() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isGraphPlaced = true
        }
    }
    
    private func handleError(_ error: ARGraphError) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - Control Subviews

struct LinearControls: View {
    @ObservedObject var viewModel: GraphInteractionViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Slope (m)
            GraphParameterSlider(
                value: $viewModel.slope,
                range: -5...5,
                step: 0.5,
                title: "Slope (m)",
                color: GraphColors.linearCurve.toSwiftUIColor
            )
            
            // Intercept (b)
            GraphParameterSlider(
                value: $viewModel.yIntercept,
                range: -5...5,
                step: 0.5,
                title: "Y-Intercept (b)",
                color: .orange
            )
        }
    }
}

struct QuadraticControls: View {
    @ObservedObject var viewModel: GraphInteractionViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // A
            GraphParameterSlider(
                value: $viewModel.quadA,
                range: -3...3,
                step: 0.1,
                title: "Width (a)",
                color: GraphColors.quadraticCurve.toSwiftUIColor
            )
            
            // B
            GraphParameterSlider(
                value: $viewModel.quadB,
                range: -5...5,
                step: 0.5,
                title: "Shift (b)",
                color: .blue
            )
            
            // C
            GraphParameterSlider(
                value: $viewModel.quadC,
                range: -5...5,
                step: 0.5,
                title: "Height (c)",
                color: .green
            )
        }
    }
}

// MARK: - Reusable Components

struct GraphParameterSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.8))
                    .contentTransition(.numericText())
            }
            
            Slider(value: $value, in: range, step: step) {
                Text(title)
            } minimumValueLabel: {
                Text(String(format: "%.0f", range.lowerBound))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            } maximumValueLabel: {
                Text(String(format: "%.0f", range.upperBound))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .tint(color)
        }
    }
}

// MARK: - Extensions

extension UIColor {
    var toSwiftUIColor: Color { Color(self) }
}

// MARK: - Preview

#Preview("Linear AR") {
    ARGraphScreen(
        equationType: .linear,
        graphData: GraphDataGenerator.generate(linear: LinearEquation(slope: 1, yIntercept: 0))
    )
}

#endif
