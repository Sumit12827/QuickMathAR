#if os(iOS)
//
//  ViewModelProtocol.swift
//  QuickMathsAR
//
//  Created on 2026-01-25.
//

import Foundation
import Combine

/// Base protocol for all ViewModels in the application
protocol ViewModelProtocol: ObservableObject {
    /// Called when the view appears
    func onAppear()
    
    /// Called when the view disappears
    func onDisappear()
}

/// Default implementations for optional lifecycle methods
extension ViewModelProtocol {
    func onAppear() {}
    func onDisappear() {}
}
#endif
