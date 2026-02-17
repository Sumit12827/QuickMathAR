//
//  InteractionTypes.swift
//  QuickMathsAR
//
//  Types and configuration for graph interaction
//

import Foundation
import simd
import UIKit

// MARK: - Zoom Configuration

/// Configuration for pinch-to-zoom interaction
public struct ZoomConfiguration {
    /// Minimum allowed zoom scale
    public let minScale: Float
    
    /// Maximum allowed zoom scale
    public let maxScale: Float
    
    /// Sensitivity multiplier for pinch gestures
    public let sensitivity: Float
    
    /// Default configuration with safe limits
    public static let `default` = ZoomConfiguration(
        minScale: 0.3,
        maxScale: 2.5,
        sensitivity: 1.0
    )
    
    public init(minScale: Float, maxScale: Float, sensitivity: Float) {
        self.minScale = max(0.1, minScale)
        self.maxScale = min(5.0, maxScale)
        self.sensitivity = max(0.1, min(2.0, sensitivity))
    }
    
    /// Clamp a zoom scale to valid range
    public func clamp(_ scale: Float) -> Float {
        return max(minScale, min(maxScale, scale))
    }
}

// MARK: - Drag Configuration

/// Configuration for drag-along-curve interaction
public struct DragConfiguration {
    /// Maximum distance (in screen points) to snap to curve
    public let snapThreshold: Float
    
    /// Sampling resolution for nearest-point detection
    public let samplingResolution: Int
    
    /// Maximum distance to travel per gesture update (prevents jumps)
    public let maxDragDelta: Int
    
    /// Default configuration
    public static let `default` = DragConfiguration(
        snapThreshold: 100.0,
        samplingResolution: 5,
        maxDragDelta: 10
    )
    
    public init(snapThreshold: Float, samplingResolution: Int, maxDragDelta: Int) {
        self.snapThreshold = max(10.0, min(200.0, snapThreshold))
        self.samplingResolution = max(1, min(20, samplingResolution))
        self.maxDragDelta = max(1, min(50, maxDragDelta))
    }
}

// MARK: - Curve Region Type

/// Type of region on the curve based on slope
public enum CurveRegionType: String, Sendable {
    /// Region where y increases as x increases (positive slope)
    case increasing
    
    /// Region where y decreases as x increases (negative slope)
    case decreasing
    
    /// Region where y stays approximately constant
    case stationary
}

// MARK: - Curve Point

/// Represents a point on the curve with its region type
public struct CurvePoint: Sendable {
    /// Index in the curve points array
    public let index: Int
    
    /// Mathematical position (x, y)
    public let position: SIMD2<Float>
    
    /// Region type at this point
    public let regionType: CurveRegionType
    
    public init(index: Int, position: SIMD2<Float>, regionType: CurveRegionType) {
        self.index = index
        self.position = position
        self.regionType = regionType
    }
}

// MARK: - Interaction Feedback Colors

/// Colors for visual feedback during interaction
public enum InteractionColors {
    /// Subtle tint for increasing regions (cyan-ish)
    public static let increasing = UIColor(red: 0.4, green: 0.8, blue: 0.9, alpha: 0.7)
    
    /// Subtle tint for decreasing regions (amber-ish)
    public static let decreasing = UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 0.7)
    
    /// Neutral color for stationary regions
    public static let stationary = UIColor(white: 0.7, alpha: 0.5)
    
    /// Position indicator color
    public static let positionIndicator = UIColor(white: 1.0, alpha: 0.9)
    
    /// Label background color
    public static let labelBackground = UIColor(white: 0.1, alpha: 0.8)
}

// MARK: - Slope Threshold

/// Threshold for determining if slope is "stationary"
public let slopeStationaryThreshold: Float = 0.05
