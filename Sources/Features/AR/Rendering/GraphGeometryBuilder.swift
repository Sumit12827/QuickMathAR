//
//  GraphGeometryBuilder.swift
//  QuickMathsAR
//
//  Builds RealityKit entities for 3D graph visualization.
//  Graph lives on the XZ plane (horizontal surface).
//  Math-X -> World X, Math-Y -> World Y (height), Z provides depth.
//

import RealityKit
import simd
import UIKit

// MARK: - Graph Colors

/// Color palette for graph visualization
public enum GraphColors {
    /// Axis line color (white for strong visibility)
    public static let axis = UIColor.white

    /// Grid line color (subtle gray)
    public static let grid = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)

    /// Linear equation curve color (bright blue)
    public static let linearCurve = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)

    /// Quadratic equation curve color (purple)
    public static let quadraticCurve = UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 1.0)

    /// X-intercept point color (green)
    public static let xIntercept = UIColor(red: 0.2, green: 0.85, blue: 0.4, alpha: 1.0)

    /// Y-intercept point color (orange)
    public static let yIntercept = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)

    /// Vertex point color (red)
    public static let vertex = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)

    /// Origin point color
    public static let origin = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
}

// MARK: - Graph Geometry Builder

/// Builds RealityKit entities for mathematical graph visualization
/// using PhysicallyBasedMaterial for realistic AR rendering.
///
/// **Coordinate mapping:**
/// - Math X -> World X (left-right)
/// - Math Y -> World Y (height, up from surface)
/// - World Z is used for depth/thickness
///
/// The graph is placed on a horizontal plane (table/floor) so users
/// can walk around it and see true 3D perspective.
public final class GraphGeometryBuilder {

    // MARK: - Properties

    private let configuration: GraphConfiguration

    // MARK: - Geometry Dimensions (world meters)

    /// Thickness of axis lines - 7mm square cross-section
    private let axisThickness: Float = 0.007

    /// Thickness of grid lines - 2mm
    private let gridThickness: Float = 0.002

    /// Radius of curve tube - 5mm gives 10mm diameter
    private let curveRadius: Float = 0.005

    /// Radius of joint spheres (slightly larger than curve for smooth joins)
    private var jointRadius: Float { curveRadius * 1.1 }

    /// Radius of key point markers - 15mm
    private let keyPointRadius: Float = 0.015

    /// Arrow head dimensions
    private let arrowHeight: Float = 0.025
    private let arrowRadius: Float = 0.012

    /// Height/Thickness (Y) for grid/axis elements to give 3D volume above floor
    private let depthThickness: Float = 0.004

    /// Y offset to lift graph slightly above detected plane (avoids z-fighting)
    private let floorOffset: Float = 0.01

    // MARK: - Initialization

    public init(configuration: GraphConfiguration = .linear) {
        self.configuration = configuration
    }

    // MARK: - Material Helpers

    /// Create a PhysicallyBasedMaterial with standard PBR properties.
    private func makePBR(
        color: UIColor,
        roughness: Float = 0.3,
        metallic: Float = 0.1
    ) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.roughness = .init(floatLiteral: roughness)
        material.metallic = .init(floatLiteral: metallic)
        return material
    }

    /// Create a PhysicallyBasedMaterial with emissive glow for curves and key points.
    private func makeEmissivePBR(
        color: UIColor,
        roughness: Float = 0.25,
        metallic: Float = 0.1,
        emissiveIntensity: Float = 0.4
    ) -> PhysicallyBasedMaterial {
        var material = makePBR(color: color, roughness: roughness, metallic: metallic)
        material.emissiveColor = .init(color: color)
        material.emissiveIntensity = emissiveIntensity
        return material
    }

    // MARK: - Public API

    /// Build complete 3D graph entity from graph data.
    ///
    /// Entity hierarchy:
    /// ```
    /// GraphRoot (Y-offset above floor)
    ///  +-- Axes            (X and Z axis boxes + arrows + ticks)
    ///  +-- Grid            (thin 3D grid lines on floor)
    ///  +-- CurveContainer  (segments + sphere joints)
    ///  +-- KeyPoint_*      (emissive spheres at intercepts/vertex)
    /// ```
    public func buildGraph(from data: GraphData) -> Entity {
        let rootEntity = Entity()
        rootEntity.name = "GraphRoot"

        // Lift entire graph slightly above detected plane to avoid z-fighting
        rootEntity.position.y = floorOffset

        // 1. Axes (X and Y) — no base board, graph sits directly on floor
        let axes = buildAxes()
        rootEntity.addChild(axes)

        // 2. Grid
        if configuration.showGrid {
            let grid = buildGrid()
            rootEntity.addChild(grid)
        }

        // 3. Curve container (for efficient updates)
        let curveContainer = Entity()
        curveContainer.name = "CurveContainer"
        rootEntity.addChild(curveContainer)

        // 4. Build curve
        let curveColor = data.equationType == .linear ? GraphColors.linearCurve : GraphColors.quadraticCurve
        let curve = buildCurve(from: data.curvePoints, color: curveColor)
        curveContainer.addChild(curve)

        // 5. Key points (intercepts, vertex)
        for keyPoint in data.keyPoints {
            let pointEntity = buildKeyPoint(keyPoint)
            rootEntity.addChild(pointEntity)
        }

        return rootEntity
    }

    /// Updates only the curve + key points (for real-time slider interaction).
    /// Axes, grid, and base board are static - no need to rebuild.
    public func updateCurve(in rootEntity: Entity, with data: GraphData) {
        // Update curve
        guard let curveContainer = rootEntity.findEntity(named: "CurveContainer") else { return }
        curveContainer.children.forEach { $0.removeFromParent() }

        let curveColor = data.equationType == .linear ? GraphColors.linearCurve : GraphColors.quadraticCurve
        let curve = buildCurve(from: data.curvePoints, color: curveColor)
        curveContainer.addChild(curve)

        // Update key points
        rootEntity.children
            .filter { $0.name.hasPrefix("KeyPoint_") }
            .forEach { $0.removeFromParent() }

        for keyPoint in data.keyPoints {
            let pointEntity = buildKeyPoint(keyPoint)
            rootEntity.addChild(pointEntity)
        }
    }

    // MARK: - Axes Building

    /// Build X and Y axes as solid 3D boxes with PBR materials.
    /// Axes lie flat on the floor (XZ plane).
    ///
    /// - X-axis: runs along world X
    /// - Y-axis (math): runs along world -Z (forward/backward)
    private func buildAxes() -> Entity {
        let axesEntity = Entity()
        axesEntity.name = "Axes"
        let ws = configuration.worldScale

        // Slightly metallic white axes for realistic look
        let axisMaterial = makePBR(color: GraphColors.axis, roughness: 0.25, metallic: 0.25)

        // --- X-axis (Width) ---
        let xMin = configuration.xRange.lowerBound * ws
        let xMax = configuration.xRange.upperBound * ws
        let xLength = xMax - xMin
        let xCenter = (xMin + xMax) / 2

        // Size: Length (X), Height (Y), Width (Z)
        let xAxisMesh = MeshResource.generateBox(
            size: SIMD3(xLength, axisThickness, axisThickness), // Square cross-section
            cornerRadius: axisThickness * 0.3
        )
        let xAxis = ModelEntity(mesh: xAxisMesh, materials: [axisMaterial])
        xAxis.name = "XAxis"
        xAxis.position = SIMD3(xCenter, 0, 0)
        axesEntity.addChild(xAxis)

        // --- Y-axis (Depth - mapped to World Z) ---
        // Math Y maps to World -Z.
        // So Math Y range [min, max] maps to World Z range [-max, -min]
        let yMin = configuration.yRange.lowerBound * ws
        let yMax = configuration.yRange.upperBound * ws
        let yLength = yMax - yMin
        // Center in Math Y
        let yCenterMath = (yMin + yMax) / 2
        // Center in World Z is -yCenterMath
        
        // Size: Width (X), Height (Y), Length (Z)
        let yAxisMesh = MeshResource.generateBox(
            size: SIMD3(axisThickness, axisThickness, yLength),
            cornerRadius: axisThickness * 0.3
        )
        let yAxis = ModelEntity(mesh: yAxisMesh, materials: [axisMaterial])
        yAxis.name = "YAxis"
        yAxis.position = SIMD3(0, 0, -yCenterMath)
        axesEntity.addChild(yAxis)

        // --- Origin marker ---
        let originMesh = MeshResource.generateSphere(radius: axisThickness * 1.8)
        let originMaterial = makePBR(color: GraphColors.origin, roughness: 0.15, metallic: 0.4)
        let origin = ModelEntity(mesh: originMesh, materials: [originMaterial])
        origin.name = "Origin"
        origin.position = .zero
        axesEntity.addChild(origin)

        // --- Axis arrows ---
        let xArrow = buildAxisArrow(
            at: SIMD3(xMax, 0, 0),
            direction: SIMD3(1, 0, 0)
        )
        // Math +Y arrow is at World -Z (far end)
        let yArrow = buildAxisArrow(
            at: SIMD3(0, 0, -yMax),
            direction: SIMD3(0, 0, -1)
        )
        axesEntity.addChild(xArrow)
        axesEntity.addChild(yArrow)

        // --- Tick marks along axes ---
        buildTickMarks(on: axesEntity)

        return axesEntity
    }

    /// Build an arrow head (box pyramid approximation).
    private func buildAxisArrow(at position: SIMD3<Float>, direction: SIMD3<Float>) -> Entity {
        let mesh = MeshResource.generateBox(size: SIMD3(arrowRadius * 2, arrowHeight, arrowRadius * 2))
        let material = makePBR(color: GraphColors.axis, roughness: 0.3, metallic: 0.15)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position

        // Orientation
        // Default box is Y-aligned (pointing Up).
        // Rotate to match direction.
        let up = SIMD3<Float>(0, 1, 0)
        let normalizedDir = simd_normalize(direction)
        
        let dot = simd_dot(up, normalizedDir)
        if abs(dot) > 0.999 {
           // If pointing up/down, no rotation needed (or 180 flip)
           if dot < 0 {
               entity.orientation = simd_quatf(angle: .pi, axis: SIMD3(1, 0, 0))
           }
        } else {
             let cross = simd_cross(up, normalizedDir)
             let angle = acos(dot)
             entity.orientation = simd_quatf(angle: angle, axis: simd_normalize(cross))
        }

        // For flat arrows on the floor, we might want to rotate them differently?
        // Actually, arrows are cones pointing in the direction.
        // If direction is (1,0,0) [X axis], we want cone pointing +X.
        // Our 'mesh' is box (radius*2, height, radius*2). Height is Y.
        // So pointing +X requires -90 deg Z rotation.
        // The logic above handles generic rotation.

        return entity
    }

    /// Build small tick marks along both axes for scale reference.
    private func buildTickMarks(on axesEntity: Entity) {
        let ws = configuration.worldScale
        let tickSize: Float = 0.004
        let tickLength: Float = 0.015
        let tickMaterial = makePBR(color: GraphColors.axis, roughness: 0.3, metallic: 0.2)

        // X-axis ticks (along X, marks are perpendicular)
        // Perpendicular to X on floor is Z.
        // Size: TickWidth(X), Height(Y), Length(Z)
        // We want small X-width, small height, long Z-length
        
        var x = configuration.xRange.lowerBound
        while x <= configuration.xRange.upperBound {
            if abs(x) > Float.ulpOfOne {
                let tickMesh = MeshResource.generateBox(size: SIMD3(tickSize, depthThickness, tickLength))
                let tick = ModelEntity(mesh: tickMesh, materials: [tickMaterial])
                tick.position = SIMD3(x * ws, 0, 0)
                axesEntity.addChild(tick)
            }
            x += configuration.gridSpacing
        }

        // Y-axis ticks (along Z, marks are perpendicular -> X)
        // Size: Length(X), Height(Y), TickWidth(Z)
        var y = configuration.yRange.lowerBound
        while y <= configuration.yRange.upperBound {
            if abs(y) > Float.ulpOfOne {
                let tickMesh = MeshResource.generateBox(size: SIMD3(tickLength, depthThickness, tickSize))
                let tick = ModelEntity(mesh: tickMesh, materials: [tickMaterial])
                // Math Y -> World -Z
                tick.position = SIMD3(0, 0, -y * ws)
                axesEntity.addChild(tick)
            }
            y += configuration.gridSpacing
        }
    }

    // MARK: - Grid Building

    /// Build 3D grid lines on the floor plane.
    private func buildGrid() -> Entity {
        let gridEntity = Entity()
        gridEntity.name = "Grid"
        let ws = configuration.worldScale

        // Soft neutral grid material
        let gridMaterial = makePBR(
            color: GraphColors.grid,
            roughness: 0.6,
            metallic: 0.05
        )

        // Vertical grid lines (Math X constant, running along Math Y / World Z)
        // Parallel to Z-axis
        var x = configuration.xRange.lowerBound
        while x <= configuration.xRange.upperBound {
            if abs(x) > Float.ulpOfOne {
                let yMin = configuration.yRange.lowerBound * ws
                let yMax = configuration.yRange.upperBound * ws
                let length = yMax - yMin
                let yCenterMath = (yMin + yMax) / 2
                
                // Size: Thickness(X), Height(Y), Length(Z)
                let mesh = MeshResource.generateBox(size: SIMD3(gridThickness, depthThickness * 0.5, length))
                let line = ModelEntity(mesh: mesh, materials: [gridMaterial])
                line.position = SIMD3(x * ws, 0, -yCenterMath)
                gridEntity.addChild(line)
            }
            x += configuration.gridSpacing
        }

        // Horizontal grid lines (Math Y constant, running along Math X / World X)
        // Parallel to X-axis
        var y = configuration.yRange.lowerBound
        while y <= configuration.yRange.upperBound {
            if abs(y) > Float.ulpOfOne {
                let xMin = configuration.xRange.lowerBound * ws
                let xMax = configuration.xRange.upperBound * ws
                let length = xMax - xMin
                let midX = (xMin + xMax) / 2
                
                // Size: Length(X), Height(Y), Thickness(Z)
                let mesh = MeshResource.generateBox(size: SIMD3(length, depthThickness * 0.5, gridThickness))
                let line = ModelEntity(mesh: mesh, materials: [gridMaterial])
                // Math Y -> World -Z
                line.position = SIMD3(midX, 0, -y * ws)
                gridEntity.addChild(line)
            }
            y += configuration.gridSpacing
        }

        return gridEntity
    }

    // MARK: - Curve Building

    /// Build 3D curve from sample points.
    private func buildCurve(from points: [SIMD2<Float>], color: UIColor) -> Entity {
        let curveEntity = Entity()
        curveEntity.name = "Curve"
        let ws = configuration.worldScale

        guard points.count >= 2 else { return curveEntity }

        let curveMaterial = makeEmissivePBR(color: color, roughness: 0.2, metallic: 0.15, emissiveIntensity: 0.5)

        // Helper to map Math(x,y) to World(x,0,-z)
        func mapPoint(_ p: SIMD2<Float>) -> SIMD3<Float> {
            return SIMD3(p.x * ws, 0, -p.y * ws)
        }
        
        // Add starting joint
        let firstWorldPos = mapPoint(points[0])
        let firstJoint = buildJoint(at: firstWorldPos, material: curveMaterial)
        curveEntity.addChild(firstJoint)

        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            // Skip discontinuities (large jumps)
            let dist = simd_distance(p1, p2)
            if dist > configuration.gridSpacing * 3 { continue }

            let start = mapPoint(p1)
            let end = mapPoint(p2)

            // Rounded box segment
            let segment = buildCylinderSegment(from: start, to: end, material: curveMaterial)
            curveEntity.addChild(segment)

            // Sphere joint at the end point
            let joint = buildJoint(at: end, material: curveMaterial)
            curveEntity.addChild(joint)
        }

        return curveEntity
    }

    /// Build a rounded box segment between two world-space points.
    private func buildCylinderSegment(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        material: PhysicallyBasedMaterial
    ) -> ModelEntity {
        let direction = end - start
        let length = simd_length(direction)
        let midpoint = (start + end) / 2

        guard length > Float.ulpOfOne else {
            return ModelEntity()
        }

        // Rounded box with cornerRadius for near-cylindrical cross-section
        let thickness = curveRadius * 2
        // Default box size aligned to Y-axis. Rotating to match direction.
        let mesh = MeshResource.generateBox(
            size: SIMD3(thickness, length, thickness),
            cornerRadius: curveRadius * 0.8
        )
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = midpoint

        // Default box is Y-aligned. Rotate to match direction.
        let up = SIMD3<Float>(0, 1, 0)
        let normalizedDir = simd_normalize(direction)

        let dot = simd_dot(up, normalizedDir)
        if dot < -0.9999 {
            // Opposite direction
            entity.orientation = simd_quatf(angle: .pi, axis: SIMD3(1, 0, 0))
        } else if dot < 0.9999 {
            // General rotation
            let cross = simd_cross(up, normalizedDir)
            if simd_length(cross) > Float.ulpOfOne {
                 let angle = acos(dot)
                 entity.orientation = simd_quatf(angle: angle, axis: simd_normalize(cross))
            }
        }
        // If dot ~ 1, already aligned - no rotation needed

        return entity
    }

    /// Build a sphere joint for smooth curve connections.
    private func buildJoint(at position: SIMD3<Float>, material: PhysicallyBasedMaterial) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: jointRadius)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        return entity
    }

    // MARK: - Key Points Building

    /// Build a key point marker (emissive PBR sphere with glow halo and collision).
    private func buildKeyPoint(_ keyPoint: KeyPoint) -> Entity {
        let ws = configuration.worldScale
        let pointEntity = Entity()
        pointEntity.name = "KeyPoint_\(keyPoint.type.rawValue)"

        let color: UIColor
        switch keyPoint.type {
        case .xIntercept: color = GraphColors.xIntercept
        case .yIntercept: color = GraphColors.yIntercept
        case .vertex:     color = GraphColors.vertex
        case .origin:     color = GraphColors.origin
        }

        // Outer sphere (emissive PBR, vibrant)
        let outerMesh = MeshResource.generateSphere(radius: keyPointRadius)
        let outerMaterial = makeEmissivePBR(
            color: color,
            roughness: 0.15,
            metallic: 0.35,
            emissiveIntensity: 0.8
        )
        let marker = ModelEntity(mesh: outerMesh, materials: [outerMaterial])
        
        // Math Y -> World -Z
        marker.position = SIMD3(
            keyPoint.position.x * ws,
            0,
            -keyPoint.position.y * ws
        )

        // Add collision for tap interaction
        marker.generateCollisionShapes(recursive: false)

        // Inner glow sphere (slightly larger, semi-transparent, unlit)
        let glowMesh = MeshResource.generateSphere(radius: keyPointRadius * 1.4)
        let glowMaterial = UnlitMaterial(color: color.withAlphaComponent(0.3))
        let glow = ModelEntity(mesh: glowMesh, materials: [glowMaterial])
        marker.addChild(glow)

        pointEntity.addChild(marker)
        return pointEntity
    }
}
