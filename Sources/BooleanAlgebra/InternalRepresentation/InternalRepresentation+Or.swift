extension InternalRepresentation {
    final class Or: Binary {
        override var discriminant: Discriminant { .or }

        override func copy() -> Or {
            Or(operands: operands.copy())
        }

        override func flattened() -> Or {
            var newOperands: [InternalRepresentation] = []
            for e in operands {
                switch e {
                case let e as Or:
                    newOperands.append(contentsOf: e.flattened().operands)
                default:
                    newOperands.append(e.flattened())
                }
            }

            return Or(operands: newOperands.copyIfParented())
        }

        override func toExpression() -> Expression {
            rightAssociateBinary(operands, base: .true, binary: Expression.or)
        }

        override func isEqual(to other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isEqual(to: other)
            default:
                false
            }
        }

        func isEqual(to other: Or) -> Bool {
            operands.elementsEqual(other.operands)
        }

        override func isLessThan(_ other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isLessThan(other)
            default:
                // Or expressions have the least precedence
                false
            }
        }

        func isLessThan(_ other: Or) -> Bool {
            isLessThan(operands, other.operands)
        }

        override func subExpressionsWithLocation(parent: ExpressionPath) -> [(InternalRepresentation, ExpressionPath)] {
            operands.enumerated().map { (i, subExp) in
                return (subExp, .or(parent, operand: i))
            }
        }
    }
}

extension InternalRepresentation {
    /// Returns `true` if this is a disjunction operation.
    var isOr: Bool {
        self is Or
    }

    /// Attempts to typecast this expression object.
    var asOr: Or? {
        self as? Or
    }

    static func or(_ operands: any Collection<InternalRepresentation>) -> InternalRepresentation {
        assert(!operands.isEmpty, "!operands.isEmpty")
        if operands.count == 1 {
            return operands.first!
        }

        return Or(operands: Array(operands.copyIfParented()))
    }
}
