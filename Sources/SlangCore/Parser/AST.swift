// Sources/SlangCore/Parser/AST.swift

// MARK: - Built-in Types (RawRepresentable)

/// Built-in type names - eliminates magic strings
public enum BuiltinTypeName: String, CaseIterable, Sendable {
    case int = "Int"
    case float = "Float"
    case string = "String"
    case bool = "Bool"
    case void = "Void"
}

// MARK: - Operators

public enum BinaryOperator: String, Sendable {
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

public enum UnaryOperator: String, Sendable {
    case negate = "-"
    case not = "!"
}

// MARK: - Simple Data Containers

public struct Parameter: Sendable {
    public let name: String
    public let type: TypeAnnotation
    public let range: SourceRange

    public init(name: String, type: TypeAnnotation, range: SourceRange) {
        self.name = name
        self.type = type
        self.range = range
    }
}

public struct StructField: Sendable {
    public let name: String
    public let type: TypeAnnotation
    public let range: SourceRange

    public init(name: String, type: TypeAnnotation, range: SourceRange) {
        self.name = name
        self.type = type
        self.range = range
    }
}

public struct EnumCase: Sendable {
    public let name: String
    public let range: SourceRange

    public init(name: String, range: SourceRange) {
        self.name = name
        self.range = range
    }
}

public struct TypeAnnotation: Sendable {
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

public struct FieldInit: Sendable {
    public let name: String
    public let value: Expression
    public let range: SourceRange

    public init(name: String, value: Expression, range: SourceRange) {
        self.name = name
        self.value = value
        self.range = range
    }
}

public struct SwitchCase: Sendable {
    public let pattern: Expression
    public let body: Statement
    public let range: SourceRange

    public init(pattern: Expression, body: Statement, range: SourceRange) {
        self.pattern = pattern
        self.body = body
        self.range = range
    }
}

public enum StringPart: Sendable {
    case literal(String)
    case interpolation(Expression)
}

// MARK: - Expressions

/// The semantic content of an expression (no range - that's in the wrapper)
public indirect enum ExpressionKind: Sendable {
    // Literals
    case intLiteral(value: Int)
    case floatLiteral(value: Double)
    case stringLiteral(value: String)
    case boolLiteral(value: Bool)

    // String interpolation
    case stringInterpolation(parts: [StringPart])

    // Identifier
    case identifier(name: String)

    // Operators
    case binary(left: Expression, op: BinaryOperator, right: Expression)
    case unary(op: UnaryOperator, operand: Expression)

    // Access
    case call(callee: Expression, arguments: [Expression])
    case memberAccess(object: Expression, member: String)

    // Struct initialization
    case structInit(typeName: String, fields: [FieldInit])

    // Switch expression (returns a value)
    case switchExpr(subject: Expression, cases: [SwitchCase])
}

/// An expression with source location
public struct Expression: Sendable {
    public let kind: ExpressionKind
    public let range: SourceRange

    public init(kind: ExpressionKind, range: SourceRange) {
        self.kind = kind
        self.range = range
    }
}

// MARK: - Statements

/// The semantic content of a statement
public indirect enum StatementKind: Sendable {
    case block(statements: [Statement])

    case varDecl(name: String, type: TypeAnnotation, initializer: Expression)

    case expression(expr: Expression)

    case returnStmt(value: Expression?)

    case ifStmt(
        condition: Expression,
        thenBranch: Statement,  // Always a .block
        elseBranch: Statement?  // Either .block or .ifStmt (else if)
    )

    case forStmt(
        initializer: Statement?,  // .varDecl or nil
        condition: Expression?,
        increment: Expression?,
        body: Statement  // Always a .block
    )

    case switchStmt(subject: Expression, cases: [SwitchCase])
}

/// A statement with source location
public struct Statement: Sendable {
    public let kind: StatementKind
    public let range: SourceRange

    public init(kind: StatementKind, range: SourceRange) {
        self.kind = kind
        self.range = range
    }
}

// MARK: - Declarations

/// The semantic content of a declaration
public enum DeclarationKind: Sendable {
    case function(
        name: String,
        parameters: [Parameter],
        returnType: TypeAnnotation?,
        body: Statement  // Always a .block
    )

    case structDecl(name: String, fields: [StructField])

    case enumDecl(name: String, cases: [EnumCase])
}

/// A declaration with source location
public struct Declaration: Sendable {
    public let kind: DeclarationKind
    public let range: SourceRange

    public init(kind: DeclarationKind, range: SourceRange) {
        self.kind = kind
        self.range = range
    }

    /// Get the name of the declaration
    public var name: String {
        switch kind {
        case .function(let name, _, _, _),
             .structDecl(let name, _),
             .enumDecl(let name, _):
            return name
        }
    }
}
