//
//  InsightRevealView.swift
//  QuickMathsAR
//
//  Animated reveal for "aha moment" insights
//

import SwiftUI

struct InsightRevealView: View {
    let text: String

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
                .symbolEffect(.pulse, options: .repeating)

            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .safeBody(alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.yellow.opacity(0.3), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    InsightRevealView(text: "Addition combines separate groups into one total. What was apart is now together!")
        .padding()
}
