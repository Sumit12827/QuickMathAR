//
//  CurveAnalyzer.swift
//  QuickMathsAR
//
//  Analyzes curve for increasing/decreasing regions
//

#if os(iOS)

import Foundation
import simd

// MARK: - Curve Analyzer

/// Precomputes and provides region type information for curve points
/// Analyzes slope between consecutive points to determine regions
public final class CurveAnalyzer {
    
    // MARK: - Properties
    
    /// Precomputed region types for each curve point
    private let regionTypes: [CurveRegionType]
    
    /// Number of points analyzed
    public let pointCount: Int
    
    // MARK: - Initialization
    
    /// Initialize analyzer with curve points
    /// - Parameter curvePoints: Array of (x, y) points along the curve
    public init(curvePoints: [SIMD2<Float>]) {
        self.pointCount = curvePoints.count
        self.regionTypes = CurveAnalyzer.analyzeRegions(curvePoints: curvePoints)
    }
    
    // MARK: - Public API
    
    /// Get region type at a specific curve index
    /// - Parameter index: Index in the curve points array
    /// - Returns: Region type (increasing, decreasing, or stationary)
    public func region(at index: Int) -> CurveRegionType {
        guard index >= 0 && index < regionTypes.count else {
            return .stationary
        }
        return regionTypes[index]
    }
    
    /// Get a range of region types
    /// - Parameters:
    ///   - startIndex: Start index (inclusive)
    ///   - endIndex: End index (exclusive)
    /// - Returns: Array of region types in range
    public func regions(from startIndex: Int, to endIndex: Int) -> [CurveRegionType] {
        let safeStart = max(0, startIndex)
        let safeEnd = min(regionTypes.count, endIndex)
        
        guard safeStart < safeEnd else { return [] }
        
        return Array(regionTypes[safeStart..<safeEnd])
    }
    
    /// Find indices where region type changes
    /// - Returns: Array of indices where the region type transitions
    public func findRegionTransitions() -> [Int] {
        var transitions: [Int] = []
        
        for i in 1..<regionTypes.count {
            if regionTypes[i] != regionTypes[i - 1] {
                transitions.append(i)
            }
        }
        
        return transitions
    }
    
    /// Get segment indices for a specific region type
    /// - Parameter type: The region type to find
    /// - Returns: Array of (startIndex, endIndex) tuples for segments of this type
    public func segments(of type: CurveRegionType) -> [(start: Int, end: Int)] {
        var segments: [(start: Int, end: Int)] = []
        var segmentStart: Int?
        
        for i in 0..<regionTypes.count {
            if regionTypes[i] == type {
                if segmentStart == nil {
                    segmentStart = i
                }
            } else {
                if let start = segmentStart {
                    segments.append((start, i))
                    segmentStart = nil
                }
            }
        }
        
        // Handle segment that goes to end
        if let start = segmentStart {
            segments.append((start, regionTypes.count))
        }
        
        return segments
    }
    
    // MARK: - Static Analysis
    
    /// Analyze curve points to determine region types
    private static func analyzeRegions(curvePoints: [SIMD2<Float>]) -> [CurveRegionType] {
        guard curvePoints.count >= 2 else {
            return curvePoints.map { _ in .stationary }
        }
        
        var regions: [CurveRegionType] = []
        
        for i in 0..<curvePoints.count {
            let regionType = determineRegionType(
                at: i,
                curvePoints: curvePoints
            )
            regions.append(regionType)
        }
        
        return regions
    }
    
    /// Determine region type at a specific index using local slope
    private static func determineRegionType(
        at index: Int,
        curvePoints: [SIMD2<Float>]
    ) -> CurveRegionType {
        // Calculate slope using neighboring points for smoothness
        let prevIndex = max(0, index - 1)
        let nextIndex = min(curvePoints.count - 1, index + 1)
        
        let prevPoint = curvePoints[prevIndex]
        let nextPoint = curvePoints[nextIndex]
        
        // Calculate dx and dy
        let dx = nextPoint.x - prevPoint.x
        let dy = nextPoint.y - prevPoint.y
        
        // Avoid division by zero
        guard abs(dx) > Float.ulpOfOne else {
            return .stationary
        }
        
        let slope = dy / dx
        
        // Determine region based on slope
        if slope > slopeStationaryThreshold {
            return .increasing
        } else if slope < -slopeStationaryThreshold {
            return .decreasing
        } else {
            return .stationary
        }
    }
}

// MARK: - Curve Region Info

/// Information about a continuous region on the curve
public struct CurveRegionInfo {
    /// Start index in curve points
    public let startIndex: Int
    
    /// End index in curve points (exclusive)
    public let endIndex: Int
    
    /// Type of this region
    public let type: CurveRegionType
    
    /// Number of points in this region
    public var pointCount: Int {
        return endIndex - startIndex
    }
}

#endif
