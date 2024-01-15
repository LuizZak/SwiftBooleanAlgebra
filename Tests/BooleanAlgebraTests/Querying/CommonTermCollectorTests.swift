import XCTest

@testable import BooleanAlgebra

class CommonTermCollectorTests: XCTestCase {
    func testTerms_twoTerms_simple_notCommon() {
        let expression: Expression =
            "a" * "b"
        
        let sut = makeSut(expression)
        let result = sut.terms()

        assertEqual(result, [
            makeResultEntry(.variable("a"), [
                .and(.root, operand: 0),
            ]),
            makeResultEntry(.variable("b"), [
                .and(.root, operand: 1),
            ]),
        ])
    }

    func testTerms_twoTerms_simple_common() {
        let expression: Expression =
            "a" * "b" * "a"
        
        let sut = makeSut(expression)
        let result = sut.terms()

        assertEqual(result, [
            makeResultEntry(.variable("a"), [
                .and(.root, operand: 0),
            ]),
            makeResultEntry(.variable("b"), [
                .and(.root, operand: 1),
            ]),
            makeResultEntry(.variable("a"), [
                .and(.root, operand: 2),
            ]),
        ])
    }

    func testTerms_twoTerms_compound() {
        let expression: Expression =
            "a" * ("b" + "c")
        
        let sut = makeSut(expression)
        let result = sut.terms()

        assertEqual(result, [
            makeResultEntry(.variable("a"), [
                .and(.root, operand: 0),
            ]),
            makeResultEntry(.or(.variable("b"), .variable("c")), [
                .and(.root, operand: 1),
            ]),
        ])
    }

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

    func testMaximalCompoundTerms_threeTerms_disjunction_notCommon_compound() {
        let expression: Expression =
            ("a" * "b") + ("a" * "c") + ("d" * "e")
        
        let sut = makeSut(expression)
        let result = sut.maximalCompoundTerms()

        assertEqual(result, [])
    }

    func testMaximalCompoundTerms_threeTerms_disjunction_notCommon_simple() {
        let expression: Expression =
            ("a" * "b") + ("a" * "c") + "d"
        
        let sut = makeSut(expression)
        let result = sut.maximalCompoundTerms()

        assertEqual(result, [])
    }

    func testMaximalCompoundTerms_threeTerms_disjunction_mismatchedTypes() {
        let expression: Expression =
            ("a" * "b") + ("a" * "c") + ("d" + "e")
        
        let sut = makeSut(expression)
        let result = sut.maximalCompoundTerms()

        assertEqual(result, [])
    }

    func testDistributedTerms_twoTerms_distinct_conjunction() {
        let expression: Expression =
            ("a" + "b") * ("c" + "d")
        
        let sut = makeSut(expression)
        let result = sut.distributedTerms()

        assertEqual(result, [
            // a * c + a * d
            makeDistributedTermResultEntry(
                [
                    makeResultEntry(.variable("a"), [
                        .or(.and(.root, operand: 0), operand: 0),
                    ]),
                    makeResultEntry(.variable("c"), [
                        .or(.and(.root, operand: 1), operand: 0),
                    ]),
                ]
            ),
            makeDistributedTermResultEntry(
                [
                    makeResultEntry(.variable("a"), [
                        .or(.and(.root, operand: 0), operand: 0),
                    ]),
                    makeResultEntry(.variable("d"), [
                        .or(.and(.root, operand: 1), operand: 1),
                    ]),
                ]
            ),
            // b * c + b * d
            makeDistributedTermResultEntry(
                [
                    makeResultEntry(.variable("b"), [
                        .or(.and(.root, operand: 0), operand: 1),
                    ]),
                    makeResultEntry(.variable("c"), [
                        .or(.and(.root, operand: 1), operand: 0),
                    ]),
                ]
            ),
            makeDistributedTermResultEntry(
                [
                    makeResultEntry(.variable("b"), [
                        .or(.and(.root, operand: 0), operand: 1),
                    ]),
                    makeResultEntry(.variable("d"), [
                        .or(.and(.root, operand: 1), operand: 1),
                    ]),
                ]
            ),
        ])
    }

    // MARK: Collection.permute() tests

    func testCollectionPermute() {
        XCTAssertEqual(
            [[0, 1], [2], [3, 4]].permute(),
            [
                [0, 2, 3],
                [0, 2, 4],
                [1, 2, 3],
                [1, 2, 4],
            ]
        )
    }

    // MARK: - Test internals
    
    func makeSut(_ exp: Expression) -> CommonTermCollector {
        let internalRepresentation = InternalRepresentation.from(exp).flattened()

        guard let binary = internalRepresentation as? InternalRepresentation.Binary else {
            fatalError("Expected input to be a binary expression, found \(type(of: internalRepresentation))")
        }

        return CommonTermCollector(binary, path: .root)
    }

    func makeDistributedTermResultEntry(
        _ terms: [CommonTermCollector.Result]
    ) -> CommonTermCollector.DistributedTermsResult {

        .init(terms: terms)
    }

    func makeResultEntry(_ exp: Expression, _ locations: [InternalRepresentation.ExpressionPath]) -> CommonTermCollector.Result {
        .init(term: InternalRepresentation.from(exp), locations: locations)
    }

    func assertEqual(
        _ actual: [CommonTermCollector.DistributedTermsResult],
        _ expected: [CommonTermCollector.DistributedTermsResult],
        line: UInt = #line
    ) {

        guard !actual.elementsEqual(expected, by: { assertEqual($0, $1, line: line) }) else {
            return
        }

        XCTFail("\(#function) failed: \(actual) != \(expected)", line: line)
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

    @discardableResult
    func assertEqual(
        _ actual: CommonTermCollector.DistributedTermsResult,
        _ expected: CommonTermCollector.DistributedTermsResult,
        line: UInt = #line
    ) -> Bool {

        guard actual != expected else {
            return true
        }

        XCTFail("\(#function) failed: \(actual) != \(expected)", line: line)
        return false
    }
}
