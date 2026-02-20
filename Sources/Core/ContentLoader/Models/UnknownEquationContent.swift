#if os(iOS)
//
//  UnknownEquationContent.swift
//  QuickMathsAR
//
//  Model for unknown/unrecognized equation guidance
//

import Foundation

/// Represents a reason why an equation might not be recognized
public struct UnknownReason: Codable, Identifiable, Sendable {
    /// Unique identifier (uses the reason string)
    public var id: String { reason }
    
    /// Brief reason label
    public let reason: String
    
    /// Detailed explanation
    public let explanation: String
}

/// Content for when an equation type cannot be determined
public struct UnknownEquationContent: Codable, Sendable {
    
    // MARK: - Properties
    
    /// Content version for compatibility checking
    public let version: String
    
    /// The type identifier (always "unknown")
    public let equationType: String
    
    /// Human-readable display name
    public let displayName: String
    
    /// Explanation of why some equations can't be classified
    public let explanation: String
    
    /// Encouraging message for the learner
    public let encouragement: String
    
    /// Suggested foundational concepts to review
    public let suggestedFoundations: [String]
    
    /// Possible reasons why the equation wasn't recognized
    public let reasonsForUnknown: [UnknownReason]
    
    /// Suggested next steps for the learner
    public let nextSteps: [String]
    
    /// Whether AR visualization is available (typically false for unknown)
    public let arAvailable: Bool
}
#endif
