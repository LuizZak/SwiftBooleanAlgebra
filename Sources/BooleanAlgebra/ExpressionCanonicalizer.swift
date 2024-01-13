/// Provides an interface for decomposing and recombining boolean expressions
/// such that any two boolean expressions that represent the same equation share
/// the exact same structure.
public enum ExpressionCanonicalizer {
    /// Canonicalizes a given boolean expression, ensuring it shares the same
    /// structure with other canonicalized expressions that represent the same
    /// underlying expression.
    ///
    /// This process reorders operations and variables to favor lexicographically
    /// ordered variable names, and rotates nested `.and`/`.or` terms around.
    public static func canonicalize(_ exp: Expression) -> Expression {
        return canonicalizeInternal(exp).toExpression()
    }

    internal static func canonicalizeInternal(_ exp: Expression) -> InternalRepresentation {
        let internalExp = InternalRepresentation.from(exp)

        return internalExp.flattened().deepSorted()
    }

    internal static func canonicalizeInternal(_ exp: InternalRepresentation) -> InternalRepresentation {
        return exp.flattened().deepSorted()
    }
}
