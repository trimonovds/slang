import Testing
@testable import SlangCore
import Foundation

@Suite("Example Tests")
struct ExampleTests {
    // MARK: - Helper

    /// URL to the examples directory relative to the test file
    static let examplesURL: URL = {
        // Navigate from test file location to examples directory
        // #filePath = .../Tests/SlangCoreTests/ExampleTests.swift
        // Examples are at .../Tests/Examples/
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // .../Tests/SlangCoreTests
            .deletingLastPathComponent()  // .../Tests
            .appendingPathComponent("Examples")
    }()

    func readExample(_ filename: String) throws -> String {
        let url = Self.examplesURL.appendingPathComponent(filename)
        return try String(contentsOf: url, encoding: .utf8)
    }

    func runAndCapture(_ source: String) throws -> [String] {
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(decls)

        var output: [String] = []
        let interpreter = Interpreter(printHandler: { output.append($0) })
        try interpreter.interpret(decls)

        return output
    }

    func runExample(_ filename: String) throws -> [String] {
        let source = try readExample(filename)
        return try runAndCapture(source)
    }

    // MARK: - Example Tests

    @Test("hello.slang")
    func helloExample() throws {
        let output = try runExample("hello.slang")
        #expect(output == ["Hello, World!"])
    }

    @Test("fibonacci.slang")
    func fibonacciExample() throws {
        let output = try runExample("fibonacci.slang")
        #expect(output[0] == "Fibonacci sequence:")
        #expect(output[1] == "fib(0) = 0")
        #expect(output[2] == "fib(1) = 1")
        #expect(output[3] == "fib(2) = 1")
        #expect(output[10] == "fib(9) = 34")
    }

    @Test("structs.slang")
    func structsExample() throws {
        let output = try runExample("structs.slang")
        #expect(output == [
            "Origin: (0, 0)",
            "Point 1: (3, 4)",
            "Manhattan distance from origin: 7",
            "Point 2: (-5, 10)",
            "Manhattan distance from origin: 15"
        ])
    }

    @Test("enums.slang")
    func enumsExample() throws {
        let output = try runExample("enums.slang")
        #expect(output == [
            "Red means: Stop",
            "Yellow means: Caution",
            "Green means: Go"
        ])
    }

    @Test("loops.slang")
    func loopsExample() throws {
        let output = try runExample("loops.slang")
        #expect(output[0] == "Counting up:")
        #expect(output[1] == "1")
        #expect(output[5] == "5")
        #expect(output[6] == "Counting down:")
        #expect(output[12] == "Sum of 1 to 10: 55")
    }

    @Test("full.slang - v0.1 reference program")
    func fullExample() throws {
        let output = try runExample("full.slang")
        #expect(output == [
            "Point at 3, 4",
            "Sum: 7",
            "Going up!",
            "0", "1", "2", "3", "4",
            "First quadrant"
        ])
    }

    @Test("switch_expr.slang - v0.1.1 switch expression")
    func switchExprExample() throws {
        let output = try runExample("switch_expr.slang")
        #expect(output == [
            "Original: up",
            "Opposite:",
            "down",
            "Opposite of left:",
            "right",
            "Value of up: 0"
        ])
    }

    @Test("unions.slang - v0.1.2 union types")
    func unionsExample() throws {
        let output = try runExample("unions.slang")
        #expect(output == [
            "Pet is: dog",
            "It's a dog named Buddy!",
            "integer: 42",
            "Pet 2 name: Whiskers"
        ])
    }

    @Test("collections.slang - v0.2 collection types")
    func collectionsExample() throws {
        let output = try runExample("collections.slang")
        #expect(output == [
            "=== Optional ===",
            "name is nil: true",
            "greeting: some(Hello)",
            "name after assignment: some(World)",
            "=== Array ===",
            "First: 1",
            "Count: 5",
            "isEmpty: false",
            "After update: 10",
            "After append: 6",
            "first: some(10)",
            "last: some(6)",
            "After removeAt(0): 2",
            "empty.isEmpty: true",
            "empty.first is nil: true",
            "=== Dictionary ===",
            "ages count: 2",
            "alice age: some(30)",
            "unknown age is nil: true",
            "After adding charlie: 3",
            "alice updated age: some(31)",
            "keys count: 3",
            "values count: 3",
            "After removing bob: 2",
            "emptyDict.isEmpty: true",
            "=== Set ===",
            "tags count (after dedup): 2",
            "tags.isEmpty: false",
            "contains swift: true",
            "contains rust: false",
            "After insert rust: 3",
            "After insert duplicate swift: 3",
            "Removed slang: true",
            "After remove: 2",
            "Removed nonexistent: false",
            "emptySet.isEmpty: true",
            "=== Done ==="
        ])
    }
}
