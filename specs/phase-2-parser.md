# Phase 2: Parser & AST

## Overview

The parser transforms a stream of tokens into an Abstract Syntax Tree (AST). The AST represents the hierarchical structure of the program.

**Input:** Array of `Token` from Lexer
**Output:** Array of `Declaration` (AST nodes)

---

## Prerequisites

- Phase 1 (Lexer) complete
- All token types defined

---

## Files to Create

| File | Purpose |
|------|---------|
| `Sources/SlangCore/Parser/AST.swift` | All AST node definitions |
| `Sources/SlangCore/Parser/Parser.swift` | Main parser implementation |

---

## Design Decision: Enums with Associated Values

We use **enums with associated values** instead of protocols with structs because:

1. **Exhaustive pattern matching** - Compiler ensures all cases are handled
2. **No type casting** - No `as?` or `as!` needed
3. **Clean switch statements** - Pattern matching with value extraction
4. **Type safety** - Cannot forget to handle a case

---

## Step 1: AST.swift - Supporting Types

```swift
// Sources/SlangCore/Parser/AST.swift

import Foundation

// MARK: - Built-in Types (RawRepresentable)

/// Built-in type names - eliminates magic strings
public enum BuiltinTypeName: String, CaseIterable {
    case int = "Int"
    case float = "Float"
    case string = "String"
    case bool = "Bool"
    case void = "Void"
}

// MARK: - Operators

public enum BinaryOperator: String {
    // Arithmetic
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"

    // Comparison
    case equal = "=="
    case notEqual = "!="
    case less = "<"
    case lessEqual = "<="
    case greater = ">"
    case greaterEqual = ">="

    // Logical
    case and = "&&"
    case or = "||"

    // Assignment
    case assign = "="
    case addAssign = "+="
    case subtractAssign = "-="
    case multiplyAssign = "*="
    case divideAssign = "/="
}

public enum UnaryOperator: String {
    case negate = "-"
    case not = "!"
}

// MARK: - Simple Data Containers (keep as structs)

public struct Parameter {
    public let name: String
    public let type: TypeAnnotation
    public let range: SourceRange

    public init(name: String, type: TypeAnnotation, range: SourceRange) {
        self.name = name
        self.type = type
        self.range = range
    }
}

public struct StructField {
    public let name: String
    public let type: TypeAnnotation
    public let range: SourceRange

    public init(name: String, type: TypeAnnotation, range: SourceRange) {
        self.name = name
        self.type = type
        self.range = range
    }
}

public struct EnumCase {
    public let name: String
    public let range: SourceRange

    public init(name: String, range: SourceRange) {
        self.name = name
        self.range = range
    }
}

public struct TypeAnnotation {
    public let name: String
    public let range: SourceRange

    public init(name: String, range: SourceRange) {
        self.name = name
        self.range = range
    }

    /// Try to parse as a built-in type
    public var asBuiltin: BuiltinTypeName? {
        BuiltinTypeName(rawValue: name)
    }
}

public struct FieldInit {
    public let name: String
    public let value: Expression
    public let range: SourceRange

    public init(name: String, value: Expression, range: SourceRange) {
        self.name = name
        self.value = value
        self.range = range
    }
}

public struct SwitchCase {
    public let pattern: Expression
    public let body: Statement
    public let range: SourceRange

    public init(pattern: Expression, body: Statement, range: SourceRange) {
        self.pattern = pattern
        self.body = body
        self.range = range
    }
}

public enum StringPart {
    case literal(String)
    case interpolation(Expression)
}
```

---

## Step 2: AST.swift - Declaration Enum

```swift
// MARK: - Declarations

public enum Declaration {
    case function(
        name: String,
        parameters: [Parameter],
        returnType: TypeAnnotation?,
        body: Statement,  // Always a .block
        range: SourceRange
    )

    case structDecl(
        name: String,
        fields: [StructField],
        range: SourceRange
    )

    case enumDecl(
        name: String,
        cases: [EnumCase],
        range: SourceRange
    )

    /// Get the source range for any declaration
    public var range: SourceRange {
        switch self {
        case .function(_, _, _, _, let range),
             .structDecl(_, _, let range),
             .enumDecl(_, _, let range):
            return range
        }
    }

    /// Get the name of the declaration
    public var name: String {
        switch self {
        case .function(let name, _, _, _, _),
             .structDecl(let name, _, _),
             .enumDecl(let name, _, _):
            return name
        }
    }
}
```

---

## Step 3: AST.swift - Statement Enum

```swift
// MARK: - Statements

public indirect enum Statement {
    case block(
        statements: [Statement],
        range: SourceRange
    )

    case varDecl(
        name: String,
        type: TypeAnnotation,
        initializer: Expression,
        range: SourceRange
    )

    case expression(
        expr: Expression,
        range: SourceRange
    )

    case returnStmt(
        value: Expression?,
        range: SourceRange
    )

    case ifStmt(
        condition: Expression,
        thenBranch: Statement,  // Always a .block
        elseBranch: Statement?, // Either .block or .ifStmt (else if)
        range: SourceRange
    )

    case forStmt(
        initializer: Statement?,  // .varDecl or nil
        condition: Expression?,
        increment: Expression?,
        body: Statement,  // Always a .block
        range: SourceRange
    )

    case switchStmt(
        subject: Expression,
        cases: [SwitchCase],
        range: SourceRange
    )

    /// Get the source range for any statement
    public var range: SourceRange {
        switch self {
        case .block(_, let range),
             .varDecl(_, _, _, let range),
             .expression(_, let range),
             .returnStmt(_, let range),
             .ifStmt(_, _, _, let range),
             .forStmt(_, _, _, _, let range),
             .switchStmt(_, _, let range):
            return range
        }
    }
}
```

---

## Step 4: AST.swift - Expression Enum

```swift
// MARK: - Expressions

public indirect enum Expression {
    // Literals
    case intLiteral(value: Int, range: SourceRange)
    case floatLiteral(value: Double, range: SourceRange)
    case stringLiteral(value: String, range: SourceRange)
    case boolLiteral(value: Bool, range: SourceRange)

    // String interpolation
    case stringInterpolation(parts: [StringPart], range: SourceRange)

    // Identifier
    case identifier(name: String, range: SourceRange)

    // Operators
    case binary(left: Expression, op: BinaryOperator, right: Expression, range: SourceRange)
    case unary(op: UnaryOperator, operand: Expression, range: SourceRange)

    // Access
    case call(callee: Expression, arguments: [Expression], range: SourceRange)
    case memberAccess(object: Expression, member: String, range: SourceRange)

    // Struct initialization
    case structInit(typeName: String, fields: [FieldInit], range: SourceRange)

    /// Get the source range for any expression
    public var range: SourceRange {
        switch self {
        case .intLiteral(_, let range),
             .floatLiteral(_, let range),
             .stringLiteral(_, let range),
             .boolLiteral(_, let range),
             .stringInterpolation(_, let range),
             .identifier(_, let range),
             .binary(_, _, _, let range),
             .unary(_, _, let range),
             .call(_, _, let range),
             .memberAccess(_, _, let range),
             .structInit(_, _, let range):
            return range
        }
    }
}
```

---

## Step 5: Parser.swift - Core Structure

```swift
// Sources/SlangCore/Parser/Parser.swift

import Foundation

/// Error thrown when parsing fails
public struct ParserError: Error {
    public let diagnostics: [Diagnostic]

    public init(_ diagnostics: [Diagnostic]) {
        self.diagnostics = diagnostics
    }

    public init(_ diagnostic: Diagnostic) {
        self.diagnostics = [diagnostic]
    }
}

/// Parses tokens into an AST
public class Parser {
    private let tokens: [Token]
    private var current: Int = 0
    private var diagnostics: [Diagnostic] = []

    public init(tokens: [Token]) {
        self.tokens = tokens
    }

    // MARK: - Public API

    /// Parse all declarations in the token stream
    public func parse() throws -> [Declaration] {
        var declarations: [Declaration] = []

        while !isAtEnd {
            skipNewlines()
            if isAtEnd { break }

            do {
                let decl = try parseDeclaration()
                declarations.append(decl)
            } catch let error as ParserError {
                diagnostics.append(contentsOf: error.diagnostics)
                synchronize()
            }
        }

        if !diagnostics.isEmpty {
            throw ParserError(diagnostics)
        }

        return declarations
    }

    // MARK: - Token Navigation

    private var isAtEnd: Bool {
        peek().kind == .eof
    }

    private func peek() -> Token {
        tokens[current]
    }

    private func previous() -> Token {
        tokens[current - 1]
    }

    @discardableResult
    private func advance() -> Token {
        if !isAtEnd {
            current += 1
        }
        return previous()
    }

    private func check(_ kind: TokenKind) -> Bool {
        if isAtEnd { return false }
        return tokenKindMatches(peek().kind, kind)
    }

    private func match(_ kinds: TokenKind...) -> Bool {
        for kind in kinds {
            if check(kind) {
                advance()
                return true
            }
        }
        return false
    }

    private func consume(_ kind: TokenKind, message: String) throws -> Token {
        if check(kind) { return advance() }
        throw error(message, at: peek())
    }

    private func skipNewlines() {
        while check(.newline) {
            advance()
        }
    }

    private func tokenKindMatches(_ a: TokenKind, _ b: TokenKind) -> Bool {
        switch (a, b) {
        case (.intLiteral, .intLiteral),
             (.floatLiteral, .floatLiteral),
             (.stringLiteral, .stringLiteral),
             (.identifier, .identifier):
            return true
        case (.keyword(let k1), .keyword(let k2)):
            return k1 == k2
        default:
            return a == b
        }
    }

    // MARK: - Error Handling

    private func error(_ message: String, at token: Token) -> ParserError {
        ParserError(Diagnostic.error(message, at: token.range))
    }

    private func synchronize() {
        advance()

        while !isAtEnd {
            if previous().kind == .newline { return }

            switch peek().kind {
            case .keyword(.func), .keyword(.struct), .keyword(.enum),
                 .keyword(.var), .keyword(.if), .keyword(.for),
                 .keyword(.switch), .keyword(.return):
                return
            default:
                advance()
            }
        }
    }
}
```

---

## Step 6: Parser.swift - Declaration Parsing

```swift
// MARK: - Declaration Parsing

extension Parser {
    private func parseDeclaration() throws -> Declaration {
        let token = peek()

        switch token.kind {
        case .keyword(.func):
            return try parseFunctionDecl()
        case .keyword(.struct):
            return try parseStructDecl()
        case .keyword(.enum):
            return try parseEnumDecl()
        default:
            throw error("Expected declaration (func, struct, or enum)", at: token)
        }
    }

    private func parseFunctionDecl() throws -> Declaration {
        let startToken = try consume(.keyword(.func), message: "Expected 'func'")
        skipNewlines()

        guard case .identifier(let name) = peek().kind else {
            throw error("Expected function name", at: peek())
        }
        advance()

        skipNewlines()
        try consume(.leftParen, message: "Expected '(' after function name")
        skipNewlines()

        var parameters: [Parameter] = []
        if !check(.rightParen) {
            repeat {
                skipNewlines()
                let param = try parseParameter()
                parameters.append(param)
                skipNewlines()
            } while match(.comma)
        }

        skipNewlines()
        try consume(.rightParen, message: "Expected ')' after parameters")
        skipNewlines()

        // Optional return type
        var returnType: TypeAnnotation? = nil
        if match(.arrow) {
            skipNewlines()
            returnType = try parseTypeAnnotation()
            skipNewlines()
        }

        let body = try parseBlockStmt()

        return .function(
            name: name,
            parameters: parameters,
            returnType: returnType,
            body: body,
            range: startToken.range.extended(to: body.range)
        )
    }

    private func parseParameter() throws -> Parameter {
        guard case .identifier(let name) = peek().kind else {
            throw error("Expected parameter name", at: peek())
        }
        let nameToken = advance()

        try consume(.colon, message: "Expected ':' after parameter name")
        skipNewlines()

        let type = try parseTypeAnnotation()

        return Parameter(
            name: name,
            type: type,
            range: nameToken.range.extended(to: type.range)
        )
    }

    private func parseTypeAnnotation() throws -> TypeAnnotation {
        guard case .identifier(let name) = peek().kind else {
            throw error("Expected type name", at: peek())
        }
        let token = advance()

        return TypeAnnotation(name: name, range: token.range)
    }

    private func parseStructDecl() throws -> Declaration {
        let startToken = try consume(.keyword(.struct), message: "Expected 'struct'")
        skipNewlines()

        guard case .identifier(let name) = peek().kind else {
            throw error("Expected struct name", at: peek())
        }
        advance()

        skipNewlines()
        try consume(.leftBrace, message: "Expected '{' after struct name")
        skipNewlines()

        var fields: [StructField] = []
        while !check(.rightBrace) && !isAtEnd {
            let field = try parseStructField()
            fields.append(field)
            skipNewlines()
        }

        let endToken = try consume(.rightBrace, message: "Expected '}' after struct fields")

        return .structDecl(
            name: name,
            fields: fields,
            range: startToken.range.extended(to: endToken.range)
        )
    }

    private func parseStructField() throws -> StructField {
        guard case .identifier(let name) = peek().kind else {
            throw error("Expected field name", at: peek())
        }
        let nameToken = advance()

        try consume(.colon, message: "Expected ':' after field name")
        skipNewlines()

        let type = try parseTypeAnnotation()

        return StructField(
            name: name,
            type: type,
            range: nameToken.range.extended(to: type.range)
        )
    }

    private func parseEnumDecl() throws -> Declaration {
        let startToken = try consume(.keyword(.enum), message: "Expected 'enum'")
        skipNewlines()

        guard case .identifier(let name) = peek().kind else {
            throw error("Expected enum name", at: peek())
        }
        advance()

        skipNewlines()
        try consume(.leftBrace, message: "Expected '{' after enum name")
        skipNewlines()

        var cases: [EnumCase] = []
        while !check(.rightBrace) && !isAtEnd {
            try consume(.keyword(.case), message: "Expected 'case'")
            skipNewlines()

            guard case .identifier(let caseName) = peek().kind else {
                throw error("Expected case name", at: peek())
            }
            let caseToken = advance()

            cases.append(EnumCase(name: caseName, range: caseToken.range))
            skipNewlines()
        }

        let endToken = try consume(.rightBrace, message: "Expected '}' after enum cases")

        return .enumDecl(
            name: name,
            cases: cases,
            range: startToken.range.extended(to: endToken.range)
        )
    }
}
```

---

## Step 7: Parser.swift - Statement Parsing

```swift
// MARK: - Statement Parsing

extension Parser {
    private func parseBlockStmt() throws -> Statement {
        let startToken = try consume(.leftBrace, message: "Expected '{'")
        skipNewlines()

        var statements: [Statement] = []
        while !check(.rightBrace) && !isAtEnd {
            let stmt = try parseStatement()
            statements.append(stmt)
            skipNewlines()
        }

        let endToken = try consume(.rightBrace, message: "Expected '}'")

        return .block(
            statements: statements,
            range: startToken.range.extended(to: endToken.range)
        )
    }

    private func parseStatement() throws -> Statement {
        skipNewlines()

        switch peek().kind {
        case .keyword(.var):
            return try parseVarDeclStmt()
        case .keyword(.return):
            return try parseReturnStmt()
        case .keyword(.if):
            return try parseIfStmt()
        case .keyword(.for):
            return try parseForStmt()
        case .keyword(.switch):
            return try parseSwitchStmt()
        default:
            return try parseExpressionStmt()
        }
    }

    private func parseVarDeclStmt() throws -> Statement {
        let startToken = try consume(.keyword(.var), message: "Expected 'var'")
        skipNewlines()

        guard case .identifier(let name) = peek().kind else {
            throw error("Expected variable name", at: peek())
        }
        advance()

        try consume(.colon, message: "Expected ':' after variable name")
        skipNewlines()

        let type = try parseTypeAnnotation()
        skipNewlines()

        try consume(.equal, message: "Expected '=' in variable declaration")
        skipNewlines()

        let initializer = try parseExpression()

        // Consume optional semicolon
        if check(.semicolon) { advance() }

        return .varDecl(
            name: name,
            type: type,
            initializer: initializer,
            range: startToken.range.extended(to: initializer.range)
        )
    }

    private func parseReturnStmt() throws -> Statement {
        let startToken = try consume(.keyword(.return), message: "Expected 'return'")

        var value: Expression? = nil

        // Check if there's a value (not newline, semicolon, or })
        if !check(.newline) && !check(.semicolon) && !check(.rightBrace) {
            value = try parseExpression()
        }

        if check(.semicolon) { advance() }

        let endRange = value?.range ?? startToken.range

        return .returnStmt(
            value: value,
            range: startToken.range.extended(to: endRange)
        )
    }

    private func parseIfStmt() throws -> Statement {
        let startToken = try consume(.keyword(.if), message: "Expected 'if'")
        skipNewlines()

        try consume(.leftParen, message: "Expected '(' after 'if'")
        skipNewlines()

        let condition = try parseExpression()
        skipNewlines()

        try consume(.rightParen, message: "Expected ')' after if condition")
        skipNewlines()

        let thenBranch = try parseBlockStmt()
        skipNewlines()

        var elseBranch: Statement? = nil
        if match(.keyword(.else)) {
            skipNewlines()
            if check(.keyword(.if)) {
                elseBranch = try parseIfStmt()
            } else {
                elseBranch = try parseBlockStmt()
            }
        }

        let endRange = elseBranch?.range ?? thenBranch.range

        return .ifStmt(
            condition: condition,
            thenBranch: thenBranch,
            elseBranch: elseBranch,
            range: startToken.range.extended(to: endRange)
        )
    }

    private func parseForStmt() throws -> Statement {
        let startToken = try consume(.keyword(.for), message: "Expected 'for'")
        skipNewlines()

        try consume(.leftParen, message: "Expected '(' after 'for'")
        skipNewlines()

        // Initializer (optional var declaration)
        var initializer: Statement? = nil
        if check(.keyword(.var)) {
            initializer = try parseVarDeclStmt()
        }

        try consume(.semicolon, message: "Expected ';' after for initializer")
        skipNewlines()

        // Condition
        var condition: Expression? = nil
        if !check(.semicolon) {
            condition = try parseExpression()
        }

        try consume(.semicolon, message: "Expected ';' after for condition")
        skipNewlines()

        // Increment
        var increment: Expression? = nil
        if !check(.rightParen) {
            increment = try parseExpression()
        }

        try consume(.rightParen, message: "Expected ')' after for clauses")
        skipNewlines()

        let body = try parseBlockStmt()

        return .forStmt(
            initializer: initializer,
            condition: condition,
            increment: increment,
            body: body,
            range: startToken.range.extended(to: body.range)
        )
    }

    private func parseSwitchStmt() throws -> Statement {
        let startToken = try consume(.keyword(.switch), message: "Expected 'switch'")
        skipNewlines()

        try consume(.leftParen, message: "Expected '(' after 'switch'")
        skipNewlines()

        let subject = try parseExpression()
        skipNewlines()

        try consume(.rightParen, message: "Expected ')' after switch subject")
        skipNewlines()

        try consume(.leftBrace, message: "Expected '{' after switch subject")
        skipNewlines()

        var cases: [SwitchCase] = []
        while !check(.rightBrace) && !isAtEnd {
            let switchCase = try parseSwitchCase()
            cases.append(switchCase)
            skipNewlines()
        }

        let endToken = try consume(.rightBrace, message: "Expected '}' after switch cases")

        return .switchStmt(
            subject: subject,
            cases: cases,
            range: startToken.range.extended(to: endToken.range)
        )
    }

    private func parseSwitchCase() throws -> SwitchCase {
        let pattern = try parseExpression()
        skipNewlines()

        try consume(.arrow, message: "Expected '->' after switch pattern")
        skipNewlines()

        let body: Statement
        if check(.leftBrace) {
            body = try parseBlockStmt()
        } else {
            let expr = try parseExpression()
            body = .expression(expr: expr, range: expr.range)
        }

        return SwitchCase(
            pattern: pattern,
            body: body,
            range: pattern.range.extended(to: body.range)
        )
    }

    private func parseExpressionStmt() throws -> Statement {
        let expr = try parseExpression()

        if check(.semicolon) { advance() }

        return .expression(expr: expr, range: expr.range)
    }
}
```

---

## Step 8: Parser.swift - Expression Parsing (Pratt Parser)

```swift
// MARK: - Expression Parsing (Pratt Parser)

extension Parser {
    private func parseExpression() throws -> Expression {
        try parseAssignment()
    }

    private func parseAssignment() throws -> Expression {
        let expr = try parseOr()

        if match(.equal, .plusEqual, .minusEqual, .starEqual, .slashEqual) {
            let opToken = previous()
            skipNewlines()
            let value = try parseAssignment()

            let op: BinaryOperator
            switch opToken.kind {
            case .equal: op = .assign
            case .plusEqual: op = .addAssign
            case .minusEqual: op = .subtractAssign
            case .starEqual: op = .multiplyAssign
            case .slashEqual: op = .divideAssign
            default: fatalError("Unexpected assignment operator")
            }

            return .binary(
                left: expr,
                op: op,
                right: value,
                range: expr.range.extended(to: value.range)
            )
        }

        return expr
    }

    private func parseOr() throws -> Expression {
        var expr = try parseAnd()

        while match(.pipePipe) {
            skipNewlines()
            let right = try parseAnd()
            expr = .binary(
                left: expr,
                op: .or,
                right: right,
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private func parseAnd() throws -> Expression {
        var expr = try parseEquality()

        while match(.ampersandAmpersand) {
            skipNewlines()
            let right = try parseEquality()
            expr = .binary(
                left: expr,
                op: .and,
                right: right,
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private func parseEquality() throws -> Expression {
        var expr = try parseComparison()

        while match(.equalEqual, .bangEqual) {
            let opToken = previous()
            skipNewlines()
            let right = try parseComparison()

            let op: BinaryOperator = opToken.kind == .equalEqual ? .equal : .notEqual

            expr = .binary(
                left: expr,
                op: op,
                right: right,
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private func parseComparison() throws -> Expression {
        var expr = try parseAddition()

        while match(.less, .lessEqual, .greater, .greaterEqual) {
            let opToken = previous()
            skipNewlines()
            let right = try parseAddition()

            let op: BinaryOperator
            switch opToken.kind {
            case .less: op = .less
            case .lessEqual: op = .lessEqual
            case .greater: op = .greater
            case .greaterEqual: op = .greaterEqual
            default: fatalError("Unexpected comparison operator")
            }

            expr = .binary(
                left: expr,
                op: op,
                right: right,
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private func parseAddition() throws -> Expression {
        var expr = try parseMultiplication()

        while match(.plus, .minus) {
            let opToken = previous()
            skipNewlines()
            let right = try parseMultiplication()

            let op: BinaryOperator = opToken.kind == .plus ? .add : .subtract

            expr = .binary(
                left: expr,
                op: op,
                right: right,
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private func parseMultiplication() throws -> Expression {
        var expr = try parseUnary()

        while match(.star, .slash, .percent) {
            let opToken = previous()
            skipNewlines()
            let right = try parseUnary()

            let op: BinaryOperator
            switch opToken.kind {
            case .star: op = .multiply
            case .slash: op = .divide
            case .percent: op = .modulo
            default: fatalError("Unexpected multiplication operator")
            }

            expr = .binary(
                left: expr,
                op: op,
                right: right,
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private func parseUnary() throws -> Expression {
        if match(.bang, .minus) {
            let opToken = previous()
            let operand = try parseUnary()

            let op: UnaryOperator = opToken.kind == .bang ? .not : .negate

            return .unary(
                op: op,
                operand: operand,
                range: opToken.range.extended(to: operand.range)
            )
        }

        return try parseCall()
    }

    private func parseCall() throws -> Expression {
        var expr = try parsePrimary()

        while true {
            if match(.leftParen) {
                expr = try finishCall(expr)
            } else if match(.dot) {
                guard case .identifier(let name) = peek().kind else {
                    throw error("Expected property name after '.'", at: peek())
                }
                let nameToken = advance()

                expr = .memberAccess(
                    object: expr,
                    member: name,
                    range: expr.range.extended(to: nameToken.range)
                )
            } else if check(.leftBrace) {
                // Check if this is a struct initialization: Identifier { ... }
                if case .identifier(let typeName) = expr {
                    expr = try parseStructInit(typeName: typeName, startRange: expr.range)
                } else {
                    break
                }
            } else {
                break
            }
        }

        return expr
    }

    private func finishCall(_ callee: Expression) throws -> Expression {
        var arguments: [Expression] = []
        skipNewlines()

        if !check(.rightParen) {
            repeat {
                skipNewlines()
                let arg = try parseExpression()
                arguments.append(arg)
                skipNewlines()
            } while match(.comma)
        }

        let endToken = try consume(.rightParen, message: "Expected ')' after arguments")

        return .call(
            callee: callee,
            arguments: arguments,
            range: callee.range.extended(to: endToken.range)
        )
    }

    private func parseStructInit(typeName: String, startRange: SourceRange) throws -> Expression {
        try consume(.leftBrace, message: "Expected '{' for struct initialization")
        skipNewlines()

        var fields: [FieldInit] = []
        while !check(.rightBrace) && !isAtEnd {
            guard case .identifier(let fieldName) = peek().kind else {
                throw error("Expected field name", at: peek())
            }
            let nameToken = advance()

            try consume(.colon, message: "Expected ':' after field name")
            skipNewlines()

            let value = try parseExpression()

            fields.append(FieldInit(
                name: fieldName,
                value: value,
                range: nameToken.range.extended(to: value.range)
            ))

            skipNewlines()
            if !check(.rightBrace) {
                try consume(.comma, message: "Expected ',' between fields")
                skipNewlines()
            }
        }

        let endToken = try consume(.rightBrace, message: "Expected '}' after struct fields")

        return .structInit(
            typeName: typeName,
            fields: fields,
            range: startRange.extended(to: endToken.range)
        )
    }

    private func parsePrimary() throws -> Expression {
        let token = peek()

        switch token.kind {
        case .intLiteral(let value):
            advance()
            return .intLiteral(value: value, range: token.range)

        case .floatLiteral(let value):
            advance()
            return .floatLiteral(value: value, range: token.range)

        case .stringLiteral(let value):
            advance()
            // Check if followed by interpolation
            if check(.stringInterpolationStart) {
                return try parseStringInterpolation(firstPart: value, startRange: token.range)
            }
            return .stringLiteral(value: value, range: token.range)

        case .keyword(.true):
            advance()
            return .boolLiteral(value: true, range: token.range)

        case .keyword(.false):
            advance()
            return .boolLiteral(value: false, range: token.range)

        case .identifier(let name):
            advance()
            return .identifier(name: name, range: token.range)

        case .leftParen:
            advance()
            skipNewlines()
            let expr = try parseExpression()
            skipNewlines()
            try consume(.rightParen, message: "Expected ')' after expression")
            return expr

        default:
            throw error("Expected expression", at: token)
        }
    }

    private func parseStringInterpolation(firstPart: String, startRange: SourceRange) throws -> Expression {
        var parts: [StringPart] = []

        if !firstPart.isEmpty {
            parts.append(.literal(firstPart))
        }

        var lastRange = startRange

        while match(.stringInterpolationStart) {
            skipNewlines()
            let expr = try parseExpression()
            skipNewlines()
            try consume(.stringInterpolationEnd, message: "Expected ')' after interpolation")
            parts.append(.interpolation(expr))

            // Check for following string literal
            if case .stringLiteral(let str) = peek().kind {
                lastRange = peek().range
                advance()
                if !str.isEmpty {
                    parts.append(.literal(str))
                }
            }
        }

        return .stringInterpolation(
            parts: parts,
            range: startRange.extended(to: lastRange)
        )
    }
}
```

---

## Usage Examples

### Clean Pattern Matching (No Casting!)

```swift
// Type checking an expression - exhaustive switch, no `as` casting
func checkExpression(_ expr: Expression) -> SlangType {
    switch expr {
    case .intLiteral:
        return .int

    case .floatLiteral:
        return .float

    case .stringLiteral, .stringInterpolation:
        return .string

    case .boolLiteral:
        return .bool

    case .identifier(let name, let range):
        return lookupVariable(name, at: range)

    case .binary(let left, let op, let right, _):
        return checkBinary(left: left, op: op, right: right)

    case .unary(let op, let operand, _):
        return checkUnary(op: op, operand: operand)

    case .call(let callee, let arguments, let range):
        return checkCall(callee: callee, arguments: arguments, at: range)

    case .memberAccess(let object, let member, let range):
        return checkMemberAccess(object: object, member: member, at: range)

    case .structInit(let typeName, let fields, let range):
        return checkStructInit(typeName: typeName, fields: fields, at: range)
    }
    // Compiler enforces all cases are handled!
}
```

### Built-in Type Resolution (No Magic Strings!)

```swift
func resolveType(_ annotation: TypeAnnotation) -> SlangType {
    // Use RawRepresentable enum instead of magic strings
    if let builtin = annotation.asBuiltin {
        switch builtin {
        case .int: return .int
        case .float: return .float
        case .string: return .string
        case .bool: return .bool
        case .void: return .void
        }
    }

    // Check user-defined types
    if let structInfo = lookupStruct(annotation.name) {
        return .structType(name: annotation.name)
    }
    if let enumInfo = lookupEnum(annotation.name) {
        return .enumType(name: annotation.name)
    }

    error("Unknown type '\(annotation.name)'", at: annotation.range)
    return .error
}
```

---

## Test Cases

### Test 1: Function Declaration

**Input:**
```slang
func add(a: Int, b: Int) -> Int {
    return a + b
}
```

**Expected AST:**
```swift
.function(
    name: "add",
    parameters: [Parameter(name: "a", ...), Parameter(name: "b", ...)],
    returnType: TypeAnnotation(name: "Int", ...),
    body: .block(statements: [
        .returnStmt(value: .binary(
            left: .identifier(name: "a", ...),
            op: .add,
            right: .identifier(name: "b", ...),
            ...
        ), ...)
    ], ...),
    ...
)
```

### Test 2: Pattern Matching in Switch

**Input:**
```slang
switch (dir) {
    Direction.up -> print("up")
    Direction.down -> print("down")
}
```

**Expected AST:**
```swift
.switchStmt(
    subject: .identifier(name: "dir", ...),
    cases: [
        SwitchCase(
            pattern: .memberAccess(object: .identifier(name: "Direction", ...), member: "up", ...),
            body: .expression(expr: .call(...), ...)
        ),
        SwitchCase(
            pattern: .memberAccess(object: .identifier(name: "Direction", ...), member: "down", ...),
            body: .expression(expr: .call(...), ...)
        )
    ],
    ...
)
```

---

## Acceptance Criteria

- [ ] AST.swift uses enums with associated values for Expression, Statement, Declaration
- [ ] BuiltinTypeName enum replaces magic strings
- [ ] All pattern matching is exhaustive (no default cases needed)
- [ ] No `as` or `as?` casting anywhere
- [ ] Parser.swift creates enum cases directly
- [ ] All existing test cases still pass
- [ ] `swift build` succeeds

---

## Next Phase

Once this phase is complete, proceed to [Phase 3: Type Checker](phase-3-typechecker.md).
