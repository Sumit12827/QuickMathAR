//
//  ParabolaPlaygroundView.swift
//  QuickMathsAR
//
//  Interactive parabola graph with sliders for a, b, c coefficients
//

#if os(iOS)
import SwiftUI

/// Interactive parabola playground with coefficient sliders
public struct ParabolaPlaygroundView: View {
    @State private var a: Double = 1.0
    @State private var b: Double = 0.0
    @State private var c: Double = 0.0

    @State private var showVertex = true
    @State private var showRoots = true
    @State private var showAxisOfSymmetry = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Parabola Playground")
                    .font(.headline)

                Spacer()

                // Reset button
                Button {
                    withAnimation(.spring()) {
                        a = 1.0
                        b = 0.0
                        c = 0.0
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.secondary)
                }
            }

            // Equation display
            equationDisplay
                .padding(.vertical, 8)

            // Graph
            ParabolaGraph(
                a: a, b: b, c: c,
                showVertex: showVertex,
                showRoots: showRoots,
                showAxisOfSymmetry: showAxisOfSymmetry
            )
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
            )

            // Coefficient sliders
            VStack(spacing: 16) {
                CoefficientSlider(
                    label: "a",
                    value: $a,
                    range: -3...3,
                    color: .red,
                    description: "Opens \(a >= 0 ? "up ↑" : "down ↓")"
                )

                CoefficientSlider(
                    label: "b",
                    value: $b,
                    range: -5...5,
                    color: .green,
                    description: "Shifts horizontally"
                )

                CoefficientSlider(
                    label: "c",
                    value: $c,
                    range: -5...5,
                    color: .blue,
                    description: "Shifts vertically"
                )
            }

            // Toggle options
            HStack(spacing: 16) {
                Toggle("Vertex", isOn: $showVertex)
                Toggle("Roots", isOn: $showRoots)
                Toggle("Axis", isOn: $showAxisOfSymmetry)
            }
            .font(.caption)
            .toggleStyle(.button)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Parabola playground. Adjust coefficients a, b, and c to see how the curve changes.")
    }

    private var equationDisplay: some View {
        HStack(spacing: 4) {
            Text("y = ")
            Text("\(a, specifier: "%.1f")").foregroundStyle(.red)
            Text("x² ")

            if b != 0 {
                Text(b >= 0 ? "+ " : "− ")
                Text("\(abs(b), specifier: "%.1f")").foregroundStyle(.green)
                Text("x ")
            }

            if c != 0 {
                Text(c >= 0 ? "+ " : "− ")
                Text("\(abs(c), specifier: "%.1f")").foregroundStyle(.blue)
            }
        }
        .font(.system(size: 18, weight: .medium, design: .rounded))
    }
}

// MARK: - Parabola Graph

private struct ParabolaGraph: View {
    let a: Double
    let b: Double
    let c: Double
    let showVertex: Bool
    let showRoots: Bool
    let showAxisOfSymmetry: Bool

    private var vertexX: Double { -b / (2 * a) }
    private var vertexY: Double { a * vertexX * vertexX + b * vertexX + c }

    private var discriminant: Double { b * b - 4 * a * c }

    private var roots: [Double] {
        guard discriminant >= 0, a != 0 else { return [] }
        if discriminant == 0 {
            return [-b / (2 * a)]
        }
        let sqrtD = sqrt(discriminant)
        return [(-b + sqrtD) / (2 * a), (-b - sqrtD) / (2 * a)]
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let midX = width / 2
            let midY = height / 2
            let scale: CGFloat = 20

            ZStack {
                // Grid lines
                GridLines(width: width, height: height)

                // Axis of symmetry
                if showAxisOfSymmetry && a != 0 {
                    let axisX = midX + CGFloat(vertexX) * scale
                    Path { path in
                        path.move(to: CGPoint(x: axisX, y: 0))
                        path.addLine(to: CGPoint(x: axisX, y: height))
                    }
                    .stroke(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }

                // Parabola curve
                if a != 0 {
                    Path { path in
                        var first = true
                        for x in stride(from: -width / 2, through: width / 2, by: 2) {
                            let mathX = Double(x) / Double(scale)
                            let mathY = a * mathX * mathX + b * mathX + c
                            let screenY = midY - CGFloat(mathY) * scale

                            if first {
                                path.move(to: CGPoint(x: midX + x, y: screenY))
                                first = false
                            } else {
                                path.addLine(to: CGPoint(x: midX + x, y: screenY))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 3
                    )
                }

                // Vertex
                if showVertex && a != 0 {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)
                        .position(
                            x: midX + CGFloat(vertexX) * scale,
                            y: midY - CGFloat(vertexY) * scale
                        )
                        .accessibilityLabel("Vertex at \(String(format: "%.1f", vertexX)), \(String(format: "%.1f", vertexY))")
                }

                // Roots
                if showRoots {
                    ForEach(roots, id: \.self) { root in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .position(
                                x: midX + CGFloat(root) * scale,
                                y: midY
                            )
                            .accessibilityLabel("Root at x = \(String(format: "%.1f", root))")
                    }
                }
            }
        }
    }
}

// MARK: - Grid Lines

private struct GridLines: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            // Vertical lines
            ForEach(-5..<6, id: \.self) { i in
                let x = width / 2 + CGFloat(i) * 20
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            }

            // Horizontal lines
            ForEach(-5..<6, id: \.self) { i in
                let y = height / 2 + CGFloat(i) * 20
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            }

            // Axes
            Path { path in
                path.move(to: CGPoint(x: width / 2, y: 0))
                path.addLine(to: CGPoint(x: width / 2, y: height))
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)

            Path { path in
                path.move(to: CGPoint(x: 0, y: height / 2))
                path.addLine(to: CGPoint(x: width, y: height / 2))
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        }
    }
}

// MARK: - Coefficient Slider

private struct CoefficientSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(color)

                Text("= \(value, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Slider(value: $value, in: range, step: 0.1)
                .tint(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) coefficient: \(String(format: "%.1f", value)). \(description)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(range.upperBound, value + 0.5)
            case .decrement:
                value = max(range.lowerBound, value - 0.5)
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ParabolaPlaygroundView()
        .padding()
}
#endif
