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

    /// A recursive structure used to specify the location of an expression within
    /// a larger expression tree.
    indirect enum ExpressionPath: Hashable, CustomStringConvertible {
        /// End point of a search. Is the base expression that is being located on.
        case `root`

        /// Expression is within an operand of a conjunction expression.
        case and(ExpressionPath, operand: Int)

        /// Expression is within an operand of an exclusive disjunction expression.
        case xor(ExpressionPath, operand: Int)

        /// Expression is within an operand of a disjunction expression.
        case or(ExpressionPath, operand: Int)

        /// Expression is within the operand of a negation expression.
        case not(ExpressionPath)

        var description: String {
            switch self {
            case .and(let parent, let operand): 
                return ".and(\(parent), \(operand))"

            case .xor(let parent, let operand):
                return ".xor(\(parent), \(operand))"

            case .or(let parent, let operand): 
                return ".or(\(parent), \(operand))"

            case .not(let parent): 
                return ".not(\(parent))"

            case .root:
                return ".root"
            }
        }

        func inverse() -> [ExpressionPath] {
            var result: [ExpressionPath] = []
            var next = self

            while next != .root {
                result.append(next)

                switch next {
                case .and(let parent, _), .or(let parent, _), .xor(let parent, _), .not(let parent):
                    next = parent
                default:
                    break
                }
            }

            return [.root] + result.reversed()
        }

        static func fromInverse<C: Collection<ExpressionPath>>(_ components: C) -> ExpressionPath {
            return components.reduce(.root) { (cur, next) in
                switch next {
                case .root:
                    return cur
                case .and(_, let operand):
                    return .and(cur, operand: operand)
                case .xor(_, let operand):
                    return .xor(cur, operand: operand)
                case .or(_, let operand):
                    return .or(cur, operand: operand)
                case .not(_):
                    return .not(cur)
                }
            }
        }

        /// Appends a parent to this path.
        ///
        /// If the current parent path is not `.root`, it's parent is appended to,
        /// recursively, instead.
        func appending(parent subPath: ExpressionPath) -> ExpressionPath {
            switch self {
            case .root:
                return subPath

            case .and(let inner, let operand):
                return .and(inner.appending(parent: subPath), operand: operand)

            case .xor(let inner, let operand):
                return .xor(inner.appending(parent: subPath), operand: operand)

            case .or(let inner, let operand):
                return .or(inner.appending(parent: subPath), operand: operand)

            case .not(let inner):
                return .not(inner.appending(parent: subPath))
            }
        }
    }
}
