//
//  VisualFeedbackController.swift
//  QuickMathsAR
//
//  Manages visual feedback during graph interactions
//

#if os(iOS)
import UIKit
import RealityKit
import simd

// MARK: - Visual Feedback Controller

/// Manages visual feedback elements during graph interaction
/// Creates and updates position indicators, region highlights, and optional labels
public final class VisualFeedbackController {
    
    // MARK: - Properties
    
    /// The graph root entity
    private weak var graphEntity: Entity?
    
    /// Dedicated entity for all feedback elements
    private var feedbackEntity: Entity?
    
    /// Position indicator entity
    private var positionIndicator: ModelEntity?
    
    /// Current region highlight entities (keyed by segment index)
    private var regionHighlights: [Int: ModelEntity] = [:]
    
    /// Optional coordinate label entity
    private var labelEntity: Entity?
    
    /// World scale from graph configuration
    private var worldScale: Float = 0.05
    
    /// Curve points for highlight generation
    private var curvePoints: [SIMD2<Float>] = []
    
    /// Curve analyzer for region info
    private var curveAnalyzer: CurveAnalyzer?
    
    // MARK: - Dimensions
    
    private let indicatorRadius: Float = 0.012
    private let highlightThickness: Float = 0.006
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Configuration
    
    /// Configure the controller with graph data
    /// - Parameters:
    ///   - graphEntity: The graph root entity
    ///   - graphData: The graph data
    public func configure(graphEntity: Entity, graphData: GraphData) {
        self.graphEntity = graphEntity
        self.worldScale = graphData.configuration.worldScale
        self.curvePoints = graphData.curvePoints
        self.curveAnalyzer = CurveAnalyzer(curvePoints: graphData.curvePoints)
        
        // Create feedback container entity
        setupFeedbackEntity()
    }
    
    /// Clear configuration and remove all feedback
    public func clearConfiguration() {
        removeAllFeedback()
        graphEntity = nil
        feedbackEntity = nil
        curvePoints = []
        curveAnalyzer = nil
    }
    
    // MARK: - Setup
    
    private func setupFeedbackEntity() {
        guard let graphEntity = graphEntity else { return }
        
        // Remove old feedback entity if exists
        feedbackEntity?.removeFromParent()
        
        // Create new feedback container
        let entity = Entity()
        entity.name = "InteractionFeedback"
        graphEntity.addChild(entity)
        feedbackEntity = entity
        
        // Create position indicator (hidden initially)
        createPositionIndicator()
    }
    
    private func createPositionIndicator() {
        guard let feedbackEntity = feedbackEntity else { return }
        
        let mesh = MeshResource.generateSphere(radius: indicatorRadius)
        var material = UnlitMaterial(color: InteractionColors.positionIndicator)
        material.color.tint = InteractionColors.positionIndicator
        
        let indicator = ModelEntity(mesh: mesh, materials: [material])
        indicator.name = "PositionIndicator"
        indicator.isEnabled = false  // Hidden initially
        
        feedbackEntity.addChild(indicator)
        positionIndicator = indicator
    }
    
    // MARK: - Position Indicator
    
    /// Show position indicator at a curve point
    /// - Parameter curvePoint: The curve point to indicate
    public func showPositionIndicator(at curvePoint: CurvePoint) {
        guard let indicator = positionIndicator else { return }
        
        // Calculate world position
        let worldPos = SIMD3<Float>(
            curvePoint.position.x * worldScale,
            curvePoint.position.y * worldScale,
            0.005  // Slight z-offset to appear in front of curve
        )
        
        indicator.position = worldPos
        indicator.isEnabled = true
        
        // Update indicator color based on region
        updateIndicatorColor(for: curvePoint.regionType)
    }
    
    /// Hide position indicator
    public func hidePositionIndicator() {
        positionIndicator?.isEnabled = false
    }
    
    private func updateIndicatorColor(for regionType: CurveRegionType) {
        guard let indicator = positionIndicator else { return }
        
        let color: UIColor
        switch regionType {
        case .increasing:
            color = InteractionColors.increasing
        case .decreasing:
            color = InteractionColors.decreasing
        case .stationary:
            color = InteractionColors.stationary
        }
        
        var material = UnlitMaterial(color: color)
        material.color.tint = color
        indicator.model?.materials = [material]
    }
    
    // MARK: - Region Highlighting
    
    /// Highlight the region around a curve point
    /// - Parameters:
    ///   - curvePoint: The curve point being explored
    ///   - radius: Number of segments to highlight on each side
    public func highlightRegion(around curvePoint: CurvePoint, radius: Int = 5) {
        // Clear existing highlights
        clearRegionHighlights()
        
        guard !curvePoints.isEmpty else { return }
        
        // Calculate highlight range
        let startIndex = max(0, curvePoint.index - radius)
        let endIndex = min(curvePoints.count - 1, curvePoint.index + radius)
        
        // Create highlights for segments in range
        for i in startIndex..<endIndex {
            createSegmentHighlight(fromIndex: i, toIndex: i + 1)
        }
    }
    
    private func createSegmentHighlight(fromIndex: Int, toIndex: Int) {
        guard let feedbackEntity = feedbackEntity,
              fromIndex >= 0 && toIndex < curvePoints.count else { return }
        
        let startPoint = curvePoints[fromIndex]
        let endPoint = curvePoints[toIndex]
        
        // Get region type for this segment
        let regionType = curveAnalyzer?.region(at: fromIndex) ?? .stationary
        
        // Calculate segment geometry
        let startPos = SIMD3<Float>(
            startPoint.x * worldScale,
            startPoint.y * worldScale,
            0.002  // Slight z-offset
        )
        let endPos = SIMD3<Float>(
            endPoint.x * worldScale,
            endPoint.y * worldScale,
            0.002
        )
        
        let direction = endPos - startPos
        let length = simd_length(direction)
        let midpoint = (startPos + endPos) / 2
        
        guard length > Float.ulpOfOne else { return }
        
        // Create highlight segment
        let mesh = MeshResource.generateBox(size: SIMD3(length, highlightThickness, highlightThickness))
        
        let color = colorForRegion(regionType)
        var material = UnlitMaterial(color: color)
        material.color.tint = color
        
        let segment = ModelEntity(mesh: mesh, materials: [material])
        segment.position = midpoint
        segment.name = "RegionHighlight_\(fromIndex)"
        
        // Rotate to align with direction
        let normalizedDir = simd_normalize(direction)
        let defaultDir = SIMD3<Float>(1, 0, 0)
        
        let dot = simd_dot(defaultDir, normalizedDir)
        if dot < -0.999 {
            segment.orientation = simd_quatf(angle: .pi, axis: SIMD3(0, 1, 0))
        } else if dot < 0.999 {
            let cross = simd_cross(defaultDir, normalizedDir)
            let angle = acos(dot)
            segment.orientation = simd_quatf(angle: angle, axis: simd_normalize(cross))
        }
        
        feedbackEntity.addChild(segment)
        regionHighlights[fromIndex] = segment
    }
    
    private func colorForRegion(_ regionType: CurveRegionType) -> UIColor {
        switch regionType {
        case .increasing:
            return InteractionColors.increasing
        case .decreasing:
            return InteractionColors.decreasing
        case .stationary:
            return InteractionColors.stationary
        }
    }
    
    /// Clear all region highlights
    public func clearRegionHighlights() {
        for (_, highlight) in regionHighlights {
            highlight.removeFromParent()
        }
        regionHighlights.removeAll()
    }
    
    // MARK: - Coordinate Label (Optional)
    
    /// Show coordinate label at a curve point
    /// Note: Currently simplified - full text rendering requires TextMeshResource
    /// - Parameter curvePoint: The curve point to label
    public func showCoordinateLabel(at curvePoint: CurvePoint) {
        // RealityKit text rendering is complex and may not be worth the complexity
        // For now, this is a placeholder that could be extended
        // The position indicator with color already provides feedback
    }
    
    /// Hide coordinate label
    public func hideCoordinateLabel() {
        labelEntity?.removeFromParent()
        labelEntity = nil
    }
    
    // MARK: - Cleanup
    
    /// Remove all feedback elements
    public func removeAllFeedback() {
        hidePositionIndicator()
        clearRegionHighlights()
        hideCoordinateLabel()
    }
    
    /// Fade out and remove feedback (for smooth transition)
    public func fadeOutFeedback() {
        // For simplicity, just remove immediately
        // Animation could be added with RealityKit's animation system
        removeAllFeedback()
    }
}

#endif
