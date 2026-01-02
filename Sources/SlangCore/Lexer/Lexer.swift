// Sources/SlangCore/Lexer/Lexer.swift

/// Tokenizes Slang source code
public class Lexer {
    private let source: String
    private let filename: String
    private var tokens: [Token] = []

    // Current position tracking
    private var currentIndex: String.Index
    private var line: Int = 1
    private var column: Int = 1
    private var offset: Int = 0

    public init(source: String, filename: String = "<stdin>") {
        self.source = source
        self.filename = filename
        self.currentIndex = source.startIndex
    }

    // MARK: - Public API

    /// Tokenize the entire source and return all tokens
    public func tokenize() throws -> [Token] {
        tokens = []

        while !isAtEnd {
            try scanToken()
        }

        // Add EOF token
        let eofLocation = currentLocation
        tokens.append(Token(
            kind: .eof,
            range: SourceRange(start: eofLocation, end: eofLocation, file: filename),
            lexeme: ""
        ))

        return tokens
    }

    // MARK: - Scanner Core

    private var isAtEnd: Bool {
        currentIndex >= source.endIndex
    }

    private var currentLocation: SourceLocation {
        SourceLocation(line: line, column: column, offset: offset)
    }

    private func peek() -> Character? {
        guard !isAtEnd else { return nil }
        return source[currentIndex]
    }

    private func peekNext() -> Character? {
        let nextIndex = source.index(after: currentIndex)
        guard nextIndex < source.endIndex else { return nil }
        return source[nextIndex]
    }

    @discardableResult
    private func advance() -> Character {
        let char = source[currentIndex]
        currentIndex = source.index(after: currentIndex)
        offset += 1

        if char == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }

        return char
    }

    private func match(_ expected: Character) -> Bool {
        guard peek() == expected else { return false }
        advance()
        return true
    }

    // MARK: - Token Scanning

    private func scanToken() throws {
        let startLocation = currentLocation
        let char = advance()

        switch char {
        // Single-character tokens
        case "(": addToken(.leftParen, start: startLocation)
        case ")": addToken(.rightParen, start: startLocation)
        case "{": addToken(.leftBrace, start: startLocation)
        case "}": addToken(.rightBrace, start: startLocation)
        case "[": addToken(.leftBracket, start: startLocation)
        case "]": addToken(.rightBracket, start: startLocation)
        case ",": addToken(.comma, start: startLocation)
        case ":": addToken(.colon, start: startLocation)
        case ";": addToken(.semicolon, start: startLocation)
        case ".": addToken(.dot, start: startLocation)
        case "%": addToken(.percent, start: startLocation)
        case "?": addToken(.questionMark, start: startLocation)

        // Operators that might be followed by =
        case "+":
            addToken(match("=") ? .plusEqual : .plus, start: startLocation)
        case "*":
            addToken(match("=") ? .starEqual : .star, start: startLocation)

        // - could be - or -= or ->
        case "-":
            if match("=") {
                addToken(.minusEqual, start: startLocation)
            } else if match(">") {
                addToken(.arrow, start: startLocation)
            } else {
                addToken(.minus, start: startLocation)
            }

        // / could be / or /= or // (comment)
        case "/":
            if match("/") {
                // Single-line comment - skip to end of line
                while peek() != nil && peek() != "\n" {
                    advance()
                }
            } else if match("=") {
                addToken(.slashEqual, start: startLocation)
            } else {
                addToken(.slash, start: startLocation)
            }

        // = or ==
        case "=":
            addToken(match("=") ? .equalEqual : .equal, start: startLocation)

        // ! or !=
        case "!":
            addToken(match("=") ? .bangEqual : .bang, start: startLocation)

        // < or <=
        case "<":
            addToken(match("=") ? .lessEqual : .less, start: startLocation)

        // > or >=
        case ">":
            addToken(match("=") ? .greaterEqual : .greater, start: startLocation)

        // &&
        case "&":
            if match("&") {
                addToken(.ampersandAmpersand, start: startLocation)
            } else {
                throw error("Unexpected character '&'. Did you mean '&&'?", at: startLocation)
            }

        // | or ||
        case "|":
            if match("|") {
                addToken(.pipePipe, start: startLocation)
            } else {
                addToken(.pipe, start: startLocation)
            }

        // Whitespace
        case " ", "\r", "\t":
            break // Ignore whitespace

        // Newline (significant for optional semicolons)
        case "\n":
            // Only add newline token if the previous token could end a statement
            if shouldAddNewlineToken() {
                addToken(.newline, start: startLocation)
            }

        // String literal
        case "\"":
            try scanString(start: startLocation)

        default:
            if char.isNumber {
                try scanNumber(start: startLocation, firstChar: char)
            } else if char.isLetter || char == "_" {
                scanIdentifier(start: startLocation, firstChar: char)
            } else {
                throw error("Unexpected character '\(char)'", at: startLocation)
            }
        }
    }

    // MARK: - Complex Token Scanning

    private func scanString(start: SourceLocation) throws {
        var value = ""
        var stringStart = start

        while let char = peek(), char != "\"" {
            if char == "\n" {
                throw error("Unterminated string literal", at: start)
            }

            if char == "\\" {
                advance() // consume backslash

                guard let escaped = peek() else {
                    throw error("Unterminated escape sequence", at: currentLocation)
                }

                switch escaped {
                case "(":
                    // String interpolation: \(expr)
                    // First, emit the string so far
                    addToken(.stringLiteral(value), start: stringStart, lexeme: "\"\(value)")
                    value = ""

                    advance() // consume (
                    addToken(.stringInterpolationStart, start: currentLocation)

                    // Scan tokens until matching )
                    try scanInterpolation()

                    // Update start for next string segment
                    stringStart = currentLocation

                case "n":
                    advance()
                    value.append("\n")
                case "t":
                    advance()
                    value.append("\t")
                case "r":
                    advance()
                    value.append("\r")
                case "\\":
                    advance()
                    value.append("\\")
                case "\"":
                    advance()
                    value.append("\"")
                default:
                    throw error("Invalid escape sequence '\\(\(escaped))'", at: currentLocation)
                }
            } else {
                value.append(advance())
            }
        }

        if isAtEnd {
            throw error("Unterminated string literal", at: start)
        }

        advance() // consume closing "

        // Add final string segment (or the whole string if no interpolation)
        addToken(.stringLiteral(value), start: stringStart, lexeme: "\(value)\"")
    }

    private func scanInterpolation() throws {
        var parenDepth = 1

        while !isAtEnd && parenDepth > 0 {
            let startLoc = currentLocation
            let char = peek()!

            if char == "(" {
                advance()
                addToken(.leftParen, start: startLoc)
                parenDepth += 1
            } else if char == ")" {
                parenDepth -= 1
                if parenDepth == 0 {
                    advance()
                    addToken(.stringInterpolationEnd, start: startLoc)
                } else {
                    advance()
                    addToken(.rightParen, start: startLoc)
                }
            } else {
                try scanToken()
            }
        }

        if parenDepth > 0 {
            throw error("Unterminated string interpolation", at: currentLocation)
        }
    }

    private func scanNumber(start: SourceLocation, firstChar: Character) throws {
        var numberStr = String(firstChar)
        var isFloat = false

        while let char = peek(), char.isNumber {
            numberStr.append(advance())
        }

        // Check for decimal point
        if peek() == "." && peekNext()?.isNumber == true {
            isFloat = true
            numberStr.append(advance()) // consume .

            while let char = peek(), char.isNumber {
                numberStr.append(advance())
            }
        }

        if isFloat {
            guard let value = Double(numberStr) else {
                throw error("Invalid float literal '\(numberStr)'", at: start)
            }
            addToken(.floatLiteral(value), start: start, lexeme: numberStr)
        } else {
            guard let value = Int(numberStr) else {
                throw error("Invalid integer literal '\(numberStr)'", at: start)
            }
            addToken(.intLiteral(value), start: start, lexeme: numberStr)
        }
    }

    private func scanIdentifier(start: SourceLocation, firstChar: Character) {
        var name = String(firstChar)

        while let char = peek(), char.isLetter || char.isNumber || char == "_" {
            name.append(advance())
        }

        // Check if it's a keyword
        if let keyword = Keyword(rawValue: name) {
            addToken(.keyword(keyword), start: start, lexeme: name)
        } else {
            addToken(.identifier(name), start: start, lexeme: name)
        }
    }

    // MARK: - Helpers

    private func addToken(_ kind: TokenKind, start: SourceLocation, lexeme: String? = nil) {
        let range = SourceRange(start: start, end: currentLocation, file: filename)
        let tokenLexeme: String
        if let lexeme = lexeme {
            tokenLexeme = lexeme
        } else {
            let startIdx = source.index(source.startIndex, offsetBy: start.offset)
            let endIdx = source.index(source.startIndex, offsetBy: offset)
            tokenLexeme = String(source[startIdx..<endIdx])
        }
        tokens.append(Token(kind: kind, range: range, lexeme: tokenLexeme))
    }

    private func shouldAddNewlineToken() -> Bool {
        guard let lastToken = tokens.last else { return false }

        // Add newline after tokens that can end a statement
        switch lastToken.kind {
        case .identifier, .intLiteral, .floatLiteral, .stringLiteral,
             .keyword(.true), .keyword(.false), .keyword(.return), .keyword(.nil),
             .rightParen, .rightBrace, .rightBracket:
            return true
        default:
            return false
        }
    }

    private func error(_ message: String, at location: SourceLocation) -> LexerError {
        let range = SourceRange(start: location, end: location, file: filename)
        return LexerError(Diagnostic.error(message, at: range))
    }
}
