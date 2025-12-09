# Phase 3: Type Checker

## Overview

The type checker verifies that programs are type-correct before execution. It catches errors like type mismatches, undefined variables, and missing switch cases.

**Input:** Array of `Declaration` (AST from Parser)
**Output:** Validated AST (same structure, but verified correct)

---

## Prerequisites

- Phase 1 (Lexer) complete
- Phase 2 (Parser & AST) complete

---

## Files to Create

| File | Purpose |
|------|---------|
| `Sources/SlangCore/TypeChecker/Type.swift` | Type representation |
| `Sources/SlangCore/TypeChecker/TypeChecker.swift` | Main type checking logic |

---

## Step 1: Type.swift - Type Representation

```swift
// Sources/SlangCore/TypeChecker/Type.swift

import Foundation

/// Represents a type in the Slang type system
public indirect enum SlangType: Equatable, CustomStringConvertible {
    // Built-in types
    case int
    case float
    case string
    case bool
    case void

    // User-defined types
    case structType(name: String)
    case enumType(name: String)

    // Function type (for type checking calls)
    case function(params: [SlangType], returnType: SlangType)

    // Error type - used when type checking fails to prevent cascading errors
    case error

    public var description: String {
        switch self {
        case .int: return "Int"
        case .float: return "Float"
        case .string: return "String"
        case .bool: return "Bool"
        case .void: return "Void"
        case .structType(let name): return name
        case .enumType(let name): return name
        case .function(let params, let ret):
            let paramStr = params.map { $0.description }.joined(separator: ", ")
            return "(\(paramStr)) -> \(ret)"
        case .error: return "<error>"
        }
    }

    /// Check if this type is numeric (Int or Float)
    public var isNumeric: Bool {
        self == .int || self == .float
    }

    /// Convert from BuiltinTypeName to SlangType
    public static func from(builtin: BuiltinTypeName) -> SlangType {
        switch builtin {
        case .int: return .int
        case .float: return .float
        case .string: return .string
        case .bool: return .bool
        case .void: return .void
        }
    }
}

/// Information about a struct type
public struct StructTypeInfo {
    public let name: String
    public let fields: [String: SlangType]  // field name -> type

    public init(name: String, fields: [String: SlangType]) {
        self.name = name
        self.fields = fields
    }
}

/// Information about an enum type
public struct EnumTypeInfo {
    public let name: String
    public let cases: Set<String>

    public init(name: String, cases: Set<String>) {
        self.name = name
        self.cases = cases
    }
}
```

---

## Step 2: TypeChecker.swift - Environment

```swift
// Sources/SlangCore/TypeChecker/TypeChecker.swift

import Foundation

/// Error thrown when type checking fails
public struct TypeCheckError: Error {
    public let diagnostics: [Diagnostic]

    public init(_ diagnostics: [Diagnostic]) {
        self.diagnostics = diagnostics
    }

    public init(_ diagnostic: Diagnostic) {
        self.diagnostics = [diagnostic]
    }
}

/// Manages type information for a scope
public class TypeEnvironment {
    private var variables: [String: SlangType] = [:]
    private var functions: [String: SlangType] = [:]
    private var structTypes: [String: StructTypeInfo] = [:]
    private var enumTypes: [String: EnumTypeInfo] = [:]
    private let parent: TypeEnvironment?

    public init(parent: TypeEnvironment? = nil) {
        self.parent = parent

        // Register built-in types and functions in the global scope
        if parent == nil {
            registerBuiltins()
        }
    }

    private func registerBuiltins() {
        // Built-in print function: (String) -> Void
        functions["print"] = .function(params: [.string], returnType: .void)
    }

    // MARK: - Variables

    public func defineVariable(_ name: String, type: SlangType) {
        variables[name] = type
    }

    public func lookupVariable(_ name: String) -> SlangType? {
        if let type = variables[name] {
            return type
        }
        return parent?.lookupVariable(name)
    }

    // MARK: - Functions

    public func defineFunction(_ name: String, type: SlangType) {
        functions[name] = type
    }

    public func lookupFunction(_ name: String) -> SlangType? {
        if let type = functions[name] {
            return type
        }
        return parent?.lookupFunction(name)
    }

    // MARK: - Struct Types

    public func defineStructType(_ info: StructTypeInfo) {
        structTypes[info.name] = info
    }

    public func lookupStructType(_ name: String) -> StructTypeInfo? {
        if let info = structTypes[name] {
            return info
        }
        return parent?.lookupStructType(name)
    }

    // MARK: - Enum Types

    public func defineEnumType(_ info: EnumTypeInfo) {
        enumTypes[info.name] = info
    }

    public func lookupEnumType(_ name: String) -> EnumTypeInfo? {
        if let info = enumTypes[name] {
            return info
        }
        return parent?.lookupEnumType(name)
    }

    // MARK: - Scope

    public func createChild() -> TypeEnvironment {
        TypeEnvironment(parent: self)
    }
}
```

---

## Step 3: TypeChecker.swift - Main Class

```swift
/// Type checks an AST
public class TypeChecker {
    private var environment: TypeEnvironment
    private var diagnostics: [Diagnostic] = []
    private var currentFunctionReturnType: SlangType? = nil

    public init() {
        self.environment = TypeEnvironment()
    }

    // MARK: - Public API

    /// Type check all declarations
    public func check(_ declarations: [Declaration]) throws {
        // First pass: register all type definitions
        for decl in declarations {
            registerDeclaration(decl)
        }

        // Second pass: type check all declarations
        for decl in declarations {
            checkDeclaration(decl)
        }

        if !diagnostics.isEmpty {
            throw TypeCheckError(diagnostics)
        }
    }

    // MARK: - First Pass: Registration

    private func registerDeclaration(_ decl: Declaration) {
        switch decl.kind {
        case .function(let name, let parameters, let returnType, _):
            registerFunction(name: name, parameters: parameters, returnType: returnType)
        case .structDecl(let name, let fields):
            registerStruct(name: name, fields: fields)
        case .enumDecl(let name, let cases):
            registerEnum(name: name, cases: cases)
        }
    }

    private func registerFunction(name: String, parameters: [Parameter], returnType: TypeAnnotation?) {
        let paramTypes = parameters.map { resolveType($0.type) }
        let retType = returnType.map { resolveType($0) } ?? .void
        let funcType = SlangType.function(params: paramTypes, returnType: retType)
        environment.defineFunction(name, type: funcType)
    }

    private func registerStruct(name: String, fields: [StructField]) {
        var fieldMap: [String: SlangType] = [:]
        for field in fields {
            fieldMap[field.name] = resolveType(field.type)
        }
        let info = StructTypeInfo(name: name, fields: fieldMap)
        environment.defineStructType(info)
    }

    private func registerEnum(name: String, cases: [EnumCase]) {
        let caseNames = Set(cases.map { $0.name })
        let info = EnumTypeInfo(name: name, cases: caseNames)
        environment.defineEnumType(info)
    }

    // MARK: - Type Resolution

    private func resolveType(_ annotation: TypeAnnotation) -> SlangType {
        // First check if it's a built-in type using the enum
        if let builtin = annotation.asBuiltin {
            return SlangType.from(builtin: builtin)
        }

        // Check for user-defined types
        if environment.lookupStructType(annotation.name) != nil {
            return .structType(name: annotation.name)
        }
        if environment.lookupEnumType(annotation.name) != nil {
            return .enumType(name: annotation.name)
        }

        error("Unknown type '\(annotation.name)'", at: annotation.range)
        return .error
    }

    // MARK: - Error Reporting

    private func error(_ message: String, at range: SourceRange) {
        diagnostics.append(Diagnostic.error(message, at: range))
    }
}
```

---

## Step 4: TypeChecker.swift - Declaration Checking

```swift
// MARK: - Declaration Checking

extension TypeChecker {
    private func checkDeclaration(_ decl: Declaration) {
        switch decl.kind {
        case .function(let name, let parameters, let returnType, let body):
            checkFunction(name: name, parameters: parameters, returnType: returnType, body: body, range: decl.range)
        case .structDecl(let name, let fields):
            checkStruct(name: name, fields: fields)
        case .enumDecl(let name, let cases):
            checkEnum(name: name, cases: cases)
        }
    }

    private func checkFunction(name: String, parameters: [Parameter], returnType: TypeAnnotation?, body: Statement, range: SourceRange) {
        // Create new scope for function body
        let funcEnv = environment.createChild()
        let savedEnv = environment
        environment = funcEnv

        // Add parameters to scope
        for param in parameters {
            let paramType = resolveType(param.type)
            environment.defineVariable(param.name, type: paramType)
        }

        // Track return type for return statement checking
        let retType = returnType.map { resolveType($0) } ?? .void
        currentFunctionReturnType = retType

        // Check body
        checkStatement(body)

        // Verify that non-void functions have a return path
        if retType != .void && !hasReturn(body) {
            error("Function '\(name)' must return a value of type '\(retType)'", at: range)
        }

        currentFunctionReturnType = nil
        environment = savedEnv
    }

    private func hasReturn(_ stmt: Statement) -> Bool {
        switch stmt.kind {
        case .block(let statements):
            for s in statements {
                if hasReturn(s) { return true }
            }
            return false
        case .returnStmt:
            return true
        case .ifStmt(_, let thenBranch, let elseBranch):
            guard hasReturn(thenBranch) else { return false }
            guard let elseB = elseBranch else { return false }
            return hasReturn(elseB)
        default:
            return false
        }
    }

    private func checkStruct(name: String, fields: [StructField]) {
        // Check for duplicate field names
        var seenFields = Set<String>()
        for field in fields {
            if seenFields.contains(field.name) {
                error("Duplicate field '\(field.name)' in struct '\(name)'", at: field.range)
            }
            seenFields.insert(field.name)

            // Verify field type exists
            _ = resolveType(field.type)
        }
    }

    private func checkEnum(name: String, cases: [EnumCase]) {
        // Check for duplicate case names
        var seenCases = Set<String>()
        for enumCase in cases {
            if seenCases.contains(enumCase.name) {
                error("Duplicate case '\(enumCase.name)' in enum '\(name)'", at: enumCase.range)
            }
            seenCases.insert(enumCase.name)
        }
    }
}
```

---

## Step 5: TypeChecker.swift - Statement Checking

```swift
// MARK: - Statement Checking

extension TypeChecker {
    private func checkStatement(_ stmt: Statement) {
        switch stmt.kind {
        case .block(let statements):
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            for s in statements {
                checkStatement(s)
            }
            environment = savedEnv

        case .varDecl(let name, let type, let initializer):
            checkVarDecl(name: name, type: type, initializer: initializer, range: stmt.range)

        case .expression(let expr):
            _ = checkExpression(expr)

        case .returnStmt(let value):
            checkReturn(value: value, range: stmt.range)

        case .ifStmt(let condition, let thenBranch, let elseBranch):
            checkIf(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)

        case .forStmt(let initializer, let condition, let increment, let body):
            checkFor(initializer: initializer, condition: condition, increment: increment, body: body)

        case .switchStmt(let subject, let cases):
            checkSwitch(subject: subject, cases: cases, range: stmt.range)
        }
    }

    private func checkVarDecl(name: String, type: TypeAnnotation, initializer: Expression, range: SourceRange) {
        let declaredType = resolveType(type)
        let initType = checkExpression(initializer)

        if declaredType != .error && initType != .error && declaredType != initType {
            error("Cannot assign value of type '\(initType)' to variable of type '\(declaredType)'", at: range)
        }

        environment.defineVariable(name, type: declaredType)
    }

    private func checkReturn(value: Expression?, range: SourceRange) {
        guard let expectedType = currentFunctionReturnType else {
            error("Return statement outside of function", at: range)
            return
        }

        if let val = value {
            let valueType = checkExpression(val)
            if valueType != .error && expectedType != .error && valueType != expectedType {
                error("Cannot return value of type '\(valueType)' from function expecting '\(expectedType)'", at: range)
            }
        } else if expectedType != .void {
            error("Non-void function must return a value", at: range)
        }
    }

    private func checkIf(condition: Expression, thenBranch: Statement, elseBranch: Statement?) {
        let condType = checkExpression(condition)
        if condType != .error && condType != .bool {
            error("Condition must be of type 'Bool', got '\(condType)'", at: condition.range)
        }

        let childEnv = environment.createChild()
        let savedEnv = environment
        environment = childEnv
        checkStatement(thenBranch)
        environment = savedEnv

        if let elseB = elseBranch {
            let elseEnv = environment.createChild()
            environment = elseEnv
            checkStatement(elseB)
            environment = savedEnv
        }
    }

    private func checkFor(initializer: Statement?, condition: Expression?, increment: Expression?, body: Statement) {
        let forEnv = environment.createChild()
        let savedEnv = environment
        environment = forEnv

        if let initStmt = initializer {
            checkStatement(initStmt)
        }

        if let cond = condition {
            let condType = checkExpression(cond)
            if condType != .error && condType != .bool {
                error("For loop condition must be of type 'Bool', got '\(condType)'", at: cond.range)
            }
        }

        if let incr = increment {
            _ = checkExpression(incr)
        }

        checkStatement(body)

        environment = savedEnv
    }

    private func checkSwitch(subject: Expression, cases: [SwitchCase], range: SourceRange) {
        let subjectType = checkExpression(subject)

        // For enum types, check exhaustiveness
        if case .enumType(let enumName) = subjectType {
            guard let enumInfo = environment.lookupEnumType(enumName) else {
                error("Unknown enum type '\(enumName)'", at: subject.range)
                return
            }

            var coveredCases = Set<String>()

            for switchCase in cases {
                // Pattern should be EnumName.caseName (MemberAccessExpr)
                if case .memberAccess(let object, let member) = switchCase.pattern.kind,
                   case .identifier(let identName) = object.kind {
                    if identName != enumName {
                        error("Expected case of enum '\(enumName)', got '\(identName)'", at: switchCase.pattern.range)
                    } else if !enumInfo.cases.contains(member) {
                        error("'\(member)' is not a case of enum '\(enumName)'", at: switchCase.pattern.range)
                    } else {
                        if coveredCases.contains(member) {
                            error("Duplicate case '\(member)' in switch", at: switchCase.pattern.range)
                        }
                        coveredCases.insert(member)
                    }
                } else {
                    error("Invalid switch pattern for enum", at: switchCase.pattern.range)
                }

                // Check the body
                checkStatement(switchCase.body)
            }

            // Check exhaustiveness
            let missingCases = enumInfo.cases.subtracting(coveredCases)
            if !missingCases.isEmpty {
                let missing = missingCases.sorted().joined(separator: ", ")
                error("Switch must be exhaustive. Missing cases: \(missing)", at: range)
            }
        } else if subjectType != .error {
            error("Switch subject must be an enum type, got '\(subjectType)'", at: subject.range)
        }
    }
}
```

---

## Step 6: TypeChecker.swift - Expression Checking

```swift
// MARK: - Expression Checking

extension TypeChecker {
    @discardableResult
    private func checkExpression(_ expr: Expression) -> SlangType {
        switch expr.kind {
        case .intLiteral:
            return .int

        case .floatLiteral:
            return .float

        case .stringLiteral:
            return .string

        case .boolLiteral:
            return .bool

        case .stringInterpolation(let parts):
            return checkStringInterpolation(parts: parts)

        case .identifier(let name):
            return checkIdentifier(name: name, range: expr.range)

        case .binary(let left, let op, let right):
            return checkBinary(left: left, op: op, right: right, range: expr.range)

        case .unary(let op, let operand):
            return checkUnary(op: op, operand: operand, range: expr.range)

        case .call(let callee, let arguments):
            return checkCall(callee: callee, arguments: arguments, range: expr.range)

        case .memberAccess(let object, let member):
            return checkMemberAccess(object: object, member: member, range: expr.range)

        case .structInit(let typeName, let fields):
            return checkStructInit(typeName: typeName, fields: fields, range: expr.range)
        }
    }

    private func checkStringInterpolation(parts: [StringPart]) -> SlangType {
        for part in parts {
            if case .interpolation(let subExpr) = part {
                // Any type can be interpolated (will be converted to string at runtime)
                _ = checkExpression(subExpr)
            }
        }
        return .string
    }

    private func checkIdentifier(name: String, range: SourceRange) -> SlangType {
        if let type = environment.lookupVariable(name) {
            return type
        }
        if let type = environment.lookupFunction(name) {
            return type
        }
        // Check if it's an enum type name (for qualified enum access)
        if environment.lookupEnumType(name) != nil {
            return .enumType(name: name)
        }
        error("Undefined variable '\(name)'", at: range)
        return .error
    }

    private func checkBinary(left: Expression, op: BinaryOperator, right: Expression, range: SourceRange) -> SlangType {
        let leftType = checkExpression(left)
        let rightType = checkExpression(right)

        if leftType == .error || rightType == .error {
            return .error
        }

        switch op {
        // Arithmetic operators
        case .add, .subtract, .multiply, .divide, .modulo:
            if leftType == .int && rightType == .int {
                return .int
            }
            if leftType.isNumeric && rightType.isNumeric {
                return .float
            }
            // String concatenation
            if op == .add && leftType == .string && rightType == .string {
                return .string
            }
            error("Cannot apply '\(op.rawValue)' to '\(leftType)' and '\(rightType)'", at: range)
            return .error

        // Comparison operators
        case .equal, .notEqual:
            if leftType != rightType {
                error("Cannot compare '\(leftType)' and '\(rightType)'", at: range)
                return .error
            }
            return .bool

        case .less, .lessEqual, .greater, .greaterEqual:
            if !leftType.isNumeric || !rightType.isNumeric {
                error("Comparison operators require numeric types, got '\(leftType)' and '\(rightType)'", at: range)
                return .error
            }
            return .bool

        // Logical operators
        case .and, .or:
            if leftType != .bool || rightType != .bool {
                error("Logical operators require Bool operands, got '\(leftType)' and '\(rightType)'", at: range)
                return .error
            }
            return .bool

        // Assignment operators
        case .assign:
            if leftType != rightType {
                error("Cannot assign '\(rightType)' to '\(leftType)'", at: range)
                return .error
            }
            return leftType

        case .addAssign, .subtractAssign, .multiplyAssign, .divideAssign:
            if !leftType.isNumeric || !rightType.isNumeric {
                error("Compound assignment requires numeric types", at: range)
                return .error
            }
            if leftType != rightType {
                error("Cannot apply '\(op.rawValue)' to '\(leftType)' and '\(rightType)'", at: range)
                return .error
            }
            return leftType
        }
    }

    private func checkUnary(op: UnaryOperator, operand: Expression, range: SourceRange) -> SlangType {
        let operandType = checkExpression(operand)

        if operandType == .error {
            return .error
        }

        switch op {
        case .negate:
            if !operandType.isNumeric {
                error("Cannot negate non-numeric type '\(operandType)'", at: range)
                return .error
            }
            return operandType

        case .not:
            if operandType != .bool {
                error("Cannot apply '!' to non-Bool type '\(operandType)'", at: range)
                return .error
            }
            return .bool
        }
    }

    private func checkCall(callee: Expression, arguments: [Expression], range: SourceRange) -> SlangType {
        let calleeType = checkExpression(callee)

        guard case .function(let paramTypes, let returnType) = calleeType else {
            if calleeType != .error {
                error("Cannot call non-function type '\(calleeType)'", at: callee.range)
            }
            return .error
        }

        if arguments.count != paramTypes.count {
            error("Expected \(paramTypes.count) argument(s), got \(arguments.count)", at: range)
            return .error
        }

        for (arg, expectedType) in zip(arguments, paramTypes) {
            let argType = checkExpression(arg)
            if argType != .error && expectedType != .error && argType != expectedType {
                error("Argument type '\(argType)' does not match parameter type '\(expectedType)'", at: arg.range)
            }
        }

        return returnType
    }

    private func checkMemberAccess(object: Expression, member: String, range: SourceRange) -> SlangType {
        let objectType = checkExpression(object)

        if objectType == .error {
            return .error
        }

        // Enum case access: Direction.up
        if case .enumType(let enumName) = objectType {
            guard let enumInfo = environment.lookupEnumType(enumName) else {
                error("Unknown enum type '\(enumName)'", at: object.range)
                return .error
            }
            if !enumInfo.cases.contains(member) {
                error("'\(member)' is not a case of enum '\(enumName)'", at: range)
                return .error
            }
            return .enumType(name: enumName)
        }

        // Struct field access: point.x
        if case .structType(let structName) = objectType {
            guard let structInfo = environment.lookupStructType(structName) else {
                error("Unknown struct type '\(structName)'", at: object.range)
                return .error
            }
            guard let fieldType = structInfo.fields[member] else {
                error("Struct '\(structName)' has no field '\(member)'", at: range)
                return .error
            }
            return fieldType
        }

        error("Cannot access member '\(member)' on type '\(objectType)'", at: range)
        return .error
    }

    private func checkStructInit(typeName: String, fields: [FieldInit], range: SourceRange) -> SlangType {
        guard let structInfo = environment.lookupStructType(typeName) else {
            error("Unknown struct type '\(typeName)'", at: range)
            return .error
        }

        var providedFields = Set<String>()

        for field in fields {
            if providedFields.contains(field.name) {
                error("Duplicate field '\(field.name)' in struct initialization", at: field.range)
                continue
            }
            providedFields.insert(field.name)

            guard let expectedType = structInfo.fields[field.name] else {
                error("Struct '\(typeName)' has no field '\(field.name)'", at: field.range)
                continue
            }

            let valueType = checkExpression(field.value)
            if valueType != .error && expectedType != .error && valueType != expectedType {
                error("Field '\(field.name)' expects '\(expectedType)', got '\(valueType)'", at: field.range)
            }
        }

        // Check for missing fields
        let missingFields = Set(structInfo.fields.keys).subtracting(providedFields)
        if !missingFields.isEmpty {
            let missing = missingFields.sorted().joined(separator: ", ")
            error("Missing fields in struct initialization: \(missing)", at: range)
        }

        return .structType(name: typeName)
    }
}
```

---

## Test Cases

### Test 1: Type Mismatch

**Input:**
```slang
func main() {
    var x: Int = "hello"
}
```

**Expected Error:**
```
error: Cannot assign value of type 'String' to variable of type 'Int'
```

### Test 2: Undefined Variable

**Input:**
```slang
func main() {
    print(x)
}
```

**Expected Error:**
```
error: Undefined variable 'x'
```

### Test 3: Wrong Argument Type

**Input:**
```slang
func add(a: Int, b: Int) -> Int {
    return a + b
}

func main() {
    add("hello", 5)
}
```

**Expected Error:**
```
error: Argument type 'String' does not match parameter type 'Int'
```

### Test 4: Non-Bool Condition

**Input:**
```slang
func main() {
    if (42) {
        print("wrong")
    }
}
```

**Expected Error:**
```
error: Condition must be of type 'Bool', got 'Int'
```

### Test 5: Non-Exhaustive Switch

**Input:**
```slang
enum Direction {
    case up
    case down
    case left
    case right
}

func main() {
    var d: Direction = Direction.up
    switch (d) {
        Direction.up -> print("up")
        Direction.down -> print("down")
    }
}
```

**Expected Error:**
```
error: Switch must be exhaustive. Missing cases: left, right
```

### Test 6: Unknown Field

**Input:**
```slang
struct Point {
    x: Int
    y: Int
}

func main() {
    var p = Point { x: 1, y: 2 }
    print(p.z)
}
```

**Expected Error:**
```
error: Struct 'Point' has no field 'z'
```

### Test 7: Valid Program (No Errors)

**Input:**
```slang
struct Point {
    x: Int
    y: Int
}

func add(a: Int, b: Int) -> Int {
    return a + b
}

func main() {
    var p = Point { x: 3, y: 4 }
    var sum: Int = add(p.x, p.y)
    if (sum > 0) {
        print("Positive")
    }
}
```

**Expected:** No errors

---

## Acceptance Criteria

- [x] Type.swift created with all type representations
- [x] TypeChecker.swift created and handles:
  - [x] Built-in types (Int, Float, String, Bool, Void)
  - [x] User-defined struct types
  - [x] User-defined enum types
  - [x] Function types
  - [x] Variable declarations with type checking
  - [x] Return type checking
  - [x] If condition must be Bool
  - [x] For condition must be Bool
  - [x] Switch exhaustiveness for enums
  - [x] Operator type checking
  - [x] Function call argument type checking
  - [x] Struct field access type checking
  - [x] Struct initialization type checking
- [x] Uses `expr.kind` and `stmt.kind` pattern matching
- [x] Accesses `expr.range` directly for error reporting
- [x] Error type prevents cascading errors
- [x] Good error messages with source locations
- [x] All test cases pass
- [x] `swift build` succeeds

---

## Next Phase

Once this phase is complete, proceed to [Phase 4: Interpreter](phase-4-interpreter.md).
