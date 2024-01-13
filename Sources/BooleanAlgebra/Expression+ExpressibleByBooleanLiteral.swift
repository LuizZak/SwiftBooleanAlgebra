extension Expression: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        if value {
            self = .true
        } else {
            self = .false
        }
    }
}
