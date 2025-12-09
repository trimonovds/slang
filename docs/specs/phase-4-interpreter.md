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
    private var functions: [String: Declaration] = [:]
    private var structs: [String: Declaration] = [:]
    private var enums: [String: Declaration] = [:]

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
        guard let mainDecl = functions["main"],
              case .function(_, let parameters, _, let body) = mainDecl.kind,
              parameters.isEmpty else {
            throw RuntimeError("No main() function found")
        }

        _ = try executeFunction(parameters: [], body: body, arguments: [])
    }

    // MARK: - Declaration Collection

    private func collectDeclaration(_ decl: Declaration) {
        switch decl.kind {
        case .function(let name, _, _, _):
            functions[name] = decl
        case .structDecl(let name, _):
            structs[name] = decl
        case .enumDecl(let name, _):
            enums[name] = decl
        }
    }

    // MARK: - Function Execution

    private func executeFunction(parameters: [Parameter], body: Statement, arguments: [Value]) throws -> Value {
        // Create new environment for function scope
        let funcEnv = globalEnv.createChild()

        // Bind parameters to arguments
        for (param, arg) in zip(parameters, arguments) {
            funcEnv.define(param.name, value: arg)
        }

        // Execute body
        let savedEnv = environment
        environment = funcEnv

        do {
            try executeStatement(body)
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
    private func executeStatement(_ stmt: Statement) throws {
        switch stmt.kind {
        case .block(let statements):
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            for s in statements {
                try executeStatement(s)
            }
            environment = savedEnv

        case .varDecl(let name, _, let initializer):
            let value = try evaluate(initializer)
            environment.define(name, value: value)

        case .expression(let expr):
            _ = try evaluate(expr)

        case .returnStmt(let value):
            let retValue: Value
            if let val = value {
                retValue = try evaluate(val)
            } else {
                retValue = .void
            }
            throw ReturnValue(value: retValue)

        case .ifStmt(let condition, let thenBranch, let elseBranch):
            try executeIf(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)

        case .forStmt(let initializer, let condition, let increment, let body):
            try executeFor(initializer: initializer, condition: condition, increment: increment, body: body)

        case .switchStmt(let subject, let cases):
            try executeSwitch(subject: subject, cases: cases, range: stmt.range)
        }
    }

    private func executeIf(condition: Expression, thenBranch: Statement, elseBranch: Statement?) throws {
        let condValue = try evaluate(condition)

        guard case .bool(let cond) = condValue else {
            throw RuntimeError("If condition must be Bool", at: condition.range)
        }

        if cond {
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            try executeStatement(thenBranch)
            environment = savedEnv
        } else if let elseB = elseBranch {
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            try executeStatement(elseB)
            environment = savedEnv
        }
    }

    private func executeFor(initializer: Statement?, condition: Expression?, increment: Expression?, body: Statement) throws {
        let forEnv = environment.createChild()
        let savedEnv = environment
        environment = forEnv

        // Initializer
        if let initStmt = initializer {
            try executeStatement(initStmt)
        }

        // Loop
        while true {
            // Check condition
            if let cond = condition {
                let condValue = try evaluate(cond)
                guard case .bool(let cont) = condValue else {
                    throw RuntimeError("For condition must be Bool", at: cond.range)
                }
                if !cont { break }
            }

            // Execute body
            let bodyEnv = environment.createChild()
            let savedBodyEnv = environment
            environment = bodyEnv
            try executeStatement(body)
            environment = savedBodyEnv

            // Increment
            if let incr = increment {
                _ = try evaluate(incr)
            }
        }

        environment = savedEnv
    }

    private func executeSwitch(subject: Expression, cases: [SwitchCase], range: SourceRange) throws {
        let subjectValue = try evaluate(subject)

        for switchCase in cases {
            let patternValue = try evaluate(switchCase.pattern)

            if subjectValue == patternValue {
                try executeStatement(switchCase.body)
                return
            }
        }

        // Should not reach here if type checker verified exhaustiveness
        throw RuntimeError("No matching case in switch", at: range)
    }
}
```

---

## Step 6: Interpreter.swift - Expression Evaluation

```swift
// MARK: - Expression Evaluation

extension Interpreter {
    private func evaluate(_ expr: Expression) throws -> Value {
        switch expr.kind {
        case .intLiteral(let value):
            return .int(value)

        case .floatLiteral(let value):
            return .float(value)

        case .stringLiteral(let value):
            return .string(value)

        case .boolLiteral(let value):
            return .bool(value)

        case .stringInterpolation(let parts):
            return try evaluateStringInterpolation(parts: parts)

        case .identifier(let name):
            return try evaluateIdentifier(name: name, range: expr.range)

        case .binary(let left, let op, let right):
            return try evaluateBinary(left: left, op: op, right: right, range: expr.range)

        case .unary(let op, let operand):
            return try evaluateUnary(op: op, operand: operand, range: expr.range)

        case .call(let callee, let arguments):
            return try evaluateCall(callee: callee, arguments: arguments, range: expr.range)

        case .memberAccess(let object, let member):
            return try evaluateMemberAccess(object: object, member: member, range: expr.range)

        case .structInit(let typeName, let fields):
            return try evaluateStructInit(typeName: typeName, fields: fields, range: expr.range)
        }
    }

    private func evaluateStringInterpolation(parts: [StringPart]) throws -> Value {
        var result = ""
        for part in parts {
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

    private func evaluateIdentifier(name: String, range: SourceRange) throws -> Value {
        // Check for variable
        if let value = environment.get(name) {
            return value
        }

        // Check for enum type (used in switch patterns like Direction.up)
        if enums[name] != nil {
            // Return a placeholder - actual case will be accessed via member access
            return .enumCase(typeName: name, caseName: "")
        }

        throw RuntimeError("Undefined variable '\(name)'", at: range)
    }

    private func evaluateBinary(left: Expression, op: BinaryOperator, right: Expression, range: SourceRange) throws -> Value {
        // Handle assignment specially (don't evaluate left side as value)
        switch op {
        case .assign, .addAssign, .subtractAssign, .multiplyAssign, .divideAssign:
            return try evaluateAssignment(left: left, op: op, right: right, range: range)
        default:
            break
        }

        let leftVal = try evaluate(left)
        let rightVal = try evaluate(right)

        switch op {
        // Arithmetic
        case .add:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                return .int(l + r)
            }
            if case .float(let l) = leftVal, case .float(let r) = rightVal {
                return .float(l + r)
            }
            if case .string(let l) = leftVal, case .string(let r) = rightVal {
                return .string(l + r)
            }
            throw RuntimeError("Cannot add \(leftVal) and \(rightVal)", at: range)

        case .subtract:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                return .int(l - r)
            }
            if case .float(let l) = leftVal, case .float(let r) = rightVal {
                return .float(l - r)
            }
            throw RuntimeError("Cannot subtract \(leftVal) and \(rightVal)", at: range)

        case .multiply:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                return .int(l * r)
            }
            if case .float(let l) = leftVal, case .float(let r) = rightVal {
                return .float(l * r)
            }
            throw RuntimeError("Cannot multiply \(leftVal) and \(rightVal)", at: range)

        case .divide:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                if r == 0 { throw RuntimeError("Division by zero", at: range) }
                return .int(l / r)
            }
            if case .float(let l) = leftVal, case .float(let r) = rightVal {
                return .float(l / r)
            }
            throw RuntimeError("Cannot divide \(leftVal) and \(rightVal)", at: range)

        case .modulo:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                if r == 0 { throw RuntimeError("Modulo by zero", at: range) }
                return .int(l % r)
            }
            throw RuntimeError("Cannot modulo \(leftVal) and \(rightVal)", at: range)

        // Comparison
        case .equal:
            return .bool(leftVal == rightVal)

        case .notEqual:
            return .bool(leftVal != rightVal)

        case .less:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                return .bool(l < r)
            }
            if case .float(let l) = leftVal, case .float(let r) = rightVal {
                return .bool(l < r)
            }
            throw RuntimeError("Cannot compare \(leftVal) and \(rightVal)", at: range)

        case .lessEqual:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                return .bool(l <= r)
            }
            if case .float(let l) = leftVal, case .float(let r) = rightVal {
                return .bool(l <= r)
            }
            throw RuntimeError("Cannot compare \(leftVal) and \(rightVal)", at: range)

        case .greater:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                return .bool(l > r)
            }
            if case .float(let l) = leftVal, case .float(let r) = rightVal {
                return .bool(l > r)
            }
            throw RuntimeError("Cannot compare \(leftVal) and \(rightVal)", at: range)

        case .greaterEqual:
            if case .int(let l) = leftVal, case .int(let r) = rightVal {
                return .bool(l >= r)
            }
            if case .float(let l) = leftVal, case .float(let r) = rightVal {
                return .bool(l >= r)
            }
            throw RuntimeError("Cannot compare \(leftVal) and \(rightVal)", at: range)

        // Logical
        case .and:
            if case .bool(let l) = leftVal, case .bool(let r) = rightVal {
                return .bool(l && r)
            }
            throw RuntimeError("Cannot apply && to \(leftVal) and \(rightVal)", at: range)

        case .or:
            if case .bool(let l) = leftVal, case .bool(let r) = rightVal {
                return .bool(l || r)
            }
            throw RuntimeError("Cannot apply || to \(leftVal) and \(rightVal)", at: range)

        case .assign, .addAssign, .subtractAssign, .multiplyAssign, .divideAssign:
            // Already handled above
            fatalError("Assignment should have been handled earlier")
        }
    }

    private func evaluateAssignment(left: Expression, op: BinaryOperator, right: Expression, range: SourceRange) throws -> Value {
        guard case .identifier(let name) = left.kind else {
            throw RuntimeError("Invalid assignment target", at: left.range)
        }

        let rightVal = try evaluate(right)
        var newValue = rightVal

        // Compound assignment
        if op != .assign {
            guard let currentValue = environment.get(name) else {
                throw RuntimeError("Undefined variable '\(name)'", at: left.range)
            }

            switch op {
            case .addAssign:
                if case .int(let l) = currentValue, case .int(let r) = rightVal {
                    newValue = .int(l + r)
                } else {
                    throw RuntimeError("Cannot apply += to \(currentValue) and \(rightVal)", at: range)
                }
            case .subtractAssign:
                if case .int(let l) = currentValue, case .int(let r) = rightVal {
                    newValue = .int(l - r)
                } else {
                    throw RuntimeError("Cannot apply -= to \(currentValue) and \(rightVal)", at: range)
                }
            case .multiplyAssign:
                if case .int(let l) = currentValue, case .int(let r) = rightVal {
                    newValue = .int(l * r)
                } else {
                    throw RuntimeError("Cannot apply *= to \(currentValue) and \(rightVal)", at: range)
                }
            case .divideAssign:
                if case .int(let l) = currentValue, case .int(let r) = rightVal {
                    if r == 0 { throw RuntimeError("Division by zero", at: range) }
                    newValue = .int(l / r)
                } else {
                    throw RuntimeError("Cannot apply /= to \(currentValue) and \(rightVal)", at: range)
                }
            default:
                break
            }
        }

        if !environment.assign(name, value: newValue) {
            throw RuntimeError("Undefined variable '\(name)'", at: left.range)
        }

        return newValue
    }

    private func evaluateUnary(op: UnaryOperator, operand: Expression, range: SourceRange) throws -> Value {
        let operandVal = try evaluate(operand)

        switch op {
        case .negate:
            if case .int(let n) = operandVal {
                return .int(-n)
            }
            if case .float(let f) = operandVal {
                return .float(-f)
            }
            throw RuntimeError("Cannot negate \(operandVal)", at: range)

        case .not:
            if case .bool(let b) = operandVal {
                return .bool(!b)
            }
            throw RuntimeError("Cannot apply ! to \(operandVal)", at: range)
        }
    }

    private func evaluateCall(callee: Expression, arguments: [Expression], range: SourceRange) throws -> Value {
        // Get the function name
        guard case .identifier(let name) = callee.kind else {
            throw RuntimeError("Invalid call target", at: callee.range)
        }

        // Check for built-in functions
        if name == "print" {
            return try evaluatePrint(arguments: arguments)
        }

        // User-defined function
        guard let funcDecl = functions[name],
              case .function(_, let parameters, _, let body) = funcDecl.kind else {
            throw RuntimeError("Undefined function '\(name)'", at: callee.range)
        }

        // Evaluate arguments
        var args: [Value] = []
        for arg in arguments {
            args.append(try evaluate(arg))
        }

        return try executeFunction(parameters: parameters, body: body, arguments: args)
    }

    private func evaluatePrint(arguments: [Expression]) throws -> Value {
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

    private func evaluateMemberAccess(object: Expression, member: String, range: SourceRange) throws -> Value {
        let objectVal = try evaluate(object)

        // Enum case access: Direction.up
        if case .enumCase(let typeName, _) = objectVal {
            // Check that the case exists
            guard let enumDecl = enums[typeName],
                  case .enumDecl(_, let cases) = enumDecl.kind else {
                throw RuntimeError("Unknown enum '\(typeName)'", at: object.range)
            }
            guard cases.contains(where: { $0.name == member }) else {
                throw RuntimeError("Enum '\(typeName)' has no case '\(member)'", at: range)
            }
            return .enumCase(typeName: typeName, caseName: member)
        }

        // Struct field access: point.x
        if case .structInstance(let typeName, let fields) = objectVal {
            guard let value = fields[member] else {
                throw RuntimeError("Struct '\(typeName)' has no field '\(member)'", at: range)
            }
            return value
        }

        throw RuntimeError("Cannot access member '\(member)' on \(objectVal)", at: range)
    }

    private func evaluateStructInit(typeName: String, fields: [FieldInit], range: SourceRange) throws -> Value {
        guard let structDecl = structs[typeName],
              case .structDecl(_, let structFields) = structDecl.kind else {
            throw RuntimeError("Unknown struct '\(typeName)'", at: range)
        }

        var fieldValues: [String: Value] = [:]

        for field in fields {
            let value = try evaluate(field.value)
            fieldValues[field.name] = value
        }

        // Verify all fields are present
        for structField in structFields {
            if fieldValues[structField.name] == nil {
                throw RuntimeError("Missing field '\(structField.name)' in struct initialization", at: range)
            }
        }

        return .structInstance(typeName: typeName, fields: fieldValues)
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

- [x] Value.swift created with all value types
- [x] Environment.swift created with scoping
- [x] Interpreter.swift created and handles:
  - [x] Function declarations and calls
  - [x] Variable declarations and access
  - [x] Struct initialization and field access
  - [x] Enum case creation and comparison
  - [x] All arithmetic operators
  - [x] All comparison operators
  - [x] All logical operators
  - [x] Assignment and compound assignment
  - [x] String interpolation
  - [x] If/else statements
  - [x] For loops
  - [x] Switch statements
  - [x] Return statements
  - [x] Built-in print() function
- [x] Uses `expr.kind` and `stmt.kind` pattern matching
- [x] Accesses `expr.range` directly for error reporting
- [x] Proper scoping (local variables don't leak)
- [x] All test cases pass
- [x] `swift build` succeeds

---

## Next Phase

Once this phase is complete, proceed to [Phase 5: CLI Polish](phase-5-cli.md).
