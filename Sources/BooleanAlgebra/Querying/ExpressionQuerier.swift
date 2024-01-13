/// Utility class for performing queries of substructures and mutations of 
/// `InternalRepresentation` expressions.
class ExpressionQuerier {
    var expression: InternalRepresentation
    let parent: InternalRepresentation.ExpressionPath

    init(expression: InternalRepresentation, parent: InternalRepresentation.ExpressionPath) {
        self.expression = expression
        self.parent = parent
    }

    /// Returns `true` if `exp` is present at any depth in `expression`.
    /// Ignores `expression` itself.
    func deepContains(_ exp: InternalRepresentation, mode: EquivalenceMode = .transitiveEquivalent) -> Bool {
        var found = false

        expression.walk { subExp in
            if Self.areEquivalent(subExp, exp, mode: mode) && subExp !== expression {
                found = true
                return .stop
            }
            return .visitSubExpressions
        }

        return found
    }

    /// Returns `true` if `exp` is an immediate sub-expression of `expression`.
    func contains(_ exp: InternalRepresentation, mode: EquivalenceMode = .transitiveEquivalent) -> Bool {
        for subExp in expression.subExpressions {
            if Self.areEquivalent(exp, subExp, mode: mode) {
                return true
            }
        }

        return false
    }

    /// Returns `true` if `exp` shows up as part of operands of a binary operation
    /// within `expression`. If `exp` itself is a binary operation, each component
    /// is checked individually for presence, in case the binary operator types
    /// match.
    ///
    /// If `expression` is not a binary expression itself, `false` is returned.
    func hasSupersetOf(_ exp: InternalRepresentation, mode: EquivalenceMode = .transitiveEquivalent) -> Bool {
        guard expression.isBinary else {
            return false
        }

        switch exp {
        case let exp as InternalRepresentation.Binary:
            guard exp.discriminant == expression.discriminant else {
                return false
            }

            var seen: Set<InternalRepresentation.ExpressionPath> = []
            for term in exp.operands {
                guard let location = location(of: term, mode: mode) else {
                    return false
                }

                if !seen.insert(location).inserted {
                    return false
                }
            }

            return true
        default:
            return contains(exp, mode: mode)
        }
    }

    /// Returns the location of a given immediate sub-expression within
    /// `expression` that is equivalent under `mode`.
    ///
    /// Returns `nil` if none are found.
    func location(
        of subExp: InternalRepresentation,
        mode: EquivalenceMode = .transitiveEquivalent
    ) -> InternalRepresentation.ExpressionPath? {

        for (exp, location) in expression.subExpressionsWithLocation(parent: parent) {
            if Self.areEquivalent(subExp, exp, mode: mode) {
                return location
            }
        }

        return nil
    }

    /// Returns the location of a given sub-expression within `expression` that
    /// is equivalent under `mode`.
    ///
    /// Returns `nil` if none are found.
    func deepLocation(
        of subExp: InternalRepresentation,
        mode: EquivalenceMode = .transitiveEquivalent
    ) -> InternalRepresentation.ExpressionPath? {

        var result: InternalRepresentation.ExpressionPath?

        expression.walkLocating { (e, location) in
            if
                let loc = createQuerier(
                    e,
                    parent: location.appending(parent: parent)
                ).location(of: subExp, mode: mode)
            {
                result = loc
                return .stop
            }

            return .visitSubExpressions
        }

        return result
    }

    /// Returns an array of locations of a given immediate sub-expression within
    /// `expression` that are equivalent under `mode`.
    ///
    /// Returns an empty array if none are found.
    func locations(
        of subExp: InternalRepresentation,
        mode: EquivalenceMode = .transitiveEquivalent
    ) -> [InternalRepresentation.ExpressionPath] {

        var result: [InternalRepresentation.ExpressionPath] = []

        for (exp, location) in expression.subExpressionsWithLocation(parent: parent) {
            if Self.areEquivalent(subExp, exp, mode: mode) {
                result.append(location)
            }
        }

        return result
    }

    /// Replaces all occurrences of `exp` within `expression` with `substitute`.
    /// Does not replace `expression` itself.
    func deepReplace(_ exp: InternalRepresentation, with substitute: InternalRepresentation, mode: EquivalenceMode = .transitiveEquivalent) {
        expression.walkLocating { (subExp, location) in
            createQuerier(subExp, parent: location.appending(parent: parent))
                .replace(exp, with: substitute, mode: mode)

            return .visitSubExpressions
        }
    }

    /// Replaces all occurrences of `exp` in immediate sub-expressions within
    /// `expression` with `substitute`.
    /// Does not replace `expression` itself.
    func replace(_ exp: InternalRepresentation, with substitute: InternalRepresentation, mode: EquivalenceMode = .transitiveEquivalent) {
        switch expression {
        case let binary as InternalRepresentation.Binary:
            for (i, operand) in binary.operands.enumerated() {
                if Self.areEquivalent(operand, exp, mode: mode) {
                    binary.operands[i] = substitute.copyIfParented()
                }
            }

        case let not as InternalRepresentation.Not:
            if Self.areEquivalent(not.operand, exp, mode: mode) {
                not.operand = substitute.copyIfParented()
            }

        default:
            break
        }
    }

    /// Replaces the expression at a given keypath within `expression` with
    /// `substitute`.
    ///
    /// - precondition: `location` is a valid keypath within `expression`.
    func replace(at location: InternalRepresentation.ExpressionPath, with substitute: InternalRepresentation) {
        expression = expression.replacing(path: location, with: substitute)
    }

    /// Removes a sub-expression within `expression` at a given keypath.
    /// If the removal can occur without creating invalid syntax (i.e. an operand
    /// of a >2 binary expression chain), the item is removed, otherwise, the
    /// parent expression is flattened so that binary expressions with two
    /// operands are replaced with the remaining operand, and binary expressions
    /// with one operand and negation expressions are removed recursively, until
    /// the root of the expression is reached, at which point if no parent is found,
    /// the expression is left in an invalid state.
    /// 
    /// Does not remove anything if `location == .root`.
    ///
    /// The 
    ///
    /// - precondition: `location` is a valid keypath within `expression`.
    func removeRecursive(at location: InternalRepresentation.ExpressionPath) {
        expression = expression.removing(at: location) ?? expression
    }

    /// Removes a sub-expression within `expression` at a given keypath.
    /// If the removal can occur without creating invalid syntax (i.e. an operand
    /// of a >2 binary expression chain), the item is removed, otherwise, it is
    /// replaced with `placeholder`.
    /// 
    /// Does not remove anything if `location == \.self`.
    ///
    /// The 
    ///
    /// - precondition: `location` is a valid keypath within `expression`.
    func remove(at location: InternalRepresentation.ExpressionPath, placeholder: InternalRepresentation) {
        if let newExp = expression.removing(at: location) {
            expression = newExp
            return
        }

        expression = expression.replacing(path: location, with: placeholder)
    }

    /// Returns `true` if `lhs` and `rhs` are equivalent under certain modes.
    /// 
    /// - `EquivalenceMode.identityEquivalence`: Expressions are equivalent under
    /// identity equality operator `===`.
    /// - `EquivalenceMode.layoutEquivalent`: Expressions are equivalent down to
    /// the layout of internal operations, even if transitively the operations
    /// evaluate to the same result.
    /// - `EquivalenceMode.transitiveEquivalent`: Expressions are equivalent
    /// under transitiveness.
    /// - `EquivalenceMode.truthTableEquivalent`: Expressions share the same
    /// variables within and evaluate to the same truth table.
    static func areEquivalent(
        _ lhs: InternalRepresentation,
        _ rhs: InternalRepresentation,
        mode: EquivalenceMode
    ) -> Bool {
        
        switch mode {
        case .identityEquivalent:
            return lhs === rhs

        case .layoutEquivalent:
            return lhs == rhs

        case .transitiveEquivalent:
            let lhsCanonical = ExpressionCanonicalizer.canonicalizeInternal(lhs)
            let rhsCanonical = ExpressionCanonicalizer.canonicalizeInternal(rhs)

            return lhsCanonical == rhsCanonical
        
        case .truthTableEquivalent:
            let lhsTruthTable = lhs.toExpression().generateTruthTable()
            let rhsTruthTable = rhs.toExpression().generateTruthTable()

            guard lhsTruthTable.variables == rhsTruthTable.variables else {
                return false
            }

            return lhsTruthTable.rows == rhsTruthTable.rows
        }
    }

    private func createQuerier(
        _ exp: InternalRepresentation,
        parent: InternalRepresentation.ExpressionPath
    ) -> ExpressionQuerier {

        ExpressionQuerier(expression: exp, parent: parent)
    }

    /// Options for checking for equivalence of boolean expressions.
    enum EquivalenceMode {
        /// Expressions are equivalent under identity operator `===`. This implies
        /// equivalence under any other category simultaneously.
        case identityEquivalent

        /// Expressions are equivalent down to the layout of internal operations,
        /// even if transitively the operations evaluate to the same result.
        case layoutEquivalent

        /// Expressions are equivalent under transitiveness.
        case transitiveEquivalent

        /// Expressions have the same truth table results and they both share the
        /// same variables within.
        case truthTableEquivalent
    }
}
