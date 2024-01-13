/// Class capable of finding common subsequence of terms in a boolean binary
/// expression.
class CommonTermCollector {
    let expression: InternalRepresentation.Binary
    let path: InternalRepresentation.ExpressionPath

    init(_ expression: InternalRepresentation.Binary, path: InternalRepresentation.ExpressionPath) {
        self.expression = expression
        self.path = path
    }

    /// Returns a collection of individual common terms in `expression`.
    func minimalTerms() -> [Result] {
        var result: [Result] = []

        let operands = expression.subExpressionsWithLocation(parent: path)
        for (operand, location) in operands {
            if let index = result.firstIndex(ofTerm: operand, mode: .transitiveEquivalent) {
                result[index].locations.append(location)
            } else {
                result.append(.init(term: operand, locations: [location]))
            }
        }

        // Remove terms that occur only once
        result.removeAll(where: { $0.locations.count == 1 })

        return result
    }

    /// Returns a collection of compound components in the expression shared in
    /// binary sub-expressions of `expression`.
    func compoundTerms() -> [Result] {
        var result: [Result] = []

        func findInBinary(
            _ binary: InternalRepresentation.Binary,
            _ discriminant: InternalRepresentation.Discriminant
        ) {

            let operands =
                binary
                    .subExpressionsWithLocation(parent: path)
                    .filter { $0.0.discriminant == discriminant }

            for case (let operand as InternalRepresentation.Binary, let location) in operands {
                let subOperands = operand.subExpressionsWithLocation(parent: location)

                for (operand, location) in subOperands {
                    if let index = result.firstIndex(ofTerm: operand, mode: .transitiveEquivalent) {
                        result[index].locations.append(location)
                    } else {
                        result.append(.init(term: operand, locations: [location]))
                    }
                }
            }
        }

        switch expression {
        case let exp as InternalRepresentation.And:
            findInBinary(exp, .or)

        case let exp as InternalRepresentation.Or:
            findInBinary(exp, .and)

        default:
            break
        }

        // Remove terms that occur only once
        result.removeAll(where: { $0.locations.count == 1 })

        return result
    }

    /// Returns a collection of compound components that appear in all binary
    /// sub-expressions of `expression`.
    func maximalCompoundTerms() -> [Result] {
        var result: [Result] = []

        func findInBinary(
            _ binary: InternalRepresentation.Binary,
            _ discriminant: InternalRepresentation.Discriminant
        ) {

            let operands =
                binary
                    .subExpressionsWithLocation(parent: path)
                    .filter { $0.0.discriminant == discriminant }
            
            var presenceInTerms: [InternalRepresentation: Set<Int>] = [:]

            var operandIndex = 0
            for case (let operand as InternalRepresentation.Binary, let location) in operands {
                defer { operandIndex += 1 }

                let subOperands = operand.subExpressionsWithLocation(parent: location)

                for (operand, location) in subOperands {
                    if let index = result.firstIndex(ofTerm: operand, mode: .transitiveEquivalent) {
                        result[index].locations.append(location)

                        let term = result[index].term
                        presenceInTerms[term]?.insert(operandIndex)
                    } else {
                        result.append(.init(term: operand, locations: [location]))
                        presenceInTerms[operand] = [operandIndex]
                    }
                }
            }

            // Remove sub-terms that don't occur in all terms
            let fullTerms = Set(0..<operands.count)
            for (term, occurrences) in presenceInTerms {
                if occurrences != fullTerms {
                    result.removeAll(where: { $0.term === term })
                }
            }
        }

        switch expression {
        case let exp as InternalRepresentation.And:
            findInBinary(exp, .or)

        case let exp as InternalRepresentation.Or:
            findInBinary(exp, .and)

        default:
            break
        }

        // Remove terms that occur only once
        result.removeAll(where: { $0.locations.count == 1 })

        return result
    }

    struct Result: Hashable {
        let term: InternalRepresentation
        var locations: [InternalRepresentation.ExpressionPath]
    }
}

fileprivate extension Collection<CommonTermCollector.Result> {
    func firstIndex(
        ofTerm term: InternalRepresentation,
        mode: ExpressionQuerier.EquivalenceMode
    ) -> Index? {

        firstIndex {
            ExpressionQuerier.areEquivalent($0.term, term, mode: mode)
        }
    }
}
