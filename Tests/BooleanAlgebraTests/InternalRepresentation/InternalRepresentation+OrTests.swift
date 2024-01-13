import XCTest

@testable import BooleanAlgebra

class InternalRepresentation_OrTests: XCTestCase {
    func testFlattened() {
        let sut: InternalRepresentation =
            .and([
                .or([
                    .or([.variable("d"), .variable("c")]),
                    .variable("b"),
                ]),
                .variable("c"),
            ])

        let result = sut.flattened()

        assertEqual(
            result,
            .and([
                .or([.variable("d"), .variable("c"), .variable("b")]),
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
