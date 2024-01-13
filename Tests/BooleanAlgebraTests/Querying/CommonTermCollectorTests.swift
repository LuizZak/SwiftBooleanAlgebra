import XCTest

@testable import BooleanAlgebra

class CommonTermCollectorTests: XCTestCase {
    func testMinimalTerms_twoTerms_simple_notCommon() {
        let expression: Expression =
            "a" * "b"
        
        let sut = makeSut(expression)
        let result = sut.minimalTerms()

        assertEqual(result, [])
    }

    func testMinimalTerms_twoTerms_simple_common() {
        let expression: Expression =
            "a" * "a"
        
        let sut = makeSut(expression)
        let result = sut.minimalTerms()

        assertEqual(result, [
            makeResultEntry(
                .variable("a"), [
                    .and(.root, operand: 0),
                    .and(.root, operand: 1),
                ]),
        ])
    }

    func testMinimalTerms_threeTerms_simple_common() {
        let expression: Expression =
            "a" * "b" * "a"
        
        let sut = makeSut(expression)
        let result = sut.minimalTerms()

        assertEqual(result, [
            makeResultEntry(
                .variable("a"), [
                    .and(.root, operand: 0),
                    .and(.root, operand: 2),
                ]),
        ])
    }

    func testCompoundTerms_twoTerm_disjunction() {
        let expression: Expression =
            ("a" * "b") + ("a" * "c")
        
        let sut = makeSut(expression)
        let result = sut.compoundTerms()

        assertEqual(result, [
            makeResultEntry(
                .variable("a"), [
                    .and(.or(.root, operand: 0), operand: 0),
                    .and(.or(.root, operand: 1), operand: 0),
                ]),
        ])
    }

    func testCompoundTerms_threeTerms_disjunction() {
        let expression: Expression =
            ("a" * "b") + ("a" * "c") + ("d" + "e")
        
        let sut = makeSut(expression)
        let result = sut.compoundTerms()

        assertEqual(result, [
            makeResultEntry(
                .variable("a"), [
                    .and(.or(.root, operand: 0), operand: 0),
                    .and(.or(.root, operand: 1), operand: 0),
                ]),
        ])
    }

    func testMaximalCompoundTerms_twoTerm_conjunction() {
        let expression: Expression =
            ("a" + "b") * ("a" + "c")
        
        let sut = makeSut(expression)
        let result = sut.maximalCompoundTerms()

        assertEqual(result, [
            makeResultEntry(
                .variable("a"), [
                    .or(.and(.root, operand: 0), operand: 0),
                    .or(.and(.root, operand: 1), operand: 0),
                ]),
        ])
    }

    func testMaximalCompoundTerms_twoTerm_disjunction() {
        let expression: Expression =
            ("a" * "b") + ("a" * "c")
        
        let sut = makeSut(expression)
        let result = sut.maximalCompoundTerms()

        assertEqual(result, [
            makeResultEntry(
                .variable("a"), [
                    .and(.or(.root, operand: 0), operand: 0),
                    .and(.or(.root, operand: 1), operand: 0),
                ]),
        ])
    }

    func testMaximalCompoundTerms_threeTerms_disjunction() {
        let expression: Expression =
            ("a" * "b") + ("a" * "c") + ("d" * "e")
        
        let sut = makeSut(expression)
        let result = sut.maximalCompoundTerms()

        assertEqual(result, [])
    }

    func testMaximalCompoundTerms_threeTerms_disjunction_mismatchedTypes() {
        let expression: Expression =
            ("a" * "b") + ("a" * "c") + ("d" + "e")
        
        let sut = makeSut(expression)
        let result = sut.maximalCompoundTerms()

        assertEqual(result, [
            makeResultEntry(
                .variable("a"), [
                    .and(.or(.root, operand: 0), operand: 0),
                    .and(.or(.root, operand: 1), operand: 0),
                ]),
        ])
    }

    // MARK: Test internals
    
    func makeSut(_ exp: Expression) -> CommonTermCollector {
        let internalRepresentation = InternalRepresentation.from(exp).flattened()

        guard let binary = internalRepresentation as? InternalRepresentation.Binary else {
            fatalError("Expected input to be a binary expression, found \(type(of: internalRepresentation))")
        }

        return CommonTermCollector(binary, path: .root)
    }

    func makeResultEntry(_ exp: Expression, _ locations: [InternalRepresentation.ExpressionPath]) -> CommonTermCollector.Result {
        .init(term: InternalRepresentation.from(exp), locations: locations)
    }

    func assertEqual(
        _ actual: [CommonTermCollector.Result],
        _ expected: [CommonTermCollector.Result],
        line: UInt = #line
    ) {

        guard !actual.elementsEqual(expected, by: { assertEqual($0, $1, line: line) }) else {
            return
        }

        XCTFail("\(#function) failed: \(actual) != \(expected)", line: line)
    }

    @discardableResult
    func assertEqual(
        _ actual: CommonTermCollector.Result,
        _ expected: CommonTermCollector.Result,
        line: UInt = #line
    ) -> Bool {

        guard actual != expected else {
            return true
        }

        XCTFail("\(#function) failed: \(actual) != \(expected)", line: line)
        return false
    }
}
