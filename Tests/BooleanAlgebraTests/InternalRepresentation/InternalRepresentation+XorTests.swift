import XCTest

@testable import BooleanAlgebra

class InternalRepresentation_XorTests: XCTestCase {
    func testFlattened() {
        let sut: InternalRepresentation =
            .or([
                .xor([
                    .xor([.variable("d"), .variable("c")]),
                    .variable("b"),
                ]),
                .variable("c"),
            ])

        let result = sut.flattened()

        assertEqual(
            result,
            .or([
                .xor([.variable("d"), .variable("c"), .variable("b")]),
                .variable("c"),
            ])
        )
    }

    // MARK: - Test internals

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
