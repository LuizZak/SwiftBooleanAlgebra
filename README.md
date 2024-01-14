# BooleanAlgebra

A small Swift package for Boolean algebra with a reducer and canonicalizer.

```swift
import BooleanAlgebra

let exp: Expression = ("c" * "d" + "a" + !(("c" * "b" + "c" * "b") * "a")) * ¬"a" + "b" * "d"
let reducer = ExpressionReducer(exp)
reducer.reduce()

print(reducer.toExpression())
// ¬a + b * d

print(reducer.toExpression().generateTruthTable().toAsciiTable())
//  a │ b │ d │ = 
// ───┼───┼───┼───
//  0 │ 0 │ 0 │ 1 
//  1 │ 0 │ 0 │ 0 
//  0 │ 1 │ 0 │ 1 
//  1 │ 1 │ 0 │ 0 
//  0 │ 0 │ 1 │ 1 
//  1 │ 0 │ 1 │ 0 
//  0 │ 1 │ 1 │ 1 
//  1 │ 1 │ 1 │ 1 
```
