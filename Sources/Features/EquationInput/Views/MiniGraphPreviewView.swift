//
//  MiniGraphPreviewView.swift
//  QuickMathsAR
//
//  Compact live graph preview during equation building.


import SwiftUI


struct MiniGraphPreviewView: View {
    let equationShape: EquationShape
    let components: [EquationComponent]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // Mini graph canvas
            Canvas { context, size in
                drawGraph(in: context, size: size)
            }
            .frame(width: 80, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Shape label
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(shapeIcon)
                        .font(.caption2)
                    Text(shapeLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                Text(shapeDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .opacity(equationShape == .incomplete ? 0 : 1)
        .animation(
            reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.8),
            value: equationShape
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Graph preview: \(shapeLabel). \(shapeDescription)")
    }

    // MARK: - Shape Info

    private var shapeIcon: String {
        switch equationShape {
        case .incomplete: return ""
        case .linear:     return "📏"
        case .quadratic:  return "📐"
        }
    }

    private var shapeLabel: String {
        switch equationShape {
        case .incomplete: return "Building..."
        case .linear:     return "Linear"
        case .quadratic:  return "Quadratic"
        }
    }

    private var shapeDescription: String {
        switch equationShape {
        case .incomplete: return "Add more components"
        case .linear:     return "Straight line relationship"
        case .quadratic:  return "Curved relationship"
        }
    }

    // MARK: - Drawing

    private func drawGraph(in context: GraphicsContext, size: CGSize) {
        let midY = size.height / 2
        let midX = size.width / 2
        let padding: CGFloat = 8

        // Draw subtle axes
        var xAxis = Path()
        xAxis.move(to: CGPoint(x: padding, y: midY))
        xAxis.addLine(to: CGPoint(x: size.width - padding, y: midY))
        context.stroke(xAxis, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)

        var yAxis = Path()
        yAxis.move(to: CGPoint(x: midX, y: padding))
        yAxis.addLine(to: CGPoint(x: midX, y: size.height - padding))
        context.stroke(yAxis, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)

        // Draw the shape
        switch equationShape {
        case .incomplete:
            break

        case .linear:
            // Draw a straight line
            var line = Path()
            line.move(to: CGPoint(x: padding, y: size.height - padding))
            line.addLine(to: CGPoint(x: size.width - padding, y: padding))
            context.stroke(
                line,
                with: .color(.blue),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )

        case .quadratic:
            // Draw a parabola
            var curve = Path()
            let steps = 30
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = padding + t * (size.width - 2 * padding)
                // Parabola: normalized so vertex is at center bottom
                let normalizedX = (t - 0.5) * 2 // -1 to 1
                let normalizedY = normalizedX * normalizedX // 0 to 1
                let y = size.height - padding - normalizedY * (size.height - 2 * padding)

                if i == 0 {
                    curve.move(to: CGPoint(x: x, y: y))
                } else {
                    curve.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(
                curve,
                with: .color(.purple),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MiniGraphPreviewView(equationShape: .linear, components: [])
        MiniGraphPreviewView(equationShape: .quadratic, components: [])
        MiniGraphPreviewView(equationShape: .incomplete, components: [])
    }
    .padding()
}
