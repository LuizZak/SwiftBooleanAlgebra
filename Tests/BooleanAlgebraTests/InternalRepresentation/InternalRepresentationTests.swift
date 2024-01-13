import XCTest

@testable import BooleanAlgebra

class InternalRepresentationTests: XCTestCase {
    func testRemoveAt() {
        let sut = makeSut(.and(.or("a", "b"), "c"))

        let result = sut.removing(at: .or(.and(.root, operand: 0), operand: 1))

        assertEqual(result, .and("a", "c"))
    }

    func testReplaceAt() {
        let sut = makeSut(.and(.or("a", "b"), "c"))

        let result = sut.replacing(path: .or(.and(.root, operand: 0), operand: 1), with: .true)

        assertEqual(result, .and(.or("a", true), "c"))
    }

    func testReplaceAt_not() {
        let sut = makeSut(.not(.and(.or("a", .not("b")), "c")))

        let result = sut.replacing(path: .not(.or(.and(.not(.root), operand: 0), operand: 1)), with: .true)

        assertEqual(result, .not(.and(.or("a", .not(true)), "c")))
    }

    // MARK: - Test internals

    func makeSut(_ exp: Expression) -> InternalRepresentation {
        .from(exp)
    }

    func assertEqual(
        _ actual: InternalRepresentation?,
        _ expected: Expression,
        line: UInt = #line
    ) {

        assertEqual(actual, InternalRepresentation.from(expected), line: line)
    }

    func assertEqual(
        _ actual: InternalRepresentation?,
        _ expected: InternalRepresentation,
        line: UInt = #line
    ) {

        guard actual != expected else {
            return
        }

        XCTAssertEqual(actual, expected, line: line)

        if let actual {
            print("Actual:  " + actual.toExpression().debugDescription)
            print("Expected:" + expected.toExpression().debugDescription)
        }
    }
}
