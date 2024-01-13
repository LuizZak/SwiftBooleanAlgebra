/// Provides an interface with which boolean expressions can be changed into
/// simplified form with less operations, but with the same resulting truth
/// table.
public class ExpressionReducer {
    var querier: ExpressionQuerier
    var expression: InternalRepresentation? {
        querier.expression[path: path]
    }

    var path: InternalRepresentation.ExpressionPath
    var didWork = false

    public init(_ expression: Expression) {
        querier = ExpressionQuerier(
            expression: ExpressionCanonicalizer.canonicalizeInternal(expression),
            parent: .root
        )
        path = .root
    }

    init(_ querier: ExpressionQuerier, path: InternalRepresentation.ExpressionPath) {
        self.querier = querier
        self.path = path
    }

    func makeReducer(subPath: InternalRepresentation.ExpressionPath) -> ExpressionReducer {
        .init(querier, path: subPath)
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
        guard !didWork, let expression = expression else {
            return
        }

        for (_, subPath) in expression.subExpressionsWithLocation(parent: path) {
            let reducer = makeReducer(subPath: subPath)
            reducer._reduce()

            if reducer.didWork {
                reportDidWork()
                return
            }
        }

        reduceBase()
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
        guard !didWork else { return }
        guard let expression else { return }

        for (_, subPath) in expression.subExpressionsWithLocation(parent: path) {
            let reducer = makeReducer(subPath: subPath)
            reducer._distributiveRecursive()

            if reducer.didWork {
                reportDidWork()
                return
            }
        }

        distributiveLaw()
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

    /// AND form                  | OR form
    /// --------------------------|-------
    ///  a + bc = (a + b)(a + c)  | a(b + c + d) = ab + ac + ad
    func distributiveLaw() {
        guard !didWork else { return }

        switch expression {
        case let exp as InternalRepresentation.And where exp.operands.contains(where: \.isOr):

            var remaining = exp.operands
            var newOperands: [InternalRepresentation] = []
            func popNextOr() -> [InternalRepresentation]? {
                if let index = remaining.firstIndex(where: \.isOr) {
                    defer { remaining.remove(at: index) }

                    switch remaining[index] {
                    case let exp as InternalRepresentation.Or:
                        return exp.operands
                    default:
                        fatalError("Thought item at index \(index) was an .or case?")
                    }
                }

                return nil
            }
            
            guard let nextOrTerms = popNextOr() else {
                // Nothing to distribute?
                break
            }

            while !remaining.isEmpty {
                let next = remaining.removeFirst()

                let terms: [InternalRepresentation]
                switch next {
                case let exp as InternalRepresentation.Or:
                    terms = exp.operands
                default:
                    terms = [next]
                }
                
                for lhs in terms {
                    for rhs in nextOrTerms {
                        newOperands.append(.and([lhs, rhs]))
                    }
                }
            }

            querier.replace(at: path, with: .or(newOperands))
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

        func distributeBinary(
            _ binary: InternalRepresentation.Binary,
            _ discriminant: InternalRepresentation.Discriminant,
            termProducer: ([InternalRepresentation]) -> InternalRepresentation,
            finalFactorProducer: ([InternalRepresentation]) -> InternalRepresentation
        ) {

            var newTerms: [InternalRepresentation] = []

            let termCollector = CommonTermCollector(binary, path: path)
            let terms = termCollector.maximalCompoundTerms()

            guard !terms.isEmpty else {
                return
            }

            let leadingTerm = termProducer(terms.map(\.term))
            var factors: [InternalRepresentation] = []

            let operands = binary.subExpressionsWithLocation(parent: path)

            for (operand, location) in operands {
                guard operand.discriminant == discriminant else {
                    newTerms.append(operand)
                    continue
                }

                for (operand, location) in operand.subExpressionsWithLocation(parent: location) {
                    guard !terms.contains(where: { $0.locations.contains(location) }) else {
                        continue
                    }

                    factors.append(operand)
                }
            }

            // Add final term
            newTerms.insert(
                termProducer([leadingTerm, finalFactorProducer(factors)]),
                at: 0
            )

            querier.replace(at: path, with: finalFactorProducer(newTerms))

            reportDidWork()
        }

        switch expression {
        case let exp as InternalRepresentation.And:
            distributeBinary(
                exp,
                .or,
                termProducer: InternalRepresentation.and,
                finalFactorProducer: InternalRepresentation.or
            )

        case let exp as InternalRepresentation.Or:
            distributeBinary(
                exp,
                .and,
                termProducer: InternalRepresentation.or,
                finalFactorProducer: InternalRepresentation.and
            )

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
}
