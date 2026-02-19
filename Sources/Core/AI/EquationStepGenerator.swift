//
//  EquationStepGenerator.swift
//  QuickMathsAR
//
//  Generates SolvingStep arrays dynamically for the user's
//  specific equation. Each step has level-appropriate reasoning.
//

import Foundation

// MARK: - Equation Step Generator

/// Generates step-by-step solutions for the user's specific equation.
/// Steps are deterministic (actual math), while the reasoning text
/// adapts to the selected explanation level.
public struct EquationStepGenerator: Sendable {
    
    public init() {}
    
    // MARK: - Public API
    
    /// Generate solving steps for the given equation.
    /// Returns nil if the equation can't be parsed.
    public func generateSteps(
        equation: String,
        type: EquationType
    ) -> [SolvingStep]? {
        guard let parsed = EquationParser.parse(equation) else { return nil }
        
        switch parsed {
        case .quadratic(let q):
            return generateQuadraticSteps(q, equation: equation)
        case .linear(let l):
            return generateLinearSteps(l, equation: equation)
        }
    }
    
    // MARK: - Linear Steps
    
    /// Generate steps for a linear equation: ax + b = c
    /// Flow: Identify → Isolate constant → Solve for x → Verify
    private func generateLinearSteps(_ eq: LinearEquation, equation: String) -> [SolvingStep] {
        // Reconstruct from parsed: y = mx + b means mx + b = 0 → x = -b/m
        let m = eq.slope
        let b = eq.yIntercept
        
        guard abs(m) > Float.ulpOfOne else { return [] }
        
        let solution = -b / m
        
        var steps: [SolvingStep] = []
        
        // Step 1: Identify
        steps.append(SolvingStep(
            stepNumber: 1,
            action: "Identify what we're solving",
            reasoning: .detailed(StepReasoning(
                brief: "We need to find the value of x that makes this equation true.",
                detailed: "This is a linear equation in the form ax + b = c. Our goal is to isolate x by undoing the operations applied to it, working in reverse order.",
                metaphor: "Think of x as a hidden treasure — the equation is a map with clues to find it."
            )),
            result: equation,
            arithmeticConceptUsed: "identification",
            transformation: Transformation(
                before: equation,
                operation: "Identify",
                after: "Goal: find x",
                animation: "highlight"
            ),
            tooltip: nil
        ))
        
        // Step 2: Isolate variable term
        if abs(b) > Float.ulpOfOne {
            let bSign = b > 0 ? "+" : "−"
            let bAbs = formatFloat(abs(b))
            let resultVal = -b  // What's left on the right after moving b
            
            steps.append(SolvingStep(
                stepNumber: 2,
                action: b > 0
                    ? "Subtract \(bAbs) from both sides"
                    : "Add \(bAbs) to both sides",
                reasoning: .detailed(StepReasoning(
                    brief: "Move the constant to the other side to isolate the x term.",
                    detailed: "We apply the \(b > 0 ? "subtraction" : "addition") property of equality: doing the same operation to both sides keeps the equation balanced. This moves the constant \(bSign)\(bAbs) away from x.",
                    metaphor: "Like removing equal weight from both sides of a balanced scale — it stays balanced."
                )),
                result: "\(formatFloat(m))x = \(formatFloat(resultVal))",
                arithmeticConceptUsed: b > 0 ? "subtraction" : "addition",
                transformation: Transformation(
                    before: equation,
                    operation: b > 0 ? "− \(bAbs)" : "+ \(bAbs)",
                    after: "\(formatFloat(m))x = \(formatFloat(resultVal))",
                    animation: "slide_out",
                    highlightTarget: bAbs
                ),
                tooltip: nil
            ))
        }
        
        // Step 3: Solve for x
        if abs(m) != 1 {
            steps.append(SolvingStep(
                stepNumber: steps.count + 1,
                action: "Divide both sides by \(formatFloat(m))",
                reasoning: .detailed(StepReasoning(
                    brief: "Divide both sides by \(formatFloat(m)) to get x alone.",
                    detailed: "The multiplication property of equality says dividing both sides by the same non-zero number preserves the equality. Since x is multiplied by \(formatFloat(m)), we divide by \(formatFloat(m)) to undo that.",
                    metaphor: "Like splitting a group evenly — if \(formatFloat(m)) groups total \(formatFloat(-b)), each group has \(formatFloat(solution))."
                )),
                result: "x = \(formatFloat(solution))",
                arithmeticConceptUsed: "division",
                transformation: Transformation(
                    before: "\(formatFloat(m))x = \(formatFloat(-b))",
                    operation: "÷ \(formatFloat(m))",
                    after: "x = \(formatFloat(solution))",
                    animation: "simplify"
                ),
                tooltip: nil
            ))
        }
        
        // Step 4: Verify
        steps.append(SolvingStep(
            stepNumber: steps.count + 1,
            action: "Verify the solution",
            reasoning: .detailed(StepReasoning(
                brief: "Plug x = \(formatFloat(solution)) back into the original equation to check.",
                detailed: "Substituting our answer back into the original equation should make both sides equal. This confirms we haven't made an error. Always verify your solutions!",
                metaphor: "Like re-reading a decoded message to make sure it makes sense."
            )),
            result: "x = \(formatFloat(solution)) ✓",
            arithmeticConceptUsed: "verification",
            transformation: nil,
            tooltip: nil
        ))
        
        return steps
    }
    
    // MARK: - Quadratic Steps
    
    /// Generate steps for a quadratic equation: ax² + bx + c = 0
    /// Flow: Identify → Calculate discriminant → Apply formula → Simplify → Interpret
    private func generateQuadraticSteps(_ eq: QuadraticEquation, equation: String) -> [SolvingStep] {
        let a = eq.a
        let b = eq.b
        let c = eq.c
        let disc = eq.discriminant
        let roots = eq.xIntercepts
        
        var steps: [SolvingStep] = []
        
        // Step 1: Identify
        steps.append(SolvingStep(
            stepNumber: 1,
            action: "Identify the equation type and coefficients",
            reasoning: .detailed(StepReasoning(
                brief: "This is a quadratic equation. We identify a = \(formatFloat(a)), b = \(formatFloat(b)), c = \(formatFloat(c)).",
                detailed: "In the standard form ax² + bx + c = 0, the coefficients are a = \(formatFloat(a)) (how wide/narrow and which direction the parabola opens), b = \(formatFloat(b)) (shifts the vertex left or right), and c = \(formatFloat(c)) (the y-intercept).",
                metaphor: "Reading the ingredients before cooking — you need to know all three coefficients before applying the quadratic formula."
            )),
            result: "a = \(formatFloat(a)),  b = \(formatFloat(b)),  c = \(formatFloat(c))",
            arithmeticConceptUsed: "identification",
            transformation: Transformation(
                before: equation,
                operation: "Identify",
                after: "a=\(formatFloat(a)), b=\(formatFloat(b)), c=\(formatFloat(c))",
                animation: "highlight"
            ),
            tooltip: nil
        ))
        
        // Step 2: Calculate discriminant
        let discCalc = "\(formatFloat(b))² − 4(\(formatFloat(a)))(\(formatFloat(c)))"
        steps.append(SolvingStep(
            stepNumber: 2,
            action: "Calculate the discriminant (b² − 4ac)",
            reasoning: .detailed(StepReasoning(
                brief: "The discriminant tells us how many solutions exist: \(discCalc) = \(formatFloat(disc)).",
                detailed: "The discriminant Δ = b² − 4ac determines the nature of the roots. If Δ > 0, there are 2 distinct real roots. If Δ = 0, there is exactly 1 repeated root. If Δ < 0, there are no real roots (only complex ones). Here, Δ = \(formatFloat(disc)).",
                metaphor: disc > 0
                    ? "Think of it like checking if a ball thrown in an arc will land — a positive discriminant means it crosses the ground in two places."
                    : disc == 0
                    ? "Like a ball that just barely touches the ground at one point before bouncing back up."
                    : "Like throwing a ball that never reaches the ground — it stays above it the whole time."
            )),
            result: "Δ = \(formatFloat(disc))",
            arithmeticConceptUsed: "order_of_operations",
            transformation: Transformation(
                before: "b² − 4ac",
                operation: discCalc,
                after: "Δ = \(formatFloat(disc))",
                animation: "calculate"
            ),
            tooltip: Tooltip(
                trigger: "discriminant",
                content: "The discriminant (Δ) is the expression under the square root in the quadratic formula. It determines how many times the parabola crosses the x-axis."
            )
        ))
        
        // Step 3: Apply quadratic formula
        if disc >= 0 {
            let sqrtDisc = sqrtf(disc)
            
            steps.append(SolvingStep(
                stepNumber: 3,
                action: "Apply the quadratic formula",
                reasoning: .detailed(StepReasoning(
                    brief: "Use x = (−b ± √Δ) / 2a to find the solution\(roots.count > 1 ? "s" : "").",
                    detailed: "The quadratic formula x = (−b ± √Δ) / 2a gives us x = (\(formatFloat(-b)) ± √\(formatFloat(disc))) / \(formatFloat(2 * a)) = (\(formatFloat(-b)) ± \(formatFloat(sqrtDisc))) / \(formatFloat(2 * a)).",
                    metaphor: "The quadratic formula is like a master key — it opens any quadratic lock, regardless of how complex the coefficients are."
                )),
                result: "x = (\(formatFloat(-b)) ± \(formatFloat(sqrtDisc))) / \(formatFloat(2 * a))",
                arithmeticConceptUsed: "order_of_operations",
                transformation: Transformation(
                    before: "x = (−b ± √Δ) / 2a",
                    operation: "Substitute",
                    after: "x = (\(formatFloat(-b)) ± \(formatFloat(sqrtDisc))) / \(formatFloat(2 * a))",
                    animation: "substitute"
                ),
                tooltip: nil
            ))
            
            // Step 4: Simplify to get roots
            if roots.count == 2 {
                steps.append(SolvingStep(
                    stepNumber: 4,
                    action: "Calculate both solutions",
                    reasoning: .detailed(StepReasoning(
                        brief: "Split into two solutions using + and − from the ± symbol.",
                        detailed: "x₁ = (\(formatFloat(-b)) + \(formatFloat(sqrtDisc))) / \(formatFloat(2 * a)) = \(formatFloat(roots[1])) and x₂ = (\(formatFloat(-b)) − \(formatFloat(sqrtDisc))) / \(formatFloat(2 * a)) = \(formatFloat(roots[0])).",
                        metaphor: "Like two different paths that both lead to valid answers — the ± gives us both routes."
                    )),
                    result: "x = \(formatFloat(roots[0]))  or  x = \(formatFloat(roots[1]))",
                    arithmeticConceptUsed: "division",
                    transformation: Transformation(
                        before: "x = (\(formatFloat(-b)) ± \(formatFloat(sqrtDisc))) / \(formatFloat(2 * a))",
                        operation: "Simplify",
                        after: "x₁ = \(formatFloat(roots[1])), x₂ = \(formatFloat(roots[0]))",
                        animation: "split"
                    ),
                    tooltip: nil
                ))
            } else if roots.count == 1 {
                steps.append(SolvingStep(
                    stepNumber: 4,
                    action: "Calculate the repeated solution",
                    reasoning: .detailed(StepReasoning(
                        brief: "Since the discriminant is zero, there's one repeated root.",
                        detailed: "x = \(formatFloat(-b)) / \(formatFloat(2 * a)) = \(formatFloat(roots[0])). The discriminant being zero means the parabola just touches the x-axis at this one point (the vertex).",
                        metaphor: "Like a ball that perfectly skims the ground at one exact spot."
                    )),
                    result: "x = \(formatFloat(roots[0]))",
                    arithmeticConceptUsed: "division",
                    transformation: nil,
                    tooltip: nil
                ))
            }
        } else {
            // No real roots
            steps.append(SolvingStep(
                stepNumber: 3,
                action: "Interpret: no real solutions",
                reasoning: .detailed(StepReasoning(
                    brief: "Since the discriminant is negative, there are no real solutions.",
                    detailed: "A negative discriminant (Δ = \(formatFloat(disc))) means we'd need to take the square root of a negative number, which has no real value. The parabola never crosses the x-axis. In advanced math, the solutions would be complex numbers.",
                    metaphor: "Like a ball thrown upward that never comes back down to ground level — the parabola floats above (or below) the x-axis."
                )),
                result: "No real solutions (Δ < 0)",
                arithmeticConceptUsed: "order_of_operations",
                transformation: nil,
                tooltip: Tooltip(
                    trigger: "complex",
                    content: "Complex numbers extend the number line into two dimensions. They use 'i' to represent √(-1), but you don't need to worry about them for now!"
                )
            ))
        }
        
        // Final step: Interpret result
        let interpretStep = steps.count + 1
        let interpretResult: String
        if roots.count == 2 {
            interpretResult = "The parabola crosses the x-axis at x = \(formatFloat(roots[0])) and x = \(formatFloat(roots[1]))"
        } else if roots.count == 1 {
            interpretResult = "The parabola touches the x-axis at x = \(formatFloat(roots[0]))"
        } else {
            interpretResult = "The parabola never crosses the x-axis"
        }
        
        steps.append(SolvingStep(
            stepNumber: interpretStep,
            action: "Interpret the result",
            reasoning: .detailed(StepReasoning(
                brief: interpretResult + ".",
                detailed: "Each solution represents a point where the parabola y = \(formatFloat(a))x² + \(formatFloat(b))x + \(formatFloat(c)) crosses the x-axis (where y = 0). The vertex is at (\(formatFloat(eq.vertex.x)), \(formatFloat(eq.vertex.y))), and the parabola opens \(a > 0 ? "upward" : "downward").",
                metaphor: "The complete picture: you've found where the curve meets the ground."
            )),
            result: interpretResult,
            arithmeticConceptUsed: "verification",
            transformation: nil,
            tooltip: nil
        ))
        
        return steps
    }
    
    // MARK: - Formatting
    
    private func formatFloat(_ value: Float) -> String {
        if value == Float(Int(value)) {
            return "\(Int(value))"
        }
        return String(format: "%.2g", value)
    }
}
