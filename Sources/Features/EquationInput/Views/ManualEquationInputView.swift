//
//  ManualEquationInputView.swift
//  QuickMathsAR
//
//  Created on 2026-02-09.
//

#if os(iOS)
import SwiftUI

struct ManualEquationInputView: View {
    @State private var equationText = ""
    @State private var validationState: EquationValidationState = .empty
    @FocusState private var isTextFieldFocused: Bool

    let onComplete: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Text Field
            VStack(spacing: 16) {
                Text("Type your equation")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                TextField("e.g., 2x+3=7 or x²-4=0", text: $equationText)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isTextFieldFocused = false
                    }
                    .onChange(of: equationText) { _, newValue in
                        validateEquation(newValue)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Validation feedback
                validationFeedbackView

                // Common symbols helper
                symbolsHelper
            }
            .padding(.horizontal)

            Spacer()

            // Continue button
            Button(action: {
                if case .valid(let eq) = validationState {
                    onComplete(eq)
                }
            }) {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!validationState.canProceed)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onAppear {
            // Auto-focus the text field when this view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Validation Feedback

    private var validationFeedbackView: some View {
        HStack(spacing: 8) {
            Image(systemName: validationIcon)
                .foregroundStyle(colorForValidation)

            Text(validationState.message)
                .font(.subheadline)
                .foregroundStyle(colorForValidation)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(colorForValidation.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Symbols Helper

    private var symbolsHelper: some View {
        VStack(spacing: 8) {
            Text("Tap to insert")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 12) {
                ForEach(["x", "²", "³", "=", "+", "-"], id: \.self) { symbol in
                    Button(action: {
                        equationText += symbol
                        validateEquation(equationText)
                    }) {
                        Text(symbol)
                            .font(.title3)
                            .fontWeight(.medium)
                            .frame(width: 44, height: 44)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Validation Icon

    private var validationIcon: String {
        switch validationState {
        case .valid:
            return "checkmark.circle.fill"
        case .empty:
            return "info.circle"
        case .unsupportedType:
            return "graduationcap.fill"
        case .invalid:
            return "exclamationmark.triangle.fill"
        default:
            return "info.circle"
        }
    }

    // MARK: - Validation Color

    private var colorForValidation: Color {
        switch validationState {
        case .empty: return .secondary
        case .missingVariable, .missingEquals, .incomplete: return .orange
        case .valid: return .green
        case .invalid: return .red
        case .unsupportedType: return .blue
        }
    }

    // MARK: - Equation Validation

    private func validateEquation(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            validationState = .empty
            return
        }

        // Use the classifier for detection
        let classifier = EquationClassifier()
        let result = classifier.classifyWithConfidence(trimmed)

        // Handle based on classification
        switch result.type {
        case .linear, .quadratic:
            // Supported — check structural completeness
            if !trimmed.contains(where: { "xyzXYZ".contains($0) }) {
                validationState = .missingVariable
            } else if !trimmed.contains("=") {
                validationState = .missingEquals
            } else {
                let parts = trimmed.split(separator: "=")
                if parts.count != 2 || parts[0].isEmpty || parts[1].isEmpty {
                    validationState = .incomplete
                } else {
                    validationState = .valid(trimmed)
                }
            }

        case .malformed(let reason):
            validationState = .invalid(message: reason.rawValue)

        case .constant:
            if !trimmed.contains("=") {
                validationState = .missingEquals
            } else {
                validationState = .valid(trimmed)
            }

        default:
            // Unsupported but recognized — show educational message
            validationState = .unsupportedType(
                type: result.type,
                message: result.type.educationalMessage
            )
        }
    }
}

#Preview {
    ManualEquationInputView { equation in
        print("Completed: \(equation)")
    }
}
#endif
