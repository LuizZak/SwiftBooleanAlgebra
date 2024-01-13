import XCTest

@testable import BooleanAlgebra

class ExpressionTests: XCTestCase {
    func testDescription() {
        assertDescription("a", "a")
        assertDescription(.parenthesized("a"), "(a)")
        assertDescription(¬"a", "¬a")
        assertDescription(¬(¬"a"), "¬(¬a)")
        assertDescription(¬(¬(¬"a")), "¬(¬(¬a))")
        assertDescription("a" + "b", "a + b")
        assertDescription("a" * "b", "a * b")
        assertDescription("a" * ("b" + "c"), "a * (b + c)")
        assertDescription("a" * "b" * "c", "a * b * c")
        assertDescription("a" + "b" + "c", "a + b + c")
        assertDescription(¬"a" * "b", "¬a * b")
        assertDescription(¬("a" * "b"), "¬(a * b)")
        assertDescription(¬.parenthesized("a" * "b"), "¬(a * b)")
    }

    // MARK: Test internals

    func assertDescription(_ expr: Expression, _ desc: String, line: UInt = #line) {
        XCTAssertEqual(expr.description, desc, line: line)
    }
}
