//
//  EquationParser.swift
//  QuickMathsAR
//
//  Parses equation strings into graph-ready data
//

#if os(iOS)

import Foundation

/// Parses equation strings into structured equation data for graphing
public enum EquationParser {
    
    // MARK: - Public API
    
    /// Parse a linear equation string
    /// Supports formats like: "2x + 5 = 13", "y = 3x - 2", "x + 4 = 0"
    /// Returns nil if parsing fails
    public static func parseLinearEquation(_ input: String) -> LinearEquation? {
        let cleaned = normalizeEquation(input)
        
        // Try different linear equation patterns
        if let result = parseStandardLinear(cleaned) {
            return result
        }
        
        if let result = parseSlopeInterceptForm(cleaned) {
            return result
        }
        
        return nil
    }
    
    /// Parse a quadratic equation string
    /// Supports formats like: "x² + 5x + 6 = 0", "y = x^2 - 4", "2x² - 3x + 1 = 0"
    /// Returns nil if parsing fails
    public static func parseQuadraticEquation(_ input: String) -> QuadraticEquation? {
        let cleaned = normalizeEquation(input)
        
        // Try to parse standard form: ax² + bx + c = 0
        if let result = parseStandardQuadratic(cleaned) {
            return result
        }
        
        return nil
    }
    
    /// Attempt to parse an equation and determine its type
    public static func parse(_ input: String) -> ParsedEquation? {
        // First try quadratic (has higher degree)
        if let quadratic = parseQuadraticEquation(input) {
            return .quadratic(quadratic)
        }
        
        // Then try linear
        if let linear = parseLinearEquation(input) {
            return .linear(linear)
        }
        
        return nil
    }
    
    // MARK: - Safe Parse (Graceful Failure)
    
    /// Result of a safe parse attempt
    public enum ParseResult {
        /// Successfully parsed into a supported equation
        case success(ParsedEquation)
        /// Recognized but unsupported equation type
        case unsupported(type: EquationType, message: String)
        /// Failed to parse
        case failed(reason: String, suggestion: String?)
    }
    
    /// Safely parses an equation with graceful failure handling
    /// - Parameter input: The equation string to parse
    /// - Returns: A ParseResult that never crashes
    public static func safeParse(_ input: String) -> ParseResult {
        // First classify
        let classifier = EquationClassifier()
        let classification = classifier.classifyWithConfidence(input)
        
        // Check if supported
        guard classification.type.isSupported else {
            return .unsupported(
                type: classification.type,
                message: classification.type.educationalMessage
            )
        }
        
        // Attempt parsing based on type
        switch classification.type {
        case .linear:
            if let linear = parseLinearEquation(input) {
                return .success(.linear(linear))
            }
            return .failed(
                reason: "Could not extract linear coefficients",
                suggestion: "Try format: 2x + 3 = 7"
            )
            
        case .quadratic:
            if let quadratic = parseQuadraticEquation(input) {
                return .success(.quadratic(quadratic))
            }
            return .failed(
                reason: "Could not extract quadratic coefficients",
                suggestion: "Try format: x² + 5x + 6 = 0"
            )
            
        default:
            return .failed(
                reason: "Unexpected equation type",
                suggestion: classification.type.suggestedAlternative
            )
        }
    }
    
    // MARK: - Normalization
    
    private static func normalizeEquation(_ input: String) -> String {
        var result = input.lowercased()
        
        // Replace unicode superscripts
        result = result.replacingOccurrences(of: "²", with: "^2")
        result = result.replacingOccurrences(of: "³", with: "^3")
        
        // Replace multiplication symbols
        result = result.replacingOccurrences(of: "×", with: "*")
        result = result.replacingOccurrences(of: "·", with: "*")
        
        // Replace division symbols
        result = result.replacingOccurrences(of: "÷", with: "/")
        
        // Replace minus signs
        result = result.replacingOccurrences(of: "−", with: "-")
        result = result.replacingOccurrences(of: "–", with: "-")
        
        // Remove spaces
        result = result.replacingOccurrences(of: " ", with: "")
        
        return result
    }
    
    // MARK: - Linear Parsing
    
    /// Parse "ax + b = c" form
    private static func parseStandardLinear(_ input: String) -> LinearEquation? {
        // Split by equals sign
        let parts = input.split(separator: "=")
        guard parts.count == 2 else { return nil }
        
        let leftSide = String(parts[0])
        let rightSide = String(parts[1])
        
        // Try to extract coefficient and constant from left side
        // ax + b = c  =>  y = ax + (b - c)
        
        var slope: Float = 0
        var leftConstant: Float = 0
        var rightConstant: Float = 0
        
        // Parse left side
        if let (s, c) = parseLinearExpression(leftSide) {
            slope = s
            leftConstant = c
        }
        
        // Parse right side (should be a constant for standard form)
        if let rightValue = parseNumber(rightSide) {
            rightConstant = rightValue
        } else if let (_, _) = parseLinearExpression(rightSide), slope == 0 {
            // Right side has the x term
            return nil // Not standard form
        }
        
        // If no x term found, this isn't a linear equation we can graph
        if slope == 0 {
            // Check if it's something like "x = 5" (vertical line - skip for now)
            if leftSide == "x" {
                // Vertical line at x = rightConstant
                // We don't support vertical lines in y = mx + b form
                return nil
            }
            return nil
        }
        
        // Calculate y-intercept: b - c (move constant to right side, negate)
        let yIntercept = leftConstant - rightConstant
        
        return LinearEquation(slope: slope, yIntercept: yIntercept)
    }
    
    /// Parse "y = mx + b" form
    private static func parseSlopeInterceptForm(_ input: String) -> LinearEquation? {
        // Check if it starts with "y="
        guard input.hasPrefix("y=") else { return nil }
        
        let expression = String(input.dropFirst(2))
        
        if let (slope, yIntercept) = parseLinearExpression(expression) {
            return LinearEquation(slope: slope, yIntercept: yIntercept)
        }
        
        return nil
    }
    
    /// Parse a linear expression like "2x+3" or "-x-5"
    /// Returns (coefficient of x, constant)
    private static func parseLinearExpression(_ expr: String) -> (Float, Float)? {
        var coefficient: Float = 0
        var constant: Float = 0
        
        // Split into terms (handling signs)
        let terms = splitIntoTerms(expr)
        
        for term in terms {
            if term.contains("x") {
                // This is the x term
                var coefStr = term.replacingOccurrences(of: "x", with: "")
                if coefStr.isEmpty || coefStr == "+" {
                    coefStr = "1"
                } else if coefStr == "-" {
                    coefStr = "-1"
                }
                if let coef = Float(coefStr) {
                    coefficient += coef
                }
            } else if !term.isEmpty {
                // This is a constant
                if let val = Float(term) {
                    constant += val
                }
            }
        }
        
        return (coefficient, constant)
    }
    
    // MARK: - Quadratic Parsing
    
    /// Parse "ax^2 + bx + c = 0" or "y = ax^2 + bx + c" form
    private static func parseStandardQuadratic(_ input: String) -> QuadraticEquation? {
        var expression = input
        
        // Handle "y = ..." form
        if input.hasPrefix("y=") {
            expression = String(input.dropFirst(2))
        } else if let equalsIndex = input.firstIndex(of: "=") {
            // Handle "... = 0" form
            let rightSide = String(input[input.index(after: equalsIndex)...])
            if let rightVal = parseNumber(rightSide), rightVal == 0 {
                expression = String(input[..<equalsIndex])
            } else {
                // Non-zero right side - would need to rearrange
                return nil
            }
        }
        
        // Parse coefficients
        var a: Float = 0
        var b: Float = 0
        var c: Float = 0
        
        let terms = splitIntoTerms(expression)
        
        for term in terms {
            if term.contains("x^2") || term.contains("x²") {
                // Quadratic term
                var coefStr = term.replacingOccurrences(of: "x^2", with: "")
                    .replacingOccurrences(of: "x²", with: "")
                if coefStr.isEmpty || coefStr == "+" {
                    coefStr = "1"
                } else if coefStr == "-" {
                    coefStr = "-1"
                }
                if let coef = Float(coefStr) {
                    a += coef
                }
            } else if term.contains("x") {
                // Linear term
                var coefStr = term.replacingOccurrences(of: "x", with: "")
                if coefStr.isEmpty || coefStr == "+" {
                    coefStr = "1"
                } else if coefStr == "-" {
                    coefStr = "-1"
                }
                if let coef = Float(coefStr) {
                    b += coef
                }
            } else if !term.isEmpty {
                // Constant term
                if let val = Float(term) {
                    c += val
                }
            }
        }
        
        // Must have a quadratic term
        guard abs(a) > Float.ulpOfOne else { return nil }
        
        return QuadraticEquation(a: a, b: b, c: c)
    }
    
    // MARK: - Helpers
    
    /// Split expression into terms, preserving signs
    private static func splitIntoTerms(_ expr: String) -> [String] {
        var terms: [String] = []
        var currentTerm = ""
        
        for (index, char) in expr.enumerated() {
            if (char == "+" || char == "-") && index > 0 {
                if !currentTerm.isEmpty {
                    terms.append(currentTerm)
                }
                currentTerm = String(char)
            } else {
                currentTerm.append(char)
            }
        }
        
        if !currentTerm.isEmpty {
            terms.append(currentTerm)
        }
        
        return terms
    }
    
    /// Parse a simple number string
    private static func parseNumber(_ str: String) -> Float? {
        return Float(str.trimmingCharacters(in: .whitespaces))
    }
}

// MARK: - Parsed Equation Result

/// Result of parsing an equation
public enum ParsedEquation {
    case linear(LinearEquation)
    case quadratic(QuadraticEquation)
    
    /// Generate graph data for this equation
    public func generateGraphData(configuration: GraphConfiguration? = nil) -> GraphData {
        switch self {
        case .linear(let equation):
            return GraphDataGenerator.generate(
                linear: equation,
                configuration: configuration ?? .linear
            )
        case .quadratic(let equation):
            return GraphDataGenerator.generate(
                quadratic: equation,
                configuration: configuration ?? .quadratic
            )
        }
    }
    
    /// The equation type
    public var graphType: GraphEquationType {
        switch self {
        case .linear: return .linear
        case .quadratic: return .quadratic
        }
    }
}

#endif
