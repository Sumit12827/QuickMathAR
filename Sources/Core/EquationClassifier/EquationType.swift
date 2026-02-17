//
//  EquationType.swift
//  QuickMathsAR
//
//  Classification result for mathematical equations
//  Expanded to recognize unsupported types gracefully
//

import Foundation

// MARK: - Malformed Reason

/// Describes why an equation input is malformed
public enum MalformedReason: String, Equatable, Hashable {
    case empty = "Empty input"
    case noVariable = "No variable found"
    case noEquals = "Missing equals sign"
    case unbalancedParentheses = "Unbalanced parentheses"
    case invalidCharacters = "Invalid characters"
    case incomplete = "Incomplete equation"
    case unparseable = "Could not parse"
}

// MARK: - EquationType

/// Represents the classification of a mathematical equation with detailed metadata
public enum EquationType: Equatable, Hashable, Identifiable {
    
    // MARK: - Supported Types
    
    /// Linear equation (degree 1): ax + b = c
    case linear
    
    /// Quadratic equation (degree 2): ax² + bx + c = 0
    case quadratic
    
    /// Constant equation (degree 0): no variables
    case constant
    
    // MARK: - Recognized Unsupported Types (educational opportunity)
    
    /// Cubic polynomial (degree 3): ax³ + bx² + cx + d = 0
    case cubicPolynomial
    
    /// Higher-degree polynomial (degree 4+)
    case higherPolynomial(degree: Int)
    
    /// Circle: x² + y² = r²
    case circle
    
    /// Ellipse: x²/a² + y²/b² = 1
    case ellipse
    
    /// Hyperbola: x²/a² - y²/b² = 1
    case hyperbola
    
    /// Trigonometric function: sin(x), cos(x), etc.
    case trigonometric(function: String)
    
    /// Exponential function: e^x, 2^x, exp(x)
    case exponential
    
    /// Logarithmic function: log(x), ln(x)
    case logarithmic
    
    /// Absolute value: |x|, abs(x)
    case absoluteValue
    
    /// Square root function: √x, sqrt(x)
    case squareRoot
    
    /// Rational function: 1/x, (x+1)/(x-2)
    case rationalFunction
    
    // MARK: - Unrecognized
    
    /// Malformed input with a specific reason
    case malformed(reason: MalformedReason)
    
    /// Equation type could not be determined
    case unknown
    
    // MARK: - Identifiable
    
    public var id: String {
        switch self {
        case .linear: return "linear"
        case .quadratic: return "quadratic"
        case .constant: return "constant"
        case .cubicPolynomial: return "cubicPolynomial"
        case .higherPolynomial(let degree): return "higherPolynomial_\(degree)"
        case .circle: return "circle"
        case .ellipse: return "ellipse"
        case .hyperbola: return "hyperbola"
        case .trigonometric(let fn): return "trigonometric_\(fn)"
        case .exponential: return "exponential"
        case .logarithmic: return "logarithmic"
        case .absoluteValue: return "absoluteValue"
        case .squareRoot: return "squareRoot"
        case .rationalFunction: return "rationalFunction"
        case .malformed(let reason): return "malformed_\(reason.rawValue)"
        case .unknown: return "unknown"
        }
    }
    
    // MARK: - allCases (manual)
    
    /// Representative cases for iteration (excludes parameterized variants)
    public static var allCases: [EquationType] {
        return [.linear, .quadratic, .constant, .unknown]
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: EquationType, rhs: EquationType) -> Bool {
        switch (lhs, rhs) {
        case (.linear, .linear), (.quadratic, .quadratic),
             (.constant, .constant), (.unknown, .unknown),
             (.cubicPolynomial, .cubicPolynomial),
             (.circle, .circle), (.ellipse, .ellipse), (.hyperbola, .hyperbola),
             (.exponential, .exponential), (.logarithmic, .logarithmic),
             (.absoluteValue, .absoluteValue), (.squareRoot, .squareRoot),
             (.rationalFunction, .rationalFunction):
            return true
        case (.higherPolynomial(let d1), .higherPolynomial(let d2)):
            return d1 == d2
        case (.trigonometric(let f1), .trigonometric(let f2)):
            return f1 == f2
        case (.malformed(let r1), .malformed(let r2)):
            return r1 == r2
        default:
            return false
        }
    }
    
    // MARK: - Support Status
    
    /// Whether the app can fully process this equation type
    public var isSupported: Bool {
        switch self {
        case .linear, .quadratic:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Display Properties
    
    /// Human-readable name for UI presentation
    public var displayName: String {
        switch self {
        case .linear:
            return "Linear Equation"
        case .quadratic:
            return "Quadratic Equation"
        case .constant:
            return "Constant Expression"
        case .cubicPolynomial:
            return "Cubic Equation"
        case .higherPolynomial(let degree):
            return "Degree-\(degree) Polynomial"
        case .circle:
            return "Circle Equation"
        case .ellipse:
            return "Ellipse Equation"
        case .hyperbola:
            return "Hyperbola Equation"
        case .trigonometric(let function):
            return "\(function.capitalized) Function"
        case .exponential:
            return "Exponential Function"
        case .logarithmic:
            return "Logarithmic Function"
        case .absoluteValue:
            return "Absolute Value"
        case .squareRoot:
            return "Square Root Function"
        case .rationalFunction:
            return "Rational Function"
        case .malformed:
            return "Invalid Input"
        case .unknown:
            return "Unrecognized Equation"
        }
    }
    
    /// Brief description of the equation type
    public var description: String {
        switch self {
        case .linear:
            return "First-degree equation that forms a straight line when graphed"
        case .quadratic:
            return "Second-degree equation that forms a parabola when graphed"
        case .constant:
            return "Expression with no variables (constant value)"
        case .cubicPolynomial:
            return "Third-degree polynomial with S-shaped curves"
        case .higherPolynomial(let degree):
            return "Degree-\(degree) polynomial with complex behavior"
        case .circle:
            return "Conic section forming a perfect round shape"
        case .ellipse:
            return "Conic section forming an oval shape"
        case .hyperbola:
            return "Conic section forming twin open curves"
        case .trigonometric(let function):
            return "Trigonometric \(function) function creating wave patterns"
        case .exponential:
            return "Function showing rapid growth or decay"
        case .logarithmic:
            return "Inverse of exponential — measures orders of magnitude"
        case .absoluteValue:
            return "Function creating V-shaped graphs"
        case .squareRoot:
            return "Function creating half-parabola curves"
        case .rationalFunction:
            return "Function with variables in the denominator"
        case .malformed(let reason):
            return reason.rawValue
        case .unknown:
            return "Could not determine equation type. Try writing more clearly."
        }
    }
    
    /// Example equation for this type
    public var example: String {
        switch self {
        case .linear: return "2x + 5 = 13"
        case .quadratic: return "x² + 5x + 6 = 0"
        case .constant: return "5 + 3 = 8"
        case .cubicPolynomial: return "x³ - 8 = 0"
        case .higherPolynomial(let degree): return "x^\(degree) + 1 = 0"
        case .circle: return "x² + y² = 25"
        case .ellipse: return "x²/9 + y²/4 = 1"
        case .hyperbola: return "x²/9 - y²/4 = 1"
        case .trigonometric(let fn): return "\(fn)(x) = 0"
        case .exponential: return "y = e^x"
        case .logarithmic: return "y = log(x)"
        case .absoluteValue: return "|x - 3| = 5"
        case .squareRoot: return "y = √x"
        case .rationalFunction: return "y = 1/x"
        case .malformed: return "—"
        case .unknown: return "—"
        }
    }
    
    /// Learning content available for this type
    public var hasLearningContent: Bool {
        switch self {
        case .linear, .quadratic:
            return true
        default:
            return false
        }
    }
    
    /// AR visualization available for this type
    public var supportsARVisualization: Bool {
        switch self {
        case .linear, .quadratic:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Mathematical Properties
    
    /// Expected number of solutions
    public var expectedSolutions: String {
        switch self {
        case .linear: return "1 solution"
        case .quadratic: return "0, 1, or 2 solutions"
        case .constant: return "0 or infinite"
        case .cubicPolynomial: return "1 to 3 solutions"
        case .higherPolynomial(let degree): return "Up to \(degree) solutions"
        case .circle, .ellipse, .hyperbola: return "Infinite points on the curve"
        case .trigonometric: return "Infinite periodic solutions"
        case .exponential, .logarithmic: return "Depends on the equation"
        case .absoluteValue: return "0, 1, or 2 solutions"
        case .squareRoot: return "0 or 1 solution"
        case .rationalFunction: return "Depends on the equation"
        case .malformed, .unknown: return "Unknown"
        }
    }
    
    /// Standard form representation
    public var standardForm: String {
        switch self {
        case .linear: return "ax + b = c"
        case .quadratic: return "ax² + bx + c = 0"
        case .constant: return "a = b"
        case .cubicPolynomial: return "ax³ + bx² + cx + d = 0"
        case .higherPolynomial(let degree):
            var terms: [String] = []
            for i in (0...degree).reversed() {
                if i == 0 { terms.append("c") }
                else if i == 1 { terms.append("bx") }
                else { terms.append("a\(i)x^\(i)") }
            }
            return terms.joined(separator: " + ") + " = 0"
        case .circle: return "x² + y² = r²"
        case .ellipse: return "x²/a² + y²/b² = 1"
        case .hyperbola: return "x²/a² - y²/b² = 1"
        case .trigonometric(let fn): return "y = \(fn)(x)"
        case .exponential: return "y = aˣ"
        case .logarithmic: return "y = log(x)"
        case .absoluteValue: return "y = |x|"
        case .squareRoot: return "y = √x"
        case .rationalFunction: return "y = p(x)/q(x)"
        case .malformed, .unknown: return "?"
        }
    }
    
    // MARK: - UI Properties
    
    /// SF Symbol icon for this type
    public var iconName: String {
        switch self {
        case .linear: return "line.diagonal"
        case .quadratic: return "waveform.path.ecg"
        case .constant: return "equal"
        case .cubicPolynomial: return "chart.line.uptrend.xyaxis"
        case .higherPolynomial: return "chart.xyaxis.line"
        case .circle: return "circle"
        case .ellipse: return "oval"
        case .hyperbola: return "arrow.up.left.and.arrow.down.right"
        case .trigonometric: return "waveform"
        case .exponential: return "arrow.up.right.circle"
        case .logarithmic: return "chart.line.downtrend.xyaxis"
        case .absoluteValue: return "chevron.down"
        case .squareRoot: return "x.squareroot"
        case .rationalFunction: return "divide"
        case .malformed: return "exclamationmark.triangle"
        case .unknown: return "questionmark.diamond"
        }
    }
    
    /// Color associated with this type for UI
    public var themeColor: String {
        switch self {
        case .linear: return "blue"
        case .quadratic: return "purple"
        case .constant: return "gray"
        case .cubicPolynomial, .higherPolynomial: return "orange"
        case .circle, .ellipse, .hyperbola: return "teal"
        case .trigonometric: return "cyan"
        case .exponential: return "pink"
        case .logarithmic: return "indigo"
        case .absoluteValue: return "mint"
        case .squareRoot: return "green"
        case .rationalFunction: return "brown"
        case .malformed: return "red"
        case .unknown: return "red"
        }
    }
    
    /// Difficulty level for learning
    public var difficulty: Difficulty {
        switch self {
        case .linear, .constant:
            return .beginner
        case .quadratic:
            return .intermediate
        case .cubicPolynomial, .higherPolynomial, .absoluteValue, .squareRoot:
            return .advanced
        case .circle, .ellipse, .hyperbola,
             .trigonometric, .exponential, .logarithmic, .rationalFunction:
            return .advanced
        case .malformed, .unknown:
            return .unknown
        }
    }
    
    /// Difficulty enum
    public enum Difficulty: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case unknown = "Unknown"
    }
    
    // MARK: - Educational Content
    
    /// Rich educational message explaining the equation type
    public var educationalMessage: String {
        switch self {
        case .linear:
            return "Linear equations form straight lines and have exactly one solution. Choose how you'd like to explore!"
        case .quadratic:
            return "Quadratic equations form parabolas and can have 0, 1, or 2 solutions. Let's explore!"
        case .constant:
            return "This expression has no variables—it's a constant. Try adding 'x' to create an equation!"
        case .cubicPolynomial:
            return "Cubic equations (degree 3) form S-shaped curves. They're fascinating but beyond our current scope. We focus on building strong foundations with linear and quadratic equations first."
        case .higherPolynomial(let degree):
            return "This is a degree-\(degree) polynomial—quite advanced! QuickMathsAR focuses on linear and quadratic equations to help you master the fundamentals."
        case .circle:
            return "You've entered a circle equation! Circles are part of conic sections—a beautiful area of mathematics. Our app specializes in linear and quadratic equations."
        case .ellipse:
            return "This is an ellipse equation—an oval-shaped curve. Ellipses appear in planetary orbits! We currently focus on linear and quadratic equations."
        case .hyperbola:
            return "Hyperbola detected! These twin-curved shapes appear in physics and navigation. Our focus is on linear and quadratic equations for now."
        case .trigonometric(let function):
            return "You've entered a \(function) function—part of trigonometry! These create wave patterns. QuickMathsAR specializes in polynomial equations (linear & quadratic)."
        case .exponential:
            return "Exponential functions show rapid growth or decay—like population growth or radioactive decay! We focus on linear and quadratic equations."
        case .logarithmic:
            return "Logarithms are the inverse of exponentials—used in measuring earthquakes and sound! Our app focuses on linear and quadratic equations."
        case .absoluteValue:
            return "Absolute value creates V-shaped graphs! While interesting, we specialize in linear and quadratic equations."
        case .squareRoot:
            return "Square root functions create half-parabola shapes! We focus on linear and quadratic equations for foundational learning."
        case .rationalFunction:
            return "Rational functions have variables in denominators, creating asymptotes! We specialize in polynomial equations (linear & quadratic)."
        case .malformed(let reason):
            return "We couldn't parse this input: \(reason.rawValue). Try a simpler format like '2x + 3 = 7' or 'x² - 4 = 0'."
        case .unknown:
            return "We couldn't identify this equation type. Try formats like '2x + 3 = 7' (linear) or 'x² + 5x + 6 = 0' (quadratic)."
        }
    }
    
    /// Suggested alternative equation the user could try
    public var suggestedAlternative: String? {
        switch self {
        case .linear, .quadratic:
            return nil // Already supported
        case .constant:
            return "2x + 3 = 7"
        case .cubicPolynomial, .higherPolynomial:
            return "x² + 5x + 6 = 0"
        case .circle, .ellipse, .hyperbola:
            return "x² - 4 = 0"
        case .trigonometric:
            return "2x + 3 = 7"
        case .exponential, .logarithmic:
            return "x² - 2x - 3 = 0"
        case .absoluteValue:
            return "2x - 6 = 0"
        case .squareRoot:
            return "x² = 9"
        case .rationalFunction:
            return "3x + 1 = 10"
        case .malformed, .unknown:
            return "2x + 5 = 13"
        }
    }
}
