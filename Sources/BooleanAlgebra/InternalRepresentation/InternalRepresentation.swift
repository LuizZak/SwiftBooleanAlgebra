internal class InternalRepresentation: Hashable, Comparable, CustomStringConvertible {
    /// Gets the list of direct sub-expressions contained within this expression.
    var subExpressions: [InternalRepresentation] { [] }

    /// The parent expression that contains this expression, if any.
    weak var parent: InternalRepresentation? {
        willSet {
            if parent !== nil && newValue !== nil && parent !== newValue {
                fatalError("Attempting to re-parent an expression that already has a parent!")
            }
        }
    }

    /// Locates a sub-expression within `self` from a given input location.
    ///
    /// Returns `nil` if the location does not exist within this expression.
    subscript(path path: ExpressionPath) -> InternalRepresentation? {
        let inverse = path.inverse().dropFirst() // Drop .root
        var next: InternalRepresentation? = self

        for path in inverse {
            guard let current = next else {
                return nil
            }

            switch path {
            case .`root`:
                break

            case .and(_, let operand):
                next = current.asAnd?.operands[operand]

            case .xor(_, let operand):
                next = current.asXor?.operands[operand]

            case .or(_, let operand):
                next = current.asOr?.operands[operand]
            
            case .not(_):
                next = current.asNot?.operand
            }
        }

        return next
    }

    var discriminant: Discriminant { fatalError("Subclasses must override \(#function)") }

    /// Gets a string representation of this expression.
    var description: String { fatalError("Subclasses must override \(#function)") }

    init() {

    }

    /// Returns a deep copy of `self`.
    func copy() -> Self {
        fatalError("Subclasses must override \(#function)")
    }

    /// Returns a deep copy of `self`, but only if `self.parent !== nil .
    func copyIfParented() -> Self {
        if parent !== nil {
            return copy()
        }

        return self
    }

    /// Returns an `Expression`-form of this internal representation's structure.
    func toExpression() -> Expression {
        fatalError("Subclasses must override \(#function)")
    }

    /// Value-wise equality check.
    func isEqual(to other: InternalRepresentation) -> Bool {
        fatalError("Subclasses must override \(#function)")
    }

    /// Returns whether this expression compares lexicographically less than
    /// another expression.
    func isLessThan(_ other: InternalRepresentation) -> Bool {
        fatalError("Subclasses must override \(#function)")
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(discriminant)
    }

    /// Performs simple inclusion check against a conjunction's, disjunction's,
    /// or exclusive disjunction's terms.
    func contains(_ subExpr: InternalRepresentation) -> Bool {
        return false
    }

    /// Returns `true` if the given expression is a conjunction, a disjunction,
    /// or an exclusive disjunction and this expression is one of its terms.
    func isSubset(of subExpr: InternalRepresentation) -> Bool {
        if let binary = subExpr as? Binary {
            return binary.operands.contains(self)
        }

        return false
    }

    /// Returns `true` if this expression is a conjunction, disjunction, or an
    /// exclusive disjunction and the given expression is one of its terms.
    func isSuperset(of subExpr: InternalRepresentation) -> Bool {
        return false
    }

    /// Returns `true` if `exp` is identical to this object or one of its
    /// sub-expressions under identity operator `===`.
    func isSubExpression(_ exp: InternalRepresentation) -> Bool {
        if exp === self {
            return true
        }

        return subExpressions.contains(where: { $0.isSubExpression(exp) })
    }

    /// Returns a list of sub-expressions within this expression, along with a
    /// keypath for that expression from `self`.
    func subExpressionsWithLocation(parent: ExpressionPath) -> [(InternalRepresentation, ExpressionPath)] {
        []
    }

    /// Replaces a sub-expression on a given path. The path must be fully contained
    /// within `self`.
    ///
    /// Returns a full copy of the resulting expression in the process.
    ///
    /// If the path does not exist within `self`, an unmodified copy of `self`
    /// is returned.
    /// If the path is simply `root`, `newExp` is returned, instead.
    func replacing(path: ExpressionPath, with newExp: InternalRepresentation) -> InternalRepresentation {
        if path == .root {
            return newExp
        }

        func replaceBinary(_ exp: Binary, _ operand: Int, _ subpath: ExpressionPath) -> InternalRepresentation {
            let newOperand = exp
                .operands[operand]
                .replacing(path: subpath, with: newExp)

            return exp.copyIfParented().replacingOperand(at: operand, with: newOperand)
        }

        let inverse = Array(path.inverse().dropFirst()) // Drop .root
        let innerPath = ExpressionPath.fromInverse(inverse.dropFirst())

        switch inverse[0] {
        case .`root`:
            return self.copyIfParented()

        case .and(_, let operand):
            guard let exp = self.asAnd else {
                assertionFailure("path \(path) does not exist?")
                return self.copyIfParented()
            }

            return replaceBinary(exp, operand, innerPath)

        case .xor(_, let operand):
            guard let exp = self.asXor else {
                assertionFailure("path \(path) does not exist?")
                return self.copyIfParented()
            }

            return replaceBinary(exp, operand, innerPath)

        case .or(_, let operand):
            guard let exp = self.asOr else {
                assertionFailure("path \(path) does not exist?")
                return self.copyIfParented()
            }

            return replaceBinary(exp, operand, innerPath)
        
        case .not(_):
            guard let exp = self.asNot else {
                assertionFailure("path \(path) does not exist?")
                return self.copyIfParented()
            }

            return exp.replacingOperand(
                exp.operand.replacing(path: innerPath, with: newExp)
            )
        }
    }

    /// Removes a sub-expression at a given path. The path must be fully contained
    /// within `self`.
    ///
    /// Returns a full copy of the resulting expression in the process.
    ///
    /// If the path does not exist within `self`, an unmodified copy of `self`
    /// is returned.
    /// If the path is simply `root`, `nil` is returned.
    /// 
    /// Removing the only operand of a binary expression, or the operand of a
    /// negation expression, results in `nil`.
    /// 
    /// Removing the second operand of a two-term binary expression returns
    /// the other expression.
    /// 
    /// Removing an operand from a binary expression with more than two terms
    /// removes the term and returns the resulting binary expression.
    func removing(at path: ExpressionPath) -> InternalRepresentation? {
        if path == .root {
            return nil
        }

        func removeOperand(_ exp: Binary, _ operand: Int, _ subpath: ExpressionPath) -> InternalRepresentation? {
            let newOperand = exp.operands[operand].removing(at: subpath)
            if let newOperand {
                return exp.copyIfParented().replacingOperand(at: operand, with: newOperand)
            }

            if exp.operands.count > 2 {
                return exp.removingOperand(at: operand)
            }
            if exp.operands.count == 2 {
                // Return other operand
                return exp.operands[exp.operands.count - 1 - operand].copy()
            }

            return nil
        }

        let inverse = Array(path.inverse().dropFirst()) // Drop .root
        let innerPath = ExpressionPath.fromInverse(inverse.dropFirst())

        switch inverse[0] {
        case .`root`:
            return nil

        case .and(_, let operand):
            guard let exp = self.asAnd else {
                assertionFailure("path \(path) does not exist?")
                return self.copyIfParented()
            }

            return removeOperand(exp, operand, innerPath)

        case .xor(_, let operand):
            guard let exp = self.asXor else {
                assertionFailure("path \(path) does not exist?")
                return self.copyIfParented()
            }

            return removeOperand(exp, operand, innerPath)

        case .or(_, let operand):
            guard let exp = self.asOr else {
                assertionFailure("path \(path) does not exist?")
                return self.copyIfParented()
            }

            return removeOperand(exp, operand, innerPath)
        
        case .not(_):
            guard let exp = self.asNot else {
                assertionFailure("path \(path) does not exist?")
                return self.copyIfParented()
            }
            guard let newOperand = exp.operand.removing(at: innerPath) else {
                return nil
            }

            return exp.replacingOperand(newOperand)
        }
    }

    /// Returns a copy of this expression tree, flattened such that immediately
    /// nested binary operations of the same type are on the same level on the
    /// tree.
    ///
    /// This operation is recursive and affects all levels of the tree.
    func flattened() -> Self {
        return copy()
    }

    /// Performs a deep-sorting of this expression's contents.
    func deepSort() {
        for exp in subExpressions {
            exp.deepSort()
        }
    }

    /// Performs a copy of this expression with all sub-expressions deep-sorted.
    func deepSorted() -> Self {
        let copy = copy()
        copy.deepSort()
        return copy
    }

    /// Helper for creating right-associative binary expression chains.
    final func rightAssociateBinary(
        _ input: [InternalRepresentation],
        base: Expression,
        binary: (Expression, Expression) -> Expression
    ) -> Expression {

        if input.count == 0 {
            return base
        }
        if input.count == 1 {
            return input[0].toExpression()
        }

        var current = binary(input[input.count - 2].toExpression(), input[input.count - 1].toExpression())
        for i in (0..<input.count - 2).reversed() {
            current = binary(input[i].toExpression(), current)
        }

        return current
    }

    /// Helper for performing comparisons across operands of binary expressions.
    final func isLessThan(_ lhs: [InternalRepresentation], _ rhs: [InternalRepresentation]) -> Bool {
        lhs.lexicographicallyPrecedes(rhs)
    }

    static func == (lhs: InternalRepresentation, rhs: InternalRepresentation) -> Bool {
        lhs.isEqual(to: rhs)
    }

    static func < (lhs: InternalRepresentation, rhs: InternalRepresentation) -> Bool {
        lhs.isLessThan(rhs)
    }

    static func from(_ expression: Expression) -> InternalRepresentation {
        let result: InternalRepresentation

        switch expression {
        case .and(let lhs, let rhs):
            result = And(operands: [from(lhs), from(rhs)])

        case .or(let lhs, let rhs):
            result = Or(operands: [from(lhs), from(rhs)])

        case .xor(let lhs, let rhs):
            result = Xor(operands: [from(lhs), from(rhs)])

        case .not(let expr):
            result = Not(operand: from(expr))

        case .parenthesized(let expr):
            result = from(expr)

        case .variable(let ident):
            result = Variable(name: ident)

        case .true:
            result = Constant(value: true)

        case .false:
            result = Constant(value: false)
        }

        return result.flattened()
    }

    /// A discriminant for the type of an expression.
    enum Discriminant: Int {
        case and
        case xor
        case or
        case not
        case variable
        case constant
    }
}

// Sub-types
extension InternalRepresentation {
    /// Base class for binary boolean expressions.
    class Binary: InternalRepresentation {
        override var subExpressions: [InternalRepresentation] { operands }

        var operands: [InternalRepresentation] {
            willSet {
                precondition(newValue.allSatisfy({ !$0.isSubExpression(self) }))
                operands.forEach({ $0.parent = nil })
            }
            didSet {
                operands.forEach({ $0.parent = self })
                operands = operands.map({ $0.flattened() })
            }
        }

        init(operands: [InternalRepresentation]) {
            self.operands = operands
            super.init()

            operands.forEach({ $0.parent = self })
        }

        override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)

            hasher.combine(operands)
        }

        override func contains(_ subExpr: InternalRepresentation) -> Bool {
            operands.contains(subExpr)
        }

        override func isSuperset(of subExpr: InternalRepresentation) -> Bool {
            operands.contains(subExpr)
        }

        /// Performs a deep-sorting of this expression's contents.
        override func deepSort() {
            for operand in operands {
                operand.deepSort()
            }

            operands.sort()
        }

        /// Removes an operand at a given index in-place, returning `self`.
        ///
        /// - note: Removing operands from binary expressions with two or less
        /// operands may lead to incorrect base expressions.
        func removingOperand(at index: Int) -> Self {
            operands.remove(at: index)
            return self
        }

        /// Replaces the operands of this binary expression in-place, returning
        /// `self`.
        func replacingOperands(_ newOperands: [InternalRepresentation]) -> Self {
            operands = newOperands.copyIfParented()
            return self
        }

        /// Replaces a specific operand at a given index in this binary expression
        /// in-place, returning `self`.
        ///
        /// - precondition: `self.operands.indices.contains(index)`
        func replacingOperand(at index: Int, with newOperand: InternalRepresentation) -> Self {
            operands[index] = newOperand.copyIfParented()
            return self
        }
    }

    /// Returns `true` if this `InternalRepresentation` is a `Binary` expression.
    var isBinary: Bool {
        self is Binary
    }

    /// Attempts to typecast this expression object.
    var asBinary: Binary? {
        self as? Binary
    }
}

extension Sequence<InternalRepresentation> {
    /// Performs a deep copy of this sequence of `InternalRepresentation` values.
    func copy() -> [InternalRepresentation] {
        map { $0.copy() }
    }

    /// Performs a conditional deep copy of this sequence of `InternalRepresentation`
    /// values, making a copy only if the element is already parented.
    func copyIfParented() -> [InternalRepresentation] {
        map { $0.copyIfParented() }
    }
}
