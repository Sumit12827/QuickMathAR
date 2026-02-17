//
//  ZoomInteractionHandler.swift
//  QuickMathsAR
//
//  Handles pinch-to-zoom gesture for graph scaling
//

import UIKit
import RealityKit

// MARK: - Zoom Interaction Handler

/// Handles pinch-to-zoom gesture on the AR graph
/// Applies uniform scale transformation without rebuilding geometry
public final class ZoomInteractionHandler: NSObject {
    
    // MARK: - Properties
    
    /// The graph root entity to transform
    private weak var graphEntity: Entity?
    
    /// Shared interaction state
    private let state: GraphInteractionState
    
    /// Configuration
    private let config: ZoomConfiguration
    
    /// Initial scale when gesture began
    private var initialScale: Float = 1.0
    
    /// Scale at gesture start for delta calculation
    private var gestureStartScale: Float = 1.0
    
    // MARK: - Initialization
    
    public init(
        state: GraphInteractionState,
        config: ZoomConfiguration = .default
    ) {
        self.state = state
        self.config = config
        super.init()
    }
    
    // MARK: - Configuration
    
    /// Set the graph entity to apply zoom transforms to
    /// - Parameter entity: The root entity of the graph
    public func setGraphEntity(_ entity: Entity?) {
        self.graphEntity = entity
    }
    
    // MARK: - Gesture Handling
    
    /// Create and return a configured pinch gesture recognizer
    public func createGestureRecognizer() -> UIPinchGestureRecognizer {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        return gesture
    }
    
    /// Handle pinch gesture
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard graphEntity != nil else { return }
        
        switch gesture.state {
        case .began:
            beginZoom()
            
        case .changed:
            updateZoom(gestureScale: Float(gesture.scale))
            
        case .ended:
            endZoom()
            
        case .cancelled, .failed:
            cancelZoom()
            
        default:
            break
        }
    }
    
    // MARK: - Zoom Operations
    
    private func beginZoom() {
        initialScale = state.zoomScale
        gestureStartScale = state.zoomScale
        state.beginZoom()
    }
    
    private func updateZoom(gestureScale: Float) {
        // Calculate new scale based on initial scale and gesture delta
        let newScale = initialScale * gestureScale
        let clampedScale = config.clamp(newScale)
        
        // Update state
        state.updateZoom(scale: clampedScale)
        
        // Apply transform to entity
        applyZoomTransform(scale: clampedScale)
    }
    
    private func endZoom() {
        state.endZoom()
    }
    
    private func cancelZoom() {
        // Revert to scale before gesture started
        applyZoomTransform(scale: gestureStartScale)
        state.cancelZoom()
    }
    
    /// Apply uniform scale to the graph entity
    private func applyZoomTransform(scale: Float) {
        guard let entity = graphEntity else { return }
        
        // Apply uniform scale on all axes to preserve proportions
        entity.scale = SIMD3<Float>(repeating: scale)
    }
    
    // MARK: - Public API
    
    /// Reset zoom to default scale
    public func resetZoom() {
        state.updateZoom(scale: 1.0)
        applyZoomTransform(scale: 1.0)
    }
    
    /// Check if zoom interaction is available
    public var isAvailable: Bool {
        return graphEntity != nil
    }
}
