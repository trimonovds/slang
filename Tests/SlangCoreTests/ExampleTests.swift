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
}
