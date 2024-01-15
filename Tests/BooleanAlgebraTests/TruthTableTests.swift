import XCTest

@testable import BooleanAlgebra

class TruthTableTests: XCTestCase {
    func testEquivalent() {
        let table1 = makeSut(variables: ["a", "b"], rows: [
            .init(values: [O, O], result: O),
            .init(values: [I, O], result: true),
            .init(values: [O, I], result: true),
            .init(values: [I, I], result: O),
        ])

        let table2 = makeSut(variables: ["a", "b", "c"], rows: [
            .init(values: [O, O, O], result: O),
            .init(values: [I, O, O], result: true),
            .init(values: [O, I, O], result: true),
            .init(values: [I, I, O], result: O),
            .init(values: [O, O, I], result: O),
            .init(values: [I, O, I], result: true),
            .init(values: [O, I, I], result: true),
            .init(values: [I, I, I], result: O),
        ])

        XCTAssertTrue(table1.equivalent(to: table2))
    }

    func testEquivalent_notEquivalent() {
        let table1 = makeSut(variables: ["c", "b"], rows: [
            .init(values: [O, O], result: O),
            .init(values: [I, O], result: true),
            .init(values: [O, I], result: true),
            .init(values: [I, I], result: O),
        ])

        let table2 = makeSut(variables: ["a", "b", "c"], rows: [
            .init(values: [O, O, O], result: O),
            .init(values: [I, O, O], result: true),
            .init(values: [O, I, O], result: true),
            .init(values: [I, I, O], result: O),
            .init(values: [O, O, I], result: O),
            .init(values: [I, O, I], result: true),
            .init(values: [O, I, I], result: true),
            .init(values: [I, I, I], result: O),
        ])

        XCTAssertFalse(table1.equivalent(to: table2))
    }

    func testEquivalent_constant_equivalent() {
        let table1 = makeSut(variables: ["c", "b"], rows: [
            .init(values: [O, O], result: true),
            .init(values: [I, O], result: true),
            .init(values: [O, I], result: true),
            .init(values: [I, I], result: true),
        ])

        let table2 = makeSut(variables: [], rows: [
            .init(values: [], result: true),
        ])

        XCTAssertTrue(table1.equivalent(to: table2))
    }

    func testEquivalent_constant_notEquivalent() {
        let table1 = makeSut(variables: ["c", "b"], rows: [
            .init(values: [O, O], result: false),
            .init(values: [I, O], result: false),
            .init(values: [O, I], result: false),
            .init(values: [I, I], result: false),
        ])

        let table2 = makeSut(variables: [], rows: [
            .init(values: [], result: true),
        ])

        XCTAssertFalse(table1.equivalent(to: table2))
    }

    // MARK: - Test internals
    
    func makeSut(from exp: Expression) -> TruthTable {
        exp.generateTruthTable()
    }

    func makeSut(variables: [String], rows: [TruthTable.Row]) -> TruthTable {
        .init(expression: true, variables: variables, rows: rows)
    }
    
    // Aliases for easier readability of table setups
    var I: Bool { return true }
    var O: Bool { return false }
}
