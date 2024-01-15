/// Provides an interface with which boolean expressions can be changed into
/// simplified form with less operations, but with the same resulting truth
/// table.
public class ExpressionReducer {
    typealias ExpressionPath = InternalRepresentation.ExpressionPath

    var querier: ExpressionQuerier
    var expression: InternalRepresentation? {
        querier.expression[path: path]
    }

    var path: ExpressionPath
    var didWork = false

    public init(_ expression: Expression) {
        querier = ExpressionQuerier(
            expression: ExpressionCanonicalizer.canonicalizeInternal(expression),
            parent: .root
        )
        path = .root
    }

    init(_ expression: InternalRepresentation, path: ExpressionPath) {
        querier = ExpressionQuerier(
            expression: ExpressionCanonicalizer.canonicalizeInternal(expression),
            parent: .root
        )
        self.path = path
    }

    init(_ querier: ExpressionQuerier, path: ExpressionPath) {
        self.querier = querier
        self.path = path
    }

    func makeReducer(subPath: ExpressionPath) -> ExpressionReducer {
        .init(querier, path: subPath)
    }

    private func _recurse(_ work: (ExpressionReducer) -> Void) {
        guard !didWork, let expression = expression else {
            return
        }

        for (_, subPath) in expression.subExpressionsWithLocation(parent: path) {
            let reducer = makeReducer(subPath: subPath)
            reducer._recurse(work)

            if reducer.didWork {
                reportDidWork()
                return
            }
        }

        work(self)
    }

    /// Returns the internal reduced expression.
    public func toExpression() -> Expression {
        guard let expression = expression else {
            return .false
        }

        return ExpressionCanonicalizer.canonicalizeInternal(expression).toExpression()
    }

    func reportDidWork() {
        didWork = true
    }

    /// Recursively reduces a given boolean expression.
    /// The process removes parenthesis from the original expression.
    public func reduce() {
        assert(path == .root, "path == .root")

        // Start by expanding exclusive disjunction (xor) expressions
        _expandExclusiveDisjunctionRecursive()

        // Run reduction loop for as long as the expression keeps changing
        var start: InternalRepresentation?
        repeat {
            start = expression?.copy()

            // Start by expanding terms
            repeat {
                // Reset flag
                didWork = false

                _distributiveRecursive()
                // Re-flatten between steps
                querier.expression = querier.expression.flattened()
            } while didWork

            // Keep reducing root expressions until no change is picked up anymore
            repeat {
                // Reset flag
                didWork = false

                _reduce()
                // Re-flatten between steps
                querier.expression = querier.expression.flattened()
            } while didWork
        } while expression != start
    }

    private func _reduce() {
        _recurse {
            $0.reduceBase()
        }
    }

    private func reduceBase() {
        guard !didWork else { return }

        deMorganLaw()

        negationOfConstant()
        doubleNegation()
        idempotentLaw()
        nullLaw()
        identityLaw()
        inverseLaw()
        absorptionLaw()
        inverseDistributiveLaw()
    }

    private func _distributiveRecursive() {
        _recurse {
            $0.distributiveLaw()
        }
    }

    private func _expandExclusiveDisjunctionRecursive() {
        _recurse {
            $0.expandExclusiveDisjunction()
        }
    }

    /// a ^ b = (a + b) * !(a * b)
    func expandExclusiveDisjunction() {
        guard !didWork else { return }
        guard let exp = expression as? InternalRepresentation.Xor else { return }
        guard exp.operands.count >= 2 else { return }

        var cumulative: InternalRepresentation = exp.operands[0]

        for operand in exp.operands.dropFirst() {
            cumulative = InternalRepresentation.and([
                .or([operand, cumulative]),
                .not(.and([operand, cumulative]))
            ])
        }

        querier.replace(at: path, with: cumulative)
        reportDidWork()
    }

    /// ¬(¬a) = a
    func doubleNegation() {
        guard !didWork else { return }
        guard let exp = expression as? InternalRepresentation.Not else { return }
        
        if let inner = exp.operand as? InternalRepresentation.Not {
            querier.remove(at: path, placeholder: inner.operand.copy())
            reportDidWork()
        }
    }

    /// ¬0 = 1  |  ¬1 = 0
    func negationOfConstant() {
        guard !didWork else { return }
        guard let exp = expression as? InternalRepresentation.Not else { return }
        
        if let inner = exp.operand as? InternalRepresentation.Constant {
            querier.remove(at: path, placeholder: inner == .true ? .false : .true)
            reportDidWork()
        }
    }

    /// AND form         | OR form
    /// -----------------|-------
    ///  ¬(ab) = ¬a + ¬b | ¬(a + b) = ¬a¬b
    func deMorganLaw() {
        guard !didWork else { return }
        guard let exp = expression as? InternalRepresentation.Not else { return }

        func applyTheorem(
            _ binary: InternalRepresentation.Binary,
            producer: ([InternalRepresentation]) -> InternalRepresentation
        ) {

            let terms: [InternalRepresentation] = binary.operands.map {
                .not($0)
            }

            querier.replace(at: path, with: producer(terms))
            reportDidWork()
        }

        switch exp.operand {
        case let exp as InternalRepresentation.And:
            applyTheorem(exp, producer: InternalRepresentation.or)

        case let exp as InternalRepresentation.Or:
            applyTheorem(exp, producer: InternalRepresentation.and)

        default:
            break
        }
    }

    /// AND form         | OR form
    /// -----------------|-------
    ///  ¬a + ¬b = ¬(ab) | ¬a¬b = ¬(a + b)
    func inverseDeMorganLaw() {
        guard !didWork else { return }

        func applyTheorem(
            _ binary: InternalRepresentation.Binary,
            producer: ([InternalRepresentation]) -> InternalRepresentation,
            remainingProducer: ([InternalRepresentation]) -> InternalRepresentation
        ) {

            let negatedOperands = binary.operands.compactMap(\.asNot)
            guard negatedOperands.count >= 2 else {
                return
            }

            let remaining = binary.operands.filter({ !$0.isNot })

            let terms: [InternalRepresentation] = negatedOperands.map {
                $0.operand
            }

            querier.replace(
                at: path,
                with: .not(remainingProducer(remaining + [producer(terms)]))
            )
            reportDidWork()
        }

        switch expression {
        case let exp as InternalRepresentation.And:
            applyTheorem(
                exp,
                producer: InternalRepresentation.or,
                remainingProducer: InternalRepresentation.and
            )

        case let exp as InternalRepresentation.Or:
            applyTheorem(
                exp,
                producer: InternalRepresentation.and,
                remainingProducer: InternalRepresentation.or
            )

        default:
            break
        }
    }

    /// AND form                  | OR form
    /// --------------------------|-------
    ///  a + bc = (a + b)(a + c)  | a(b + c + d) = ab + ac + ad
    func distributiveLaw() {
        guard !didWork else { return }

        switch expression {
        case let exp as InternalRepresentation.And where exp.operands.contains(where: \.isOr):
            let collector = CommonTermCollector(exp, path: path)
            let operations = collector.distributedTerms().map({
                InternalRepresentation.and($0.terms.map(\.term))
            })

            querier.replace(at: path, with: .or(operations).flattened())
            reportDidWork()

        default:
            break
        }
    }

    /// AND form                  | OR form
    /// --------------------------|-------
    ///  (a + b)(a + c) = a + bc  | ab + ac + ad = a(b + c + d)
    func inverseDistributiveLaw() {
        guard !didWork else { return }

        func collectInBinary(
            _ binary: InternalRepresentation.Binary,
            _ discriminant: InternalRepresentation.Discriminant
        ) -> (leadingTerm: InternalRepresentation, factors: [[InternalRepresentation]], remaining: [InternalRepresentation])? {

            // Pick only one valid term at a time to avoid reversing whole
            // distributions at once
            let termCollector = CommonTermCollector(binary, path: path)
            guard let leadingTerm = termCollector.compoundTerms().first else {
                return nil
            }

            func isPartOfTerms(_ location: ExpressionPath) -> Bool {
                leadingTerm.locations.contains { $0.parent == location }
            }

            var remaining: [InternalRepresentation] = []
            var factors: [[InternalRepresentation]] = []

            let operands = binary.subExpressionsWithLocation(parent: path)

            for (operand, location) in operands {
                guard operand.discriminant == discriminant && isPartOfTerms(location) else {
                    remaining.append(operand)
                    continue
                }

                var operandFactors: [InternalRepresentation] = []

                for (operand, location) in operand.subExpressionsWithLocation(parent: location) {
                    guard !leadingTerm.locations.contains(location) else {
                        continue
                    }

                    operandFactors.append(operand)
                }

                guard operandFactors.count > 0 else { continue }

                factors.append(operandFactors)
            }

            return (
                leadingTerm: leadingTerm.term,
                factors: factors,
                remaining: remaining
            )
        }

        switch expression {
        case let exp as InternalRepresentation.And:
            let result = collectInBinary(exp, .or)

            guard let result else { return }

            // Compute final expression
            let finalExp = InternalRepresentation.and([
                result.leadingTerm, .or(result.factors.map(InternalRepresentation.or(_:)))
            ] + result.remaining)

            querier.replace(at: path, with: finalExp.flattened())
            reportDidWork()

        case let exp as InternalRepresentation.Or:
            let result = collectInBinary(exp, .and)

            guard let result else { return }

            // Compute final expression
            let finalExp = InternalRepresentation.and([
                result.leadingTerm, .or(result.factors.map(InternalRepresentation.and(_:)))
            ])

            querier.replace(at: path, with: .or([finalExp] + result.remaining).flattened())
            reportDidWork()

        default:
            break
        }
    }

    /// AND form | OR form
    /// ---------|-------
    ///  aa = a  | b + b = b
    func idempotentLaw() {
        guard !didWork else { return }

        func removeInBinary(_ binary: InternalRepresentation.Binary) {
            let operands = binary.subExpressionsWithLocation(parent: path)

            for (operand1, location1) in operands {
                for (operand2, location2) in operands where location1 != location2 {
                    if
                        ExpressionQuerier.areEquivalent(
                            operand1,
                            operand2,
                            mode: .transitiveEquivalent
                    ) {
                        querier.removeRecursive(at: location2)
                        reportDidWork()
                        return
                    }
                }
            }
        }

        switch expression {
        case let exp as InternalRepresentation.And:
            removeInBinary(exp)

        case let exp as InternalRepresentation.Or:
            removeInBinary(exp)

        default:
            break
        }
    }

    /// AND form | OR form
    /// ---------|-------
    ///  1a = a  | 0 + a = a
    func identityLaw() {
        guard !didWork else { return }
        
        switch expression {
        case let exp as InternalRepresentation.And where exp.contains(.true):
            querier.replace(at: path, with: .and(exp.operands.filter({ $0 != .true })))
            reportDidWork()

        case let exp as InternalRepresentation.Or where exp.contains(.false):
            querier.replace(at: path, with: .or(exp.operands.filter({ $0 != .false })))
            reportDidWork()

        default:
            break
        }
    }

    /// AND form | OR form
    /// ---------|-------
    ///  0a = 0  | 1 + a = 1
    func nullLaw() {
        guard !didWork else { return }
        
        switch expression {
        case let exp as InternalRepresentation.And where exp.contains(.false):
            querier.replace(at: path, with: .false)
            reportDidWork()

        case let exp as InternalRepresentation.Or where exp.contains(.true):
            querier.replace(at: path, with: .true)
            reportDidWork()

        default:
            break
        }
    }

    /// AND form | OR form
    /// ---------|-------
    ///  a¬a = 0 | a + ¬a = 1
    func inverseLaw() {
        guard !didWork else { return }
        
        switch expression {
        case let exp as InternalRepresentation.And:
            for e in exp.operands {
                if exp.operands.contains(.not(e).flattened()) {
                    querier.replace(at: path, with: .false)
                    reportDidWork()
                    return
                }
            }

        case let exp as InternalRepresentation.Or:
            for e in exp.operands {
                if exp.operands.contains(.not(e).flattened()) {
                    querier.replace(at: path, with: .true)
                    reportDidWork()
                    return
                }
            }

        default:
            break
        }
    }

    /// AND form      | OR form
    /// --------------|-------
    ///  a(a + b) = a | a + ab = a
    func absorptionLaw() {
        guard !didWork else { return }
        
        switch expression {
        case let exp as InternalRepresentation.And:
            for (i, e) in exp.operands.enumerated() {
                for case let (otherI, otherE as InternalRepresentation.Or) in exp.operands.enumerated() where i != otherI {
                    let otherEQuerier = ExpressionQuerier(
                        expression: otherE,
                        parent: .and(path, operand: otherI)
                    )

                    if
                        otherEQuerier.hasSupersetOf(e, mode: .transitiveEquivalent),
                        let location = querier.location(of: otherE, mode: .identityEquivalent)
                    {
                        querier.removeRecursive(at: location)
                        reportDidWork()
                        return
                    }
                }
            }

        case let exp as InternalRepresentation.Or:
            for (i, e) in exp.operands.enumerated() {
                for case let (otherI, otherE as InternalRepresentation.And) in exp.operands.enumerated() where i != otherI {
                    let otherEQuerier = ExpressionQuerier(
                        expression: otherE,
                        parent: .or(path, operand: otherI)
                    )
                    if
                        otherEQuerier.hasSupersetOf(e, mode: .transitiveEquivalent)
                    {
                        querier.removeRecursive(at: otherEQuerier.parent)
                        reportDidWork()
                        return
                    }
                }
            }

        default:
            break
        }
    }
}
