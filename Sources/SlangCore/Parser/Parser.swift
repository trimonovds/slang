// Sources/SlangCore/Parser/Parser.swift

/// Error thrown when parsing fails
public struct ParserError: Error, Sendable {
    public let diagnostics: [Diagnostic]

    public init(_ diagnostics: [Diagnostic]) {
        self.diagnostics = diagnostics
    }

    public init(_ diagnostic: Diagnostic) {
        self.diagnostics = [diagnostic]
    }
}

/// Parses tokens into an AST
public struct Parser {
    private let tokens: [Token]
    private var current: Int = 0
    private var diagnostics: [Diagnostic] = []

    public init(tokens: [Token]) {
        self.tokens = tokens
    }

    // MARK: - Public API

    /// Parse all declarations in the token stream
    public mutating func parse() throws -> [Declaration] {
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
    private mutating func advance() -> Token {
        if !isAtEnd {
            current += 1
        }
        return previous()
    }

    private func check(_ kind: TokenKind) -> Bool {
        if isAtEnd { return false }
        return tokenKindMatches(peek().kind, kind)
    }

    private mutating func match(_ kinds: TokenKind...) -> Bool {
        for kind in kinds {
            if check(kind) {
                advance()
                return true
            }
        }
        return false
    }

    @discardableResult
    private mutating func consume(_ kind: TokenKind, message: String) throws -> Token {
        if check(kind) { return advance() }
        throw error(message, at: peek())
    }

    private mutating func skipNewlines() {
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

    private mutating func synchronize() {
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

// MARK: - Declaration Parsing

extension Parser {
    private mutating func parseDeclaration() throws -> Declaration {
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

    private mutating func parseFunctionDecl() throws -> Declaration {
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

        return Declaration(
            kind: .function(
                name: name,
                parameters: parameters,
                returnType: returnType,
                body: body
            ),
            range: startToken.range.extended(to: body.range)
        )
    }

    private mutating func parseParameter() throws -> Parameter {
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

    private mutating func parseTypeAnnotation() throws -> TypeAnnotation {
        guard case .identifier(let name) = peek().kind else {
            throw error("Expected type name", at: peek())
        }
        let token = advance()

        return TypeAnnotation(name: name, range: token.range)
    }

    private mutating func parseStructDecl() throws -> Declaration {
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

        return Declaration(
            kind: .structDecl(name: name, fields: fields),
            range: startToken.range.extended(to: endToken.range)
        )
    }

    private mutating func parseStructField() throws -> StructField {
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

    private mutating func parseEnumDecl() throws -> Declaration {
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

        return Declaration(
            kind: .enumDecl(name: name, cases: cases),
            range: startToken.range.extended(to: endToken.range)
        )
    }
}

// MARK: - Statement Parsing

extension Parser {
    private mutating func parseBlockStmt() throws -> Statement {
        let startToken = try consume(.leftBrace, message: "Expected '{'")
        skipNewlines()

        var statements: [Statement] = []
        while !check(.rightBrace) && !isAtEnd {
            let stmt = try parseStatement()
            statements.append(stmt)
            skipNewlines()
        }

        let endToken = try consume(.rightBrace, message: "Expected '}'")

        return Statement(
            kind: .block(statements: statements),
            range: startToken.range.extended(to: endToken.range)
        )
    }

    private mutating func parseStatement() throws -> Statement {
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

    private mutating func parseVarDeclStmt(consumeSemicolon: Bool = true) throws -> Statement {
        let startToken = try consume(.keyword(.var), message: "Expected 'var'")
        skipNewlines()

        guard case .identifier(let name) = peek().kind else {
            throw error("Expected variable name", at: peek())
        }
        advance()

        // Type annotation is optional (for type inference)
        var type: TypeAnnotation? = nil
        if check(.colon) {
            advance()
            skipNewlines()
            type = try parseTypeAnnotation()
        }
        skipNewlines()

        try consume(.equal, message: "Expected '=' in variable declaration")
        skipNewlines()

        let initializer = try parseExpression()

        // Consume optional semicolon (unless told not to for for-loop context)
        if consumeSemicolon && check(.semicolon) { advance() }

        // If no explicit type, we still need a TypeAnnotation - use a placeholder that the typechecker infers
        let actualType = type ?? TypeAnnotation(name: "_infer", range: startToken.range)

        return Statement(
            kind: .varDecl(name: name, type: actualType, initializer: initializer),
            range: startToken.range.extended(to: initializer.range)
        )
    }

    private mutating func parseReturnStmt() throws -> Statement {
        let startToken = try consume(.keyword(.return), message: "Expected 'return'")

        var value: Expression? = nil

        // Check if there's a value (not newline, semicolon, or })
        if !check(.newline) && !check(.semicolon) && !check(.rightBrace) && !isAtEnd {
            value = try parseExpression()
        }

        if check(.semicolon) { advance() }

        let endRange = value?.range ?? startToken.range

        return Statement(
            kind: .returnStmt(value: value),
            range: startToken.range.extended(to: endRange)
        )
    }

    private mutating func parseIfStmt() throws -> Statement {
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

        return Statement(
            kind: .ifStmt(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch),
            range: startToken.range.extended(to: endRange)
        )
    }

    private mutating func parseForStmt() throws -> Statement {
        let startToken = try consume(.keyword(.for), message: "Expected 'for'")
        skipNewlines()

        try consume(.leftParen, message: "Expected '(' after 'for'")
        skipNewlines()

        // Initializer (optional var declaration)
        var initializer: Statement? = nil
        if check(.keyword(.var)) {
            initializer = try parseVarDeclStmt(consumeSemicolon: false)
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

        return Statement(
            kind: .forStmt(initializer: initializer, condition: condition, increment: increment, body: body),
            range: startToken.range.extended(to: body.range)
        )
    }

    private mutating func parseSwitchStmt() throws -> Statement {
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

        return Statement(
            kind: .switchStmt(subject: subject, cases: cases),
            range: startToken.range.extended(to: endToken.range)
        )
    }

    private mutating func parseSwitchCase() throws -> SwitchCase {
        let pattern = try parseExpression()
        skipNewlines()

        try consume(.arrow, message: "Expected '->' after switch pattern")
        skipNewlines()

        let body: Statement
        if check(.leftBrace) {
            body = try parseBlockStmt()
        } else {
            let expr = try parseExpression()
            body = Statement(kind: .expression(expr: expr), range: expr.range)
        }

        return SwitchCase(
            pattern: pattern,
            body: body,
            range: pattern.range.extended(to: body.range)
        )
    }

    private mutating func parseExpressionStmt() throws -> Statement {
        let expr = try parseExpression()

        if check(.semicolon) { advance() }

        return Statement(kind: .expression(expr: expr), range: expr.range)
    }
}

// MARK: - Expression Parsing (Pratt Parser)

extension Parser {
    private mutating func parseExpression() throws -> Expression {
        try parseAssignment()
    }

    private mutating func parseAssignment() throws -> Expression {
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

            return Expression(
                kind: .binary(left: expr, op: op, right: value),
                range: expr.range.extended(to: value.range)
            )
        }

        return expr
    }

    private mutating func parseOr() throws -> Expression {
        var expr = try parseAnd()

        while match(.pipePipe) {
            skipNewlines()
            let right = try parseAnd()
            expr = Expression(
                kind: .binary(left: expr, op: .or, right: right),
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private mutating func parseAnd() throws -> Expression {
        var expr = try parseEquality()

        while match(.ampersandAmpersand) {
            skipNewlines()
            let right = try parseEquality()
            expr = Expression(
                kind: .binary(left: expr, op: .and, right: right),
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private mutating func parseEquality() throws -> Expression {
        var expr = try parseComparison()

        while match(.equalEqual, .bangEqual) {
            let opToken = previous()
            skipNewlines()
            let right = try parseComparison()

            let op: BinaryOperator = opToken.kind == .equalEqual ? .equal : .notEqual

            expr = Expression(
                kind: .binary(left: expr, op: op, right: right),
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private mutating func parseComparison() throws -> Expression {
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

            expr = Expression(
                kind: .binary(left: expr, op: op, right: right),
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private mutating func parseAddition() throws -> Expression {
        var expr = try parseMultiplication()

        while match(.plus, .minus) {
            let opToken = previous()
            skipNewlines()
            let right = try parseMultiplication()

            let op: BinaryOperator = opToken.kind == .plus ? .add : .subtract

            expr = Expression(
                kind: .binary(left: expr, op: op, right: right),
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private mutating func parseMultiplication() throws -> Expression {
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

            expr = Expression(
                kind: .binary(left: expr, op: op, right: right),
                range: expr.range.extended(to: right.range)
            )
        }

        return expr
    }

    private mutating func parseUnary() throws -> Expression {
        if match(.bang, .minus) {
            let opToken = previous()
            let operand = try parseUnary()

            let op: UnaryOperator = opToken.kind == .bang ? .not : .negate

            return Expression(
                kind: .unary(op: op, operand: operand),
                range: opToken.range.extended(to: operand.range)
            )
        }

        return try parseCall()
    }

    private mutating func parseCall() throws -> Expression {
        var expr = try parsePrimary()

        while true {
            if match(.leftParen) {
                expr = try finishCall(expr)
            } else if match(.dot) {
                guard case .identifier(let name) = peek().kind else {
                    throw error("Expected property name after '.'", at: peek())
                }
                let nameToken = advance()

                expr = Expression(
                    kind: .memberAccess(object: expr, member: name),
                    range: expr.range.extended(to: nameToken.range)
                )
            } else if check(.leftBrace) {
                // Check if this is a struct initialization: Identifier { ... }
                if case .identifier(let typeName) = expr.kind {
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

    private mutating func finishCall(_ callee: Expression) throws -> Expression {
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

        return Expression(
            kind: .call(callee: callee, arguments: arguments),
            range: callee.range.extended(to: endToken.range)
        )
    }

    private mutating func parseStructInit(typeName: String, startRange: SourceRange) throws -> Expression {
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

        return Expression(
            kind: .structInit(typeName: typeName, fields: fields),
            range: startRange.extended(to: endToken.range)
        )
    }

    private mutating func parsePrimary() throws -> Expression {
        let token = peek()

        switch token.kind {
        case .intLiteral(let value):
            advance()
            return Expression(kind: .intLiteral(value: value), range: token.range)

        case .floatLiteral(let value):
            advance()
            return Expression(kind: .floatLiteral(value: value), range: token.range)

        case .stringLiteral(let value):
            advance()
            // Check if followed by interpolation
            if check(.stringInterpolationStart) {
                return try parseStringInterpolation(firstPart: value, startRange: token.range)
            }
            return Expression(kind: .stringLiteral(value: value), range: token.range)

        case .keyword(.true):
            advance()
            return Expression(kind: .boolLiteral(value: true), range: token.range)

        case .keyword(.false):
            advance()
            return Expression(kind: .boolLiteral(value: false), range: token.range)

        case .identifier(let name):
            advance()
            return Expression(kind: .identifier(name: name), range: token.range)

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

    private mutating func parseStringInterpolation(firstPart: String, startRange: SourceRange) throws -> Expression {
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

        return Expression(
            kind: .stringInterpolation(parts: parts),
            range: startRange.extended(to: lastRange)
        )
    }
}
