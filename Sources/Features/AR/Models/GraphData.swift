//
//  GraphData.swift
//  QuickMathsAR
//
//  Mathematical models for graph visualization
//

import Foundation
import simd

// MARK: - Graph Types

/// Supported equation types for AR visualization
public enum GraphEquationType: String, Sendable {
    case linear
    case quadratic
}

// MARK: - Linear Equation

/// Represents a linear equation in the form: y = mx + b
/// - m: slope
/// - b: y-intercept
public struct LinearEquation: Sendable {
    public let slope: Float       // m
    public let yIntercept: Float  // b
    
    public init(slope: Float, yIntercept: Float) {
        self.slope = slope
        self.yIntercept = yIntercept
    }
    
    /// Calculate y value for a given x
    public func evaluate(at x: Float) -> Float {
        return slope * x + yIntercept
    }
    
    /// Calculate x-intercept (where y = 0)
    /// Returns nil if the line is horizontal (slope = 0) and doesn't cross x-axis
    public var xIntercept: Float? {
        guard abs(slope) > .ulpOfOne else {
            // Horizontal line - only intercepts if b = 0
            return abs(yIntercept) < .ulpOfOne ? 0 : nil
        }
        return -yIntercept / slope
    }
}

// MARK: - Quadratic Equation

/// Represents a quadratic equation in the form: y = ax² + bx + c
/// - a: coefficient of x² (must be non-zero)
/// - b: coefficient of x
/// - c: constant term
public struct QuadraticEquation: Sendable {
    public let a: Float  // coefficient of x²
    public let b: Float  // coefficient of x
    public let c: Float  // constant
    
    public init(a: Float, b: Float, c: Float) {
        self.a = a
        self.b = b
        self.c = c
    }
    
    /// Calculate y value for a given x
    public func evaluate(at x: Float) -> Float {
        return a * x * x + b * x + c
    }
    
    /// X-coordinate of the vertex
    public var vertexX: Float {
        guard abs(a) > .ulpOfOne else { return 0 }
        return -b / (2 * a)
    }
    
    /// Y-coordinate of the vertex
    public var vertexY: Float {
        return evaluate(at: vertexX)
    }
    
    /// Vertex point (minimum or maximum of the parabola)
    public var vertex: SIMD2<Float> {
        return SIMD2(vertexX, vertexY)
    }
    
    /// Discriminant (b² - 4ac) - determines number of x-intercepts
    public var discriminant: Float {
        return b * b - 4 * a * c
    }
    
    /// X-intercepts (roots) of the equation
    /// Returns 0, 1, or 2 values depending on discriminant
    public var xIntercepts: [Float] {
        guard abs(a) > .ulpOfOne else { return [] }
        
        let disc = discriminant
        
        if disc < -Float.ulpOfOne {
            // No real roots
            return []
        } else if abs(disc) < Float.ulpOfOne {
            // One root (vertex touches x-axis)
            return [vertexX]
        } else {
            // Two roots
            let sqrtDisc = sqrt(disc)
            let x1 = (-b + sqrtDisc) / (2 * a)
            let x2 = (-b - sqrtDisc) / (2 * a)
            return [min(x1, x2), max(x1, x2)]
        }
    }
    
    /// Y-intercept (where x = 0)
    public var yIntercept: Float {
        return c
    }
}

// MARK: - Graph Configuration

/// Configuration for graph rendering
public struct GraphConfiguration: Sendable {
    /// Range of x values to display
    public let xRange: ClosedRange<Float>
    
    /// Range of y values to display
    public let yRange: ClosedRange<Float>
    
    /// Number of sample points for curve rendering
    public let sampleCount: Int
    
    /// Scale factor for AR world units (meters)
    public let worldScale: Float
    
    /// Grid line spacing
    public let gridSpacing: Float
    
    /// Whether to show grid lines
    public let showGrid: Bool
    
    public init(
        xRange: ClosedRange<Float> = -5...5,
        yRange: ClosedRange<Float> = -5...5,
        sampleCount: Int = 100,
        worldScale: Float = 0.07,  // 1 unit = 7cm → ~0.7m graph width
        gridSpacing: Float = 1.0,
        showGrid: Bool = true
    ) {
        self.xRange = xRange
        self.yRange = yRange
        self.sampleCount = max(10, sampleCount)
        self.worldScale = worldScale
        self.gridSpacing = gridSpacing
        self.showGrid = showGrid
    }
    
    /// Default configuration for linear equations
    public static let linear = GraphConfiguration(
        xRange: -5...5,
        yRange: -5...5,
        sampleCount: 50
    )
    
    /// Default configuration for quadratic equations
    public static let quadratic = GraphConfiguration(
        xRange: -6...6,
        yRange: -4...10,
        sampleCount: 100
    )
}

// MARK: - Key Point

/// Represents an important point on the graph
public struct KeyPoint: Identifiable, Sendable {
    public let id = UUID()
    public let position: SIMD2<Float>
    public let type: KeyPointType
    public let label: String?
    
    public init(position: SIMD2<Float>, type: KeyPointType, label: String? = nil) {
        self.position = position
        self.type = type
        self.label = label
    }
}

/// Types of key points
public enum KeyPointType: String, Sendable {
    case xIntercept = "x-intercept"
    case yIntercept = "y-intercept"
    case vertex = "vertex"
    case origin = "origin"
}

// MARK: - Graph Data

/// Complete data for rendering a graph
public struct GraphData: Sendable {
    /// The type of equation
    public let equationType: GraphEquationType
    
    /// Sample points along the curve (in mathematical coordinates)
    public let curvePoints: [SIMD2<Float>]
    
    /// Key points to highlight
    public let keyPoints: [KeyPoint]
    
    /// Configuration used to generate this data
    public let configuration: GraphConfiguration
    
    public init(
        equationType: GraphEquationType,
        curvePoints: [SIMD2<Float>],
        keyPoints: [KeyPoint],
        configuration: GraphConfiguration
    ) {
        self.equationType = equationType
        self.curvePoints = curvePoints
        self.keyPoints = keyPoints
        self.configuration = configuration
    }
}

// MARK: - Graph Data Generator

/// Generates graph data from equations
public enum GraphDataGenerator {
    
    /// Generate graph data for a linear equation
    public static func generate(
        linear equation: LinearEquation,
        configuration: GraphConfiguration = .linear
    ) -> GraphData {
        // Generate curve points
        var curvePoints: [SIMD2<Float>] = []
        let step = (configuration.xRange.upperBound - configuration.xRange.lowerBound) / Float(configuration.sampleCount)
        
        var x = configuration.xRange.lowerBound
        while x <= configuration.xRange.upperBound {
            let y = equation.evaluate(at: x)
            if configuration.yRange.contains(y) {
                curvePoints.append(SIMD2(x, y))
            }
            x += step
        }
        
        // Generate key points
        var keyPoints: [KeyPoint] = []
        
        // Y-intercept
        if configuration.xRange.contains(0) && configuration.yRange.contains(equation.yIntercept) {
            keyPoints.append(KeyPoint(
                position: SIMD2(0, equation.yIntercept),
                type: .yIntercept,
                label: "y-int"
            ))
        }
        
        // X-intercept
        if let xInt = equation.xIntercept,
           configuration.xRange.contains(xInt) && configuration.yRange.contains(0) {
            keyPoints.append(KeyPoint(
                position: SIMD2(xInt, 0),
                type: .xIntercept,
                label: "x-int"
            ))
        }
        
        return GraphData(
            equationType: .linear,
            curvePoints: curvePoints,
            keyPoints: keyPoints,
            configuration: configuration
        )
    }
    
    /// Generate graph data for a quadratic equation
    public static func generate(
        quadratic equation: QuadraticEquation,
        configuration: GraphConfiguration = .quadratic
    ) -> GraphData {
        // Generate curve points
        var curvePoints: [SIMD2<Float>] = []
        let step = (configuration.xRange.upperBound - configuration.xRange.lowerBound) / Float(configuration.sampleCount)
        
        var x = configuration.xRange.lowerBound
        while x <= configuration.xRange.upperBound {
            let y = equation.evaluate(at: x)
            // Clamp to visible range but still include point for continuity
            let clampedY = min(max(y, configuration.yRange.lowerBound - 1), configuration.yRange.upperBound + 1)
            curvePoints.append(SIMD2(x, clampedY))
            x += step
        }
        
        // Generate key points
        var keyPoints: [KeyPoint] = []
        
        // Vertex
        let vertex = equation.vertex
        if configuration.xRange.contains(vertex.x) && configuration.yRange.contains(vertex.y) {
            keyPoints.append(KeyPoint(
                position: vertex,
                type: .vertex,
                label: "vertex"
            ))
        }
        
        // Y-intercept
        if configuration.xRange.contains(0) && configuration.yRange.contains(equation.yIntercept) {
            keyPoints.append(KeyPoint(
                position: SIMD2(0, equation.yIntercept),
                type: .yIntercept,
                label: "y-int"
            ))
        }
        
        // X-intercepts
        for xInt in equation.xIntercepts {
            if configuration.xRange.contains(xInt) && configuration.yRange.contains(0) {
                keyPoints.append(KeyPoint(
                    position: SIMD2(xInt, 0),
                    type: .xIntercept,
                    label: "x-int"
                ))
            }
        }
        
        return GraphData(
            equationType: .quadratic,
            curvePoints: curvePoints,
            keyPoints: keyPoints,
            configuration: configuration
        )
    }
}
