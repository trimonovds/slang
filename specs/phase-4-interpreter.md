# Phase 4: Tree-Walking Interpreter

## Overview

The interpreter executes type-checked programs by walking the AST and evaluating each node. This is a straightforward "tree-walking" interpreter.

**Input:** Type-checked AST (Array of `Declaration`)
**Output:** Program execution (side effects like printing)

---

## Prerequisites

- Phase 1 (Lexer) complete
- Phase 2 (Parser & AST) complete
- Phase 3 (Type Checker) complete

---

## Files to Create

| File | Purpose |
|------|---------|
| `Sources/SlangCore/Interpreter/Value.swift` | Runtime value representation |
| `Sources/SlangCore/Interpreter/Environment.swift` | Variable storage and scoping |
| `Sources/SlangCore/Interpreter/Interpreter.swift` | Main execution logic |

---

## Step 1: Value.swift - Runtime Values

```swift
// Sources/SlangCore/Interpreter/Value.swift

import Foundation

/// Runtime values in Slang
public indirect enum Value: Equatable, CustomStringConvertible {
    case int(Int)
    case float(Double)
    case string(String)
    case bool(Bool)
    case void
    case structInstance(typeName: String, fields: [String: Value])
    case enumCase(typeName: String, caseName: String)

    public var description: String {
        switch self {
        case .int(let n): return String(n)
        case .float(let f): return String(f)
        case .string(let s): return s
        case .bool(let b): return b ? "true" : "false"
        case .void: return "()"
        case .structInstance(let name, let fields):
            let fieldStrs = fields.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")
            return "\(name) { \(fieldStrs) }"
        case .enumCase(let typeName, let caseName):
            return "\(typeName).\(caseName)"
        }
    }

    /// Convert value to string for printing/interpolation
    public func stringify() -> String {
        description
    }
}
```

---

## Step 2: Environment.swift - Runtime Environment

```swift
// Sources/SlangCore/Interpreter/Environment.swift

import Foundation

/// Runtime environment for storing variables
public class RuntimeEnvironment {
    private var values: [String: Value] = [:]
    private let parent: RuntimeEnvironment?

    public init(parent: RuntimeEnvironment? = nil) {
        self.parent = parent
    }

    /// Define a new variable in the current scope
    public func define(_ name: String, value: Value) {
        values[name] = value
    }

    /// Get a variable's value, searching up the scope chain
    public func get(_ name: String) -> Value? {
        if let value = values[name] {
            return value
        }
        return parent?.get(name)
    }

    /// Assign to an existing variable
    public func assign(_ name: String, value: Value) -> Bool {
        if values[name] != nil {
            values[name] = value
            return true
        }
        if let parent = parent {
            return parent.assign(name, value: value)
        }
        return false
    }

    /// Create a child environment for a new scope
    public func createChild() -> RuntimeEnvironment {
        RuntimeEnvironment(parent: self)
    }
}
```

---

## Step 3: Interpreter.swift - Error Types

```swift
// Sources/SlangCore/Interpreter/Interpreter.swift

import Foundation

/// Error thrown during interpretation
public struct RuntimeError: Error, CustomStringConvertible {
    public let message: String
    public let range: SourceRange?

    public init(_ message: String, at range: SourceRange? = nil) {
        self.message = message
        self.range = range
    }

    public var description: String {
        if let range = range {
            return "Runtime error at \(range.start): \(message)"
        }
        return "Runtime error: \(message)"
    }
}

/// Used to implement return statements via exception
struct ReturnValue: Error {
    let value: Value
}
```

---

## Step 4: Interpreter.swift - Main Class

```swift
/// Tree-walking interpreter for Slang
public class Interpreter {
    private var globalEnv: RuntimeEnvironment
    private var environment: RuntimeEnvironment

    // Stored declarations for function lookup
    private var functions: [String: FunctionDecl] = [:]
    private var structs: [String: StructDecl] = [:]
    private var enums: [String: EnumDecl] = [:]

    public init() {
        self.globalEnv = RuntimeEnvironment()
        self.environment = globalEnv
    }

    // MARK: - Public API

    /// Interpret a program (list of declarations)
    public func interpret(_ declarations: [Declaration]) throws {
        // First pass: collect all declarations
        for decl in declarations {
            collectDeclaration(decl)
        }

        // Find and call main()
        guard let main = functions["main"] else {
            throw RuntimeError("No main() function found")
        }

        _ = try executeFunction(main, arguments: [])
    }

    // MARK: - Declaration Collection

    private func collectDeclaration(_ decl: Declaration) {
        switch decl {
        case let funcDecl as FunctionDecl:
            functions[funcDecl.name] = funcDecl
        case let structDecl as StructDecl:
            structs[structDecl.name] = structDecl
        case let enumDecl as EnumDecl:
            enums[enumDecl.name] = enumDecl
        default:
            break
        }
    }

    // MARK: - Function Execution

    private func executeFunction(_ decl: FunctionDecl, arguments: [Value]) throws -> Value {
        // Create new environment for function scope
        let funcEnv = globalEnv.createChild()

        // Bind parameters to arguments
        for (param, arg) in zip(decl.parameters, arguments) {
            funcEnv.define(param.name, value: arg)
        }

        // Execute body
        let savedEnv = environment
        environment = funcEnv

        do {
            try executeBlock(decl.body)
            environment = savedEnv
            return .void
        } catch let returnValue as ReturnValue {
            environment = savedEnv
            return returnValue.value
        } catch {
            environment = savedEnv
            throw error
        }
    }
}
```

---

## Step 5: Interpreter.swift - Statement Execution

```swift
// MARK: - Statement Execution

extension Interpreter {
    private func executeBlock(_ block: BlockStmt) throws {
        for stmt in block.statements {
            try executeStatement(stmt)
        }
    }

    private func executeStatement(_ stmt: Statement) throws {
        switch stmt {
        case let varDecl as VarDeclStmt:
            try executeVarDecl(varDecl)
        case let exprStmt as ExpressionStmt:
            _ = try evaluate(exprStmt.expression)
        case let returnStmt as ReturnStmt:
            try executeReturn(returnStmt)
        case let ifStmt as IfStmt:
            try executeIf(ifStmt)
        case let forStmt as ForStmt:
            try executeFor(forStmt)
        case let switchStmt as SwitchStmt:
            try executeSwitch(switchStmt)
        case let blockStmt as BlockStmt:
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            try executeBlock(blockStmt)
            environment = savedEnv
        default:
            throw RuntimeError("Unknown statement type", at: stmt.range)
        }
    }

    private func executeVarDecl(_ stmt: VarDeclStmt) throws {
        let value = try evaluate(stmt.initializer)
        environment.define(stmt.name, value: value)
    }

    private func executeReturn(_ stmt: ReturnStmt) throws {
        let value: Value
        if let expr = stmt.value {
            value = try evaluate(expr)
        } else {
            value = .void
        }
        throw ReturnValue(value: value)
    }

    private func executeIf(_ stmt: IfStmt) throws {
        let condition = try evaluate(stmt.condition)

        guard case .bool(let condValue) = condition else {
            throw RuntimeError("If condition must be Bool", at: stmt.condition.range)
        }

        if condValue {
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            try executeBlock(stmt.thenBranch)
            environment = savedEnv
        } else if let elseBranch = stmt.elseBranch {
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            try executeStatement(elseBranch)
            environment = savedEnv
        }
    }

    private func executeFor(_ stmt: ForStmt) throws {
        let forEnv = environment.createChild()
        let savedEnv = environment
        environment = forEnv

        // Initializer
        if let initializer = stmt.initializer {
            try executeVarDecl(initializer)
        }

        // Loop
        while true {
            // Check condition
            if let condition = stmt.condition {
                let condValue = try evaluate(condition)
                guard case .bool(let cont) = condValue else {
                    throw RuntimeError("For condition must be Bool", at: condition.range)
                }
                if !cont { break }
            }

            // Execute body
            let bodyEnv = environment.createChild()
            let savedBodyEnv = environment
            environment = bodyEnv
            try executeBlock(stmt.body)
            environment = savedBodyEnv

            // Increment
            if let increment = stmt.increment {
                _ = try evaluate(increment)
            }
        }

        environment = savedEnv
    }

    private func executeSwitch(_ stmt: SwitchStmt) throws {
        let subject = try evaluate(stmt.subject)

        for switchCase in stmt.cases {
            let pattern = try evaluate(switchCase.pattern)

            if subject == pattern {
                try executeStatement(switchCase.body)
                return
            }
        }

        // Should not reach here if type checker verified exhaustiveness
        throw RuntimeError("No matching case in switch", at: stmt.range)
    }
}
```

---

## Step 6: Interpreter.swift - Expression Evaluation

```swift
// MARK: - Expression Evaluation

extension Interpreter {
    private func evaluate(_ expr: Expression) throws -> Value {
        switch expr {
        case let intLit as IntLiteralExpr:
            return .int(intLit.value)

        case let floatLit as FloatLiteralExpr:
            return .float(floatLit.value)

        case let stringLit as StringLiteralExpr:
            return .string(stringLit.value)

        case let boolLit as BoolLiteralExpr:
            return .bool(boolLit.value)

        case let stringInterp as StringInterpolationExpr:
            return try evaluateStringInterpolation(stringInterp)

        case let ident as IdentifierExpr:
            return try evaluateIdentifier(ident)

        case let binary as BinaryExpr:
            return try evaluateBinary(binary)

        case let unary as UnaryExpr:
            return try evaluateUnary(unary)

        case let call as CallExpr:
            return try evaluateCall(call)

        case let member as MemberAccessExpr:
            return try evaluateMemberAccess(member)

        case let structInit as StructInitExpr:
            return try evaluateStructInit(structInit)

        default:
            throw RuntimeError("Unknown expression type", at: expr.range)
        }
    }

    private func evaluateStringInterpolation(_ expr: StringInterpolationExpr) throws -> Value {
        var result = ""
        for part in expr.parts {
            switch part {
            case .literal(let str):
                result += str
            case .interpolation(let subExpr):
                let value = try evaluate(subExpr)
                result += value.stringify()
            }
        }
        return .string(result)
    }

    private func evaluateIdentifier(_ expr: IdentifierExpr) throws -> Value {
        // Check for variable
        if let value = environment.get(expr.name) {
            return value
        }

        // Check for enum type (used in switch patterns like Direction.up)
        if enums[expr.name] != nil {
            // Return a placeholder - actual case will be accessed via member access
            return .enumCase(typeName: expr.name, caseName: "")
        }

        throw RuntimeError("Undefined variable '\(expr.name)'", at: expr.range)
    }

    private func evaluateBinary(_ expr: BinaryExpr) throws -> Value {
        // Handle assignment specially (don't evaluate left side as value)
        switch expr.op {
        case .assign, .addAssign, .subtractAssign, .multiplyAssign, .divideAssign:
            return try evaluateAssignment(expr)
        default:
            break
        }

        let left = try evaluate(expr.left)
        let right = try evaluate(expr.right)

        switch expr.op {
        // Arithmetic
        case .add:
            if case .int(let l) = left, case .int(let r) = right {
                return .int(l + r)
            }
            if case .float(let l) = left, case .float(let r) = right {
                return .float(l + r)
            }
            if case .string(let l) = left, case .string(let r) = right {
                return .string(l + r)
            }
            throw RuntimeError("Cannot add \(left) and \(right)", at: expr.range)

        case .subtract:
            if case .int(let l) = left, case .int(let r) = right {
                return .int(l - r)
            }
            if case .float(let l) = left, case .float(let r) = right {
                return .float(l - r)
            }
            throw RuntimeError("Cannot subtract \(left) and \(right)", at: expr.range)

        case .multiply:
            if case .int(let l) = left, case .int(let r) = right {
                return .int(l * r)
            }
            if case .float(let l) = left, case .float(let r) = right {
                return .float(l * r)
            }
            throw RuntimeError("Cannot multiply \(left) and \(right)", at: expr.range)

        case .divide:
            if case .int(let l) = left, case .int(let r) = right {
                if r == 0 { throw RuntimeError("Division by zero", at: expr.range) }
                return .int(l / r)
            }
            if case .float(let l) = left, case .float(let r) = right {
                return .float(l / r)
            }
            throw RuntimeError("Cannot divide \(left) and \(right)", at: expr.range)

        case .modulo:
            if case .int(let l) = left, case .int(let r) = right {
                if r == 0 { throw RuntimeError("Modulo by zero", at: expr.range) }
                return .int(l % r)
            }
            throw RuntimeError("Cannot modulo \(left) and \(right)", at: expr.range)

        // Comparison
        case .equal:
            return .bool(left == right)

        case .notEqual:
            return .bool(left != right)

        case .less:
            if case .int(let l) = left, case .int(let r) = right {
                return .bool(l < r)
            }
            if case .float(let l) = left, case .float(let r) = right {
                return .bool(l < r)
            }
            throw RuntimeError("Cannot compare \(left) and \(right)", at: expr.range)

        case .lessEqual:
            if case .int(let l) = left, case .int(let r) = right {
                return .bool(l <= r)
            }
            if case .float(let l) = left, case .float(let r) = right {
                return .bool(l <= r)
            }
            throw RuntimeError("Cannot compare \(left) and \(right)", at: expr.range)

        case .greater:
            if case .int(let l) = left, case .int(let r) = right {
                return .bool(l > r)
            }
            if case .float(let l) = left, case .float(let r) = right {
                return .bool(l > r)
            }
            throw RuntimeError("Cannot compare \(left) and \(right)", at: expr.range)

        case .greaterEqual:
            if case .int(let l) = left, case .int(let r) = right {
                return .bool(l >= r)
            }
            if case .float(let l) = left, case .float(let r) = right {
                return .bool(l >= r)
            }
            throw RuntimeError("Cannot compare \(left) and \(right)", at: expr.range)

        // Logical
        case .and:
            if case .bool(let l) = left, case .bool(let r) = right {
                return .bool(l && r)
            }
            throw RuntimeError("Cannot apply && to \(left) and \(right)", at: expr.range)

        case .or:
            if case .bool(let l) = left, case .bool(let r) = right {
                return .bool(l || r)
            }
            throw RuntimeError("Cannot apply || to \(left) and \(right)", at: expr.range)

        default:
            throw RuntimeError("Unknown binary operator", at: expr.range)
        }
    }

    private func evaluateAssignment(_ expr: BinaryExpr) throws -> Value {
        guard let ident = expr.left as? IdentifierExpr else {
            throw RuntimeError("Invalid assignment target", at: expr.left.range)
        }

        let right = try evaluate(expr.right)
        var newValue = right

        // Compound assignment
        if expr.op != .assign {
            guard let currentValue = environment.get(ident.name) else {
                throw RuntimeError("Undefined variable '\(ident.name)'", at: ident.range)
            }

            switch expr.op {
            case .addAssign:
                if case .int(let l) = currentValue, case .int(let r) = right {
                    newValue = .int(l + r)
                } else {
                    throw RuntimeError("Cannot apply += to \(currentValue) and \(right)", at: expr.range)
                }
            case .subtractAssign:
                if case .int(let l) = currentValue, case .int(let r) = right {
                    newValue = .int(l - r)
                } else {
                    throw RuntimeError("Cannot apply -= to \(currentValue) and \(right)", at: expr.range)
                }
            case .multiplyAssign:
                if case .int(let l) = currentValue, case .int(let r) = right {
                    newValue = .int(l * r)
                } else {
                    throw RuntimeError("Cannot apply *= to \(currentValue) and \(right)", at: expr.range)
                }
            case .divideAssign:
                if case .int(let l) = currentValue, case .int(let r) = right {
                    if r == 0 { throw RuntimeError("Division by zero", at: expr.range) }
                    newValue = .int(l / r)
                } else {
                    throw RuntimeError("Cannot apply /= to \(currentValue) and \(right)", at: expr.range)
                }
            default:
                break
            }
        }

        if !environment.assign(ident.name, value: newValue) {
            throw RuntimeError("Undefined variable '\(ident.name)'", at: ident.range)
        }

        return newValue
    }

    private func evaluateUnary(_ expr: UnaryExpr) throws -> Value {
        let operand = try evaluate(expr.operand)

        switch expr.op {
        case .negate:
            if case .int(let n) = operand {
                return .int(-n)
            }
            if case .float(let f) = operand {
                return .float(-f)
            }
            throw RuntimeError("Cannot negate \(operand)", at: expr.range)

        case .not:
            if case .bool(let b) = operand {
                return .bool(!b)
            }
            throw RuntimeError("Cannot apply ! to \(operand)", at: expr.range)
        }
    }

    private func evaluateCall(_ expr: CallExpr) throws -> Value {
        // Get the function name
        guard let ident = expr.callee as? IdentifierExpr else {
            throw RuntimeError("Invalid call target", at: expr.callee.range)
        }

        // Check for built-in functions
        if ident.name == "print" {
            return try evaluatePrint(expr.arguments)
        }

        // User-defined function
        guard let funcDecl = functions[ident.name] else {
            throw RuntimeError("Undefined function '\(ident.name)'", at: ident.range)
        }

        // Evaluate arguments
        var args: [Value] = []
        for arg in expr.arguments {
            args.append(try evaluate(arg))
        }

        return try executeFunction(funcDecl, arguments: args)
    }

    private func evaluatePrint(_ arguments: [Expression]) throws -> Value {
        guard arguments.count == 1 else {
            throw RuntimeError("print() expects 1 argument, got \(arguments.count)")
        }

        let value = try evaluate(arguments[0])

        // print() only accepts strings
        guard case .string(let str) = value else {
            throw RuntimeError("print() expects String argument, got \(value)")
        }

        print(str)
        return .void
    }

    private func evaluateMemberAccess(_ expr: MemberAccessExpr) throws -> Value {
        let object = try evaluate(expr.object)

        // Enum case access: Direction.up
        if case .enumCase(let typeName, _) = object {
            // Check that the case exists
            guard let enumDecl = enums[typeName] else {
                throw RuntimeError("Unknown enum '\(typeName)'", at: expr.object.range)
            }
            guard enumDecl.cases.contains(where: { $0.name == expr.member }) else {
                throw RuntimeError("Enum '\(typeName)' has no case '\(expr.member)'", at: expr.range)
            }
            return .enumCase(typeName: typeName, caseName: expr.member)
        }

        // Struct field access: point.x
        if case .structInstance(let typeName, let fields) = object {
            guard let value = fields[expr.member] else {
                throw RuntimeError("Struct '\(typeName)' has no field '\(expr.member)'", at: expr.range)
            }
            return value
        }

        throw RuntimeError("Cannot access member '\(expr.member)' on \(object)", at: expr.range)
    }

    private func evaluateStructInit(_ expr: StructInitExpr) throws -> Value {
        guard let structDecl = structs[expr.typeName] else {
            throw RuntimeError("Unknown struct '\(expr.typeName)'", at: expr.range)
        }

        var fields: [String: Value] = [:]

        for field in expr.fields {
            let value = try evaluate(field.value)
            fields[field.name] = value
        }

        // Verify all fields are present
        for structField in structDecl.fields {
            if fields[structField.name] == nil {
                throw RuntimeError("Missing field '\(structField.name)' in struct initialization", at: expr.range)
            }
        }

        return .structInstance(typeName: expr.typeName, fields: fields)
    }
}
```

---

## Test Cases

### Test 1: Hello World

**Input:**
```slang
func main() {
    print("Hello, World!")
}
```

**Expected Output:**
```
Hello, World!
```

### Test 2: Arithmetic

**Input:**
```slang
func main() {
    var x: Int = 10
    var y: Int = 3
    print("\(x + y)")
    print("\(x - y)")
    print("\(x * y)")
    print("\(x / y)")
    print("\(x % y)")
}
```

**Expected Output:**
```
13
7
30
3
1
```

### Test 3: Function Call

**Input:**
```slang
func add(a: Int, b: Int) -> Int {
    return a + b
}

func main() {
    var result: Int = add(5, 3)
    print("\(result)")
}
```

**Expected Output:**
```
8
```

### Test 4: Struct

**Input:**
```slang
struct Point {
    x: Int
    y: Int
}

func main() {
    var p = Point { x: 3, y: 4 }
    print("x = \(p.x), y = \(p.y)")
}
```

**Expected Output:**
```
x = 3, y = 4
```

### Test 5: If/Else

**Input:**
```slang
func main() {
    var x: Int = 10
    if (x > 5) {
        print("big")
    } else {
        print("small")
    }
}
```

**Expected Output:**
```
big
```

### Test 6: For Loop

**Input:**
```slang
func main() {
    for (var i: Int = 0; i < 5; i = i + 1) {
        print("\(i)")
    }
}
```

**Expected Output:**
```
0
1
2
3
4
```

### Test 7: Switch

**Input:**
```slang
enum Color {
    case red
    case green
    case blue
}

func main() {
    var c: Color = Color.green
    switch (c) {
        Color.red -> print("Red!")
        Color.green -> print("Green!")
        Color.blue -> print("Blue!")
    }
}
```

**Expected Output:**
```
Green!
```

### Test 8: Full v0.1 Test Program

**Input:** (The v0.1 test program from roadmap)

**Expected Output:**
```
Point at 3, 4
Sum: 7
Going up!
0
1
2
3
4
First quadrant
```

---

## Acceptance Criteria

- [ ] Value.swift created with all value types
- [ ] Environment.swift created with scoping
- [ ] Interpreter.swift created and handles:
  - [ ] Function declarations and calls
  - [ ] Variable declarations and access
  - [ ] Struct initialization and field access
  - [ ] Enum case creation and comparison
  - [ ] All arithmetic operators
  - [ ] All comparison operators
  - [ ] All logical operators
  - [ ] Assignment and compound assignment
  - [ ] String interpolation
  - [ ] If/else statements
  - [ ] For loops
  - [ ] Switch statements
  - [ ] Return statements
  - [ ] Built-in print() function
- [ ] Proper scoping (local variables don't leak)
- [ ] All test cases pass
- [ ] `swift build` succeeds

---

## Next Phase

Once this phase is complete, proceed to [Phase 5: CLI Polish](phase-5-cli.md).
