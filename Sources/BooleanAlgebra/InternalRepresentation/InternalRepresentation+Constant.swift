extension InternalRepresentation {
    final class Constant: InternalRepresentation {
        override var discriminant: Discriminant { .constant }

        let value: Bool

        override var description: String {
            ".constant(\(value))"
        }

        init(value: Bool) {
            self.value = value
        }

        override func copy() -> Constant {
            Constant(value: value)
        }

        override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)

            hasher.combine(value)
        }

        override func toExpression() -> Expression {
            value ? true : false
        }

        override func isEqual(to other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isEqual(to: other)
            default:
                false
            }
        }

        func isEqual(to other: Constant) -> Bool {
            value == other.value
        }

        override func isLessThan(_ other: InternalRepresentation) -> Bool {
            switch other {
            case let other as Self:
                isLessThan(other)
            default:
                // Constants have the highest precedence
                true
            }
        }

        func isLessThan(_ other: Constant) -> Bool {
            value && !other.value
        }
    }
}

extension InternalRepresentation {
    /// Alias for `.constant(true)`
    static var `true`: Constant { constant(true) }

    /// Alias for `.constant(false)`
    static var `false`: Constant { constant(false) }

    /// Returns `true` if this is a constant expression.
    var isConstant: Bool {
        self is Constant
    }

    /// Attempts to typecast this expression object.
    var asConstant: Constant? {
        self as? Constant
    }

    static func constant(_ value: Bool) -> Constant {
        .init(value: value)
    }
}
