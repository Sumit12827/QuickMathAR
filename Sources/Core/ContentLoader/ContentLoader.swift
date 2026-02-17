//
//  ContentLoader.swift
//  QuickMathsAR
//
//  Loads and provides access to learning content from JSON files
//

import Foundation

/// Errors that can occur when loading content
public enum ContentLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)
    case invalidContent(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Content file '\(filename)' was not found in the app bundle."
        case .decodingFailed(let filename, let error):
            return "Failed to decode '\(filename)': \(error.localizedDescription)"
        case .invalidContent(let message):
            return "Invalid content: \(message)"
        }
    }
}

/// Loads and manages learning content from JSON files in the app bundle
///
/// The ContentLoader provides a clean API for accessing:
/// - Foundational arithmetic concepts
/// - Equation type learning content (linear, quadratic)
/// - Unknown equation guidance
///
/// All content is loaded from JSON files and cached for performance.
/// The loader is completely independent of UI concerns.
public final class ContentLoader: @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// Shared instance for app-wide access
    public static let shared = ContentLoader()
    
    // MARK: - Cache
    
    private var foundationsCache: FoundationsContent?
    private var linearContentCache: EquationLearningContent?
    private var quadraticContentCache: EquationLearningContent?
    private var unknownContentCache: UnknownEquationContent?
    
    /// Lock for thread-safe cache access
    private let cacheLock = NSLock()
    
    // MARK: - File Names
    
    private enum JSONFile {
        static let foundationsArithmetic = "foundations_arithmetic"
        static let linearEquations = "linear_equations"
        static let quadraticEquations = "quadratic_equations"
        static let unknownEquations = "unknown_equations"
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API: Arithmetic Concepts
    
    /// Retrieves all foundational arithmetic concepts
    /// - Returns: Array of arithmetic concepts, or empty array if loading fails
    public func getAllArithmeticConcepts() -> [ArithmeticConcept] {
        loadFoundationsIfNeeded()
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return foundationsCache?.concepts ?? []
    }
    
    /// Retrieves a specific arithmetic concept by ID
    /// - Parameter id: The concept identifier (e.g., "addition", "subtraction")
    /// - Returns: The arithmetic concept if found, nil otherwise
    public func getArithmeticConcept(_ id: String) -> ArithmeticConcept? {
        loadFoundationsIfNeeded()
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return foundationsCache?.concepts.first { $0.id == id }
    }
    
    /// Retrieves arithmetic concepts for given IDs
    /// - Parameter ids: Array of concept identifiers
    /// - Returns: Array of found concepts (may be fewer than requested if some not found)
    public func getArithmeticConcepts(for ids: [String]) -> [ArithmeticConcept] {
        loadFoundationsIfNeeded()
        cacheLock.lock()
        defer { cacheLock.unlock() }
        guard let concepts = foundationsCache?.concepts else { return [] }
        return ids.compactMap { id in concepts.first { $0.id == id } }
    }
    
    // MARK: - Public API: Equation Content
    
    /// Retrieves learning content for a specific equation type
    /// - Parameter type: The equation type to get content for
    /// - Returns: The learning content if available, nil otherwise
    public func getEquationContent(for type: EquationType) -> EquationLearningContent? {
        switch type {
        case .linear:
            return getLinearContent()
        case .quadratic:
            return getQuadraticContent()
        default:
            return nil
        }
    }
    
    /// Retrieves content specifically for unknown/unrecognized equations
    /// - Returns: The unknown equation content if available, nil otherwise
    public func getUnknownEquationContent() -> UnknownEquationContent? {
        loadUnknownContentIfNeeded()
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return unknownContentCache
    }
    
    /// Checks if AR visualization is available for an equation type
    /// - Parameter type: The equation type to check
    /// - Returns: True if AR is available, false otherwise
    public func isARAvailable(for type: EquationType) -> Bool {
        switch type {
        case .linear:
            return getLinearContent()?.arAvailable ?? false
        case .quadratic:
            return getQuadraticContent()?.arAvailable ?? false
        default:
            return false
        }
    }
    
    /// Retrieves prerequisite concepts for an equation type
    /// - Parameter type: The equation type
    /// - Returns: Array of prerequisite arithmetic concepts
    public func getPrerequisites(for type: EquationType) -> [ArithmeticConcept] {
        guard let content = getEquationContent(for: type) else { return [] }
        return getArithmeticConcepts(for: content.prerequisites)
    }
    
    // MARK: - Public API: Examples
    
    /// Retrieves all learning examples for an equation type
    /// - Parameter type: The equation type
    /// - Returns: Array of learning examples
    public func getExamples(for type: EquationType) -> [LearningExample] {
        return getEquationContent(for: type)?.examples ?? []
    }
    
    /// Retrieves learning examples filtered by difficulty
    /// - Parameters:
    ///   - type: The equation type
    ///   - difficulty: The desired difficulty level
    /// - Returns: Filtered array of learning examples
    public func getExamples(for type: EquationType, difficulty: String) -> [LearningExample] {
        return getExamples(for: type).filter { $0.difficulty == difficulty }
    }
    
    // MARK: - Private: Content Loading
    
    private func getLinearContent() -> EquationLearningContent? {
        loadLinearContentIfNeeded()
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return linearContentCache
    }
    
    private func getQuadraticContent() -> EquationLearningContent? {
        loadQuadraticContentIfNeeded()
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return quadraticContentCache
    }
    
    private func loadFoundationsIfNeeded() {
        cacheLock.lock()
        let needsLoad = foundationsCache == nil
        cacheLock.unlock()
        
        guard needsLoad else { return }
        
        if let content: FoundationsContent = loadJSON(filename: JSONFile.foundationsArithmetic) {
            cacheLock.lock()
            foundationsCache = content
            cacheLock.unlock()
        }
    }
    
    private func loadLinearContentIfNeeded() {
        cacheLock.lock()
        let needsLoad = linearContentCache == nil
        cacheLock.unlock()
        
        guard needsLoad else { return }
        
        if let content: EquationLearningContent = loadJSON(filename: JSONFile.linearEquations) {
            cacheLock.lock()
            linearContentCache = content
            cacheLock.unlock()
        }
    }
    
    private func loadQuadraticContentIfNeeded() {
        cacheLock.lock()
        let needsLoad = quadraticContentCache == nil
        cacheLock.unlock()
        
        guard needsLoad else { return }
        
        if let content: EquationLearningContent = loadJSON(filename: JSONFile.quadraticEquations) {
            cacheLock.lock()
            quadraticContentCache = content
            cacheLock.unlock()
        }
    }
    
    private func loadUnknownContentIfNeeded() {
        cacheLock.lock()
        let needsLoad = unknownContentCache == nil
        cacheLock.unlock()
        
        guard needsLoad else { return }
        
        if let content: UnknownEquationContent = loadJSON(filename: JSONFile.unknownEquations) {
            cacheLock.lock()
            unknownContentCache = content
            cacheLock.unlock()
        }
    }
    
    // MARK: - Private: JSON Loading
    
    /// Loads and decodes a JSON file from the app bundle
    /// - Parameter filename: The name of the JSON file (without extension)
    /// - Returns: The decoded content, or nil if loading/decoding fails
    private func loadJSON<T: Decodable>(filename: String) -> T? {
        // Use Bundle.module for Swift Package Manager compatibility
        guard let url = Bundle.module.url(forResource: filename, withExtension: "json") else {
            print("ContentLoader: File not found - \(filename).json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let content = try decoder.decode(T.self, from: data)
            return content
        } catch {
            print("ContentLoader: Failed to decode \(filename).json - \(error)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached content (useful for testing or memory pressure)
    public func clearCache() {
        cacheLock.lock()
        foundationsCache = nil
        linearContentCache = nil
        quadraticContentCache = nil
        unknownContentCache = nil
        cacheLock.unlock()
    }
    
    /// Preloads all content into cache
    public func preloadAllContent() {
        loadFoundationsIfNeeded()
        loadLinearContentIfNeeded()
        loadQuadraticContentIfNeeded()
        loadUnknownContentIfNeeded()
    }
}
