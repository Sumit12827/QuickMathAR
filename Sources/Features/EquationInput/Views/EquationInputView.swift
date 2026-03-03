//
//  EquationInputView.swift
//  QuickMathsAR
//
//  Created on 2026-02-09.
//

#if os(iOS)
import SwiftUI

struct EquationInputView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var selectedMode: InputMode = .builder

    enum InputMode: String, CaseIterable {
        case builder = "Builder"
        case manual = "Type"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode Picker
            Picker("Input Mode", selection: $selectedMode) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            Group {
                switch selectedMode {
                case .builder:
                    InteractiveEquationBuilderView { equation in
                        handleEquationComplete(equation)
                    }
                    .transition(.opacity)

                case .manual:
                    ManualEquationInputView { equation in
                        handleEquationComplete(equation)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedMode)
        }
        .navigationTitle("Input Equation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleEquationComplete(_ equation: String) {
        // Classify equation with full confidence data
        let classifier = EquationClassifier()
        let result = classifier.classifyWithConfidence(equation)

        // Navigate to equation type view — it handles all cases gracefully
        navigationCoordinator.push(.equationType(equation: equation, type: result.type))
    }
}

#Preview("Light") {
    NavigationStack {
        EquationInputView()
            .environmentObject(NavigationCoordinator())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        EquationInputView()
            .environmentObject(NavigationCoordinator())
    }
    .preferredColorScheme(.dark)
}
#endif
