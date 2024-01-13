/// A boolean expression definition.
public enum Expression: Hashable {
    /// A variable expression.
    case variable(String)

    /// A constant `true` expression.
    case `true`

    /// A constant `false` expression.
    case `false`

    /// A boolean conjunction, a.k.a. 'AND'- of two sub-expressions.
    indirect case and(Expression, Expression)

    /// A boolean disjunction, a.k.a. 'OR' of two sub-expressions.
    indirect case or(Expression, Expression)

    /// A boolean exclusive disjunction, a.k.a. 'XOR' of two sub-expressions.
    indirect case xor(Expression, Expression)

    /// A boolean negation, a.k.a. 'NOT' of a sub-expression.
    indirect case not(Expression)

    /// A parenthesized sub-expression.
    indirect case parenthesized(Expression)

    /// Returns a tuple of the sub-expressions present within this boolean
    /// expression.
    /// If this expression is a variable, the result is `nil`, and if this
    /// expression is a negation or parenthesized expression, the second
    /// argument of the tuple is `nil` instead.
    var subExpressions: (Expression, Expression?)? {
        switch self {
        case .and(let lhs, let rhs):
            return (lhs, rhs)

        case .or(let lhs, let rhs):
            return (lhs, rhs)
        
        case .xor(let lhs, let rhs):
            return (lhs, rhs)

        case .not(let expr):
            return (expr, nil)

        case .parenthesized(let expr):
            return (expr, nil)

        case .variable, .true, .false:
            return nil
        }
    }
}

extension Expression: CustomStringConvertible {
    /// Returns a string representation of this boolean expression, with `*` as
    /// the conjunction operator, `+` as the conjunction operator, and `¬` as the
    /// negation operator. Sub-expressions may be parenthesized automatically,
    /// depending on operator preceding rules that must be obeyed.
    public var description: String {
        switch self {
        case .and(let lhs, let rhs):
            return "\(lhs.andParenthesized) * \(rhs.andParenthesized)"

        case .or(let lhs, let rhs):
            return "\(lhs) + \(rhs)"
        
        case .xor(let lhs, let rhs):
            return "\(lhs) ^ \(rhs)"

        case .not(.not(let expr)):
            return "¬(\(Self.not(expr)))"

        case .not(let expr):
            return "¬\(expr.notParenthesized)"

        case .parenthesized(let expr):
            return "(\(expr))"

        case .true:
            return "1"

        case .false:
            return "0"

        case .variable(let ident):
            return ident
        }
    }

    /// Returns a parenthesized string version of this expression for a conjunction
    /// and expression, unless it is a conjunction itself, a variable expression,
    /// a not expression, a constant expression, or is already a `.parenthesized`
    /// case.
    var andParenthesized: String {
        switch self {
        case .or:
            return "(\(description))"
        case .and, .xor, .not, .variable, .true, .false, .parenthesized:
            return description
        }
    }

    /// Returns a parenthesized string version of this expression for a negation
    /// expression, unless it is a variable expression, a constant expression,
    /// or is already a `.parenthesized` case.
    var notParenthesized: String {
        switch self {
        case .and, .or, .xor, .not:
            return "(\(description))"
        case .variable, .true, .false, .parenthesized:
            return description
        }
    }
}

extension Expression: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .and(let lhs, let rhs):
            return ".and(\(lhs.debugDescription), \(rhs.debugDescription))"

        case .or(let lhs, let rhs):
            return ".or(\(lhs.debugDescription), \(rhs.debugDescription))"

        case .xor(let lhs, let rhs):
            return ".xor(\(lhs.debugDescription), \(rhs.debugDescription))"

        case .not(let expr):
            return ".not(\(expr.debugDescription))"

        case .parenthesized(let expr):
            return ".parenthesized(\(expr.debugDescription))"

        case .variable(let ident):
            return ".variable(\(ident))"

        case .true:
            return ".true"

        case .false:
            return ".false"
        }
    }
}

public extension Expression {
    /// Returns a set of all unique variables found within this boolean expression.
    ///
    /// Since the result is a set and not an array, the order of the elements
    /// is not related to the order of first occurrence of each variable.
    func variables() -> Set<String> {
        switch self {
        case .and(let lhs, let rhs),
            .or(let lhs, let rhs),
            .xor(let lhs, let rhs):
            return lhs.variables().union(rhs.variables())

        case .not(let expr):
            return expr.variables()

        case .parenthesized(let expr):
            return expr.variables()

        case .variable(let ident):
            return [ident]

        case .true, .false:
            return []
        }
    }
}
