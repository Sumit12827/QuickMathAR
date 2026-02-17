//
//  View+SafeText.swift
//  QuickMathsAR
//
//  Created on 2026-02-06.
//

import SwiftUI

extension View {
    /// For titles - scales down before truncating, max 2 lines
    func safeTitle(minScale: CGFloat = 0.7, alignment: TextAlignment = .center) -> some View {
        self
            .lineLimit(2)
            .minimumScaleFactor(minScale)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// For body text - allows unlimited wrapping
    func safeBody(alignment: TextAlignment = .center) -> some View {
        self
            .lineLimit(nil)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// For captions - max 3 lines with scaling
    func safeCaption(minScale: CGFloat = 0.8, alignment: TextAlignment = .center) -> some View {
        self
            .lineLimit(3)
            .minimumScaleFactor(minScale)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// For single-line labels - scales only, no wrapping
    func safeInline(minScale: CGFloat = 0.8) -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(minScale)
    }
}
