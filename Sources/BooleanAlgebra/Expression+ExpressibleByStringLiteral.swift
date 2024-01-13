extension Expression: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .variable(value)
    }
}
