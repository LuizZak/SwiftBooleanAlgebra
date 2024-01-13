/// A truth table generated from a boolean expression.
public struct TruthTable: Hashable {
    /// The expression for this truth table.
    public var expression: Expression

    /// The list of variables that are present in the truth table.
    /// Also serves as the columns for the input side of the truth table.
    public var variables: [String]

    /// The rows on this truth table.
    public var rows: [Row]

    public init(expression: Expression, variables: [String], rows: [Row]) {
        self.expression = expression
        self.variables = variables
        self.rows = rows
    }

    /// Represents a single row in a truth table.
    public struct Row: Hashable {
        /// The toggle values for each variable on this row.
        public var values: [Bool]

        /// The final value of the expression when each variable is set to their
        /// respective values on the `values` array.
        public var result: Bool

        public init(values: [Bool], result: Bool) {
            self.values = values
            self.result = result
        }
    }

    /// Converts this truth table into a presentable ASCII string representation.
    public func toAsciiTable(
        includeExpression: Bool = false
    ) -> String {

        func padString(_ input: String, length: Int) -> String {
            var string: [String] = Array(repeating: " ", count: length / 2)
            
            string.append(contentsOf: input.map(String.init(describing:)))
            string.append(contentsOf: Array(repeating: " ", count: length / 2))

            while string.count > length {
                string.removeFirst()
            }

            return string.joined()
        }

        let booleanToString: (Bool) -> String = { $0 ? "1" : "0" }

        let horizontalSeparator = "│"
        let verticalSeparator = "─"

        var lines: [String] = []
        if includeExpression {
            lines.append(expression.description)
        }

        let columns = variables.map({ " \($0.description) " }) + [" = "]
        let columnsWidth = columns.map(\.count)

        lines.append(columns.joined(separator: horizontalSeparator))
        lines.append(columnsWidth.map({ String(repeating: verticalSeparator, count: $0) }).joined(separator: "┼"))

        for row in rows {
            var rowCells: [String] = []

            for (i, value) in row.values.enumerated() {
                let width = columnsWidth[i]

                rowCells.append(padString(booleanToString(value), length: width))
            }

            // Result
            let width = columnsWidth[columnsWidth.count - 1]

            rowCells.append(padString(booleanToString(row.result), length: width))

            lines.append(rowCells.joined(separator: horizontalSeparator))
        }

        return lines.joined(separator: "\n")
    }

}

extension TruthTable: CustomStringConvertible {
    public var description: String {
        return "TruthTable(expression: \(expression), variables: \(variables), rows: \(rows))"
    }
}

extension TruthTable.Row: CustomStringConvertible {
    public var description: String {
        return "Row(values: \(values), result: \(result))"
    }
}
