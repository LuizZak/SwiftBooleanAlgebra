import XCTest

@testable import BooleanAlgebra

class Expression_TruthTableTests: XCTestCase {
    
    func testGenerateTruthTable_oneTerm() {
        let sut: Expression = "a" + ¬"a"

        let result = sut.generateTruthTable()
        let expected = TruthTable(
            expression: sut,
            variables: ["a"],
            rows: [
                .init(values: [false], result: true),
                .init(values: [true], result: true),
            ])

        assertEqual(result, expected)
    }

    func testGenerateTruthTable_twoTerms() {
        let sut: Expression = ("a" * ¬"b") + ¬"a"

        let result = sut.generateTruthTable()
        let expected = TruthTable(
            expression: sut,
            variables: ["a", "b"],
            rows: [
                .init(values: [false, false], result: true),
                .init(values: [true, false], result: true),
                .init(values: [false, true], result: true),
                .init(values: [true, true], result: false),
            ])

        assertEqual(result, expected)
    }

    func testGenerateTruthTable_threeTerms() {
        // Boolean algebra expression for the carry term of a one-bit full adder.
        let sut: Expression = ("a" * "b" * ¬"c") + ("a" * ¬"b" * "c") + (¬"a" * "b" * "c") + ("a" * "b" * "c")

        let result = sut.generateTruthTable()
        let expected = TruthTable(
            expression: sut,
            variables: ["a", "b", "c"],
            rows: [
                .init(values: [false, false, false], result: false),
                .init(values: [true, false, false], result: false),
                .init(values: [false, true, false], result: false),
                .init(values: [true, true, false], result: true),
                .init(values: [false, false, true], result: false),
                .init(values: [true, false, true], result: true),
                .init(values: [false, true, true], result: true),
                .init(values: [true, true, true], result: true),
            ])

        assertEqual(result, expected)
    }

    func testGenerateTruthTable_threeTerms_exclusiveDisjunction() {
        // Boolean algebra expression for the sum term of a one-bit full adder.
        let sut: Expression = "a" ^ "b" ^ "c"

        let result = sut.generateTruthTable()
        let expected = TruthTable(
            expression: sut,
            variables: ["a", "b", "c"],
            rows: [
                .init(values: [false, false, false], result: false),
                .init(values: [true, false, false], result: true),
                .init(values: [false, true, false], result: true),
                .init(values: [true, true, false], result: false),
                .init(values: [false, false, true], result: true),
                .init(values: [true, false, true], result: false),
                .init(values: [false, true, true], result: false),
                .init(values: [true, true, true], result: true),
            ])

        assertEqual(result, expected)
    }

    // MARK: Test internals

    func assertEqual(_ actual: TruthTable, _ expected: TruthTable, line: UInt = #line) {
        XCTAssertEqual(actual, expected, line: line)

        if actual != expected {
            let actualTable = actual.toAsciiTable()
            let expectedTable = expected.toAsciiTable()

            print("Actual:\n\(actualTable)")
            print()
            print("Expected:\n\(expectedTable)")
        }
    }
}
