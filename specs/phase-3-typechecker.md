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
        switch decl {
        case let funcDecl as FunctionDecl:
            registerFunction(funcDecl)
        case let structDecl as StructDecl:
            registerStruct(structDecl)
        case let enumDecl as EnumDecl:
            registerEnum(enumDecl)
        default:
            break
        }
    }

    private func registerFunction(_ decl: FunctionDecl) {
        let paramTypes = decl.parameters.map { resolveType($0.type) }
        let returnType = decl.returnType.map { resolveType($0) } ?? .void
        let funcType = SlangType.function(params: paramTypes, returnType: returnType)
        environment.defineFunction(decl.name, type: funcType)
    }

    private func registerStruct(_ decl: StructDecl) {
        var fields: [String: SlangType] = [:]
        for field in decl.fields {
            fields[field.name] = resolveType(field.type)
        }
        let info = StructTypeInfo(name: decl.name, fields: fields)
        environment.defineStructType(info)
    }

    private func registerEnum(_ decl: EnumDecl) {
        let cases = Set(decl.cases.map { $0.name })
        let info = EnumTypeInfo(name: decl.name, cases: cases)
        environment.defineEnumType(info)
    }

    // MARK: - Type Resolution

    private func resolveType(_ annotation: TypeAnnotation) -> SlangType {
        switch annotation.name {
        case "Int": return .int
        case "Float": return .float
        case "String": return .string
        case "Bool": return .bool
        case "Void": return .void
        default:
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
        switch decl {
        case let funcDecl as FunctionDecl:
            checkFunction(funcDecl)
        case let structDecl as StructDecl:
            checkStruct(structDecl)
        case let enumDecl as EnumDecl:
            checkEnum(enumDecl)
        default:
            break
        }
    }

    private func checkFunction(_ decl: FunctionDecl) {
        // Create new scope for function body
        let funcEnv = environment.createChild()
        let savedEnv = environment
        environment = funcEnv

        // Add parameters to scope
        for param in decl.parameters {
            let paramType = resolveType(param.type)
            environment.defineVariable(param.name, type: paramType)
        }

        // Track return type for return statement checking
        let returnType = decl.returnType.map { resolveType($0) } ?? .void
        currentFunctionReturnType = returnType

        // Check body
        checkBlock(decl.body)

        // Verify that non-void functions have a return path
        // (simplified: just check if there's at least one return)
        if returnType != .void && !hasReturn(decl.body) {
            error("Function '\(decl.name)' must return a value of type '\(returnType)'", at: decl.range)
        }

        currentFunctionReturnType = nil
        environment = savedEnv
    }

    private func hasReturn(_ block: BlockStmt) -> Bool {
        for stmt in block.statements {
            if stmt is ReturnStmt { return true }
            if let ifStmt = stmt as? IfStmt {
                if hasReturn(ifStmt.thenBranch) {
                    if let elseBranch = ifStmt.elseBranch as? BlockStmt, hasReturn(elseBranch) {
                        return true
                    }
                    if let elseIf = ifStmt.elseBranch as? IfStmt, hasReturnInIf(elseIf) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private func hasReturnInIf(_ stmt: IfStmt) -> Bool {
        guard hasReturn(stmt.thenBranch) else { return false }
        if let elseBranch = stmt.elseBranch as? BlockStmt {
            return hasReturn(elseBranch)
        }
        if let elseIf = stmt.elseBranch as? IfStmt {
            return hasReturnInIf(elseIf)
        }
        return false
    }

    private func checkStruct(_ decl: StructDecl) {
        // Check for duplicate field names
        var seenFields = Set<String>()
        for field in decl.fields {
            if seenFields.contains(field.name) {
                error("Duplicate field '\(field.name)' in struct '\(decl.name)'", at: field.range)
            }
            seenFields.insert(field.name)

            // Verify field type exists
            _ = resolveType(field.type)
        }
    }

    private func checkEnum(_ decl: EnumDecl) {
        // Check for duplicate case names
        var seenCases = Set<String>()
        for enumCase in decl.cases {
            if seenCases.contains(enumCase.name) {
                error("Duplicate case '\(enumCase.name)' in enum '\(decl.name)'", at: enumCase.range)
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
    private func checkBlock(_ block: BlockStmt) {
        for stmt in block.statements {
            checkStatement(stmt)
        }
    }

    private func checkStatement(_ stmt: Statement) {
        switch stmt {
        case let varDecl as VarDeclStmt:
            checkVarDecl(varDecl)
        case let exprStmt as ExpressionStmt:
            _ = checkExpression(exprStmt.expression)
        case let returnStmt as ReturnStmt:
            checkReturn(returnStmt)
        case let ifStmt as IfStmt:
            checkIf(ifStmt)
        case let forStmt as ForStmt:
            checkFor(forStmt)
        case let switchStmt as SwitchStmt:
            checkSwitch(switchStmt)
        case let blockStmt as BlockStmt:
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            checkBlock(blockStmt)
            environment = savedEnv
        default:
            break
        }
    }

    private func checkVarDecl(_ stmt: VarDeclStmt) {
        let declaredType = resolveType(stmt.type)
        let initType = checkExpression(stmt.initializer)

        if declaredType != .error && initType != .error && declaredType != initType {
            error("Cannot assign value of type '\(initType)' to variable of type '\(declaredType)'", at: stmt.range)
        }

        environment.defineVariable(stmt.name, type: declaredType)
    }

    private func checkReturn(_ stmt: ReturnStmt) {
        guard let expectedType = currentFunctionReturnType else {
            error("Return statement outside of function", at: stmt.range)
            return
        }

        if let value = stmt.value {
            let valueType = checkExpression(value)
            if valueType != .error && expectedType != .error && valueType != expectedType {
                error("Cannot return value of type '\(valueType)' from function expecting '\(expectedType)'", at: stmt.range)
            }
        } else if expectedType != .void {
            error("Non-void function must return a value", at: stmt.range)
        }
    }

    private func checkIf(_ stmt: IfStmt) {
        let condType = checkExpression(stmt.condition)
        if condType != .error && condType != .bool {
            error("Condition must be of type 'Bool', got '\(condType)'", at: stmt.condition.range)
        }

        let childEnv = environment.createChild()
        let savedEnv = environment
        environment = childEnv
        checkBlock(stmt.thenBranch)
        environment = savedEnv

        if let elseBranch = stmt.elseBranch {
            let elseEnv = environment.createChild()
            environment = elseEnv
            checkStatement(elseBranch)
            environment = savedEnv
        }
    }

    private func checkFor(_ stmt: ForStmt) {
        let forEnv = environment.createChild()
        let savedEnv = environment
        environment = forEnv

        if let initializer = stmt.initializer {
            checkVarDecl(initializer)
        }

        if let condition = stmt.condition {
            let condType = checkExpression(condition)
            if condType != .error && condType != .bool {
                error("For loop condition must be of type 'Bool', got '\(condType)'", at: condition.range)
            }
        }

        if let increment = stmt.increment {
            _ = checkExpression(increment)
        }

        checkBlock(stmt.body)

        environment = savedEnv
    }

    private func checkSwitch(_ stmt: SwitchStmt) {
        let subjectType = checkExpression(stmt.subject)

        // For enum types, check exhaustiveness
        if case .enumType(let enumName) = subjectType {
            guard let enumInfo = environment.lookupEnumType(enumName) else {
                error("Unknown enum type '\(enumName)'", at: stmt.subject.range)
                return
            }

            var coveredCases = Set<String>()

            for switchCase in stmt.cases {
                // Pattern should be EnumName.caseName (MemberAccessExpr)
                if let memberAccess = switchCase.pattern as? MemberAccessExpr,
                   let enumIdent = memberAccess.object as? IdentifierExpr {
                    if enumIdent.name != enumName {
                        error("Expected case of enum '\(enumName)', got '\(enumIdent.name)'", at: switchCase.pattern.range)
                    } else if !enumInfo.cases.contains(memberAccess.member) {
                        error("'\(memberAccess.member)' is not a case of enum '\(enumName)'", at: switchCase.pattern.range)
                    } else {
                        if coveredCases.contains(memberAccess.member) {
                            error("Duplicate case '\(memberAccess.member)' in switch", at: switchCase.pattern.range)
                        }
                        coveredCases.insert(memberAccess.member)
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
                error("Switch must be exhaustive. Missing cases: \(missing)", at: stmt.range)
            }
        } else if subjectType != .error {
            error("Switch subject must be an enum type, got '\(subjectType)'", at: stmt.subject.range)
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
        switch expr {
        case let intLit as IntLiteralExpr:
            return .int

        case let floatLit as FloatLiteralExpr:
            return .float

        case let stringLit as StringLiteralExpr:
            return .string

        case let boolLit as BoolLiteralExpr:
            return .bool

        case let stringInterp as StringInterpolationExpr:
            return checkStringInterpolation(stringInterp)

        case let ident as IdentifierExpr:
            return checkIdentifier(ident)

        case let binary as BinaryExpr:
            return checkBinary(binary)

        case let unary as UnaryExpr:
            return checkUnary(unary)

        case let call as CallExpr:
            return checkCall(call)

        case let member as MemberAccessExpr:
            return checkMemberAccess(member)

        case let structInit as StructInitExpr:
            return checkStructInit(structInit)

        default:
            error("Unknown expression type", at: expr.range)
            return .error
        }
    }

    private func checkStringInterpolation(_ expr: StringInterpolationExpr) -> SlangType {
        for part in expr.parts {
            if case .interpolation(let subExpr) = part {
                // Any type can be interpolated (will be converted to string at runtime)
                _ = checkExpression(subExpr)
            }
        }
        return .string
    }

    private func checkIdentifier(_ expr: IdentifierExpr) -> SlangType {
        if let type = environment.lookupVariable(expr.name) {
            return type
        }
        if let type = environment.lookupFunction(expr.name) {
            return type
        }
        // Check if it's an enum type name (for qualified enum access)
        if environment.lookupEnumType(expr.name) != nil {
            return .enumType(name: expr.name)
        }
        error("Undefined variable '\(expr.name)'", at: expr.range)
        return .error
    }

    private func checkBinary(_ expr: BinaryExpr) -> SlangType {
        let leftType = checkExpression(expr.left)
        let rightType = checkExpression(expr.right)

        if leftType == .error || rightType == .error {
            return .error
        }

        switch expr.op {
        // Arithmetic operators
        case .add, .subtract, .multiply, .divide, .modulo:
            if leftType == .int && rightType == .int {
                return .int
            }
            if leftType.isNumeric && rightType.isNumeric {
                return .float
            }
            // String concatenation
            if expr.op == .add && leftType == .string && rightType == .string {
                return .string
            }
            error("Cannot apply '\(expr.op.rawValue)' to '\(leftType)' and '\(rightType)'", at: expr.range)
            return .error

        // Comparison operators
        case .equal, .notEqual:
            if leftType != rightType {
                error("Cannot compare '\(leftType)' and '\(rightType)'", at: expr.range)
                return .error
            }
            return .bool

        case .less, .lessEqual, .greater, .greaterEqual:
            if !leftType.isNumeric || !rightType.isNumeric {
                error("Comparison operators require numeric types, got '\(leftType)' and '\(rightType)'", at: expr.range)
                return .error
            }
            return .bool

        // Logical operators
        case .and, .or:
            if leftType != .bool || rightType != .bool {
                error("Logical operators require Bool operands, got '\(leftType)' and '\(rightType)'", at: expr.range)
                return .error
            }
            return .bool

        // Assignment operators
        case .assign:
            if leftType != rightType {
                error("Cannot assign '\(rightType)' to '\(leftType)'", at: expr.range)
                return .error
            }
            return leftType

        case .addAssign, .subtractAssign, .multiplyAssign, .divideAssign:
            if !leftType.isNumeric || !rightType.isNumeric {
                error("Compound assignment requires numeric types", at: expr.range)
                return .error
            }
            if leftType != rightType {
                error("Cannot apply '\(expr.op.rawValue)' to '\(leftType)' and '\(rightType)'", at: expr.range)
                return .error
            }
            return leftType
        }
    }

    private func checkUnary(_ expr: UnaryExpr) -> SlangType {
        let operandType = checkExpression(expr.operand)

        if operandType == .error {
            return .error
        }

        switch expr.op {
        case .negate:
            if !operandType.isNumeric {
                error("Cannot negate non-numeric type '\(operandType)'", at: expr.range)
                return .error
            }
            return operandType

        case .not:
            if operandType != .bool {
                error("Cannot apply '!' to non-Bool type '\(operandType)'", at: expr.range)
                return .error
            }
            return .bool
        }
    }

    private func checkCall(_ expr: CallExpr) -> SlangType {
        let calleeType = checkExpression(expr.callee)

        guard case .function(let paramTypes, let returnType) = calleeType else {
            if calleeType != .error {
                error("Cannot call non-function type '\(calleeType)'", at: expr.callee.range)
            }
            return .error
        }

        if expr.arguments.count != paramTypes.count {
            error("Expected \(paramTypes.count) argument(s), got \(expr.arguments.count)", at: expr.range)
            return .error
        }

        for (arg, expectedType) in zip(expr.arguments, paramTypes) {
            let argType = checkExpression(arg)
            if argType != .error && expectedType != .error && argType != expectedType {
                error("Argument type '\(argType)' does not match parameter type '\(expectedType)'", at: arg.range)
            }
        }

        return returnType
    }

    private func checkMemberAccess(_ expr: MemberAccessExpr) -> SlangType {
        let objectType = checkExpression(expr.object)

        if objectType == .error {
            return .error
        }

        // Enum case access: Direction.up
        if case .enumType(let enumName) = objectType {
            guard let enumInfo = environment.lookupEnumType(enumName) else {
                error("Unknown enum type '\(enumName)'", at: expr.object.range)
                return .error
            }
            if !enumInfo.cases.contains(expr.member) {
                error("'\(expr.member)' is not a case of enum '\(enumName)'", at: expr.range)
                return .error
            }
            return .enumType(name: enumName)
        }

        // Struct field access: point.x
        if case .structType(let structName) = objectType {
            guard let structInfo = environment.lookupStructType(structName) else {
                error("Unknown struct type '\(structName)'", at: expr.object.range)
                return .error
            }
            guard let fieldType = structInfo.fields[expr.member] else {
                error("Struct '\(structName)' has no field '\(expr.member)'", at: expr.range)
                return .error
            }
            return fieldType
        }

        error("Cannot access member '\(expr.member)' on type '\(objectType)'", at: expr.range)
        return .error
    }

    private func checkStructInit(_ expr: StructInitExpr) -> SlangType {
        guard let structInfo = environment.lookupStructType(expr.typeName) else {
            error("Unknown struct type '\(expr.typeName)'", at: expr.range)
            return .error
        }

        var providedFields = Set<String>()

        for field in expr.fields {
            if providedFields.contains(field.name) {
                error("Duplicate field '\(field.name)' in struct initialization", at: field.range)
                continue
            }
            providedFields.insert(field.name)

            guard let expectedType = structInfo.fields[field.name] else {
                error("Struct '\(expr.typeName)' has no field '\(field.name)'", at: field.range)
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
            error("Missing fields in struct initialization: \(missing)", at: expr.range)
        }

        return .structType(name: expr.typeName)
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

- [ ] Type.swift created with all type representations
- [ ] TypeChecker.swift created and handles:
  - [ ] Built-in types (Int, Float, String, Bool, Void)
  - [ ] User-defined struct types
  - [ ] User-defined enum types
  - [ ] Function types
  - [ ] Variable declarations with type checking
  - [ ] Return type checking
  - [ ] If condition must be Bool
  - [ ] For condition must be Bool
  - [ ] Switch exhaustiveness for enums
  - [ ] Operator type checking
  - [ ] Function call argument type checking
  - [ ] Struct field access type checking
  - [ ] Struct initialization type checking
- [ ] Error type prevents cascading errors
- [ ] Good error messages with source locations
- [ ] All test cases pass
- [ ] `swift build` succeeds

---

## Next Phase

Once this phase is complete, proceed to [Phase 4: Interpreter](phase-4-interpreter.md).
