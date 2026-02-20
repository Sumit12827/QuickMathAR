#if os(iOS)
//
//  GraphInteractionState.swift
//  QuickMathsAR
//
//  Centralized state manager for graph interactions
//

import Foundation
import Combine

// MARK: - Graph Interaction State

/// Manages the current state of graph interactions
/// Thread-safe and observable for UI updates
public final class GraphInteractionState: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current zoom scale (1.0 = default)
    @Published public private(set) var zoomScale: Float = 1.0
    
    /// Current curve point index being explored (-1 if none)
    @Published public private(set) var currentCurveIndex: Int = -1
    
    /// Current curve point position (nil if not dragging)
    @Published public private(set) var currentPosition: SIMD2<Float>?
    
    /// Region type at current position
    @Published public private(set) var currentRegionType: CurveRegionType?
    
    /// Whether any interaction is currently active
    @Published public private(set) var isInteractionActive: Bool = false
    
    /// Whether zoom gesture is active
    @Published public private(set) var isZooming: Bool = false
    
    /// Whether drag gesture is active
    @Published public private(set) var isDragging: Bool = false
    
    // MARK: - Configuration
    
    private let zoomConfig: ZoomConfiguration
    private let dragConfig: DragConfiguration
    
    // MARK: - State Backup (for recovery)
    
    private var lastStableZoomScale: Float = 1.0
    private var lastStableCurveIndex: Int = -1
    
    // MARK: - Initialization
    
    public init(
        zoomConfig: ZoomConfiguration = .default,
        dragConfig: DragConfiguration = .default
    ) {
        self.zoomConfig = zoomConfig
        self.dragConfig = dragConfig
    }
    
    // MARK: - Zoom State Updates
    
    /// Begin a zoom gesture
    public func beginZoom() {
        isZooming = true
        isInteractionActive = true
        lastStableZoomScale = zoomScale
    }
    
    /// Update zoom scale during gesture
    /// - Parameter scale: New scale value (will be clamped)
    public func updateZoom(scale: Float) {
        guard isZooming else { return }
        zoomScale = zoomConfig.clamp(scale)
    }
    
    /// Apply scale delta to current zoom
    /// - Parameter delta: Multiplier to apply (e.g., 1.1 for 10% zoom in)
    public func applyZoomDelta(_ delta: Float) {
        guard isZooming else { return }
        let newScale = zoomScale * delta
        zoomScale = zoomConfig.clamp(newScale)
    }
    
    /// End zoom gesture
    public func endZoom() {
        isZooming = false
        lastStableZoomScale = zoomScale
        updateInteractionActiveState()
    }
    
    /// Cancel zoom and revert to last stable state
    public func cancelZoom() {
        zoomScale = lastStableZoomScale
        isZooming = false
        updateInteractionActiveState()
    }
    
    // MARK: - Drag State Updates
    
    /// Begin a drag gesture
    public func beginDrag() {
        isDragging = true
        isInteractionActive = true
        lastStableCurveIndex = currentCurveIndex
    }
    
    /// Update current curve point during drag
    /// - Parameters:
    ///   - index: Index in curve points array
    ///   - position: Mathematical position
    ///   - regionType: Region type at this point
    public func updateDrag(
        index: Int,
        position: SIMD2<Float>,
        regionType: CurveRegionType
    ) {
        guard isDragging else { return }
        
        // Clamp index movement to prevent large jumps
        if lastStableCurveIndex >= 0 {
            let delta = abs(index - lastStableCurveIndex)
            if delta > dragConfig.maxDragDelta {
                // Skip update if jump is too large
                return
            }
        }
        
        currentCurveIndex = index
        currentPosition = position
        currentRegionType = regionType
        lastStableCurveIndex = index
    }
    
    /// End drag gesture
    /// - Parameter keepFeedback: If true, keeps position indicator visible briefly
    public func endDrag(keepFeedback: Bool = false) {
        isDragging = false
        
        if !keepFeedback {
            clearDragState()
        }
        
        updateInteractionActiveState()
    }
    
    /// Cancel drag and clear state
    public func cancelDrag() {
        isDragging = false
        clearDragState()
        updateInteractionActiveState()
    }
    
    // MARK: - State Management
    
    /// Reset all interaction state to defaults
    public func reset() {
        zoomScale = 1.0
        currentCurveIndex = -1
        currentPosition = nil
        currentRegionType = nil
        isInteractionActive = false
        isZooming = false
        isDragging = false
        lastStableZoomScale = 1.0
        lastStableCurveIndex = -1
    }
    
    /// Revert to last known stable state
    public func revertToStableState() {
        zoomScale = lastStableZoomScale
        currentCurveIndex = lastStableCurveIndex
        isZooming = false
        isDragging = false
        updateInteractionActiveState()
    }
    
    // MARK: - Private Helpers
    
    private func clearDragState() {
        currentCurveIndex = -1
        currentPosition = nil
        currentRegionType = nil
    }
    
    private func updateInteractionActiveState() {
        isInteractionActive = isZooming || isDragging
    }
}
#endif
