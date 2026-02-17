//
//  ARGraphViewController.swift
//  QuickMathsAR
//
//  Manages the AR session, graph visualization, and interaction.
//  Handles plane detection -> ghost preview -> tap-to-place flow.
//  Supports pinch-to-scale and rotation gestures after placement.
//

import UIKit
import RealityKit
import ARKit
import Combine

/// State of the AR placement workflow
private enum ARPlacementState {
    case scanning
    case placing // Ghost mode
    case placed  // Anchored
}

/// Manages AR graph visualization with RealityKit
public final class ARGraphViewController: UIViewController, ARSessionDelegate {

    // MARK: - Properties

    /// The AR view
    private var arView: ARView!

    /// View Model for graph interaction
    private var viewModel: GraphInteractionViewModel?

    /// The geometry builder
    private var geometryBuilder: GraphGeometryBuilder?

    /// Current placement state
    private var placementState: ARPlacementState = .scanning

    /// The current graph anchor (when placed)
    private var graphAnchor: AnchorEntity?

    /// The ghost anchor (during placement)
    private var ghostAnchor: AnchorEntity?

    /// The graph entity currently displayed (ghost or placed)
    private var currentGraphEntity: Entity?

    /// Coaching overlay for guiding the user
    private var coachingOverlay: ARCoachingOverlayView?

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Shadow/occlusion plane entity
    private var shadowPlane: ModelEntity?

    /// Stored initial scale for smooth pinch gesture
    private var initialPinchScale: Float = 1.0

    // MARK: - Callbacks

    /// Callback when graph is placed
    public var onGraphPlaced: (() -> Void)?

    /// Callback for AR errors
    public var onError: ((ARGraphError) -> Void)?

    /// Callback for AR status updates (for UI display)
    public var onStatusUpdate: ((String) -> Void)?

    // MARK: - Interaction Layer

    private var feedbackController = VisualFeedbackController()

    // MARK: - Initialization

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupCoachingOverlay()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraPermissionAndStart()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseARSession()
    }

    // MARK: - Configuration

    /// Configure with a ViewModel
    public func configure(with viewModel: GraphInteractionViewModel) {
        self.viewModel = viewModel

        // Initial geometry builder setup
        if let data = viewModel.graphData {
            self.geometryBuilder = GraphGeometryBuilder(configuration: data.configuration)
        }

        // Subscribe to updates
        bindViewModel()

        // If we are already placed, trigger a geometry update
        if placementState == .placed, let data = viewModel.graphData, let entity = currentGraphEntity {
            geometryBuilder?.updateCurve(in: entity, with: data)
        }
    }

    private func bindViewModel() {
        // Debounce updates to avoid excessive mesh generation
        viewModel?.$graphData
            .compactMap { $0 }
            .throttle(for: DispatchQueue.SchedulerTimeType.Stride.milliseconds(80), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] data in
                self?.updateGraphGeometry(with: data)
            }
            .store(in: &cancellables)
    }

    private func updateGraphGeometry(with data: GraphData) {
        guard let geometryBuilder = geometryBuilder, let entity = currentGraphEntity else { return }

        // Efficiently update just the dynamic parts (curve + key points)
        geometryBuilder.updateCurve(in: entity, with: data)
    }

    // MARK: - Setup

    private func setupARView() {
        arView = ARView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)

        // Configure AR view
        arView.environment.background = .cameraFeed()
        arView.session.delegate = self

        // Enable automatic environment lighting for realistic materials
        arView.environment.lighting.intensityExponent = 1.0

        // Disable motion blur for crisp rendering
        arView.renderOptions.insert(.disableMotionBlur)

        // Tap gesture for placement and point inspection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        // Pinch gesture for scaling (0.3x - 2.5x range)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        arView.addGestureRecognizer(pinchGesture)

        // Rotation gesture for Y-axis rotation
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        arView.addGestureRecognizer(rotationGesture)
    }

    private func setupCoachingOverlay() {
        let overlay = ARCoachingOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.session = arView.session
        overlay.goal = .horizontalPlane
        overlay.activatesAutomatically = true
        overlay.delegate = self
        arView.addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: arView.centerYAnchor),
            overlay.widthAnchor.constraint(equalTo: arView.widthAnchor),
            overlay.heightAnchor.constraint(equalTo: arView.heightAnchor)
        ])
        
        coachingOverlay = overlay
    }

    // MARK: - Session Management

    private func checkCameraPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startARSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startARSession()
                    } else {
                        self?.onError?(.cameraPermissionDenied)
                    }
                }
            }
        case .denied, .restricted:
            onError?(.cameraPermissionDenied)
        @unknown default:
            onError?(.cameraPermissionDenied)
        }
    }

    private func startARSession() {
        #if targetEnvironment(simulator)
        onStatusUpdate?("AR Simulator Mode")
        return
        #else
        guard ARWorldTrackingConfiguration.isSupported else {
            onError?(.arNotSupported)
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true

        // Enable scene depth if available (LiDAR)
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }

        // Enable scene reconstruction if available (LiDAR)
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        #endif
    }

    private func pauseARSession() {
        arView.session.pause()
    }

    // MARK: - ARSessionDelegate & Game Loop

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update ghost graph position if in placing mode
        if placementState == .placing {
            updateGhostPosition()
        }
    }

    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            if placementState == .scanning {
                onStatusUpdate?("Scan floor to place graph")
            }
        case .notAvailable:
            onStatusUpdate?("Tracking unavailable")
        case .limited(let reason):
            onStatusUpdate?("Tracking limited: \(reason)")
        }
    }

    public func session(_ session: ARSession, didFailWithError error: Error) {
        onError?(.sessionFailed(error))
    }

    // MARK: - Placement Logic

    private func updateGhostPosition() {
        // Raycast from screen center to find a plane
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let results = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal)

        if let result = results.first {
            if ghostAnchor == nil {
                createGhostGraph()
            }

            // Smooth ghost movement
            let transform = Transform(matrix: result.worldTransform)
            ghostAnchor?.move(to: transform, relativeTo: nil, duration: 0.1)

            currentGraphEntity?.isEnabled = true
            onStatusUpdate?("Tap to place")
        } else {
            onStatusUpdate?("Point at floor")
        }
    }

    private func createGhostGraph() {
        guard let data = viewModel?.graphData else { return }

        // Create anchor
        let anchor = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(anchor)
        ghostAnchor = anchor

        // Build graph with builder
        let builder = GraphGeometryBuilder(configuration: data.configuration)
        self.geometryBuilder = builder
        let graphEntity = builder.buildGraph(from: data)

        // Auto-scale ghost to same target size
        let fitScale = computeFitScale(for: graphEntity, targetSize: 0.7)
        graphEntity.scale = SIMD3<Float>(repeating: fitScale)

        // Ghost effect: reduce opacity on all model entities
        applyGhostEffect(to: graphEntity)

        anchor.addChild(graphEntity)
        currentGraphEntity = graphEntity

        // Add lighting
        addLighting(to: anchor)
    }

    /// Recursively make entities semi-transparent for ghost preview.
    /// Converts PBR materials to simple transparent materials.
    private func applyGhostEffect(to entity: Entity) {
        if let modelEntity = entity as? ModelEntity,
           let model = modelEntity.model {
            var ghostMaterials: [Material] = []
            for material in model.materials {
                if let pbrMat = material as? PhysicallyBasedMaterial {
                    // Convert PBR to semi-transparent SimpleMaterial for ghost
                    var ghost = SimpleMaterial()
                    ghost.color = .init(
                        tint: pbrMat.baseColor.tint.withAlphaComponent(0.4)
                    )
                    ghostMaterials.append(ghost)
                } else if let simpleMat = material as? SimpleMaterial {
                    var ghost = SimpleMaterial()
                    ghost.color = .init(
                        tint: simpleMat.color.tint.withAlphaComponent(0.4)
                    )
                    ghost.metallic = simpleMat.metallic
                    ghost.roughness = simpleMat.roughness
                    ghostMaterials.append(ghost)
                } else {
                    ghostMaterials.append(material)
                }
            }
            modelEntity.model?.materials = ghostMaterials
        }

        for child in entity.children {
            applyGhostEffect(to: child)
        }
    }

    private func handlePlacement(at location: CGPoint) {
        guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first,
              let data = viewModel?.graphData else {
            return
        }

        // Create world-anchored entity from raycast
        let anchor = AnchorEntity(raycastResult: result)
        arView.scene.addAnchor(anchor)
        graphAnchor = anchor

        // Build fresh graph with full PBR materials (replaces ghost)
        let builder = GraphGeometryBuilder(configuration: data.configuration)
        self.geometryBuilder = builder
        let graphEntity = builder.buildGraph(from: data)

        // Auto-scale to fit comfortably in AR (~0.6-0.8m)
        let fitScale = computeFitScale(for: graphEntity, targetSize: 0.7)

        // Start small for scale-up animation
        graphEntity.scale = SIMD3<Float>(repeating: 0.01)
        anchor.addChild(graphEntity)
        currentGraphEntity = graphEntity

        // Animate scale-up to computed fit scale
        var targetTransform = graphEntity.transform
        targetTransform.scale = SIMD3<Float>(repeating: fitScale)
        graphEntity.move(
            to: targetTransform,
            relativeTo: anchor,
            duration: 0.5,
            timingFunction: .easeInOut
        )

        // Add collision shapes for gesture interactions
        graphEntity.generateCollisionShapes(recursive: true)

        // Add shadow-receiving occlusion plane
        addShadowPlane(to: anchor)

        // Add lighting
        addLighting(to: anchor)

        // Cleanup ghost
        if let ghost = ghostAnchor {
            arView.scene.removeAnchor(ghost)
            ghostAnchor = nil
        }

        // Update state
        placementState = .placed
        onGraphPlaced?()
        onStatusUpdate?("Pinch to scale, twist to rotate")

        // Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Compute a uniform scale that fits the graph within a target size (meters).
    private func computeFitScale(for entity: Entity, targetSize: Float) -> Float {
        let bounds = entity.visualBounds(relativeTo: entity)
        let maxDimension = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        guard maxDimension > Float.ulpOfOne else { return 1.0 }
        return targetSize / maxDimension
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)

        switch placementState {
        case .scanning:
            break
        case .placing:
            handlePlacement(at: location)
        case .placed:
            // Tap-to-inspect on key points
            handlePointTap(at: location)
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard placementState == .placed, let graphEntity = currentGraphEntity else { return }

        switch gesture.state {
        case .began:
            initialPinchScale = graphEntity.scale.x
        case .changed:
            let rawScale = initialPinchScale * Float(gesture.scale)
            // Clamp to 0.2x - 3.0x range
            let clampedScale = max(0.2, min(3.0, rawScale))
            // Smooth interpolation for fluid feel
            let currentScale = graphEntity.scale.x
            let smoothed = currentScale + (clampedScale - currentScale) * 0.4
            graphEntity.scale = SIMD3<Float>(repeating: smoothed)
        case .ended, .cancelled:
            initialPinchScale = graphEntity.scale.x
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        default:
            break
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard placementState == .placed, let graphEntity = currentGraphEntity else { return }

        switch gesture.state {
        case .changed:
            // Rotate around Y-axis with smooth interpolation
            let rotation = Float(gesture.rotation) * 0.8
            graphEntity.orientation *= simd_quatf(angle: -rotation, axis: SIMD3(0, 1, 0))
            gesture.rotation = 0
        case .ended:
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        default:
            break
        }
    }

    /// Handle tapping on key point spheres to show coordinate info.
    private func handlePointTap(at location: CGPoint) {
        guard let arView = self.arView else { return }

        // Hit test for entities with collision
        let hits = arView.entities(at: location)

        for entity in hits {
            // Walk up the entity hierarchy to find KeyPoint parent
            var current: Entity? = entity
            while let e = current {
                if e.name.hasPrefix("KeyPoint_") {
                    // Found a key point!
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()

                    // Extract coordinate from entity position
                    if let marker = e.children.first {
                        let pos = marker.position
                        let ws = viewModel?.graphData?.configuration.worldScale ?? 0.07
                        let mathX = pos.x / ws
                        let mathY = pos.y / ws
                        let coordString = String(format: "(%.1f, %.1f)", mathX, mathY)
                        onStatusUpdate?("Point: \(coordString)")
                    }
                    return
                }
                current = e.parent
            }
        }
    }

    // MARK: - Helpers

    /// Add an occlusion plane beneath the graph for shadow grounding.
    private func addShadowPlane(to anchor: AnchorEntity) {
        let planeMesh = MeshResource.generatePlane(width: 2.0, depth: 2.0)
        let occlusionMaterial = OcclusionMaterial()
        let plane = ModelEntity(mesh: planeMesh, materials: [occlusionMaterial])
        plane.position.y = -0.001 // Slightly below surface
        anchor.addChild(plane)
        shadowPlane = plane
    }

    private func addLighting(to anchor: AnchorEntity) {
        // Key directional light with soft shadows
        let keyLight = DirectionalLight()
        keyLight.light.color = .white
        keyLight.light.intensity = 1200
        keyLight.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 3,
            depthBias: 2.0
        )
        keyLight.look(at: [0, 0, 0], from: [1, 4, 2], relativeTo: anchor)
        anchor.addChild(keyLight)

        // Fill light from opposite side for softer appearance
        let fillLight = PointLight()
        fillLight.light.color = .white
        fillLight.light.intensity = 300
        fillLight.light.attenuationRadius = 2.0
        fillLight.position = SIMD3(-0.5, 0.4, 0.3)
        anchor.addChild(fillLight)

        // Subtle rim light from behind for depth
        let rimLight = PointLight()
        rimLight.light.color = UIColor(white: 0.9, alpha: 1)
        rimLight.light.intensity = 200
        rimLight.light.attenuationRadius = 2.0
        rimLight.position = SIMD3(0, 0.3, -0.5)
        anchor.addChild(rimLight)
    }

    // MARK: - Public API

    public var isGraphPlaced: Bool {
        return placementState == .placed
    }

    public func reset() {
        if let anchor = graphAnchor {
            arView.scene.removeAnchor(anchor)
        }
        if let ghost = ghostAnchor {
            arView.scene.removeAnchor(ghost)
        }
        graphAnchor = nil
        ghostAnchor = nil
        currentGraphEntity = nil
        shadowPlane = nil
        placementState = .scanning

        startARSession()
    }
}

// MARK: - ARCoachingOverlayViewDelegate

extension ARGraphViewController: ARCoachingOverlayViewDelegate {
    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // Ready to place
        if placementState == .scanning {
            placementState = .placing
            onStatusUpdate?("Point at a table or floor")
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ARGraphViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow pinch and rotation gestures to work simultaneously
        let gestures = [gestureRecognizer, otherGestureRecognizer]
        let hasPinch = gestures.contains(where: { $0 is UIPinchGestureRecognizer })
        let hasRotation = gestures.contains(where: { $0 is UIRotationGestureRecognizer })
        return hasPinch && hasRotation
    }
}

// MARK: - AR Errors

public enum ARGraphError: Error, LocalizedError {
    case arNotSupported
    case sessionFailed(Error)
    case graphDataMissing
    case cameraPermissionDenied

    public var errorDescription: String? {
        switch self {
        case .arNotSupported: return "AR not supported."
        case .sessionFailed(let e): return "Session failed: \(e.localizedDescription)"
        case .graphDataMissing: return "Missing graph data."
        case .cameraPermissionDenied: return "Camera access denied."
        }
    }
}
