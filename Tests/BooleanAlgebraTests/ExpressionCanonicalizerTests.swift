import XCTest

@testable import BooleanAlgebra

class ExpressionCanonicalizerTests: XCTestCase {
    func testCanonicalize() {
        let exp: Expression = "d" + ("b" + "a")

        let result = ExpressionCanonicalizer.canonicalize(exp)

        XCTAssertEqual(result, .or("a", .or("b", "d")))
    }
}
