//
//  KnowledgeGraphRevealView.swift
//  QuickMathsAR
//
//  P3 "Wow Moment" — The Learning Reveal.
//  Animated knowledge graph plays when a user completes their first lesson.
//  Nodes appear with staggered spring cascade, light-trail connections animate.
//  ~2.5s total, skippable, reduce-motion safe.
//

#if os(iOS)
import SwiftUI

// MARK: - Knowledge Node Model

struct KnowledgeNode: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let position: CGPoint   // Normalized 0…1 coordinate
}

// MARK: - Knowledge Graph Reveal View

/// Signature delight moment: an animated knowledge graph that unfolds
/// when a user completes their first lesson. Nodes bloom with staggered
/// spring cascades and connections draw between them like light trails.
struct KnowledgeGraphRevealView: View {

    let equationType: String
    var onDismiss: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Animation State
    @State private var nodesRevealed: [Bool] = []
    @State private var connectionsRevealed = false
    @State private var glowPulse = false
    @State private var dismissed = false

    // MARK: - Data
    private var nodes: [KnowledgeNode] {
        [
            KnowledgeNode(title: "Numbers", icon: "number", color: .blue,
                          position: CGPoint(x: 0.2, y: 0.3)),
            KnowledgeNode(title: "Variables", icon: "x.squareroot", color: .purple,
                          position: CGPoint(x: 0.5, y: 0.15)),
            KnowledgeNode(title: "Operators", icon: "plus.forwardslash.minus", color: .orange,
                          position: CGPoint(x: 0.8, y: 0.3)),
            KnowledgeNode(title: equationType.capitalized, icon: "function", color: .cyan,
                          position: CGPoint(x: 0.5, y: 0.55)),
            KnowledgeNode(title: "Graph", icon: "chart.xyaxis.line", color: .green,
                          position: CGPoint(x: 0.5, y: 0.85)),
        ]
    }

    /// Node-to-node connections (indices into `nodes`)
    private let edges: [(Int, Int)] = [
        (0, 3), (1, 3), (2, 3), (3, 4)
    ]

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                // Connections
                ForEach(Array(edges.enumerated()), id: \.offset) { index, edge in
                    let from = absolutePosition(nodes[edge.0].position, in: geometry.size)
                    let to = absolutePosition(nodes[edge.1].position, in: geometry.size)

                    ConnectionLine(from: from, to: to)
                        .trim(from: 0, to: connectionsRevealed ? 1 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [nodes[edge.0].color, nodes[edge.1].color],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .opacity(connectionsRevealed ? 0.7 : 0)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .delay(Double(index) * 0.15 + 1.2),
                            value: connectionsRevealed
                        )
                }

                // Nodes
                ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                    let pos = absolutePosition(node.position, in: geometry.size)
                    let revealed = index < nodesRevealed.count ? nodesRevealed[index] : false

                    nodeView(node: node, revealed: revealed)
                        .position(pos)
                        .animation(.staggered(index: index), value: revealed)
                }

                // Title
                VStack {
                    Spacer()
                    Text("Knowledge Unlocked ✨")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .opacity(connectionsRevealed ? 1 : 0)
                        .animation(.specEntry.delay(2.0), value: connectionsRevealed)
                        .padding(.bottom, AppMetrics.spacingAir)
                }
            }
            .onTapGesture {
                dismiss()
            }
        }
        .onAppear {
            startReveal()
        }
        .opacity(dismissed ? 0 : 1)
        .animation(.specExit, value: dismissed)
    }

    // MARK: - Node View

    private func nodeView(node: KnowledgeNode, revealed: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(node.color.opacity(0.2))
                    .frame(width: 56, height: 56)

                Circle()
                    .strokeBorder(node.color.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 56, height: 56)

                Image(systemName: node.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(node.color)
            }
            .shadow(color: node.color.opacity(glowPulse ? 0.4 : 0.15), radius: glowPulse ? 16 : 8)

            Text(node.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .scaleEffect(revealed ? 1.0 : 0.01)
        .opacity(revealed ? 1 : 0)
    }

    // MARK: - Animation Sequence

    private func startReveal() {
        nodesRevealed = Array(repeating: false, count: nodes.count)

        if reduceMotion {
            // Instant reveal for accessibility
            nodesRevealed = Array(repeating: true, count: nodes.count)
            connectionsRevealed = true
            return
        }

        // Stagger node reveals
        for index in nodes.indices {
            let delay = Double(index) * AppConstants.staggerDelay * 4 + 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if index < nodesRevealed.count {
                    nodesRevealed[index] = true
                }
                HapticManager.shared.light()
            }
        }

        // Connections after nodes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            connectionsRevealed = true
        }

        // Glow pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            HapticManager.shared.success()
        }
    }

    private func dismiss() {
        dismissed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }

    // MARK: - Helpers

    private func absolutePosition(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }
}

// MARK: - Connection Line Shape

struct ConnectionLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)

        // Subtle bezier curve for organic feel
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        let controlOffset: CGFloat = 30
        let control1 = CGPoint(x: midX - controlOffset, y: midY - controlOffset)
        let control2 = CGPoint(x: midX + controlOffset, y: midY + controlOffset)

        path.addCurve(to: to, control1: control1, control2: control2)
        return path
    }
}

// MARK: - Preview

#Preview {
    KnowledgeGraphRevealView(equationType: "linear") {
        print("Dismissed")
    }
}
#endif
