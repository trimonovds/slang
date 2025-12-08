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

## Step 1: AST.swift - Base Protocols

```swift
// Sources/SlangCore/Parser/AST.swift

import Foundation

// MARK: - Base Protocol

/// All AST nodes conform to this protocol
public protocol ASTNode {
    var range: SourceRange { get }
}

// MARK: - Top-Level Declarations

public protocol Declaration: ASTNode {}

// MARK: - Statements

public protocol Statement: ASTNode {}

// MARK: - Expressions

public protocol Expression: ASTNode {}
```

---

## Step 2: AST.swift - Declaration Nodes

```swift
// MARK: - Function Declaration

public struct FunctionDecl: Declaration {
    public let name: String
    public let parameters: [Parameter]
    public let returnType: TypeAnnotation?  // nil means Void
    public let body: BlockStmt
    public let range: SourceRange

    public init(name: String, parameters: [Parameter], returnType: TypeAnnotation?, body: BlockStmt, range: SourceRange) {
        self.name = name
        self.parameters = parameters
        self.returnType = returnType
        self.body = body
        self.range = range
    }
}

public struct Parameter: ASTNode {
    public let name: String
    public let type: TypeAnnotation
    public let range: SourceRange

    public init(name: String, type: TypeAnnotation, range: SourceRange) {
        self.name = name
        self.type = type
        self.range = range
    }
}

// MARK: - Struct Declaration

public struct StructDecl: Declaration {
    public let name: String
    public let fields: [StructField]
    public let range: SourceRange

    public init(name: String, fields: [StructField], range: SourceRange) {
        self.name = name
        self.fields = fields
        self.range = range
    }
}

public struct StructField: ASTNode {
    public let name: String
    public let type: TypeAnnotation
    public let range: SourceRange

    public init(name: String, type: TypeAnnotation, range: SourceRange) {
        self.name = name
        self.type = type
        self.range = range
    }
}

// MARK: - Enum Declaration

public struct EnumDecl: Declaration {
    public let name: String
    public let cases: [EnumCase]
    public let range: SourceRange

    public init(name: String, cases: [EnumCase], range: SourceRange) {
        self.name = name
        self.cases = cases
        self.range = range
    }
}

public struct EnumCase: ASTNode {
    public let name: String
    public let range: SourceRange

    public init(name: String, range: SourceRange) {
        self.name = name
        self.range = range
    }
}

// MARK: - Type Annotation

public struct TypeAnnotation: ASTNode {
    public let name: String
    public let range: SourceRange

    public init(name: String, range: SourceRange) {
        self.name = name
        self.range = range
    }
}
```

---

## Step 3: AST.swift - Statement Nodes

```swift
// MARK: - Block Statement

public struct BlockStmt: Statement {
    public let statements: [Statement]
    public let range: SourceRange

    public init(statements: [Statement], range: SourceRange) {
        self.statements = statements
        self.range = range
    }
}

// MARK: - Variable Declaration

public struct VarDeclStmt: Statement {
    public let name: String
    public let type: TypeAnnotation
    public let initializer: Expression
    public let range: SourceRange

    public init(name: String, type: TypeAnnotation, initializer: Expression, range: SourceRange) {
        self.name = name
        self.type = type
        self.initializer = initializer
        self.range = range
    }
}

// MARK: - Expression Statement

public struct ExpressionStmt: Statement {
    public let expression: Expression
    public let range: SourceRange

    public init(expression: Expression, range: SourceRange) {
        self.expression = expression
        self.range = range
    }
}

// MARK: - Return Statement

public struct ReturnStmt: Statement {
    public let value: Expression?
    public let range: SourceRange

    public init(value: Expression?, range: SourceRange) {
        self.value = value
        self.range = range
    }
}

// MARK: - If Statement

public struct IfStmt: Statement {
    public let condition: Expression
    public let thenBranch: BlockStmt
    public let elseBranch: Statement?  // Either BlockStmt or another IfStmt (else if)
    public let range: SourceRange

    public init(condition: Expression, thenBranch: BlockStmt, elseBranch: Statement?, range: SourceRange) {
        self.condition = condition
        self.thenBranch = thenBranch
        self.elseBranch = elseBranch
        self.range = range
    }
}

// MARK: - For Statement

public struct ForStmt: Statement {
    public let initializer: VarDeclStmt?
    public let condition: Expression?
    public let increment: Expression?
    public let body: BlockStmt
    public let range: SourceRange

    public init(initializer: VarDeclStmt?, condition: Expression?, increment: Expression?, body: BlockStmt, range: SourceRange) {
        self.initializer = initializer
        self.condition = condition
        self.increment = increment
        self.body = body
        self.range = range
    }
}

// MARK: - Switch Statement

public struct SwitchStmt: Statement {
    public let subject: Expression
    public let cases: [SwitchCase]
    public let range: SourceRange

    public init(subject: Expression, cases: [SwitchCase], range: SourceRange) {
        self.subject = subject
        self.cases = cases
        self.range = range
    }
}

public struct SwitchCase: ASTNode {
    public let pattern: Expression  // The pattern to match (e.g., Direction.up)
    public let body: Statement      // Either expression statement or block
    public let range: SourceRange

    public init(pattern: Expression, body: Statement, range: SourceRange) {
        self.pattern = pattern
        self.body = body
        self.range = range
    }
}
```

---

## Step 4: AST.swift - Expression Nodes

```swift
// MARK: - Literals

public struct IntLiteralExpr: Expression {
    public let value: Int
    public let range: SourceRange

    public init(value: Int, range: SourceRange) {
        self.value = value
        self.range = range
    }
}

public struct FloatLiteralExpr: Expression {
    public let value: Double
    public let range: SourceRange

    public init(value: Double, range: SourceRange) {
        self.value = value
        self.range = range
    }
}

public struct StringLiteralExpr: Expression {
    public let value: String
    public let range: SourceRange

    public init(value: String, range: SourceRange) {
        self.value = value
        self.range = range
    }
}

public struct BoolLiteralExpr: Expression {
    public let value: Bool
    public let range: SourceRange

    public init(value: Bool, range: SourceRange) {
        self.value = value
        self.range = range
    }
}

// MARK: - String Interpolation

public struct StringInterpolationExpr: Expression {
    public let parts: [StringPart]
    public let range: SourceRange

    public init(parts: [StringPart], range: SourceRange) {
        self.parts = parts
        self.range = range
    }
}

public enum StringPart {
    case literal(String)
    case interpolation(Expression)
}

// MARK: - Identifier

public struct IdentifierExpr: Expression {
    public let name: String
    public let range: SourceRange

    public init(name: String, range: SourceRange) {
        self.name = name
        self.range = range
    }
}

// MARK: - Binary Expression

public struct BinaryExpr: Expression {
    public let left: Expression
    public let op: BinaryOperator
    public let right: Expression
    public let range: SourceRange

    public init(left: Expression, op: BinaryOperator, right: Expression, range: SourceRange) {
        self.left = left
        self.op = op
        self.right = right
        self.range = range
    }
}

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

// MARK: - Unary Expression

public struct UnaryExpr: Expression {
    public let op: UnaryOperator
    public let operand: Expression
    public let range: SourceRange

    public init(op: UnaryOperator, operand: Expression, range: SourceRange) {
        self.op = op
        self.operand = operand
        self.range = range
    }
}

public enum UnaryOperator: String {
    case negate = "-"
    case not = "!"
}

// MARK: - Call Expression

public struct CallExpr: Expression {
    public let callee: Expression
    public let arguments: [Expression]
    public let range: SourceRange

    public init(callee: Expression, arguments: [Expression], range: SourceRange) {
        self.callee = callee
        self.arguments = arguments
        self.range = range
    }
}

// MARK: - Member Access

public struct MemberAccessExpr: Expression {
    public let object: Expression
    public let member: String
    public let range: SourceRange

    public init(object: Expression, member: String, range: SourceRange) {
        self.object = object
        self.member = member
        self.range = range
    }
}

// MARK: - Struct Initialization

public struct StructInitExpr: Expression {
    public let typeName: String
    public let fields: [FieldInit]
    public let range: SourceRange

    public init(typeName: String, fields: [FieldInit], range: SourceRange) {
        self.typeName = typeName
        self.fields = fields
        self.range = range
    }
}

public struct FieldInit: ASTNode {
    public let name: String
    public let value: Expression
    public let range: SourceRange

    public init(name: String, value: Expression, range: SourceRange) {
        self.name = name
        self.value = value
        self.range = range
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

    private func parseFunctionDecl() throws -> FunctionDecl {
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

        return FunctionDecl(
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

    private func parseStructDecl() throws -> StructDecl {
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

        return StructDecl(
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

    private func parseEnumDecl() throws -> EnumDecl {
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

        return EnumDecl(
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
    private func parseBlockStmt() throws -> BlockStmt {
        let startToken = try consume(.leftBrace, message: "Expected '{'")
        skipNewlines()

        var statements: [Statement] = []
        while !check(.rightBrace) && !isAtEnd {
            let stmt = try parseStatement()
            statements.append(stmt)
            skipNewlines()
        }

        let endToken = try consume(.rightBrace, message: "Expected '}'")

        return BlockStmt(
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

    private func parseVarDeclStmt() throws -> VarDeclStmt {
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

        // Consume optional semicolon or newline
        if check(.semicolon) { advance() }

        return VarDeclStmt(
            name: name,
            type: type,
            initializer: initializer,
            range: startToken.range.extended(to: initializer.range)
        )
    }

    private func parseReturnStmt() throws -> ReturnStmt {
        let startToken = try consume(.keyword(.return), message: "Expected 'return'")

        var value: Expression? = nil

        // Check if there's a value (not newline, semicolon, or })
        if !check(.newline) && !check(.semicolon) && !check(.rightBrace) {
            value = try parseExpression()
        }

        if check(.semicolon) { advance() }

        let endRange = value?.range ?? startToken.range

        return ReturnStmt(
            value: value,
            range: startToken.range.extended(to: endRange)
        )
    }

    private func parseIfStmt() throws -> IfStmt {
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

        return IfStmt(
            condition: condition,
            thenBranch: thenBranch,
            elseBranch: elseBranch,
            range: startToken.range.extended(to: endRange)
        )
    }

    private func parseForStmt() throws -> ForStmt {
        let startToken = try consume(.keyword(.for), message: "Expected 'for'")
        skipNewlines()

        try consume(.leftParen, message: "Expected '(' after 'for'")
        skipNewlines()

        // Initializer (optional var declaration)
        var initializer: VarDeclStmt? = nil
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

        return ForStmt(
            initializer: initializer,
            condition: condition,
            increment: increment,
            body: body,
            range: startToken.range.extended(to: body.range)
        )
    }

    private func parseSwitchStmt() throws -> SwitchStmt {
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

        return SwitchStmt(
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
            body = ExpressionStmt(expression: expr, range: expr.range)
        }

        return SwitchCase(
            pattern: pattern,
            body: body,
            range: pattern.range.extended(to: body.range)
        )
    }

    private func parseExpressionStmt() throws -> ExpressionStmt {
        let expr = try parseExpression()

        if check(.semicolon) { advance() }

        return ExpressionStmt(expression: expr, range: expr.range)
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

            return BinaryExpr(
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
            expr = BinaryExpr(
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
            expr = BinaryExpr(
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

            expr = BinaryExpr(
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

            expr = BinaryExpr(
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

            expr = BinaryExpr(
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

            expr = BinaryExpr(
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

            return UnaryExpr(
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

                expr = MemberAccessExpr(
                    object: expr,
                    member: name,
                    range: expr.range.extended(to: nameToken.range)
                )
            } else if check(.leftBrace) {
                // Check if this is a struct initialization: Identifier { ... }
                if let identExpr = expr as? IdentifierExpr {
                    expr = try parseStructInit(typeName: identExpr.name, startRange: identExpr.range)
                } else {
                    break
                }
            } else {
                break
            }
        }

        return expr
    }

    private func finishCall(_ callee: Expression) throws -> CallExpr {
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

        return CallExpr(
            callee: callee,
            arguments: arguments,
            range: callee.range.extended(to: endToken.range)
        )
    }

    private func parseStructInit(typeName: String, startRange: SourceRange) throws -> StructInitExpr {
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

        return StructInitExpr(
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
            return IntLiteralExpr(value: value, range: token.range)

        case .floatLiteral(let value):
            advance()
            return FloatLiteralExpr(value: value, range: token.range)

        case .stringLiteral(let value):
            advance()
            // Check if followed by interpolation
            if check(.stringInterpolationStart) {
                return try parseStringInterpolation(firstPart: value, startRange: token.range)
            }
            return StringLiteralExpr(value: value, range: token.range)

        case .keyword(.true):
            advance()
            return BoolLiteralExpr(value: true, range: token.range)

        case .keyword(.false):
            advance()
            return BoolLiteralExpr(value: false, range: token.range)

        case .identifier(let name):
            advance()
            return IdentifierExpr(name: name, range: token.range)

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

    private func parseStringInterpolation(firstPart: String, startRange: SourceRange) throws -> StringInterpolationExpr {
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

        return StringInterpolationExpr(
            parts: parts,
            range: startRange.extended(to: lastRange)
        )
    }
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
```
FunctionDecl(
    name: "add",
    parameters: [Parameter(name: "a", type: Int), Parameter(name: "b", type: Int)],
    returnType: Int,
    body: BlockStmt([
        ReturnStmt(BinaryExpr(IdentifierExpr("a"), +, IdentifierExpr("b")))
    ])
)
```

### Test 2: Struct Declaration

**Input:**
```slang
struct Point {
    x: Int
    y: Int
}
```

**Expected AST:**
```
StructDecl(
    name: "Point",
    fields: [StructField(name: "x", type: Int), StructField(name: "y", type: Int)]
)
```

### Test 3: If Statement

**Input:**
```slang
if (x > 0) {
    print("positive")
} else {
    print("not positive")
}
```

**Expected AST:**
```
IfStmt(
    condition: BinaryExpr(IdentifierExpr("x"), >, IntLiteralExpr(0)),
    thenBranch: BlockStmt([ExpressionStmt(CallExpr(...))]),
    elseBranch: BlockStmt([ExpressionStmt(CallExpr(...))])
)
```

### Test 4: For Loop

**Input:**
```slang
for (var i: Int = 0; i < 10; i = i + 1) {
    print(i)
}
```

**Expected AST:**
```
ForStmt(
    initializer: VarDeclStmt(name: "i", type: Int, initializer: IntLiteralExpr(0)),
    condition: BinaryExpr(IdentifierExpr("i"), <, IntLiteralExpr(10)),
    increment: BinaryExpr(IdentifierExpr("i"), =, BinaryExpr(...)),
    body: BlockStmt([...])
)
```

### Test 5: Switch Statement

**Input:**
```slang
switch (dir) {
    Direction.up -> print("up")
    Direction.down -> print("down")
}
```

**Expected AST:**
```
SwitchStmt(
    subject: IdentifierExpr("dir"),
    cases: [
        SwitchCase(pattern: MemberAccessExpr(Direction, up), body: ExpressionStmt(...)),
        SwitchCase(pattern: MemberAccessExpr(Direction, down), body: ExpressionStmt(...))
    ]
)
```

### Test 6: String Interpolation

**Input:**
```slang
"Hello \(name)!"
```

**Expected AST:**
```
StringInterpolationExpr(
    parts: [
        .literal("Hello "),
        .interpolation(IdentifierExpr("name")),
        .literal("!")
    ]
)
```

---

## Acceptance Criteria

- [ ] AST.swift created with all node types
- [ ] Parser.swift created and handles:
  - [ ] Function declarations
  - [ ] Struct declarations
  - [ ] Enum declarations
  - [ ] Variable declarations
  - [ ] Return statements
  - [ ] If/else statements
  - [ ] For loops
  - [ ] Switch statements
  - [ ] All operators with correct precedence
  - [ ] Function calls
  - [ ] Member access (dot notation)
  - [ ] Struct initialization
  - [ ] String interpolation
- [ ] Error recovery works (synchronize)
- [ ] Good error messages with source locations
- [ ] All test cases pass
- [ ] `swift build` succeeds

---

## Next Phase

Once this phase is complete, proceed to [Phase 3: Type Checker](phase-3-typechecker.md).
