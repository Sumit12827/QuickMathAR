import SwiftUI
import RealityKit
import ARKit

// MARK: - Legacy AR Placement State (used only by this placeholder view)
enum LegacyARPlacementState {
    case scanning
    case placement
    case postPlacement
}

// MARK: - AR Visualization View
struct ARVisualizationView: UIViewRepresentable {
    @Binding var state: LegacyARPlacementState
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure Session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        
        // Set up Coordinator
        context.coordinator.arView = arView
        arView.session.delegate = context.coordinator
        
        // Add Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Handle state updates if needed
        if state == .scanning {
             // Show scanning visual
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARVisualizationView
        weak var arView: ARView?
        
        // Cinematics
        private var axesEntity: ModelEntity?
        private var gridEntity: ModelEntity?
        private var graphCurveEntity: ModelEntity?
        
        init(_ parent: ARVisualizationView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView, parent.state == .scanning else { return }
            
            let location = gesture.location(in: arView)
            
            // Raycast for horizontal plane
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let result = results.first {
                // Transition State
                withAnimation {
                    parent.state = .placement
                }
                
                // Trigger Placement Sequence
                placeAnchor(at: result.worldTransform)
            }
        }
        
        private func placeAnchor(at transform: simd_float4x4) {
            guard let arView = arView else { return }
            
            let anchor = AnchorEntity(world: transform)
            arView.scene.anchors.append(anchor)
            
            // Haptic Start
            HapticManager.shared.play(.heavy)
            
            // Start Cinematic Birth Sequence
            startEquationBirthSequence(on: anchor)
        }
        
        private func startEquationBirthSequence(on anchor: AnchorEntity) {
            // Phase 1: Grid Draw (Self-executing)
            let gridMesh = MeshResource.generatePlane(width: 1.0, depth: 1.0)
            let gridMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.1), isMetallic: false)
            let grid = ModelEntity(mesh: gridMesh, materials: [gridMaterial])

            anchor.addChild(grid)
            self.gridEntity = grid
            
            // Animate Grid In
            var gridTransform = grid.transform
            gridTransform.scale = .zero
            grid.move(to: gridTransform, relativeTo: anchor, duration: 0)
            
            gridTransform.scale = .one
            grid.move(to: gridTransform, relativeTo: anchor, duration: 0.6, timingFunction: .easeInOut)
            
            // Phase 2: Axes (Simulated Draw)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let axisMesh = MeshResource.generateBox(size: SIMD3<Float>(0.01, 1.0, 0.01)) // Vertical
                let axisMaterial = UnlitMaterial(color: .white)
                let axis = ModelEntity(mesh: axisMesh, materials: [axisMaterial])
                axis.position.y = 0.5
                anchor.addChild(axis)
                self.axesEntity = axis
                
                HapticManager.shared.play(.medium)
            }
            
            // Phase 3: Curve (Simulated Draw)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                // Placeholder for curve generation
                // Real implementation would use mesh generation from points
                let sphere = MeshResource.generateSphere(radius: 0.05)
                let material = SimpleMaterial(color: .cyan, isMetallic: false)
                let curvePoint = ModelEntity(mesh: sphere, materials: [material])
                curvePoint.position.y = 0.5
                anchor.addChild(curvePoint)
                self.graphCurveEntity = curvePoint
                
                // Final Lock Haptic
                HapticManager.shared.play(.success)
                
                // State Transition
                withAnimation {
                    self.parent.state = .postPlacement
                }
            }
        }
    }
}
