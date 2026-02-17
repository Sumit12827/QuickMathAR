//
//  GraphInteractionViewModel.swift
//  QuickMathsAR
//
//  Manages state for interactive graph modification
//

import Foundation
import Combine
import SwiftUI

/// View model for handling interactive graph parameters
public class GraphInteractionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current equation type
    @Published public var equationType: GraphEquationType
    
    // Linear Parameters
    @Published public var slope: Float = 1.0 { didSet { updateGraph() } }
    @Published public var yIntercept: Float = 0.0 { didSet { updateGraph() } }
    
    // Quadratic Parameters
    @Published public var quadA: Float = 1.0 { didSet { updateGraph() } }
    @Published public var quadB: Float = 0.0 { didSet { updateGraph() } }
    @Published public var quadC: Float = 0.0 { didSet { updateGraph() } }
    
    /// The generated graph data based on current parameters
    @Published public private(set) var graphData: GraphData?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(initialData: GraphData) {
        self.equationType = initialData.equationType
        self.graphData = initialData
        
        // Initialize parameters based on input data if possible
        // For now, we start with defaults or could parse the equation if we had the raw equation models accessible easily
        // But since GraphData is already compiled points, we might just settle for defaults or need a way to reverse engineer or pass equation in.
        // For this specific task, we'll initialize with reasonable defaults for interaction.
        
        switch initialData.equationType {
        case .linear:
            self.slope = 1.0
            self.yIntercept = 0.0
        case .quadratic:
            self.quadA = 1.0
            self.quadB = 0.0
            self.quadC = 0.0
        }
        
        updateGraph()
    }
    
    // MARK: - Updates
    
    private func updateGraph() {
        // Debounce or generate immediately? For AR, 60fps might be too heavy for full mesh regen, 
        // but GraphDataGenerator is pure math, so it's fast. 
        // The heavier part is RealityKit mesh generation, which happens in the Controller.
        
        let newGraphData: GraphData
        
        switch equationType {
        case .linear:
            let equation = LinearEquation(slope: slope, yIntercept: yIntercept)
            newGraphData = GraphDataGenerator.generate(linear: equation, configuration: .linear)
            
        case .quadratic:
            let equation = QuadraticEquation(a: quadA, b: quadB, c: quadC)
            newGraphData = GraphDataGenerator.generate(quadratic: equation, configuration: .quadratic)
        }
        
        self.graphData = newGraphData
    }
    
    /// Resets parameters to standard form
    public func reset() {
        switch equationType {
        case .linear:
            slope = 1.0
            yIntercept = 0.0
        case .quadratic:
            quadA = 1.0
            quadB = 0.0
            quadC = 0.0
        }
    }
}
