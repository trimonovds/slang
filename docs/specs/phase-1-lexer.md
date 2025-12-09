# Phase 1: Lexer

## Overview

The lexer (tokenizer) transforms source code text into a stream of tokens. This is the foundation of the compiler pipeline.

**Input:** Source code string
**Output:** Array of `Token` structs

---

## Prerequisites

- Swift Package Manager project set up
- `SlangCore` library target created in Package.swift

---

## Files to Create

| File | Purpose |
|------|---------|
| `Sources/SlangCore/Lexer/SourceLocation.swift` | Position tracking for errors/LSP |
| `Sources/SlangCore/Lexer/Token.swift` | Token type definitions |
| `Sources/SlangCore/Lexer/Lexer.swift` | Main lexer implementation |
| `Sources/SlangCore/Diagnostics/Diagnostic.swift` | Error reporting |

---

## Step 1: Update Package.swift

First, update `Package.swift` to add the `SlangCore` library target:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "slang",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "slang", targets: ["slang"]),
        .library(name: "SlangCore", targets: ["SlangCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "slang",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "SlangCore",
            ]
        ),
        .target(
            name: "SlangCore",
            dependencies: []
        ),
        .testTarget(
            name: "SlangCoreTests",
            dependencies: ["SlangCore"]
        ),
    ]
)
```

---

## Step 2: SourceLocation.swift

Create source position tracking structures.

```swift
// Sources/SlangCore/Lexer/SourceLocation.swift

/// A position in source code
public struct SourceLocation: Equatable, CustomStringConvertible {
    /// 1-indexed line number
    public let line: Int
    /// 1-indexed column number
    public let column: Int
    /// 0-indexed byte offset from start of file
    public let offset: Int

    public init(line: Int, column: Int, offset: Int) {
        self.line = line
        self.column = column
        self.offset = offset
    }

    public var description: String {
        "\(line):\(column)"
    }
}

/// A range in source code (start to end positions)
public struct SourceRange: Equatable, CustomStringConvertible {
    public let start: SourceLocation
    public let end: SourceLocation
    public let file: String

    public init(start: SourceLocation, end: SourceLocation, file: String = "<stdin>") {
        self.start = start
        self.end = end
        self.file = file
    }

    public var description: String {
        "\(file):\(start)-\(end)"
    }

    /// Create a range spanning from this range's start to another range's end
    public func extended(to other: SourceRange) -> SourceRange {
        SourceRange(start: self.start, end: other.end, file: self.file)
    }
}
```

---

## Step 3: Token.swift

Define all token types for the Slang language.

```swift
// Sources/SlangCore/Lexer/Token.swift

/// All keywords in the Slang language
public enum Keyword: String, CaseIterable {
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
}

/// The type of a token
public enum TokenKind: Equatable {
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
public struct Token: Equatable {
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
```

---

## Step 4: Diagnostic.swift

Create basic error reporting infrastructure.

```swift
// Sources/SlangCore/Diagnostics/Diagnostic.swift

/// Severity level of a diagnostic message
public enum DiagnosticSeverity {
    case error
    case warning
    case note
}

/// A diagnostic message (error, warning, or note)
public struct Diagnostic: Error, CustomStringConvertible {
    public let severity: DiagnosticSeverity
    public let message: String
    public let range: SourceRange

    public init(severity: DiagnosticSeverity, message: String, range: SourceRange) {
        self.severity = severity
        self.message = message
        self.range = range
    }

    public static func error(_ message: String, at range: SourceRange) -> Diagnostic {
        Diagnostic(severity: .error, message: message, range: range)
    }

    public var description: String {
        let severityStr: String
        switch severity {
        case .error: severityStr = "error"
        case .warning: severityStr = "warning"
        case .note: severityStr = "note"
        }
        return "\(severityStr): \(message)\n  --> \(range.file):\(range.start)"
    }
}

/// Error thrown when lexing fails
public struct LexerError: Error {
    public let diagnostics: [Diagnostic]

    public init(_ diagnostics: [Diagnostic]) {
        self.diagnostics = diagnostics
    }

    public init(_ diagnostic: Diagnostic) {
        self.diagnostics = [diagnostic]
    }
}
```

---

## Step 5: Lexer.swift

The main lexer implementation.

```swift
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

    // For handling string interpolation
    private var interpolationDepth: Int = 0

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
        case ",": addToken(.comma, start: startLocation)
        case ":": addToken(.colon, start: startLocation)
        case ";": addToken(.semicolon, start: startLocation)
        case ".": addToken(.dot, start: startLocation)
        case "%": addToken(.percent, start: startLocation)

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

        // ||
        case "|":
            if match("|") {
                addToken(.pipePipe, start: startLocation)
            } else {
                throw error("Unexpected character '|'. Did you mean '||'?", at: startLocation)
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
                    if !value.isEmpty {
                        addToken(.stringLiteral(value), start: start, lexeme: value)
                        value = ""
                    }

                    advance() // consume (
                    addToken(.stringInterpolationStart, start: start)

                    // Scan tokens until matching )
                    try scanInterpolation()

                    // Continue scanning the rest of the string
                    // The closing quote will be handled by the outer loop

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
        addToken(.stringLiteral(value), start: start, lexeme: "\"\(value)\"")
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
        let tokenLexeme = lexeme ?? String(source[source.index(source.startIndex, offsetBy: start.offset)..<source.index(source.startIndex, offsetBy: offset)])
        tokens.append(Token(kind: kind, range: range, lexeme: tokenLexeme))
    }

    private func shouldAddNewlineToken() -> Bool {
        guard let lastToken = tokens.last else { return false }

        // Add newline after tokens that can end a statement
        switch lastToken.kind {
        case .identifier, .intLiteral, .floatLiteral, .stringLiteral,
             .keyword(.true), .keyword(.false), .keyword(.return),
             .rightParen, .rightBrace:
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
```

---

## Step 6: Create Directory Structure

Run these commands to create the directory structure:

```bash
mkdir -p Sources/SlangCore/Lexer
mkdir -p Sources/SlangCore/Diagnostics
mkdir -p Tests/SlangCoreTests
```

---

## Test Cases

### Test 1: Simple Tokens

**Input:**
```
+ - * / = == != < > <= >= && ||
```

**Expected tokens:**
```
plus, minus, star, slash, equal, equalEqual, bangEqual, less, greater, lessEqual, greaterEqual, ampersandAmpersand, pipePipe, eof
```

### Test 2: Keywords and Identifiers

**Input:**
```
func main var x struct enum if else for switch return true false myVar _private
```

**Expected tokens:**
```
keyword(func), identifier(main), keyword(var), identifier(x), keyword(struct), keyword(enum), keyword(if), keyword(else), keyword(for), keyword(switch), keyword(return), keyword(true), keyword(false), identifier(myVar), identifier(_private), eof
```

### Test 3: Numbers

**Input:**
```
42 3.14 0 100
```

**Expected tokens:**
```
intLiteral(42), floatLiteral(3.14), intLiteral(0), intLiteral(100), eof
```

### Test 4: Strings

**Input:**
```
"hello" "world"
```

**Expected tokens:**
```
stringLiteral("hello"), stringLiteral("world"), eof
```

### Test 5: String Interpolation

**Input:**
```
"Hello \(name)!"
```

**Expected tokens:**
```
stringLiteral("Hello "), stringInterpolationStart, identifier(name), stringInterpolationEnd, stringLiteral("!"), eof
```

### Test 6: Comments

**Input:**
```
var x = 5 // this is a comment
var y = 10
```

**Expected tokens:**
```
keyword(var), identifier(x), equal, intLiteral(5), newline, keyword(var), identifier(y), equal, intLiteral(10), eof
```

### Test 7: Full Program

**Input:**
```
func main() {
    var x: Int = 42
    print("Value: \(x)")
}
```

**Expected tokens (abbreviated):**
```
keyword(func), identifier(main), leftParen, rightParen, leftBrace, newline,
keyword(var), identifier(x), colon, identifier(Int), equal, intLiteral(42), newline,
identifier(print), leftParen, stringLiteral("Value: "), stringInterpolationStart, identifier(x), stringInterpolationEnd, stringLiteral(""), rightParen, newline,
rightBrace, eof
```

---

## Acceptance Criteria

- [ ] Package.swift updated with SlangCore target
- [ ] SourceLocation.swift created with line/column/offset tracking
- [ ] Token.swift created with all token kinds
- [ ] Diagnostic.swift created for error reporting
- [ ] Lexer.swift created and handles:
  - [ ] All operators
  - [ ] All keywords
  - [ ] Identifiers
  - [ ] Integer literals
  - [ ] Float literals
  - [ ] String literals
  - [ ] String interpolation `\(expr)`
  - [ ] Single-line comments `//`
  - [ ] Newlines (for optional semicolons)
- [ ] All test cases pass
- [ ] `swift build` succeeds
- [ ] `swift test` runs (even if no tests yet)

---

## Next Phase

Once this phase is complete, proceed to [Phase 2: Parser & AST](phase-2-parser.md).
