import Foundation

public extension Expression {
    /// Generates the truth table for this boolean expression.
    ///
    /// The variables are by default sorted lexicographically in the truth table's
    /// `variables` array.
    ///
    /// Complexity: O(2^n)
    func generateTruthTable() -> TruthTable {
        let variables = variables().sorted(by: { $0.lexicographicallyPrecedes($1) })        
        var rows: [TruthTable.Row] = []

        let totalVariations = 2 << (variables.count - 1)
        var variation: [Bool] = variables.map { _ in false }
        var variationDict: [String: Bool] = [:]

        var index: Int = 0
        while index < totalVariations {
            defer { index += 1 }

            // Use bits in index to toggle each variable in 'variation'
            for i in 0..<variables.count {
                variation[i] = (index >> i) & 1 == 1
                variationDict[variables[i]] = variation[i]
            }

            let result = (try? self.evaluate(variables: variationDict)) ?? false
            let row = TruthTable.Row(values: variation, result: result)
            rows.append(row)
        }

        return TruthTable(expression: self, variables: variables, rows: rows)
    }
}
