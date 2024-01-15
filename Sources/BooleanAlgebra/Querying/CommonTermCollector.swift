/// Class capable of finding common subsequence of terms in a boolean binary
/// expression.
class CommonTermCollector {
    let expression: InternalRepresentation.Binary
    let path: InternalRepresentation.ExpressionPath

    init(_ expression: InternalRepresentation.Binary, path: InternalRepresentation.ExpressionPath) {
        self.expression = expression
        self.path = path
    }

    /// Returns a collection of all terms found in `expression`, as they appear
    /// individually, regardless if they are repeated or not.
    func terms() -> [Result] {
        var result: [Result] = []

        let operands = expression.subExpressionsWithLocation(parent: path)
        for (operand, location) in operands {
            result.append(.init(term: operand, locations: [location]))
        }

        return result
    }

    /// Returns a collection of individual common terms in `expression`.
    func minimalTerms() -> [Result] {
        // TODO: Reuse `terms()` and collapse repeated terms for the result
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

    /// Returns a list of terms computed by applying a distributive law to the
    /// terms of `expression`.
    ///
    /// When expanding conjunction expressions, nested disjunction expression terms
    /// are expanded as well as a conjunction of the leading terms by the disjunction
    /// terms.
    func distributedTerms() -> [DistributedTermsResult] {
        let distributeInType: InternalRepresentation.Discriminant?

        switch expression.discriminant {
        case .and:
            distributeInType = .or
        default:
            distributeInType = .and
        }

        var allTerms: [[Result]] = []

        for term in terms() {
            guard
                let exp = term.term as? InternalRepresentation.Binary,
                term.term.discriminant == distributeInType else
            {
                allTerms.append([term])
                continue
            }

            let distribute = CommonTermCollector(exp, path: term.locations[0])

            allTerms.append(distribute.terms())
        }

        // Permute items now
        var result: [DistributedTermsResult] = []

        for perm in allTerms.permute() {
            let entry = DistributedTermsResult(terms: perm)
            result.append(entry)
        }

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

            let discriminateOperands =
                binary
                    .subExpressionsWithLocation(parent: path)
                    .filter { $0.0.discriminant == discriminant }
            
            var presenceInTerms: [InternalRepresentation: Set<Int>] = [:]

            var operandIndex = 0
            for case (let operand as InternalRepresentation.Binary, let location) in discriminateOperands {
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
            let fullTerms = Set(0..<binary.operands.count)
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

    struct Result: Hashable, CustomStringConvertible {
        let term: InternalRepresentation
        var locations: [InternalRepresentation.ExpressionPath]

        var description: String {
            "Result(term: \(term), locations: \(locations))"
        }
    }

    /// Structure 
    struct DistributedTermsResult: Hashable, CustomStringConvertible {
        let terms: [Result]

        var description: String {
            "DistributedTermsResult(terms: \(terms))"
        }
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

internal extension Collection where Element: Collection {
    /// Expands a collection-of-collections by returning a permutation of each
    /// combination of individual items in each collection in a separate array.
    ///
    /// If the array is empty, an empty array is returned.
    ///
    /// - precondition: None of the inner collections must be empty.
    func permute() -> [[Element.Element]] {
        if isEmpty {
            return []
        }

        precondition(!contains(where: \.isEmpty), #"!contains(where: \.isEmpty)"#)

        if count == 1 {
            return self[startIndex].map({ [$0] })
        }

        var result: [[Element.Element]] = []

        for el in self[startIndex] {
            let rem = self[self.index(after: startIndex)...].permute()
            
            result.append(contentsOf: rem.map({ [el] + $0 }))
        }

        return result
    }
}
