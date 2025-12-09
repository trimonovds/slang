// Sources/SlangCore/Lexer/Token.swift

/// All keywords in the Slang language
public enum Keyword: String, CaseIterable, Sendable {
    case `func`
    case `var`
    case `struct`
    case `enum`
    case `case`
    case `if`
    case `else`
    case `for`
    case `switch`
    case `return`
    case `true`
    case `false`
    case `union`
}

/// The type of a token
public enum TokenKind: Equatable, Sendable {
    // MARK: - Literals
    case intLiteral(Int)
    case floatLiteral(Double)
    case stringLiteral(String)

    // MARK: - Identifiers and Keywords
    case identifier(String)
    case keyword(Keyword)

    // MARK: - Operators
    case plus           // +
    case minus          // -
    case star           // *
    case slash          // /
    case percent        // %

    case equal          // =
    case equalEqual     // ==
    case bang           // !
    case bangEqual      // !=

    case less           // <
    case lessEqual      // <=
    case greater        // >
    case greaterEqual   // >=

    case ampersandAmpersand  // &&
    case pipePipe            // ||
    case pipe                // |

    case plusEqual      // +=
    case minusEqual     // -=
    case starEqual      // *=
    case slashEqual     // /=

    case arrow          // ->

    // MARK: - Delimiters
    case leftParen      // (
    case rightParen     // )
    case leftBrace      // {
    case rightBrace     // }
    case comma          // ,
    case colon          // :
    case semicolon      // ;
    case dot            // .

    // MARK: - Special
    case newline        // For optional semicolon handling
    case eof            // End of file

    // MARK: - String Interpolation
    case stringInterpolationStart  // Start of interpolation in string: \(
    case stringInterpolationEnd    // End of interpolation: )
}

/// A token with its kind and source location
public struct Token: Equatable, Sendable {
    public let kind: TokenKind
    public let range: SourceRange
    /// Raw text of the token as it appears in source
    public let lexeme: String

    public init(kind: TokenKind, range: SourceRange, lexeme: String) {
        self.kind = kind
        self.range = range
        self.lexeme = lexeme
    }
}

// MARK: - CustomStringConvertible

extension TokenKind: CustomStringConvertible {
    public var description: String {
        switch self {
        case .intLiteral(let value): return "int(\(value))"
        case .floatLiteral(let value): return "float(\(value))"
        case .stringLiteral(let value): return "string(\"\(value)\")"
        case .identifier(let name): return "identifier(\(name))"
        case .keyword(let kw): return "keyword(\(kw.rawValue))"
        case .plus: return "+"
        case .minus: return "-"
        case .star: return "*"
        case .slash: return "/"
        case .percent: return "%"
        case .equal: return "="
        case .equalEqual: return "=="
        case .bang: return "!"
        case .bangEqual: return "!="
        case .less: return "<"
        case .lessEqual: return "<="
        case .greater: return ">"
        case .greaterEqual: return ">="
        case .ampersandAmpersand: return "&&"
        case .pipePipe: return "||"
        case .pipe: return "|"
        case .plusEqual: return "+="
        case .minusEqual: return "-="
        case .starEqual: return "*="
        case .slashEqual: return "/="
        case .arrow: return "->"
        case .leftParen: return "("
        case .rightParen: return ")"
        case .leftBrace: return "{"
        case .rightBrace: return "}"
        case .comma: return ","
        case .colon: return ":"
        case .semicolon: return ";"
        case .dot: return "."
        case .newline: return "newline"
        case .eof: return "eof"
        case .stringInterpolationStart: return "\\("
        case .stringInterpolationEnd: return ")"
        }
    }
}

extension Token: CustomStringConvertible {
    public var description: String {
        "\(kind) at \(range.start)"
    }
}
