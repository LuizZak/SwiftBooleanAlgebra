extension InternalRepresentation {
    final class Xor: Binary {
        override var discriminant: Discriminant { .xor }

        override var description: String {
            ".xor(\(operands))"
        }

        override func copy() -> Xor {
            Xor(operands: operands.copy())
        }

        override func flattened() -> Xor {
            var newOperands: [InternalRepresentation] = []
            for e in operands {
                switch e {
                case let e as Xor:
                    newOperands.append(contentsOf: e.flattened().operands)
                default:
                    newOperands.append(e.flattened())
                }
            }
            
            return Xor(operands: newOperands.copyIfParented())
        }

        override func toExpression() -> Expression {
            rightAssociateBinary(operands, base: .true, binary: Expression.xor)
        }

        override func isEqual(to other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isEqual(to: other)
            default:
                false
            }
        }

        func isEqual(to other: Xor) -> Bool {
            operands.elementsEqual(other.operands)
        }

        override func isLessThan(_ other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isLessThan(other)
            case is And, is Not, is Constant, is Variable:
                false
            case is Or:
                true
            default:
                false
            }
        }

        func isLessThan(_ other: Xor) -> Bool {
            isLessThan(operands, other.operands)
        }

        override func subExpressionsWithLocation(parent: ExpressionPath) -> [(InternalRepresentation, ExpressionPath)] {
            operands.enumerated().map { (i, subExp) in
                return (subExp, .xor(parent, operand: i))
            }
        }
    }
}

extension InternalRepresentation {
    /// Returns `true` if this is an exclusive disjunction operation.
    var isXor: Bool {
        self is Xor
    }

    /// Attempts to typecast this expression object.
    var asXor: Xor? {
        self as? Xor
    }

    static func xor(_ operands: any Collection<InternalRepresentation>) -> InternalRepresentation {
        assert(!operands.isEmpty, "!operands.isEmpty")
        if operands.count == 1 {
            return operands.first!
        }

        return Xor(operands: Array(operands.copyIfParented()))
    }
}
