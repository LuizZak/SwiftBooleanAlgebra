import XCTest

@testable import BooleanAlgebra

class ExpressionReducerTests: XCTestCase {
    func testReduce_atomicVariable() {
        runReduce("a", expected: "a")
    }

    func testReduce_doubleNegation() {
        runReduce(¬"a", expected: ¬"a")
        runReduce(¬(¬"a"), expected: "a")
        runReduce(¬(¬(¬"a")), expected: ¬"a")
    }

    func testReduce_negationOfConstant() {
        runReduceStep(¬false, expected: true, step: ExpressionReducer.negationOfConstant)
        runReduceStep(¬true, expected: false, step: ExpressionReducer.negationOfConstant)

        runReduce(¬(¬(¬false)), expected: true)
        runReduce(¬(¬(¬true)), expected: false)
    }

    func testReduce_deMorganLaw() {
        // AND form
        runReduceStep(¬("a" * "b"), expected: ¬"a" + ¬"b", step: ExpressionReducer.deMorganLaw)
        runReduceStep(¬("a" * ¬"b"), expected: ¬"a" + ¬(¬"b"), step: ExpressionReducer.deMorganLaw)
        // OR form
        runReduceStep(¬("a" + "b"), expected: ¬"a" * ¬"b", step: ExpressionReducer.deMorganLaw)
        runReduceStep(¬("a" + ¬"b"), expected: ¬"a" * ¬(¬"b"), step: ExpressionReducer.deMorganLaw)
    }

    func testReduce_idempotentLaw() {
        runReduceStep("a" * "a", expected: "a", step: ExpressionReducer.idempotentLaw)
        runReduceStep("a" + "a", expected: "a", step: ExpressionReducer.idempotentLaw)
        runReduceStep(("a" + "b") * ("a" + "b"), expected: "a" + "b", step: ExpressionReducer.idempotentLaw)
        runReduceStep(("a" + "a") * ("a" + "a"), expected: "a" + "a", step: ExpressionReducer.idempotentLaw)
        runReduceStep(("a" * "a") + ("a" * "a"), expected: "a" * "a", step: ExpressionReducer.idempotentLaw)
        runReduceStep(("a" + "a") * ("a" + "a"), expected: "a" + "a", step: ExpressionReducer.idempotentLaw)
        runReduceStep(("a" * "a") + ("a" * "a"), expected: "a" * "a", step: ExpressionReducer.idempotentLaw)
        runReduceStep(("a" + "b") * ("b" + "a"), expected: "a" + "b", step: ExpressionReducer.idempotentLaw)

        // Ensure idempotency is reduced in multi-term expressions
        runReduce("a" * "a" * "a" * "a", expected: "a")
        runReduce("a" + "a" + "a" + "a", expected: "a")
    }

    func testReduce_idempotentLaw_skipSubExpressions() {
        runReduceStep("a" + ("b" * "a"), expected: "a" + ("b" * "a"), step: ExpressionReducer.idempotentLaw)
    }

    func testReduce_identityLaw() {
        runReduceStep(true * "a", expected: "a", step: ExpressionReducer.identityLaw)
        runReduceStep("a" * true, expected: "a", step: ExpressionReducer.identityLaw)
        runReduceStep("a" * (true * "b"), expected: "a" * "b", step: ExpressionReducer.identityLaw)
        runReduceStep(false + "a", expected: "a", step: ExpressionReducer.identityLaw)
        runReduceStep("a" + false, expected: "a", step: ExpressionReducer.identityLaw)
        runReduceStep("a" + (false + "b"), expected: "a" + "b", step: ExpressionReducer.identityLaw)
    }

    func testReduce_nullLaw() {
        runReduceStep(false * "a", expected: false, step: ExpressionReducer.nullLaw)
        runReduceStep("a" * false, expected: false, step: ExpressionReducer.nullLaw)
        runReduceStep("a" * false * "b", expected: false, step: ExpressionReducer.nullLaw)
        runReduceStep(true + "a", expected: true, step: ExpressionReducer.nullLaw)
        runReduceStep("a" + true, expected: true, step: ExpressionReducer.nullLaw)
        runReduceStep("a" + true + "b", expected: true, step: ExpressionReducer.nullLaw)
    }

    func testReduce_inverseLaw() {
        runReduceStep("a" * ¬"a", expected: false, step: ExpressionReducer.inverseLaw)
        runReduceStep("a" * "b" * ¬"a", expected: false, step: ExpressionReducer.inverseLaw)
        runReduceStep("a" + ¬"a", expected: true, step: ExpressionReducer.inverseLaw)
        runReduceStep("a" + "b" + ¬"a", expected: true, step: ExpressionReducer.inverseLaw)
    }

    func testReduce_absorptionLaw() {
        // AND form
        runReduceStep("a" * ("a" + "b"), expected: "a", step: ExpressionReducer.absorptionLaw)
        runReduceStep("a" * ("b" + "a"), expected: "a", step: ExpressionReducer.absorptionLaw)
        runReduceStep(("b" + "a") * "a", expected: "a", step: ExpressionReducer.absorptionLaw)
        runReduceStep(("a" + "b") * "a", expected: "a", step: ExpressionReducer.absorptionLaw)
        runReduceStep(("a" + "b") * ("a" + "b" + "c"), expected: "a" + "b", step: ExpressionReducer.absorptionLaw)
        runReduceStep(("a" + "b") * ("a" + "c"), expected: ("a" + "b") * ("a" + "c"), step: ExpressionReducer.absorptionLaw)
        // OR form
        runReduceStep(("a" * "b") + ("a" * "b") * "c", expected: "a" * "b", step: ExpressionReducer.absorptionLaw)
        runReduceStep("a" + "a" * "b", expected: "a", step: ExpressionReducer.absorptionLaw)
        runReduceStep("a" + "b" * "a", expected: "a", step: ExpressionReducer.absorptionLaw)
        runReduceStep("b" * "a" + "a", expected: "a", step: ExpressionReducer.absorptionLaw)
        runReduceStep("a" * "b" + "a", expected: "a", step: ExpressionReducer.absorptionLaw)

        // Ensure absorption is correctly flattened if multiple operands can be absorbed
        runReduce("a" + "b" * "a" + "b" * "c" + "a" * "c", expected: "a" + "b" * "c")
    }

    func testReduce_distributiveLaw() throws {
        runReduceStep(
            "a" * ("b" + "c"),
            expected: "a" * "b" + "a" * "c",
            step: ExpressionReducer.distributiveLaw
        )
        runReduceStep(
            ("b" + "c") * "a",
            expected: "a" * "b" + "a" * "c",
            step: ExpressionReducer.distributiveLaw
        )
        runReduceStep(
            ("a" + "b") * ("c" * "d"),
            expected: "a" * "c" + "a" * "d" + "b" * "c" + "b" * "d",
            step: ExpressionReducer.distributiveLaw
        )
    }

    func testReduce_distributiveLaw_offset() throws {
        let exprStr = "d + (¬a * b * ¬c) + (¬a * ¬b * c)"
        let expr = try parse(exprStr)

        runReduceStep(
            expr,
            expected: "d" + ¬"a" * ¬"c" * "b" + ¬"a" * ¬"b" * "c",
            step: ExpressionReducer.distributiveLaw
        )
    }

    func testReduce_distributiveLaw_nested() throws {
        let exprStr = "(¬a * b * ¬c) + (¬a * ¬b * c) + d"
        let expr = try parse(exprStr)

        runReduceStep(
            expr,
            expected: "d" + "b" * ¬"a" * ¬"c" + "c" * ¬"a" * ¬"b",
            step: ExpressionReducer.distributiveLaw
        )
    }

    func testReduce_inverseDistributiveLaw_conjunction() throws {
        let exprStr = "(a + b + c) * (a + d)"
        let expr = try parse(exprStr)

        runReduceStep(
            expr,
            expected: "a" * ("b" + "c" + "d"),
            step: ExpressionReducer.inverseDistributiveLaw
        )
    }

    func testReduce_inverseDistributiveLaw_disjunction() throws {
        let exprStr = "(a * b * c) + (a * d)"
        let expr = try parse(exprStr)

        runReduceStep(
            expr,
            expected: "a" + ("b" * "c" * "d"),
            step: ExpressionReducer.inverseDistributiveLaw
        )
    }

    func testReduce() throws {
        runReduce(
            try parse("¬((b * 1 + c * d) * c) + d * 0"),
            expected: ¬"d" * ¬"b" + ¬"c"
        )
        runReduce(
            try parse("¬(b * b) + (¬(c * 0) + 0 * C) * b"),
            expected: true
        )
        runReduce(
            try parse("¬0 * a + (1 * c + c * 0) * ¬d"),
            expected: "a" + "c" * ¬"d"
        )
        runReduce(
            try parse("(c * d + a * a + ¬((c * b + c * b) * a)) * ¬a + b * d"),
            expected: ¬"a" + "b" * "d"
        )
        runReduce(
            ("a" + "b") * ("a" + "c"),
            expected: "a" + "b" * "c"
        )
        runReduce(
            try parse("(a * ¬b * ¬c) + (a * b * ¬c) + (a * ¬b * c) + (a * b * c)"),
            expected: "a"
        )
    }

    // MARK: Test internals

    func runReduce(
        _ input: Expression,
        expected: Expression,
        line: UInt = #line
    ) {
        let sut = makeSut(input)
        sut.reduce()

        let resultCanonical = sut.toExpression()
        let expectedCanonical = ExpressionCanonicalizer.canonicalize(expected)

        XCTAssertEqual(resultCanonical, expectedCanonical, line: line)
        
        if resultCanonical != expectedCanonical && resultCanonical.description == expectedCanonical.description {
            print("Result:  ", resultCanonical.debugDescription)
            print("Expected:", expectedCanonical.debugDescription)
        }
    }

    func runReduceStep(
        _ input: Expression,
        expected: Expression,
        step: (ExpressionReducer) -> () -> Void,
        line: UInt = #line
    ) {
        let sut = makeSut(input)

        step(sut)()
        let result = sut.toExpression()


        let resultCanonical = ExpressionCanonicalizer.canonicalize(result)
        let expectedCanonical = ExpressionCanonicalizer.canonicalize(expected)

        XCTAssertEqual(resultCanonical, expectedCanonical, line: line)
        
        if resultCanonical != expectedCanonical && resultCanonical.description == expectedCanonical.description {
            print("Result:  ", resultCanonical.debugDescription)
            print("Expected:", expectedCanonical.debugDescription)
        }
    }

    func makeSut(_ expression: Expression) -> ExpressionReducer {
        ExpressionReducer(expression)
    }

    func parse(_ expString: String) throws -> Expression {
        try Parser.parse(expression: expString)
    }
}
