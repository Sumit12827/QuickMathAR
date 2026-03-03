//
//  Graph2DView.swift
//  QuickMathsAR
//
//  2D graph visualization fallback when AR is unavailable
//

#if os(iOS)
import SwiftUI

/// A 2D graph visualization view (non-AR fallback)
public struct Graph2DView: View {
    
    // MARK: - Properties
    
    /// The graph data to visualize
    let graphData: GraphData
    
    /// View size
    @State private var viewSize: CGSize = .zero
    
    // MARK: - Computed Properties
    
    private var config: GraphConfiguration {
        graphData.configuration
    }
    
    /// Curve color based on equation type
    private var curveColor: Color {
        graphData.equationType == .linear ? .blue : .purple
    }
    
    // MARK: - Coordinate Transformation
    
    /// Convert math coordinates to view coordinates
    private func toViewCoordinates(_ point: SIMD2<Float>) -> CGPoint {
        let xRange = config.xRange.upperBound - config.xRange.lowerBound
        let yRange = config.yRange.upperBound - config.yRange.lowerBound
        
        let xNormalized = (point.x - config.xRange.lowerBound) / xRange
        let yNormalized = (point.y - config.yRange.lowerBound) / yRange
        
        return CGPoint(
            x: CGFloat(xNormalized) * viewSize.width,
            y: viewSize.height - CGFloat(yNormalized) * viewSize.height // Flip Y
        )
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                
                // Grid
                gridLines
                
                // Axes
                axesLines
                
                // Curve
                curvePath
                
                // Key points
                keyPointsView
            }
            .onAppear {
                viewSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
            }
        }
        .aspectRatio(1.2, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
    }
    
    // MARK: - Grid Lines
    
    private var gridLines: some View {
        Canvas { context, size in
            guard viewSize.width > 0 else { return }
            
            let xRange = config.xRange.upperBound - config.xRange.lowerBound
            let yRange = config.yRange.upperBound - config.yRange.lowerBound
            
            // Draw vertical grid lines
            var x = config.xRange.lowerBound
            while x <= config.xRange.upperBound {
                let xNorm = (x - config.xRange.lowerBound) / xRange
                let xPos = CGFloat(xNorm) * size.width
                
                var path = Path()
                path.move(to: CGPoint(x: xPos, y: 0))
                path.addLine(to: CGPoint(x: xPos, y: size.height))
                
                context.stroke(
                    path,
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 0.5
                )
                
                x += config.gridSpacing
            }
            
            // Draw horizontal grid lines
            var y = config.yRange.lowerBound
            while y <= config.yRange.upperBound {
                let yNorm = (y - config.yRange.lowerBound) / yRange
                let yPos = size.height - CGFloat(yNorm) * size.height
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: yPos))
                path.addLine(to: CGPoint(x: size.width, y: yPos))
                
                context.stroke(
                    path,
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 0.5
                )
                
                y += config.gridSpacing
            }
        }
    }
    
    // MARK: - Axes
    
    private var axesLines: some View {
        Canvas { context, size in
            guard viewSize.width > 0 else { return }
            
            let origin = toViewCoordinates(SIMD2(0, 0))
            
            // X-axis
            var xAxisPath = Path()
            xAxisPath.move(to: CGPoint(x: 0, y: origin.y))
            xAxisPath.addLine(to: CGPoint(x: size.width, y: origin.y))
            context.stroke(xAxisPath, with: .color(.primary.opacity(0.6)), lineWidth: 1.5)
            
            // Y-axis
            var yAxisPath = Path()
            yAxisPath.move(to: CGPoint(x: origin.x, y: 0))
            yAxisPath.addLine(to: CGPoint(x: origin.x, y: size.height))
            context.stroke(yAxisPath, with: .color(.primary.opacity(0.6)), lineWidth: 1.5)
        }
    }
    
    // MARK: - Curve
    
    private var curvePath: some View {
        Canvas { context, size in
            guard viewSize.width > 0, graphData.curvePoints.count >= 2 else { return }
            
            var path = Path()
            let points = graphData.curvePoints.map { toViewCoordinates($0) }
            
            path.move(to: points[0])
            for i in 1..<points.count {
                path.addLine(to: points[i])
            }
            
            context.stroke(
                path,
                with: .color(curveColor),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
        }
    }
    
    // MARK: - Key Points
    
    private var keyPointsView: some View {
        ForEach(graphData.keyPoints) { keyPoint in
            let position = toViewCoordinates(keyPoint.position)
            
            Circle()
                .fill(colorForKeyPoint(keyPoint.type))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                )
                .position(position)
        }
    }
    
    private func colorForKeyPoint(_ type: KeyPointType) -> Color {
        switch type {
        case .xIntercept: return .green
        case .yIntercept: return .orange
        case .vertex: return .red
        case .origin: return .gray
        }
    }
}

// MARK: - Graph Card View

/// A card containing a 2D graph with title and legend
public struct GraphCardView: View {
    let title: String
    let graphData: GraphData
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Graph
            Graph2DView(graphData: graphData)
                .frame(height: 250)
            
            // Legend
            HStack(spacing: 16) {
                LegendDot(
                    color: graphData.equationType == .linear ? .blue : .purple,
                    label: "Curve"
                )
                
                if graphData.keyPoints.contains(where: { $0.type == .vertex }) {
                    LegendDot(color: .red, label: "Vertex")
                }
                
                if graphData.keyPoints.contains(where: { $0.type == .xIntercept }) {
                    LegendDot(color: .green, label: "X-Intercept")
                }
                
                if graphData.keyPoints.contains(where: { $0.type == .yIntercept }) {
                    LegendDot(color: .orange, label: "Y-Intercept")
                }
            }
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Legend Dot

struct LegendDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("2D Linear Graph") {
    Graph2DView(
        graphData: GraphDataGenerator.generate(
            linear: LinearEquation(slope: 2, yIntercept: -1)
        )
    )
    .frame(height: 300)
    .padding()
}

#Preview("2D Quadratic Graph") {
    Graph2DView(
        graphData: GraphDataGenerator.generate(
            quadratic: QuadraticEquation(a: 1, b: -2, c: -3)
        )
    )
    .frame(height: 300)
    .padding()
}

#Preview("Graph Card") {
    GraphCardView(
        title: "y = x² - 2x - 3",
        graphData: GraphDataGenerator.generate(
            quadratic: QuadraticEquation(a: 1, b: -2, c: -3)
        )
    )
    .padding()
}
#endif
