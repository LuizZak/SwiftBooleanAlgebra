public extension Expression {
    /// Attempts to evaluate the result of this expression by using a given
    /// dictionary that maps unique variables with their values.
    ///
    /// Throws an error if a variable expression was not found in the provided
    /// `variables` dictionary.
    ///
    /// Evaluation might be short-circuited by Swift's `&&` and `||` operators.
    func evaluate(variables: [String: Bool]) throws -> Bool {
        switch self {
        case .and(let lhs, let rhs):
            return try lhs.evaluate(variables: variables) && rhs.evaluate(variables: variables)

        case .or(let lhs, let rhs):
            return try lhs.evaluate(variables: variables) || rhs.evaluate(variables: variables)
        
        case .xor(let lhs, let rhs):
            let lhs = try lhs.evaluate(variables: variables)
            let rhs = try rhs.evaluate(variables: variables)

            return (lhs || rhs) && !(lhs && rhs)

        case .not(let expr):
            return try !expr.evaluate(variables: variables)

        case .parenthesized(let expr):
            return try expr.evaluate(variables: variables)

        case .variable(let name):
            guard let value = variables[name] else {
                throw EvaluationError.undefinedVariable(name)
            }

            return value

        case .true:
            return true

        case .false:
            return false
        }
    }

    /// Errors thrown during expression evaluation
    enum EvaluationError: Error {
        /// Error thrown when a variable could not be associated with a boolean
        /// value.
        case undefinedVariable(String)
    }
}
