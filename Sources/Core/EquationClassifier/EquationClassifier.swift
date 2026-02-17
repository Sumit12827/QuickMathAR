

//
//  EquationClassifier.swift
//  QuickMathsAR
//
//  Classifies equations by type using advanced pattern matching
//  Enhanced with pre-classification for unsupported equation types
//

import Foundation

/// Classification result with confidence score
public struct ClassificationResult {
    public let type: EquationType
    public let confidence: Double
    public let detectedVariable: String?
    public let degree: Int
    
    public init(type: EquationType, confidence: Double, detectedVariable: String? = nil, degree: Int = 0) {
        self.type = type
        self.confidence = confidence
        self.detectedVariable = detectedVariable
        self.degree = degree
    }
}

/// Advanced equation classifier with fuzzy matching and high accuracy detection
public struct EquationClassifier {
    
    // MARK: - Constants
    
    /// Variable pattern - supports common math variables
    private static let variablePattern = "[a-zA-Z]"
    
    /// Confidence threshold for valid classification
    private static let confidenceThreshold = 0.75
    
    // MARK: - Detection Patterns
    
    /// Transcendental function names to detect
    private static let transcendentalFunctions: [String: EquationType] = {
        var map: [String: EquationType] = [:]
        // Trigonometric
        for fn in ["sin", "cos", "tan", "cot", "sec", "csc"] {
            map[fn] = .trigonometric(function: fn)
        }
        // Inverse trig
        for fn in ["arcsin", "arccos", "arctan", "asin", "acos", "atan"] {
            map[fn] = .trigonometric(function: fn)
        }
        // Hyperbolic
        for fn in ["sinh", "cosh", "tanh"] {
            map[fn] = .trigonometric(function: fn)
        }
        // Logarithmic
        for fn in ["log", "ln", "log2", "log10"] {
            map[fn] = .logarithmic
        }
        // Exponential
        map["exp"] = .exponential
        return map
    }()
    
    /// Squared term detection
    private static let squaredPatterns: [String] = [
        "\\^2\\b", "²", "\\*\\*2\\b", "\\^\\s*2\\b", "\\^{\\s*2\\s*}", "\\(\\s*2\\s*\\)",
    ]
    
    /// Cubed term detection
    private static let cubedPatterns: [String] = [
        "\\^3\\b", "³", "\\*\\*3\\b", "\\^\\s*3\\b",
    ]
    
    /// Higher power detection (degree 4-9)
    private static let higherPowerPatterns: [String] = [
        "\\^[4-9]\\b", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹",
    ]
    
    /// Multi-digit power detection (degree 10+)
    private static let multiDigitPowerPattern = "\\^(\\d{2,})\\b"
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// Classifies an equation with confidence scoring
    /// - Parameter equation: Raw equation string from OCR or user input
    /// - Returns: Classification result with confidence
    public func classifyWithConfidence(_ equation: String) -> ClassificationResult {
        // Handle empty input
        let trimmed = equation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ClassificationResult(type: .malformed(reason: .empty), confidence: 1.0, degree: 0)
        }
        
        // Check for pure gibberish / invalid characters
        if containsOnlyInvalidCharacters(trimmed) {
            return ClassificationResult(type: .malformed(reason: .invalidCharacters), confidence: 1.0, degree: 0)
        }
        
        // Too short to be meaningful
        if trimmed.count < 3 {
            return ClassificationResult(type: .malformed(reason: .incomplete), confidence: 0.9, degree: 0)
        }
        
        // Check unbalanced parentheses
        if hasUnbalancedParentheses(trimmed) {
            return ClassificationResult(type: .malformed(reason: .unbalancedParentheses), confidence: 0.95, degree: 0)
        }
        
        // Preprocess for analysis
        let normalized = normalizeForAnalysis(trimmed)
        
        // --- Pre-classification: detect unsupported types BEFORE polynomial analysis ---
        
        // 1. Detect transcendental functions (highest priority)
        if let transcendental = detectTranscendental(normalized) {
            return transcendental
        }
        
        // 2. Detect exponential patterns (e^x, 2^x but not x^2)
        if detectExponential(normalized) {
            return ClassificationResult(type: .exponential, confidence: 0.95, degree: 0)
        }
        
        // 3. Detect absolute value
        if detectAbsoluteValue(trimmed) {
            return ClassificationResult(type: .absoluteValue, confidence: 0.95, degree: 0)
        }
        
        // 4. Detect square root
        if detectSquareRoot(normalized, original: trimmed) {
            return ClassificationResult(type: .squareRoot, confidence: 0.95, degree: 0)
        }
        
        // 5. Detect conic sections (before polynomial degree check)
        if let conic = detectConicSection(normalized) {
            return conic
        }
        
        // 6. Detect rational functions (variable in denominator)
        if detectRationalFunction(normalized) {
            return ClassificationResult(type: .rationalFunction, confidence: 0.9, degree: 0)
        }
        
        // --- Standard polynomial classification ---
        
        // Try multiple classification strategies and pick best
        let results = [
            classifyByParsing(normalized),
            classifyByPatterns(normalized),
            classifyByDegreeExtraction(normalized)
        ]
        
        // Return result with highest confidence
        guard let best = results.max(by: { $0.confidence < $1.confidence }) else {
            return ClassificationResult(type: .unknown, confidence: 0.0, degree: 0)
        }
        
        // ENFORCE STRICT CONFIDENCE THRESHOLD
        if best.confidence < EquationClassifier.confidenceThreshold {
            // Check if it at least has valid math-like characters
            let hasAnyMathContent = trimmed.contains(where: { $0.isNumber || $0.isLetter })
            if !hasAnyMathContent {
                return ClassificationResult(type: .malformed(reason: .invalidCharacters), confidence: 0.9, degree: 0)
            }
            return ClassificationResult(type: .unknown, confidence: best.confidence, degree: 0)
        }
        
        return best
    }
    
    /// Legacy classifier for backward compatibility
    public func classify(_ equation: String) -> EquationType {
        return classifyWithConfidence(equation).type
    }
    
    // MARK: - Pre-classification Detectors
    
    /// Checks if input contains only non-mathematical characters
    private func containsOnlyInvalidCharacters(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Must have at least one letter, digit, or math symbol
        let hasMathContent = cleaned.contains(where: {
            $0.isNumber || $0.isLetter || "+-*/=^²³√().".contains($0)
        })
        return !hasMathContent
    }
    
    /// Checks for unbalanced parentheses
    private func hasUnbalancedParentheses(_ text: String) -> Bool {
        var depth = 0
        for char in text {
            if char == "(" { depth += 1 }
            else if char == ")" { depth -= 1 }
            if depth < 0 { return true }
        }
        return depth != 0
    }
    
    /// Detects transcendental function names
    private func detectTranscendental(_ text: String) -> ClassificationResult? {
        let lowered = text.lowercased()
        // Sort by length descending so "arcsin" matches before "sin"
        let sortedKeys = EquationClassifier.transcendentalFunctions.keys.sorted { $0.count > $1.count }
        for funcName in sortedKeys {
            // Match function name not preceded by another letter
            let pattern = "(?<![a-z])\(NSRegularExpression.escapedPattern(for: funcName))\\s*[\\(x]"
            if matchesPattern(lowered, pattern: pattern) {
                if let eqType = EquationClassifier.transcendentalFunctions[funcName] {
                    return ClassificationResult(type: eqType, confidence: 0.95, degree: 0)
                }
            }
        }
        return nil
    }
    
    /// Detects exponential patterns like e^x, 2^x, eˣ
    private func detectExponential(_ text: String) -> Bool {
        let lowered = text.lowercased()
        // e^x, e^(something with x)
        if matchesPattern(lowered, pattern: "e\\^") && lowered.contains("x") {
            // Make sure it's not just x^e pattern (unlikely but safe)
            if matchesPattern(lowered, pattern: "e\\^\\s*[\\(x]") {
                return true
            }
        }
        // eˣ
        if lowered.contains("eˣ") { return true }
        // Number^x like 2^x, 10^x (number followed by ^x)
        if matchesPattern(lowered, pattern: "\\d+\\^\\s*x") { return true }
        return false
    }
    
    /// Detects absolute value: |...|, abs(...)
    private func detectAbsoluteValue(_ text: String) -> Bool {
        // Pipe-based: |something|
        if matchesPattern(text, pattern: "\\|[^|]+\\|") { return true }
        // Function-based: abs(...)
        if matchesPattern(text.lowercased(), pattern: "(?<![a-z])abs\\s*\\(") { return true }
        return false
    }
    
    /// Detects square root: √, sqrt(), ^(1/2), ^0.5
    private func detectSquareRoot(_ normalized: String, original: String) -> Bool {
        if original.contains("√") { return true }
        if matchesPattern(normalized, pattern: "(?<![a-z])sqrt\\s*\\(") { return true }
        if matchesPattern(normalized, pattern: "\\^\\s*\\(?\\s*1\\s*/\\s*2") { return true }
        if matchesPattern(normalized, pattern: "\\^\\s*0?\\.5") { return true }
        return false
    }
    
    /// Detects conic sections: circle, ellipse, hyperbola
    private func detectConicSection(_ text: String) -> ClassificationResult? {
        let lowered = text.lowercased()
        
        // Need both x² and y² present
        let hasXSquared = matchesPattern(lowered, pattern: "x\\^2|x²") || matchesPattern(lowered, pattern: "x\\*x")
        let hasYSquared = matchesPattern(lowered, pattern: "y\\^2|y²") || matchesPattern(lowered, pattern: "y\\*y")
        
        guard hasXSquared && hasYSquared else { return nil }
        
        // Check for division (ellipse/hyperbola standard form: x²/a² + y²/b²)
        let hasDivision = matchesPattern(lowered, pattern: "x\\^?2\\s*/|y\\^?2\\s*/")
        
        // Check for minus between the squared terms
        // Hyperbola has a minus between x² and y²
        if matchesPattern(lowered, pattern: "x\\^?2.*-.*y\\^?2|y\\^?2.*-.*x\\^?2") {
            return ClassificationResult(type: .hyperbola, confidence: 0.9, degree: 2)
        }
        
        // Plus between squared terms
        if matchesPattern(lowered, pattern: "x\\^?2.*\\+.*y\\^?2|y\\^?2.*\\+.*x\\^?2") {
            if hasDivision {
                return ClassificationResult(type: .ellipse, confidence: 0.9, degree: 2)
            }
            return ClassificationResult(type: .circle, confidence: 0.9, degree: 2)
        }
        
        // Fallback: has both squared terms, assume circle
        return ClassificationResult(type: .circle, confidence: 0.8, degree: 2)
    }
    
    /// Detects rational functions (variable in denominator)
    private func detectRationalFunction(_ text: String) -> Bool {
        let lowered = text.lowercased()
        // Pattern: something / (expression containing a variable)
        // e.g., 1/x, (x+1)/(x-2), /x
        if matchesPattern(lowered, pattern: "/\\s*\\(?[^)]*[a-z][^)]*\\)?") {
            // Make sure the variable in denominator is actually a variable (x, y, etc.)
            // and not a function name like sin
            if matchesPattern(lowered, pattern: "/\\s*\\(?\\s*[xyz]") { return true }
            if matchesPattern(lowered, pattern: "/\\s*\\([^)]*[xyz]") { return true }
        }
        return false
    }
    
    // MARK: - Classification Strategies
    
    /// Primary classification by mathematical parsing
    private func classifyByParsing(_ equation: String) -> ClassificationResult {
        // Extract the main variable (usually x, y, or z)
        guard let mainVariable = detectMainVariable(equation) else {
            // Could be a constant equation
            if isConstantEquation(equation) {
                return ClassificationResult(type: .constant, confidence: 0.9, degree: 0)
            }
            // Check if it contains no variables at all
            if !containsVariable(equation) {
                if equation.contains(where: { $0.isLetter }) {
                    // Has letters but no recognized variables - possibly gibberish
                    return ClassificationResult(type: .malformed(reason: .noVariable), confidence: 0.85, degree: 0)
                }
            }
            return ClassificationResult(type: .unknown, confidence: 0.1, degree: 0)
        }
        
        // Calculate polynomial degree for that variable
        let degree = calculateDegree(equation, variable: mainVariable)
        
        // Map degree to equation type
        switch degree {
        case 0:
            if equation.contains("=") {
                return ClassificationResult(type: .constant, confidence: 0.85, detectedVariable: mainVariable, degree: 0)
            } else {
                return ClassificationResult(type: .linear, confidence: 0.6, detectedVariable: mainVariable, degree: 1)
            }
        case 1:
            return ClassificationResult(type: .linear, confidence: 0.95, detectedVariable: mainVariable, degree: 1)
        case 2:
            return ClassificationResult(type: .quadratic, confidence: 0.95, detectedVariable: mainVariable, degree: 2)
        case 3:
            return ClassificationResult(type: .cubicPolynomial, confidence: 0.8, detectedVariable: mainVariable, degree: 3)
        default:
            return ClassificationResult(type: .higherPolynomial(degree: degree), confidence: 0.8, detectedVariable: mainVariable, degree: degree)
        }
    }
    
    /// Fallback classification by pattern matching
    private func classifyByPatterns(_ equation: String) -> ClassificationResult {
        let normalized = equation.lowercased()
        
        // Check for squared terms (quadratic indicators)
        let hasSquare = EquationClassifier.squaredPatterns.contains { pattern in
            matchesPattern(normalized, pattern: pattern)
        }
        
        // Check for cubed terms
        let hasCube = EquationClassifier.cubedPatterns.contains { pattern in
            matchesPattern(normalized, pattern: pattern)
        }
        
        // Check for higher powers
        let hasHigherPower = EquationClassifier.higherPowerPatterns.contains { pattern in
            matchesPattern(normalized, pattern: pattern)
        }
        
        // Multi-digit power detection
        if let multiDigitMatch = normalized.range(of: EquationClassifier.multiDigitPowerPattern, options: .regularExpression) {
            let powerStr = String(normalized[multiDigitMatch])
            if let power = Int(powerStr.replacingOccurrences(of: "^", with: "")) {
                return ClassificationResult(type: .higherPolynomial(degree: power), confidence: 0.7, degree: power)
            }
        }
        
        // Classification logic
        if hasHigherPower {
            return ClassificationResult(type: .higherPolynomial(degree: 4), confidence: 0.6, degree: 4)
        }
        
        if hasCube {
            return ClassificationResult(type: .cubicPolynomial, confidence: 0.6, degree: 3)
        }
        
        if hasSquare {
            return ClassificationResult(type: .quadratic, confidence: 0.85, degree: 2)
        }
        
        // Check for linear indicators
        if containsVariable(normalized) {
            return ClassificationResult(type: .linear, confidence: 0.8, degree: 1)
        }
        
        // No variable found - could be constant or invalid
        if normalized.contains("=") {
            let parts = normalized.split(separator: "=")
            if parts.count == 2 {
                return ClassificationResult(type: .constant, confidence: 0.7, degree: 0)
            }
        }
        
        return ClassificationResult(type: .unknown, confidence: 0.2, degree: 0)
    }
    
    /// Classification by explicit degree extraction
    private func classifyByDegreeExtraction(_ equation: String) -> ClassificationResult {
        var maxDegree = 0
        var detectedVar: String?
        
        let variables = Set(equation.filter { $0.isLetter && $0.isLowercase })
        
        for variable in variables {
            let varStr = String(variable)
            let degree = calculateDegree(equation, variable: varStr)
            if degree > maxDegree {
                maxDegree = degree
                detectedVar = varStr
            }
        }
        
        switch maxDegree {
        case 0:
            return ClassificationResult(type: .constant, confidence: 0.6, detectedVariable: detectedVar, degree: 0)
        case 1:
            return ClassificationResult(type: .linear, confidence: 0.9, detectedVariable: detectedVar, degree: 1)
        case 2:
            return ClassificationResult(type: .quadratic, confidence: 0.9, detectedVariable: detectedVar, degree: 2)
        case 3:
            return ClassificationResult(type: .cubicPolynomial, confidence: 0.7, detectedVariable: detectedVar, degree: 3)
        default:
            return ClassificationResult(type: .higherPolynomial(degree: maxDegree), confidence: 0.7, detectedVariable: detectedVar, degree: maxDegree)
        }
    }
    
    // MARK: - Degree Calculation
    
    /// Calculates the degree of a polynomial for a specific variable
    private func calculateDegree(_ equation: String, variable: String) -> Int {
        var maxDegree = 0
        
        // Remove equals sign and right side for degree calculation
        let lhs = equation.split(separator: "=").first.map(String.init) ?? equation
        
        // Normalize the expression
        let normalized = lhs
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "**", with: "^")
            .replacingOccurrences(of: "²", with: "^2")
            .replacingOccurrences(of: "³", with: "^3")
        
        // Pattern: variable followed by power
        let powerPattern = "\(variable)\\^(\\d+)"
        if let regex = try? NSRegularExpression(pattern: powerPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: normalized, options: [], range: NSRange(normalized.startIndex..., in: normalized))
            for match in matches {
                if let powerRange = Range(match.range(at: 1), in: normalized) {
                    if let power = Int(normalized[powerRange]) {
                        maxDegree = max(maxDegree, power)
                    }
                }
            }
        }
        
        // Check for squared/cubed unicode characters
        if normalized.contains("²") && normalized.contains(variable) {
            maxDegree = max(maxDegree, 2)
        }
        if normalized.contains("³") && normalized.contains(variable) {
            maxDegree = max(maxDegree, 3)
        }
        
        // Check for superscript digits
        let superscriptMap: [Character: Int] = ["⁴": 4, "⁵": 5, "⁶": 6, "⁷": 7, "⁸": 8, "⁹": 9]
        for (superscript, value) in superscriptMap {
            if normalized.contains(superscript) && normalized.contains(variable) {
                maxDegree = max(maxDegree, value)
            }
        }
        
        // Check for implicit degree 1 (just the variable)
        let implicitPattern = "(?<![a-zA-Z])\(variable)(?![a-zA-Z0-9^])"
        if matchesPattern(normalized, pattern: implicitPattern) {
            maxDegree = max(maxDegree, 1)
        }
        
        // Check for implicit multiplication (2x, 3x)
        let coeffPattern = "\\d+\(variable)"
        if matchesPattern(normalized, pattern: coeffPattern) {
            maxDegree = max(maxDegree, 1)
        }
        
        return maxDegree
    }
    
    // MARK: - Variable Detection
    
    /// Detects the main variable in the equation
    private func detectMainVariable(_ equation: String) -> String? {
        let normalized = equation.lowercased()
        
        // Priority order for variable detection
        let priorityVariables = ["x", "y", "z", "n", "t", "a", "b", "c"]
        
        // Exclude function name letters from variable detection
        let functionNames = ["sin", "cos", "tan", "cot", "sec", "csc",
                           "arcsin", "arccos", "arctan", "asin", "acos", "atan",
                           "sinh", "cosh", "tanh", "log", "ln", "exp", "abs", "sqrt"]
        
        var cleaned = normalized
        for fn in functionNames.sorted(by: { $0.count > $1.count }) {
            cleaned = cleaned.replacingOccurrences(of: fn, with: String(repeating: "_", count: fn.count))
        }
        
        // Count occurrences of each variable
        var counts: [String: Int] = [:]
        for char in cleaned {
            let str = String(char)
            if priorityVariables.contains(str) && char != "_" {
                counts[str, default: 0] += 1
            }
        }
        
        // Return the most frequent variable, or first in priority order if tied
        if let mostFrequent = counts.max(by: { $0.value < $1.value }) {
            return mostFrequent.key
        }
        
        // Check for any single letter
        for char in cleaned {
            if char.isLetter && char.isLowercase && char != "_" {
                return String(char)
            }
        }
        
        return nil
    }
    
    // MARK: - Validation Helpers
    
    /// Checks if the equation is a constant equation (no variables)
    private func isConstantEquation(_ equation: String) -> Bool {
        let normalized = equation.lowercased()
        if normalized.contains(where: { $0.isLetter }) {
            return false
        }
        return normalized.contains("=")
    }
    
    /// Checks if the string contains a variable
    private func containsVariable(_ equation: String) -> Bool {
        return equation.range(of: EquationClassifier.variablePattern, options: .regularExpression) != nil
    }
    
    // MARK: - Normalization
    
    /// Normalizes the equation for consistent analysis
    private func normalizeForAnalysis(_ equation: String) -> String {
        var result = equation.lowercased()
        
        // Remove whitespace
        result = result.replacingOccurrences(of: " ", with: "")
        
        // Normalize multiplication signs
        result = result.replacingOccurrences(of: "×", with: "*")
        result = result.replacingOccurrences(of: "·", with: "*")
        
        // Normalize division
        result = result.replacingOccurrences(of: "÷", with: "/")
        
        // Convert Python-style ** to ^
        result = result.replacingOccurrences(of: "**", with: "^")
        
        // Normalize superscripts
        result = result.replacingOccurrences(of: "²", with: "^2")
        result = result.replacingOccurrences(of: "³", with: "^3")
        
        // Normalize implicit multiplication: 2x → 2*x
        result = result.replacingOccurrences(
            of: "(\\d)([a-z])",
            with: "$1*$2",
            options: .regularExpression
        )
        
        // Handle double negatives and signs
        result = result.replacingOccurrences(of: "--", with: "+")
        result = result.replacingOccurrences(of: "+-", with: "-")
        result = result.replacingOccurrences(of: "-+", with: "-")
        
        // Remove duplicate operators
        while result.contains("++") || result.contains("--") {
            result = result.replacingOccurrences(of: "++", with: "+")
            result = result.replacingOccurrences(of: "--", with: "+")
        }
        
        return result
    }
    
    // MARK: - Pattern Matching
    
    private func matchesPattern(_ text: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return false
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
    
    // MARK: - Utility Methods
    
    /// Validates if an equation is solvable/valid
    public func isValidEquation(_ equation: String) -> Bool {
        let result = classifyWithConfidence(equation)
        return result.confidence >= Self.confidenceThreshold
    }
    
    /// Extracts all variables in the equation
    public func extractVariables(_ equation: String) -> [String] {
        var variables: Set<String> = []
        for char in equation.lowercased() {
            if char.isLetter {
                variables.insert(String(char))
            }
        }
        return Array(variables).sorted()
    }
    
    /// Determines if the equation is in standard form
    public func isStandardForm(_ equation: String) -> Bool {
        let normalized = normalizeForAnalysis(equation)
        
        if matchesPattern(normalized, pattern: "\\d*[a-z]\\^?\\d*[+-]") {
            return true
        }
        
        return false
    }
}
