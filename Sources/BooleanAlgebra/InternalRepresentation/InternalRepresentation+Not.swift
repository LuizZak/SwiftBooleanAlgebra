extension InternalRepresentation {
    final class Not: InternalRepresentation {
        override var discriminant: Discriminant { .not }

        override var subExpressions: [InternalRepresentation] { [operand] }

        var operand: InternalRepresentation {
            willSet {
                precondition(!operand.isSubExpression(self))
                operand.parent = nil
            }
            didSet {
                operand.parent = self
            }
        }

        init(operand: InternalRepresentation) {
            self.operand = operand

            super.init()

            operand.parent = self
        }

        override func copy() -> Not {
            .not(operand.copy())
        }

        override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)

            hasher.combine(operand)
        }

        override func toExpression() -> Expression {
            .not(operand.toExpression())
        }

        override func flattened() -> Not {
            .not(operand.flattened())
        }

        override func isEqual(to other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isEqual(to: other)
            default:
                false
            }
        }

        func isEqual(to other: Not) -> Bool {
            operand == other.operand
        }

        override func isLessThan(_ other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isLessThan(other)
            case is And, is Xor, is Or:
                true
            case is Variable, is Constant:
                false
            default:
                false
            }
        }

        func isLessThan(_ other: Not) -> Bool {
            operand < other.operand
        }

        override func subExpressionsWithLocation(parent: ExpressionPath) -> [(InternalRepresentation, ExpressionPath)] {
            return [(operand, .not(parent))]
        }

        /// Replaces the operand of this negation expression in-place, returning
        /// `self`.
        func replacingOperand(_ newOperand: InternalRepresentation) -> Self {
            operand = newOperand
            
            return self
        }
    }
}

extension InternalRepresentation {
    /// Returns `true` if this is a negation operation.
    var isNot: Bool {
        self is Not
    }

    /// Attempts to typecast this expression object.
    var asNot: Not? {
        self as? Not
    }

    static func not(_ operand: InternalRepresentation) -> Not {
        Not(operand: operand.copyIfParented())
    }
}
