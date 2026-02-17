//
//  ARGraphService.swift
//  QuickMathsAR
//
//  High-level service for AR graph visualization
//

import Foundation

/// Service for creating AR graph visualizations
public final class ARGraphService {
    
    // MARK: - Singleton
    
    public static let shared = ARGraphService()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check if AR visualization is available for an equation type
    public func isARAvailable(for equationType: EquationType) -> Bool {
        switch equationType {
        case .linear, .quadratic:
            return true
        default:
            return false
        }
    }
    
    /// Create graph data from an equation string
    /// - Parameters:
    ///   - equation: The equation string (e.g., "2x + 5 = 13")
    ///   - equationType: The classified equation type
    /// - Returns: Graph data ready for AR visualization, or nil if parsing fails
    public func createGraphData(
        from equation: String,
        equationType: EquationType
    ) -> GraphData? {
        switch equationType {
        case .linear:
            return createLinearGraphData(from: equation)
        case .quadratic:
            return createQuadraticGraphData(from: equation)
        default:
            return nil
        }
    }
    
    /// Create graph data for a linear equation
    public func createLinearGraphData(from equation: String) -> GraphData? {
        guard let linearEquation = EquationParser.parseLinearEquation(equation) else {
            // Fallback: use default example equation
            return createDefaultLinearGraph()
        }
        
        return GraphDataGenerator.generate(
            linear: linearEquation,
            configuration: .linear
        )
    }
    
    /// Create graph data for a quadratic equation
    public func createQuadraticGraphData(from equation: String) -> GraphData? {
        guard let quadraticEquation = EquationParser.parseQuadraticEquation(equation) else {
            // Fallback: use default example equation
            return createDefaultQuadraticGraph()
        }
        
        return GraphDataGenerator.generate(
            quadratic: quadraticEquation,
            configuration: .quadratic
        )
    }
    
    /// Create graph data with explicit linear coefficients
    /// - Parameters:
    ///   - slope: The slope (m)
    ///   - yIntercept: The y-intercept (b)
    /// - Returns: Graph data for y = mx + b
    public func createLinearGraph(slope: Float, yIntercept: Float) -> GraphData {
        let equation = LinearEquation(slope: slope, yIntercept: yIntercept)
        return GraphDataGenerator.generate(linear: equation, configuration: .linear)
    }
    
    /// Create graph data with explicit quadratic coefficients
    /// - Parameters:
    ///   - a: Coefficient of x²
    ///   - b: Coefficient of x
    ///   - c: Constant term
    /// - Returns: Graph data for y = ax² + bx + c
    public func createQuadraticGraph(a: Float, b: Float, c: Float) -> GraphData {
        let equation = QuadraticEquation(a: a, b: b, c: c)
        return GraphDataGenerator.generate(quadratic: equation, configuration: .quadratic)
    }
    
    // MARK: - Default Graphs
    
    /// Default linear graph: y = x (identity line)
    public func createDefaultLinearGraph() -> GraphData {
        return createLinearGraph(slope: 1, yIntercept: 0)
    }
    
    /// Default quadratic graph: y = x² (basic parabola)
    public func createDefaultQuadraticGraph() -> GraphData {
        return createQuadraticGraph(a: 1, b: 0, c: 0)
    }
    
    // MARK: - Example Graphs
    
    /// Sample linear graphs for demonstration
    public var sampleLinearGraphs: [(String, GraphData)] {
        [
            ("y = 2x + 1", createLinearGraph(slope: 2, yIntercept: 1)),
            ("y = -x + 3", createLinearGraph(slope: -1, yIntercept: 3)),
            ("y = 0.5x - 2", createLinearGraph(slope: 0.5, yIntercept: -2)),
            ("y = x", createLinearGraph(slope: 1, yIntercept: 0))
        ]
    }
    
    /// Sample quadratic graphs for demonstration
    public var sampleQuadraticGraphs: [(String, GraphData)] {
        [
            ("y = x²", createQuadraticGraph(a: 1, b: 0, c: 0)),
            ("y = x² - 4", createQuadraticGraph(a: 1, b: 0, c: -4)),
            ("y = -x² + 4", createQuadraticGraph(a: -1, b: 0, c: 4)),
            ("y = x² - 2x - 3", createQuadraticGraph(a: 1, b: -2, c: -3))
        ]
    }
}
