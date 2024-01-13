import XCTest

@testable import BooleanAlgebra

class InternalRepresentation_Visitor_ExpressionPathTests: XCTestCase {
    typealias Sut = InternalRepresentation.ExpressionPath

    func testFromInverse() {
        let components = [
            makeSut(.or(.and(.root, operand: 1), operand: 0)),
            makeSut(.and(.root, operand: 1)),
        ]

        let result = Sut.fromInverse(components)
        let expected = Sut.and(.or(.root, operand: 0), operand: 1)

        XCTAssertEqual(result, expected)
    }

    func testFromInverse_not() {
        let components = [
            makeSut(.or(.and(.root, operand: 1), operand: 0)),
            makeSut(.and(.root, operand: 1)),
            makeSut(.not(.root)),
        ]

        let result = Sut.fromInverse(components)
        let expected = Sut.not(.and(.or(.root, operand: 0), operand: 1))

        XCTAssertEqual(result, expected)
    }

    // MARK: - Test internals

    func makeSut(_ path: Sut) -> Sut {
        return path
    }
}
