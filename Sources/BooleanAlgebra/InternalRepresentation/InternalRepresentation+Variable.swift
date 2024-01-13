extension InternalRepresentation {
    final class Variable: InternalRepresentation {
        override var discriminant: Discriminant { .variable }

        let name: String

        init(name: String) {
            self.name = name
        }

        override func copy() -> Variable {
            .variable(name)
        }

        override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)

            hasher.combine(name)
        }

        override func toExpression() -> Expression {
            .variable(name)
        }

        override func isEqual(to other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isEqual(to: other)
            default:
                false
            }
        }

        func isEqual(to other: Variable) -> Bool {
            name == other.name
        }

        override func isLessThan(_ other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isLessThan(other)
            case is And, is Xor, is Or, is Not:
                true
            case is Constant:
                false
            default:
                false
            }
        }

        func isLessThan(_ other: Variable) -> Bool {
            name.compare(other.name) == .orderedAscending
        }
    }
}

extension InternalRepresentation {
    /// Returns `true` if this is a variable expression.
    var isVariable: Bool {
        self is Variable
    }

    /// Attempts to typecast this expression object.
    var asVariable: Variable? {
        self as? Variable
    }

    static func variable(_ name: String) -> Variable {
        Variable(name: name)
    }
}
