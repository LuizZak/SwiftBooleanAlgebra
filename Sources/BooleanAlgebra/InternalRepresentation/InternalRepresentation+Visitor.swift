extension InternalRepresentation {
    /// The location of a walk so far.
    typealias WalkLocation = KeyPath<InternalRepresentation, InternalRepresentation>

    /// Walks this tree of expressions with a given visitor function.
    func walk(_ visitor: (InternalRepresentation) -> VisitResult) {
        var stack: [InternalRepresentation] = [self]

        while let next = stack.popLast() {
            switch visitor(next) {
            case .visitSubExpressions:
                stack.append(contentsOf: next.subExpressions)

            case .ignoreSubExpressions:
                break

            case .stop:
                return
            }
        }
    }

    /// Walks this tree of expressions with a given visitor function, while
    /// relaying the relative location of the visit in respect to `self`.
    func walkLocating(_ visitor: (InternalRepresentation, ExpressionPath) -> VisitResult) {
        var stack: [(InternalRepresentation, ExpressionPath)] = [(self, .root)]

        while let (next, location) = stack.popLast() {
            switch visitor(next, location) {
            case .visitSubExpressions:
                stack.append(contentsOf: next.subExpressionsWithLocation(parent: location))

            case .ignoreSubExpressions:
                break

            case .stop:
                return
            }
        }
    }

    enum VisitResult {
        /// Requests that the walk walk through sub expressions in an expression.
        case visitSubExpressions
        
        /// Requests that the walk ignore sub expressions in an expression.
        case ignoreSubExpressions

        /// Requests that the walk stop on an expression.
        case stop
    }
}
