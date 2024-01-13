import XCTest

@testable import BooleanAlgebra

class Expression_EvaluateTests: XCTestCase {
    func testEvaluate_conjunction() throws {
        let expr: Expression = "a" * "b"

        XCTAssertFalse(try expr.evaluate(variables: ["a": false, "b": false]))
        XCTAssertFalse(try expr.evaluate(variables: ["a": true, "b": false]))
        XCTAssertFalse(try expr.evaluate(variables: ["a": false, "b": true]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": true, "b": true]))
    }

    func testEvaluate_exclusiveDisjunction() throws {
        let expr: Expression = "a" ^ "b"

        XCTAssertFalse(try expr.evaluate(variables: ["a": false, "b": false]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": true, "b": false]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": false, "b": true]))
        XCTAssertFalse(try expr.evaluate(variables: ["a": true, "b": true]))
    }

    func testEvaluate_disjunction() throws {
        let expr: Expression = "a" + "b"

        XCTAssertFalse(try expr.evaluate(variables: ["a": false, "b": false]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": true, "b": false]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": false, "b": true]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": true, "b": true]))
    }

    func testEvaluate_negate() throws {
        let expr: Expression = !"a"

        XCTAssertFalse(try expr.evaluate(variables: ["a": true]))
    }

    func testEvaluate_variable() throws {
        let expr: Expression = "a"

        XCTAssertTrue(try expr.evaluate(variables: ["a": true]))
    }

    func testEvaluate_variable_throwsErrorOnUndefined() throws {
        let expr: Expression = "a"

        XCTAssertThrowsError(try expr.evaluate(variables: [:]))
    }

    func testEvaluate_parenthesized() throws {
        let expr: Expression = .parenthesized("a" + "b") * "c"

        XCTAssertFalse(try expr.evaluate(variables: ["a": false, "b": false, "c": false]))
        XCTAssertFalse(try expr.evaluate(variables: ["a": true, "b": false, "c": false]))
        XCTAssertFalse(try expr.evaluate(variables: ["a": false, "b": true, "c": false]))
        XCTAssertFalse(try expr.evaluate(variables: ["a": true, "b": true, "c": false]))
        XCTAssertFalse(try expr.evaluate(variables: ["a": false, "b": false, "c": true]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": true, "b": false, "c": true]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": false, "b": true, "c": true]))
        XCTAssertTrue(try expr.evaluate(variables: ["a": true, "b": true, "c": true]))
    }

    func testEvaluate_constantTrue() throws {
        let expr: Expression = true

        XCTAssertTrue(try expr.evaluate(variables: [:]))
    }

    func testEvaluate_constantFalse() throws {
        let expr: Expression = false

        XCTAssertFalse(try expr.evaluate(variables: [:]))
    }
}
