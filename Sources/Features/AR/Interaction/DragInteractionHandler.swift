//
//  DragInteractionHandler.swift
//  QuickMathsAR
//
//  Handles drag-along-curve gesture for exploring graph
//

import UIKit
import RealityKit
import simd

// MARK: - Drag Interaction Handler

/// Handles drag gesture constrained to the curve
/// Finds nearest point on precomputed curve points
public final class DragInteractionHandler: NSObject {
    
    // MARK: - Properties
    
    /// The AR view for coordinate conversion
    private weak var arView: ARView?
    
    /// The graph root entity
    private weak var graphEntity: Entity?
    
    /// Shared interaction state
    private let state: GraphInteractionState
    
    /// Configuration
    private let config: DragConfiguration
    
    /// Precomputed curve points from graph data
    private var curvePoints: [SIMD2<Float>] = []
    
    /// Curve analyzer for region detection
    private var curveAnalyzer: CurveAnalyzer?
    
    /// World scale from graph configuration
    private var worldScale: Float = 0.05
    
    /// Callback when drag position updates
    public var onDragUpdate: ((CurvePoint) -> Void)?
    
    /// Callback when drag ends
    public var onDragEnd: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(
        state: GraphInteractionState,
        config: DragConfiguration = .default
    ) {
        self.state = state
        self.config = config
        super.init()
    }
    
    // MARK: - Configuration
    
    /// Configure the handler with graph data
    /// - Parameters:
    ///   - arView: The AR view for coordinate conversions
    ///   - graphEntity: The graph root entity
    ///   - graphData: The graph data containing curve points
    public func configure(
        arView: ARView,
        graphEntity: Entity,
        graphData: GraphData
    ) {
        self.arView = arView
        self.graphEntity = graphEntity
        self.curvePoints = graphData.curvePoints
        self.worldScale = graphData.configuration.worldScale
        self.curveAnalyzer = CurveAnalyzer(curvePoints: graphData.curvePoints)
    }
    
    /// Clear configuration
    public func clearConfiguration() {
        arView = nil
        graphEntity = nil
        curvePoints = []
        curveAnalyzer = nil
    }
    
    // MARK: - Gesture Handling
    
    /// Create and return a configured pan gesture recognizer
    public func createGestureRecognizer() -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        return gesture
    }
    
    /// Handle pan gesture
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = arView,
              graphEntity != nil,
              !curvePoints.isEmpty else { return }
        
        switch gesture.state {
        case .began:
            beginDrag(at: gesture.location(in: arView))
            
        case .changed:
            updateDrag(at: gesture.location(in: arView))
            
        case .ended:
            endDrag()
            
        case .cancelled, .failed:
            cancelDrag()
            
        default:
            break
        }
    }
    
    // MARK: - Drag Operations
    
    private func beginDrag(at screenPoint: CGPoint) {
        state.beginDrag()
        updateDrag(at: screenPoint)
    }
    
    private func updateDrag(at screenPoint: CGPoint) {
        guard let nearestPoint = findNearestCurvePoint(to: screenPoint) else { return }
        
        // Get region type from analyzer
        let regionType = curveAnalyzer?.region(at: nearestPoint.index) ?? .stationary
        
        // Update state
        state.updateDrag(
            index: nearestPoint.index,
            position: nearestPoint.position,
            regionType: regionType
        )
        
        // Create curve point and notify
        let curvePoint = CurvePoint(
            index: nearestPoint.index,
            position: nearestPoint.position,
            regionType: regionType
        )
        onDragUpdate?(curvePoint)
    }
    
    private func endDrag() {
        state.endDrag(keepFeedback: true)
        onDragEnd?()
    }
    
    private func cancelDrag() {
        state.cancelDrag()
        onDragEnd?()
    }
    
    // MARK: - Nearest Point Detection
    
    /// Find the nearest curve point to a screen location
    private func findNearestCurvePoint(to screenPoint: CGPoint) -> (index: Int, position: SIMD2<Float>)? {
        guard let arView = arView,
              let graphEntity = graphEntity,
              !curvePoints.isEmpty else { return nil }
        
        var nearestIndex = 0
        var nearestDistanceSquared: Float = .infinity
        
        // Get graph entity world transform
        let graphWorldTransform = graphEntity.transformMatrix(relativeTo: nil)
        
        // Sample curve points at configured resolution
        let step = max(1, curvePoints.count / config.samplingResolution)
        
        for i in stride(from: 0, to: curvePoints.count, by: step) {
            let mathPoint = curvePoints[i]
            
            // Convert to world position
            let worldPos = SIMD3<Float>(
                mathPoint.x * worldScale,
                mathPoint.y * worldScale,
                0
            )
            let transformedWorldPos = graphWorldTransform * SIMD4<Float>(worldPos.x, worldPos.y, worldPos.z, 1.0)
            
            // Project to screen
            guard let screenPos = arView.project(
                SIMD3<Float>(transformedWorldPos.x, transformedWorldPos.y, transformedWorldPos.z)
            ) else { continue }
            
            // Calculate distance
            let dx = Float(screenPoint.x) - Float(screenPos.x)
            let dy = Float(screenPoint.y) - Float(screenPos.y)
            let distSquared = dx * dx + dy * dy
            
            if distSquared < nearestDistanceSquared {
                nearestDistanceSquared = distSquared
                nearestIndex = i
            }
        }
        
        // Check if within snap threshold
        let nearestDistance = sqrt(nearestDistanceSquared)
        if nearestDistance > config.snapThreshold {
            return nil
        }
        
        // Refine by checking neighbors
        let refinedIndex = refineNearestIndex(from: nearestIndex, screenPoint: screenPoint)
        
        return (refinedIndex, curvePoints[refinedIndex])
    }
    
    /// Refine the nearest index by checking immediate neighbors
    private func refineNearestIndex(from baseIndex: Int, screenPoint: CGPoint) -> Int {
        guard let arView = arView,
              let graphEntity = graphEntity else { return baseIndex }
        
        let graphWorldTransform = graphEntity.transformMatrix(relativeTo: nil)
        var bestIndex = baseIndex
        var bestDistSquared: Float = .infinity
        
        // Check a small window around the base index
        let windowSize = max(1, curvePoints.count / config.samplingResolution)
        let startIdx = max(0, baseIndex - windowSize)
        let endIdx = min(curvePoints.count - 1, baseIndex + windowSize)
        
        for i in startIdx...endIdx {
            let mathPoint = curvePoints[i]
            let worldPos = SIMD3<Float>(
                mathPoint.x * worldScale,
                mathPoint.y * worldScale,
                0
            )
            let transformedWorldPos = graphWorldTransform * SIMD4<Float>(worldPos.x, worldPos.y, worldPos.z, 1.0)
            
            guard let screenPos = arView.project(
                SIMD3<Float>(transformedWorldPos.x, transformedWorldPos.y, transformedWorldPos.z)
            ) else { continue }
            
            let dx = Float(screenPoint.x) - Float(screenPos.x)
            let dy = Float(screenPoint.y) - Float(screenPos.y)
            let distSquared = dx * dx + dy * dy
            
            if distSquared < bestDistSquared {
                bestDistSquared = distSquared
                bestIndex = i
            }
        }
        
        return bestIndex
    }
    
    // MARK: - Public API
    
    /// Check if drag interaction is available
    public var isAvailable: Bool {
        return graphEntity != nil && !curvePoints.isEmpty
    }
    
    /// Reset drag state
    public func reset() {
        state.cancelDrag()
    }
}
