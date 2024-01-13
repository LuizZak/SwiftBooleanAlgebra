import XCTest
import MiniLexer

@testable import BooleanAlgebra

class ParserTests: XCTestCase {
    func testParseExpression() throws {
        try assertParse(
            "(a*¬b*¬c)+(a*¬b*¬c)",
            expected: .or(
                .parenthesized(.and("a", .and(¬"b", ¬"c"))),
                .parenthesized(.and("a", .and(¬"b", ¬"c")))
            )
        )
    }

    func testParseExpression_and() throws {
        try assertParse(
            "a * b", expected: .and("a", "b")
        )
        try assertParse(
            "a ∧ b", expected: .and("a", "b")
        )
        try assertParse(
            "a & b", expected: .and("a", "b")
        )
    }

    func testParseExpression_xor() throws {
        try assertParse(
            "a ^ b", expected: .xor("a", "b")
        )
        try assertParse(
            "a ⊕ b", expected: .xor("a", "b")
        )
    }

    func testParseExpression_or() throws {
        try assertParse(
            "a + b", expected: .or("a", "b")
        )
        try assertParse(
            "a ∨ b", expected: .or("a", "b")
        )
        try assertParse(
            "a | b", expected: .or("a", "b")
        )
    }

    func testParseExpression_negate() throws {
        try assertParse(
            "!abc", expected: .not("abc")
        )
        try assertParse(
            "¬abc", expected: .not("abc")
        )
    }

    func testParseExpression_variable() throws {
        try assertParse(
            "abc", expected: .variable("abc")
        )
    }

    func testParseExpression_parenthesized() throws {
        try assertParse(
            "(a + b) * (c + d)",
            expected: .parenthesized("a" + "b") * .parenthesized("c" + "d")
        )
    }

    func testParseExpression_constantTrue() throws {
        try assertParse(
            "1", expected: true
        )
        try assertParse(
            "a + 1", expected: .or("a", true)
        )
        try assertParse(
            "1 + a", expected: .or(true, "a")
        )
    }

    func testParseExpression_constantFalse() throws {
        try assertParse(
            "0", expected: false
        )
        try assertParse(
            "a + 0", expected: .or("a", false)
        )
        try assertParse(
            "0 + a", expected: .or(false, "a")
        )
    }

    func testParseExpression_associativityAndPrecedence_conjunction() throws {
        // * is right associative
        try assertParse(
            "a * b * c", expected: .and("a", .and("b", "c"))
        )
        // ! < *
        try assertParse(
            "!a * b", expected: .and(.not("a"), "b")
        )
        try assertParse(
            "a * !b", expected: .and("a", .not("b"))
        )
        // * < +
        try assertParse(
            "a * b + c", expected: .or(.and("a", "b"), "c")
        )
        try assertParse(
            "a + b * c", expected: .or("a", .and("b", "c"))
        )
        // * < ^
        try assertParse(
            "a * b ^ c", expected: .xor(.and("a", "b"), "c")
        )
        try assertParse(
            "a ^ b * c", expected: .xor("a", .and("b", "c"))
        )
    }

    func testParseExpression_associativityAndPrecedence_exclusiveDisjunction() throws {
        // ^ is right associative
        try assertParse(
            "a ^ b ^ c", expected: .xor("a", .xor("b", "c"))
        )
        // ! < ^
        try assertParse(
            "!a ^ b", expected: .xor(.not("a"), "b")
        )
        try assertParse(
            "a ^ !b", expected: .xor("a", .not("b"))
        )
        // ^ < +
        try assertParse(
            "a ^ b + c", expected: .or(.xor("a", "b"), "c")
        )
        try assertParse(
            "a + b ^ c", expected: .or("a", .xor("b", "c"))
        )
    }

    func testParseExpression_associativityAndPrecedence_disjunction() throws {
        // + is right associative
        try assertParse(
            "a + b + c", expected: .or("a", .or("b", "c"))
        )
        // ! < +
        try assertParse(
            "!a + b", expected: .or(.not("a"), "b")
        )
        try assertParse(
            "a + !b", expected: .or("a", .not("b"))
        )
    }

    // MARK: Test internals

    private func assertParse(_ input: String, expected: Expression, line: UInt = #line) throws {
        let result = try tryParse(input: input, parser: Parser.parse(expression:))

        XCTAssertEqual(result, expected, line: line)

        if result != expected && result.description == expected.description {
            print("Result:  ", result.debugDescription)
            print("Expected:", expected.debugDescription)
        }
    }

    private func tryParse<T>(input: String, parser: (String) throws -> T) throws -> T {
        do {
            let result = try parser(input)
            return result
        } catch let error as LexerError {
            throw ParserError(description: error.description(withOffsetsIn: input))
        }
    }

    private struct ParserError: Error {
        var description: String
    }
}
