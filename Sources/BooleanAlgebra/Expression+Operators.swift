public extension Expression {
    static func * (lhs: Expression, rhs: Expression) -> Expression {
        .and(lhs, rhs)
    }

    static func + (lhs: Expression, rhs: Expression) -> Expression {
        .or(lhs, rhs)
    }

    static func ^ (lhs: Expression, rhs: Expression) -> Expression {
        .xor(lhs, rhs)
    }

    static prefix func ! (value: Expression) -> Expression {
        .not(value)
    }

    /// Alias for conjunction operator '*'
    static func & (lhs: Expression, rhs: Expression) -> Expression {
        lhs * rhs
    }

    /// Alias for conjunction operator '*'
    static func && (lhs: Expression, rhs: Expression) -> Expression {
        lhs * rhs
    }

    /// Alias for disjunction operator '+'
    static func | (lhs: Expression, rhs: Expression) -> Expression {
        lhs + rhs
    }

    /// Alias for disjunction operator '+'
    static func || (lhs: Expression, rhs: Expression) -> Expression {
        lhs + rhs
    }

    /// Alias for exclusive disjunction operator '^'
    static func ⊕ (lhs: Expression, rhs: Expression) -> Expression {
        lhs ^ rhs
    }

    /// Alias for negation operator '¬'
    static prefix func ¬ (value: Expression) -> Expression {
        !value
    }

    /// Alias for negation operator '!'
    static prefix func - (value: Expression) -> Expression {
        !value
    }
}

/// Boolean negation operator
prefix operator ¬

/// Boolean XOR operator
precedencegroup LogicalExclusiveDisjunctionPrecedence {
    associativity: left
    lowerThan: LogicalConjunctionPrecedence
    higherThan: LogicalDisjunctionPrecedence
}

infix operator ⊕: LogicalExclusiveDisjunctionPrecedence
