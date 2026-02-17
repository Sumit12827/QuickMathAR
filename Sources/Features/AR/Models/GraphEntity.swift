import RealityKit
import SwiftUI
import Combine

// MARK: - Graph Entity

/// Lightweight wrapper entity for the AR graph.
/// The actual geometry is built by `GraphGeometryBuilder`.
/// This entity provides the anchoring and collision interface.
class GraphEntity: Entity, HasAnchoring, HasCollision {
    
    required init() {
        super.init()
    }
    
    /// Rebuild graph geometry from data using the builder.
    func buildFrom(data: GraphData) {
        // Clear existing children
        children.forEach { $0.removeFromParent() }
        
        let builder = GraphGeometryBuilder(configuration: data.configuration)
        let graphContent = builder.buildGraph(from: data)
        addChild(graphContent)
        
        // Generate collision shapes for all child geometry
        generateCollisionShapes(recursive: true)
    }
}

// MARK: - Material Helper
extension SimpleMaterial {
    static let graphNeon = SimpleMaterial(color: .cyan, isMetallic: false)
    static let graphPurple = SimpleMaterial(color: .purple, isMetallic: false)
}
