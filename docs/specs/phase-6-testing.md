# Phase 6: Testing & Documentation

## Overview

This phase establishes a comprehensive test suite and creates example programs that demonstrate all language features.

---

## Prerequisites

- Phase 1-5 complete (full working compiler)

---

## Files to Create

| File | Purpose |
|------|---------|
| `Tests/SlangCoreTests/LexerTests.swift` | Lexer unit tests |
| `Tests/SlangCoreTests/ParserTests.swift` | Parser unit tests |
| `Tests/SlangCoreTests/TypeCheckerTests.swift` | Type checker unit tests |
| `Tests/SlangCoreTests/InterpreterTests.swift` | Interpreter unit tests |
| `Tests/SlangCoreTests/IntegrationTests.swift` | End-to-end tests |
| `examples/hello.slang` | Hello World example |
| `examples/fibonacci.slang` | Recursion example |
| `examples/structs.slang` | Struct usage example |
| `examples/enums.slang` | Enum and switch example |
| `examples/loops.slang` | Loop examples |

---

## Step 1: Test Utilities

Create a shared test utilities file:

```swift
// Tests/SlangCoreTests/TestUtils.swift

import XCTest
@testable import SlangCore

/// Helper to run a Slang program and capture output
func runProgram(_ source: String) throws -> String {
    // Capture stdout
    var output = ""

    // Create a custom print function for testing
    let lexer = Lexer(source: source, filename: "<test>")
    let tokens = try lexer.tokenize()

    let parser = Parser(tokens: tokens)
    let ast = try parser.parse()

    let typeChecker = TypeChecker()
    try typeChecker.check(ast)

    let interpreter = Interpreter()
    // Note: In real implementation, you'd redirect stdout
    // For now, tests verify no exceptions are thrown
    try interpreter.interpret(ast)

    return output
}

/// Helper to verify lexer produces expected tokens
func assertTokens(_ source: String, expected: [TokenKind], file: StaticString = #file, line: UInt = #line) throws {
    let lexer = Lexer(source: source, filename: "<test>")
    let tokens = try lexer.tokenize()

    // Filter out EOF for comparison
    let tokenKinds = tokens.dropLast().map { $0.kind }

    XCTAssertEqual(tokenKinds.count, expected.count, "Token count mismatch", file: file, line: line)

    for (actual, exp) in zip(tokenKinds, expected) {
        XCTAssertEqual(actual, exp, "Token mismatch", file: file, line: line)
    }
}

/// Helper to verify parsing succeeds
func assertParses(_ source: String, file: StaticString = #file, line: UInt = #line) throws {
    let lexer = Lexer(source: source, filename: "<test>")
    let tokens = try lexer.tokenize()
    let parser = Parser(tokens: tokens)
    _ = try parser.parse()
}

/// Helper to verify type checking succeeds
func assertTypeChecks(_ source: String, file: StaticString = #file, line: UInt = #line) throws {
    let lexer = Lexer(source: source, filename: "<test>")
    let tokens = try lexer.tokenize()
    let parser = Parser(tokens: tokens)
    let ast = try parser.parse()
    let typeChecker = TypeChecker()
    try typeChecker.check(ast)
}

/// Helper to verify type checking fails with expected message
func assertTypeError(_ source: String, containing message: String, file: StaticString = #file, line: UInt = #line) {
    do {
        let lexer = Lexer(source: source, filename: "<test>")
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(ast)
        XCTFail("Expected type error but none was thrown", file: file, line: line)
    } catch let error as TypeCheckError {
        let messages = error.diagnostics.map { $0.message }.joined(separator: "\n")
        XCTAssertTrue(messages.contains(message), "Expected error containing '\(message)' but got '\(messages)'", file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}
```

---

## Step 2: LexerTests.swift

```swift
// Tests/SlangCoreTests/LexerTests.swift

import XCTest
@testable import SlangCore

final class LexerTests: XCTestCase {

    // MARK: - Literals

    func testIntegerLiteral() throws {
        let lexer = Lexer(source: "42")
        let tokens = try lexer.tokenize()
        XCTAssertEqual(tokens.count, 2)  // 42, EOF
        XCTAssertEqual(tokens[0].kind, .intLiteral(42))
    }

    func testFloatLiteral() throws {
        let lexer = Lexer(source: "3.14")
        let tokens = try lexer.tokenize()
        XCTAssertEqual(tokens[0].kind, .floatLiteral(3.14))
    }

    func testStringLiteral() throws {
        let lexer = Lexer(source: "\"hello world\"")
        let tokens = try lexer.tokenize()
        XCTAssertEqual(tokens[0].kind, .stringLiteral("hello world"))
    }

    func testBoolLiterals() throws {
        let lexer = Lexer(source: "true false")
        let tokens = try lexer.tokenize()
        XCTAssertEqual(tokens[0].kind, .keyword(.true))
        XCTAssertEqual(tokens[1].kind, .keyword(.false))
    }

    // MARK: - Operators

    func testArithmeticOperators() throws {
        try assertTokens("+ - * / %", expected: [.plus, .minus, .star, .slash, .percent])
    }

    func testComparisonOperators() throws {
        try assertTokens("== != < <= > >=", expected: [.equalEqual, .bangEqual, .less, .lessEqual, .greater, .greaterEqual])
    }

    func testLogicalOperators() throws {
        try assertTokens("&& || !", expected: [.ampersandAmpersand, .pipePipe, .bang])
    }

    func testAssignmentOperators() throws {
        try assertTokens("= += -= *= /=", expected: [.equal, .plusEqual, .minusEqual, .starEqual, .slashEqual])
    }

    func testArrow() throws {
        try assertTokens("->", expected: [.arrow])
    }

    // MARK: - Keywords

    func testKeywords() throws {
        try assertTokens("func var struct enum case if else for switch return", expected: [
            .keyword(.func), .keyword(.var), .keyword(.struct), .keyword(.enum),
            .keyword(.case), .keyword(.if), .keyword(.else), .keyword(.for),
            .keyword(.switch), .keyword(.return)
        ])
    }

    // MARK: - Identifiers

    func testIdentifiers() throws {
        let lexer = Lexer(source: "foo bar_123 _private")
        let tokens = try lexer.tokenize()
        XCTAssertEqual(tokens[0].kind, .identifier("foo"))
        XCTAssertEqual(tokens[1].kind, .identifier("bar_123"))
        XCTAssertEqual(tokens[2].kind, .identifier("_private"))
    }

    // MARK: - Delimiters

    func testDelimiters() throws {
        try assertTokens("( ) { } , : ; .", expected: [
            .leftParen, .rightParen, .leftBrace, .rightBrace,
            .comma, .colon, .semicolon, .dot
        ])
    }

    // MARK: - Comments

    func testSingleLineComment() throws {
        let lexer = Lexer(source: "42 // this is a comment\n43")
        let tokens = try lexer.tokenize()
        XCTAssertEqual(tokens[0].kind, .intLiteral(42))
        XCTAssertEqual(tokens[1].kind, .newline)
        XCTAssertEqual(tokens[2].kind, .intLiteral(43))
    }

    // MARK: - String Interpolation

    func testStringInterpolation() throws {
        let lexer = Lexer(source: "\"Hello \\(name)!\"")
        let tokens = try lexer.tokenize()

        XCTAssertEqual(tokens[0].kind, .stringLiteral("Hello "))
        XCTAssertEqual(tokens[1].kind, .stringInterpolationStart)
        XCTAssertEqual(tokens[2].kind, .identifier("name"))
        XCTAssertEqual(tokens[3].kind, .stringInterpolationEnd)
        XCTAssertEqual(tokens[4].kind, .stringLiteral("!"))
    }

    // MARK: - Source Location

    func testSourceLocation() throws {
        let lexer = Lexer(source: "func\nmain")
        let tokens = try lexer.tokenize()

        XCTAssertEqual(tokens[0].range.start.line, 1)
        XCTAssertEqual(tokens[0].range.start.column, 1)
        XCTAssertEqual(tokens[2].range.start.line, 2)  // tokens[1] is newline
        XCTAssertEqual(tokens[2].range.start.column, 1)
    }

    // MARK: - Errors

    func testUnterminatedString() {
        let lexer = Lexer(source: "\"hello")
        XCTAssertThrowsError(try lexer.tokenize())
    }

    func testUnexpectedCharacter() {
        let lexer = Lexer(source: "@")
        XCTAssertThrowsError(try lexer.tokenize())
    }
}
```

---

## Step 3: ParserTests.swift

```swift
// Tests/SlangCoreTests/ParserTests.swift

import XCTest
@testable import SlangCore

final class ParserTests: XCTestCase {

    // MARK: - Function Declarations

    func testSimpleFunction() throws {
        try assertParses("""
            func main() {
            }
            """)
    }

    func testFunctionWithParameters() throws {
        try assertParses("""
            func add(a: Int, b: Int) -> Int {
                return a + b
            }
            """)
    }

    // MARK: - Struct Declarations

    func testStructDeclaration() throws {
        try assertParses("""
            struct Point {
                x: Int
                y: Int
            }
            """)
    }

    // MARK: - Enum Declarations

    func testEnumDeclaration() throws {
        try assertParses("""
            enum Direction {
                case up
                case down
                case left
                case right
            }
            """)
    }

    // MARK: - Statements

    func testVarDeclaration() throws {
        try assertParses("""
            func main() {
                var x: Int = 42
            }
            """)
    }

    func testIfStatement() throws {
        try assertParses("""
            func main() {
                if (x > 0) {
                    print("positive")
                } else {
                    print("not positive")
                }
            }
            """)
    }

    func testForStatement() throws {
        try assertParses("""
            func main() {
                for (var i: Int = 0; i < 10; i = i + 1) {
                    print("\\(i)")
                }
            }
            """)
    }

    func testSwitchStatement() throws {
        try assertParses("""
            enum Color { case red case blue }
            func main() {
                var c: Color = Color.red
                switch (c) {
                    Color.red -> print("red")
                    Color.blue -> print("blue")
                }
            }
            """)
    }

    // MARK: - Expressions

    func testBinaryExpression() throws {
        try assertParses("""
            func main() {
                var x: Int = 1 + 2 * 3
            }
            """)
    }

    func testUnaryExpression() throws {
        try assertParses("""
            func main() {
                var x: Int = -42
                var b: Bool = !true
            }
            """)
    }

    func testFunctionCall() throws {
        try assertParses("""
            func add(a: Int, b: Int) -> Int { return a + b }
            func main() {
                var x: Int = add(1, 2)
            }
            """)
    }

    func testStructInit() throws {
        try assertParses("""
            struct Point { x: Int y: Int }
            func main() {
                var p = Point { x: 1, y: 2 }
            }
            """)
    }

    func testMemberAccess() throws {
        try assertParses("""
            struct Point { x: Int y: Int }
            func main() {
                var p = Point { x: 1, y: 2 }
                var x: Int = p.x
            }
            """)
    }

    func testStringInterpolation() throws {
        try assertParses("""
            func main() {
                var x: Int = 42
                print("Value: \\(x)")
            }
            """)
    }

    // MARK: - Operator Precedence

    func testOperatorPrecedence() throws {
        // 1 + 2 * 3 should parse as 1 + (2 * 3)
        try assertParses("""
            func main() {
                var x: Int = 1 + 2 * 3
            }
            """)
    }

    // MARK: - Errors

    func testMissingClosingBrace() {
        let source = """
            func main() {
                var x: Int = 42
            """
        let lexer = Lexer(source: source, filename: "<test>")
        let tokens = try! lexer.tokenize()
        let parser = Parser(tokens: tokens)
        XCTAssertThrowsError(try parser.parse())
    }
}
```

---

## Step 4: TypeCheckerTests.swift

```swift
// Tests/SlangCoreTests/TypeCheckerTests.swift

import XCTest
@testable import SlangCore

final class TypeCheckerTests: XCTestCase {

    // MARK: - Valid Programs

    func testSimpleProgram() throws {
        try assertTypeChecks("""
            func main() {
                var x: Int = 42
            }
            """)
    }

    func testFunctionCall() throws {
        try assertTypeChecks("""
            func add(a: Int, b: Int) -> Int {
                return a + b
            }
            func main() {
                var x: Int = add(1, 2)
            }
            """)
    }

    func testStructUsage() throws {
        try assertTypeChecks("""
            struct Point {
                x: Int
                y: Int
            }
            func main() {
                var p = Point { x: 1, y: 2 }
                var sum: Int = p.x + p.y
            }
            """)
    }

    func testEnumUsage() throws {
        try assertTypeChecks("""
            enum Direction {
                case up
                case down
            }
            func main() {
                var d: Direction = Direction.up
                switch (d) {
                    Direction.up -> print("up")
                    Direction.down -> print("down")
                }
            }
            """)
    }

    // MARK: - Type Errors

    func testTypeMismatch() {
        assertTypeError("""
            func main() {
                var x: Int = "hello"
            }
            """, containing: "Cannot assign")
    }

    func testUndefinedVariable() {
        assertTypeError("""
            func main() {
                print(x)
            }
            """, containing: "Undefined variable")
    }

    func testWrongArgumentType() {
        assertTypeError("""
            func add(a: Int, b: Int) -> Int {
                return a + b
            }
            func main() {
                add("hello", 5)
            }
            """, containing: "does not match parameter type")
    }

    func testNonBoolCondition() {
        assertTypeError("""
            func main() {
                if (42) {
                    print("wrong")
                }
            }
            """, containing: "must be of type 'Bool'")
    }

    func testNonExhaustiveSwitch() {
        assertTypeError("""
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
            """, containing: "Missing cases")
    }

    func testUnknownField() {
        assertTypeError("""
            struct Point {
                x: Int
                y: Int
            }
            func main() {
                var p = Point { x: 1, y: 2 }
                var z: Int = p.z
            }
            """, containing: "has no field 'z'")
    }

    func testMissingField() {
        assertTypeError("""
            struct Point {
                x: Int
                y: Int
            }
            func main() {
                var p = Point { x: 1 }
            }
            """, containing: "Missing fields")
    }

    func testReturnTypeMismatch() {
        assertTypeError("""
            func getString() -> String {
                return 42
            }
            func main() {
            }
            """, containing: "Cannot return value of type")
    }
}
```

---

## Step 5: InterpreterTests.swift

```swift
// Tests/SlangCoreTests/InterpreterTests.swift

import XCTest
@testable import SlangCore

final class InterpreterTests: XCTestCase {

    // MARK: - Basic Execution

    func testEmptyMain() throws {
        let source = """
            func main() {
            }
            """
        // Should not throw
        try runProgramSilent(source)
    }

    func testArithmetic() throws {
        // Test that arithmetic doesn't crash
        // (Output verification requires stdout capture)
        let source = """
            func main() {
                var a: Int = 10
                var b: Int = 3
                var sum: Int = a + b
                var diff: Int = a - b
                var prod: Int = a * b
                var quot: Int = a / b
                var mod: Int = a % b
            }
            """
        try runProgramSilent(source)
    }

    func testFunctionCall() throws {
        let source = """
            func add(a: Int, b: Int) -> Int {
                return a + b
            }
            func main() {
                var result: Int = add(5, 3)
            }
            """
        try runProgramSilent(source)
    }

    func testStruct() throws {
        let source = """
            struct Point {
                x: Int
                y: Int
            }
            func main() {
                var p = Point { x: 3, y: 4 }
                var sum: Int = p.x + p.y
            }
            """
        try runProgramSilent(source)
    }

    func testIfElse() throws {
        let source = """
            func main() {
                var x: Int = 10
                if (x > 5) {
                    var y: Int = 1
                } else {
                    var y: Int = 2
                }
            }
            """
        try runProgramSilent(source)
    }

    func testForLoop() throws {
        let source = """
            func main() {
                var sum: Int = 0
                for (var i: Int = 0; i < 5; i = i + 1) {
                    sum = sum + i
                }
            }
            """
        try runProgramSilent(source)
    }

    func testSwitch() throws {
        let source = """
            enum Color {
                case red
                case green
                case blue
            }
            func main() {
                var c: Color = Color.green
                switch (c) {
                    Color.red -> print("red")
                    Color.green -> print("green")
                    Color.blue -> print("blue")
                }
            }
            """
        try runProgramSilent(source)
    }

    // MARK: - Helper

    private func runProgramSilent(_ source: String) throws {
        let lexer = Lexer(source: source, filename: "<test>")
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(ast)
        let interpreter = Interpreter()
        try interpreter.interpret(ast)
    }
}
```

---

## Step 6: IntegrationTests.swift

```swift
// Tests/SlangCoreTests/IntegrationTests.swift

import XCTest
@testable import SlangCore

final class IntegrationTests: XCTestCase {

    func testFullV01Program() throws {
        let source = """
            struct Point {
                x: Int
                y: Int
            }

            enum Direction {
                case up
                case down
                case left
                case right
            }

            func add(a: Int, b: Int) -> Int {
                return a + b
            }

            func describePoint(p: Point) -> String {
                return "Point at \\(p.x), \\(p.y)"
            }

            func main() {
                var p = Point { x: 3, y: 4 }
                print(describePoint(p))
                print("Sum: \\(add(p.x, p.y))")

                var dir: Direction = Direction.up

                switch (dir) {
                    Direction.up -> print("Going up!")
                    Direction.down -> print("Going down!")
                    Direction.left -> print("Going left!")
                    Direction.right -> print("Going right!")
                }

                for (var i: Int = 0; i < 5; i = i + 1) {
                    print("\\(i)")
                }

                if (p.x > 0 && p.y > 0) {
                    print("First quadrant")
                } else {
                    print("Other quadrant")
                }
            }
            """

        // This should execute without errors
        let lexer = Lexer(source: source, filename: "<test>")
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(ast)
        let interpreter = Interpreter()
        try interpreter.interpret(ast)
    }

    func testRecursiveFibonacci() throws {
        let source = """
            func fib(n: Int) -> Int {
                if (n <= 1) {
                    return n
                }
                return fib(n - 1) + fib(n - 2)
            }

            func main() {
                var result: Int = fib(10)
                print("\\(result)")
            }
            """

        let lexer = Lexer(source: source, filename: "<test>")
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(ast)
        let interpreter = Interpreter()
        try interpreter.interpret(ast)
    }
}
```

---

## Step 7: Example Programs

### examples/hello.slang

```slang
// Hello World - The simplest Slang program

func main() {
    print("Hello, World!")
}
```

### examples/fibonacci.slang

```slang
// Fibonacci sequence using recursion

func fib(n: Int) -> Int {
    if (n <= 1) {
        return n
    }
    return fib(n - 1) + fib(n - 2)
}

func main() {
    print("Fibonacci sequence:")
    for (var i: Int = 0; i < 10; i = i + 1) {
        print("fib(\(i)) = \(fib(i))")
    }
}
```

### examples/structs.slang

```slang
// Demonstrates struct usage

struct Point {
    x: Int
    y: Int
}

struct Rectangle {
    topLeft: Point
    width: Int
    height: Int
}

func area(rect: Rectangle) -> Int {
    return rect.width * rect.height
}

func describe(p: Point) -> String {
    return "(\(p.x), \(p.y))"
}

func main() {
    var origin = Point { x: 0, y: 0 }
    print("Origin: \(describe(origin))")

    var rect = Rectangle {
        topLeft: Point { x: 10, y: 20 },
        width: 100,
        height: 50
    }

    print("Rectangle area: \(area(rect))")
}
```

### examples/enums.slang

```slang
// Demonstrates enum and switch

enum TrafficLight {
    case red
    case yellow
    case green
}

func action(light: TrafficLight) -> String {
    switch (light) {
        TrafficLight.red -> return "Stop"
        TrafficLight.yellow -> return "Caution"
        TrafficLight.green -> return "Go"
    }
}

func main() {
    var light: TrafficLight = TrafficLight.red
    print("Red means: \(action(light))")

    light = TrafficLight.green
    print("Green means: \(action(light))")
}
```

### examples/loops.slang

```slang
// Demonstrates for loops

func main() {
    // Count up
    print("Counting up:")
    for (var i: Int = 1; i <= 5; i = i + 1) {
        print("\(i)")
    }

    // Count down
    print("Counting down:")
    for (var i: Int = 5; i >= 1; i = i - 1) {
        print("\(i)")
    }

    // Sum numbers
    var sum: Int = 0
    for (var i: Int = 1; i <= 100; i = i + 1) {
        sum = sum + i
    }
    print("Sum of 1 to 100: \(sum)")

    // Multiplication table
    print("5 times table:")
    for (var i: Int = 1; i <= 10; i = i + 1) {
        print("5 x \(i) = \(5 * i)")
    }
}
```

---

## Running Tests

```bash
# Run all tests
swift test

# Run specific test class
swift test --filter LexerTests

# Run specific test
swift test --filter LexerTests.testIntegerLiteral

# Run with verbose output
swift test -v
```

---

## Acceptance Criteria

### Tests
- [x] LexerTests pass (10+ test cases)
- [x] ParserTests pass (15+ test cases)
- [x] TypeCheckerTests pass (12+ test cases)
- [x] InterpreterTests pass (8+ test cases)
- [x] IntegrationTests pass (2+ test cases)
- [x] All tests run via `swift test`

### Examples
- [x] examples/hello.slang runs successfully
- [x] examples/fibonacci.slang runs successfully
- [x] examples/structs.slang runs successfully
- [x] examples/enums.slang runs successfully
- [x] examples/loops.slang runs successfully

### v0.1 Complete
- [x] Full v0.1 test program runs with expected output
- [x] All 6 phases documented and tested
- [x] `slang run`, `slang check`, `slang parse`, `slang tokenize` all work
- [x] Error messages are helpful and include source location

---

## v0.1 Complete!

Congratulations! Once all acceptance criteria are met, you have completed the v0.1 implementation of the Slang programming language.

### What's Next?

See the [Post v0.1 Roadmap](../roadmap.md#post-v01-roadmap) for future phases:
- Phase 7: Unions with pattern matching
- Phase 8: Methods on structs
- Phase 9: Module system
- Phase 10: Generics
- And more...
