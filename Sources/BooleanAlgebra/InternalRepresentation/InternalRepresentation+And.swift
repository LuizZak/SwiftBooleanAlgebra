extension InternalRepresentation {
    final class And: Binary {
        override var discriminant: Discriminant { .and }

        override func copy() -> And {
            And(operands: operands.copy())
        }

        override func flattened() -> And {
            var newOperands: [InternalRepresentation] = []
            for e in operands {
                switch e {
                case let e as And:
                    newOperands.append(contentsOf: e.flattened().operands)
                default:
                    newOperands.append(e.flattened())
                }
            }

            return And(operands: newOperands.copyIfParented())
        }

        override func toExpression() -> Expression {
            rightAssociateBinary(operands, base: .true, binary: Expression.and)
        }

        override func isEqual(to other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isEqual(to: other)
            default:
                false
            }
        }

        func isEqual(to other: And) -> Bool {
            operands.elementsEqual(other.operands)
        }

        override func isLessThan(_ other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isLessThan(other)
            case is Xor, is Or:
                true
            case is Constant, is Variable, is Not:
                false
            default:
                false
            }
        }

        func isLessThan(_ other: And) -> Bool {
            isLessThan(operands, other.operands)
        }

        override func subExpressionsWithLocation(parent: ExpressionPath) -> [(InternalRepresentation, ExpressionPath)] {
            operands.enumerated().map { (i, subExp) in
                return (subExp, .and(parent, operand: i))
            }
        }
    }
}

extension InternalRepresentation {
    /// Returns `true` if this is a conjunction operation.
    var isAnd: Bool {
        self is And
    }

    /// Attempts to typecast this expression object.
    var asAnd: And? {
        self as? And
    }

    static func and(_ operands: any Collection<InternalRepresentation>) -> InternalRepresentation {
        assert(!operands.isEmpty, "!operands.isEmpty")
        if operands.count == 1 {
            return operands.first!
        }

        return And(operands: Array(operands.copyIfParented()))
    }
}
