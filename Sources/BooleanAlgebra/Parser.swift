import MiniLexer

/// Parser for boolean expressions.
/// Syntax:
/// 
/// ```ANTLR
/// expression
///   : expression-element
///   ;
/// 
/// expression-element
///   : or-expression
///   ;
/// 
/// or-expression
///   : xor-expression (('|' | '+' | '∨') xor-expression)* // Note: '∨' is the unicode mathematical symbol, not the letter 'v'
///   ;
/// 
/// xor-expression
///   : and-expression (('^' | '⊕') and-expression)*
///   ;
/// 
/// and-expression
///   : not-expression (('&' | '*' | '∧') not-expression)* // Note: '∧' is the unicode mathematical symbol, not the diacritic '^'
///   ;
/// 
/// not-expression
///   : '¬' variable
///   | '!' variable
///   | variable
///   ;
/// 
/// variable
///   : identifier-token
///   | constant
///   | '(' expression-element ')'
///   ;
/// 
/// constant
///   : '0'
///   | '1'
///   ;
/// 
/// identifier-token
///   : alpha (alpha | digit)*
///   ;
/// 
/// alpha: (a-z|A-Z)+ ;
/// digit: (0-9)+ ;
/// ```
public enum Parser {
}

public extension Parser {
    typealias Tokenizer = TokenizerLexer<FullToken<BooleanTokens>>

    /// ```ANTLR
    /// expression:
    ///   expression-element
    ///   ;
    /// ```
    static func parse(expression: String) throws -> Expression {
        let lexer = Tokenizer(input: expression)

        return try parse(expressionElement: lexer)
    }

    /// ```ANTLR
    /// expression
    ///   : expression-element
    ///   ;
    /// ```
    static func parse(expression lexer: Tokenizer) throws -> Expression {
        return try parse(expressionElement: lexer)
    }

    /// ```ANTLR
    /// expression-element
    ///   : and-expression
    ///   ;
    /// ```
    static func parse(expressionElement lexer: Tokenizer) throws -> Expression {
        return try parse(orExpression: lexer)
    }

    /// ```ANTLR
    /// or-expression
    ///   : xor-expression (('|' | '+' | '∨') xor-expression)* // Note: '∨' is the unicode mathematical symbol, not the letter 'v'
    ///   ;
    /// ```
    static func parse(orExpression lexer: Tokenizer) throws -> Expression {
        let lhs = try parse(xorExpression: lexer)
        
        if lexer.consumeToken(ifTypeIs: .or) != nil {
            let rhs = try parse(orExpression: lexer)
            
            return .or(lhs, rhs)
        }

        return lhs
    }

    /// ```ANTLR
    /// xor-expression
    ///   : and-expression (('^' | '⊕') and-expression)*
    ///   ;
    /// ```
    static func parse(xorExpression lexer: Tokenizer) throws -> Expression {
        let lhs = try parse(andExpression: lexer)
        
        if lexer.consumeToken(ifTypeIs: .xor) != nil {
            let rhs = try parse(xorExpression: lexer)
            
            return .xor(lhs, rhs)
        }

        return lhs
    }

    /// ```ANTLR
    /// and-expression
    ///   : not-expression (('&' | '*' | '∧') not-expression)* // Note: '∧' is the unicode mathematical symbol, not the diacritic '^'
    ///   ;
    /// ```
    static func parse(andExpression lexer: Tokenizer) throws -> Expression {
        let lhs = try parse(notExpression: lexer)

        if lexer.consumeToken(ifTypeIs: .and) != nil {
            let rhs = try parse(andExpression: lexer)

            return .and(lhs, rhs)
        }

        return lhs
    }

    /// ```ANTLR
    /// not-expression
    ///   : ('¬' + '!') not-expression
    ///   | variable
    ///   ;
    /// ```
    static func parse(notExpression lexer: Tokenizer) throws -> Expression {
        if lexer.consumeToken(ifTypeIs: .not) != nil {
            let value = try parse(notExpression: lexer)

            return .not(value)
        }
        
        return try parse(variableExpression: lexer)
    }

    /// ```ANTLR
    /// variable
    ///   : identifier-token
    ///   | constant
    ///   | '(' expression-element ')'
    ///   ;
    /// 
    /// identifier-token
    ///   : alpha (alpha | digit)*
    ///   ;
    /// 
    /// alpha: (a-z|A-Z)+ ;
    /// digit: (0-9)+ ;
    /// ```
    static func parse(variableExpression lexer: Tokenizer) throws -> Expression {
        if let token = lexer.consumeToken(ifTypeIs: .identifier) {
            return .variable(String(token.value))
        }
        
        if lexer.consumeToken(ifTypeIs: .leftParens) != nil {
            let element = try parse(expressionElement: lexer)

            try lexer.advance(overTokenType: .rightParens)

            return .parenthesized(element)
        }

        return try parse(constantExpression: lexer)
    }

    /// ```
    /// constant
    ///   : '0'
    ///   | '1'
    ///   ;
    /// ```
    static func parse(constantExpression lexer: Tokenizer) throws -> Expression {
        if lexer.consumeToken(ifTypeIs: .constantTrue) != nil {
            return .true
        }
        if lexer.consumeToken(ifTypeIs: .constantFalse) != nil {
            return .false
        }
        
        throw lexer.lexer.syntaxError("Expected identifier, parenthesized, or constant boolean expression")
    }
}

public enum BooleanTokens: TokenProtocol {
    private static let identifierGrammar: GrammarRule = .letter + (.letter | .digit)*

    case identifier
    case leftParens
    case rightParens
    case constantTrue
    case constantFalse
    case and
    case xor
    case or
    case not
    case eofToken

    public var tokenString: String {
        switch self {
        case .identifier:
            return "<identifier>"

        case .leftParens:
            return "("

        case .rightParens:
            return "("

        case .and:
            return "*"

        case .xor:
            return "^"

        case .or:
            return "+"

        case .not:
            return "¬"

        case .constantTrue:
            return "1"

        case .constantFalse:
            return "0"

        case .eofToken:
            return "<eof>"
        }
    }

    public static func tokenType(at lexer: Lexer) -> BooleanTokens? {
        do {
            if lexer.isEof() {
                return .eofToken
            }

            if identifierGrammar.passes(in: lexer) {
                return .identifier
            }

            let next = try lexer.peek()
            switch next {
            case "(":
                return .leftParens
            case ")":
                return .rightParens
            case "*", "&", "∧":
                return .and
            case "^", "⊕":
                return .xor
            case "+", "|", "∨":
                return .or
            case "¬", "!":
                return .not
            case "1":
                return .constantTrue
            case "0":
                return .constantFalse
            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    public func length(in lexer: Lexer) -> Int {
        do {
            if Self.identifierGrammar.passes(in: lexer) {
                return try Self.identifierGrammar.consume(from: lexer).count
            }

            let token = Self.tokenType(at: lexer)

            switch token {
            case .and, .or, .xor, .not, .leftParens, .rightParens, .constantTrue, .constantFalse:
                return 1
            case .identifier, .eofToken, nil:
                return 0
            }
        } catch {
            return 0
        }
    }
}
