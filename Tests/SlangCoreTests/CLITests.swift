import Testing
@testable import SlangCore
import Foundation

@Suite("CLI Tests")
struct CLITests {
    // MARK: - DiagnosticPrinter Tests

    @Test("DiagnosticPrinter formats error correctly")
    func diagnosticPrinterError() throws {
        let source = """
        func main() {
            var x: Int = "hello"
        }
        """
        let printer = DiagnosticPrinter(source: source)

        let diagnostic = Diagnostic(
            severity: .error,
            message: "Type mismatch: expected Int, got String",
            range: SourceRange(
                start: SourceLocation(line: 2, column: 18, offset: 30),
                end: SourceLocation(line: 2, column: 25, offset: 37),
                file: "test.slang"
            )
        )

        // Verify printer doesn't crash - output goes to stdout
        printer.print(diagnostic)
    }

    @Test("DiagnosticPrinter formats warning correctly")
    func diagnosticPrinterWarning() throws {
        let source = "var x: Int = 42"
        let printer = DiagnosticPrinter(source: source)

        let diagnostic = Diagnostic(
            severity: .warning,
            message: "Unused variable 'x'",
            range: SourceRange(
                start: SourceLocation(line: 1, column: 5, offset: 4),
                end: SourceLocation(line: 1, column: 6, offset: 5),
                file: "test.slang"
            )
        )

        printer.print(diagnostic)
    }

    @Test("DiagnosticPrinter handles multiline underline")
    func diagnosticPrinterMultiline() throws {
        let source = """
        func main() {
            var longVariable: Int = 42
        }
        """
        let printer = DiagnosticPrinter(source: source)

        let diagnostic = Diagnostic(
            severity: .note,
            message: "Test multiline",
            range: SourceRange(
                start: SourceLocation(line: 2, column: 9, offset: 21),
                end: SourceLocation(line: 2, column: 21, offset: 33),
                file: "test.slang"
            )
        )

        printer.print(diagnostic)
    }

    // MARK: - Integration Tests (End-to-End Pipeline)

    @Test("Full pipeline: Valid program")
    func fullPipelineValid() throws {
        let source = """
        func main() {
            print("Hello, World!")
        }
        """

        // Lexer
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        #expect(tokens.count > 0)

        // Parser
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        #expect(declarations.count == 1)

        // Type Checker
        let typeChecker = TypeChecker()
        try typeChecker.check(declarations)

        // Interpreter with captured output
        var output: [String] = []
        let interpreter = Interpreter(printHandler: { output.append($0) })
        try interpreter.interpret(declarations)

        #expect(output == ["Hello, World!"])
    }

    @Test("Full pipeline: Type error produces diagnostic")
    func fullPipelineTypeError() throws {
        let source = """
        func main() {
            var x: Int = "hello"
        }
        """

        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()

        let typeChecker = TypeChecker()

        do {
            try typeChecker.check(declarations)
            Issue.record("Should have thrown TypeCheckError")
        } catch let error as TypeCheckError {
            #expect(error.diagnostics.count >= 1)
            #expect(error.diagnostics[0].severity == .error)
            #expect(error.diagnostics[0].message.contains("Type mismatch") ||
                   error.diagnostics[0].message.contains("type"))
        }
    }

    @Test("Full pipeline: Parser error produces diagnostic")
    func fullPipelineParseError() throws {
        let source = """
        func main( {
            print("missing paren")
        }
        """

        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)

        do {
            _ = try parser.parse()
            Issue.record("Should have thrown ParserError")
        } catch let error as ParserError {
            #expect(error.diagnostics.count >= 1)
            #expect(error.diagnostics[0].severity == .error)
        }
    }

    @Test("Full pipeline: Lexer error produces diagnostic")
    func fullPipelineLexerError() throws {
        let source = """
        func main() {
            var x = "unterminated string
        }
        """

        let lexer = Lexer(source: source)

        do {
            _ = try lexer.tokenize()
            Issue.record("Should have thrown LexerError")
        } catch let error as LexerError {
            #expect(error.diagnostics.count >= 1)
            #expect(error.diagnostics[0].severity == .error)
        }
    }

    @Test("Full pipeline: Complex program")
    func fullPipelineComplex() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        enum Direction {
            case up
            case down
        }

        func add(a: Int, b: Int) -> Int {
            return a + b
        }

        func main() {
            var p = Point { x: 3, y: 4 }
            print("Sum: \\(add(p.x, p.y))")

            var dir: Direction = Direction.up
            switch (dir) {
                Direction.up -> print("Going up!")
                Direction.down -> print("Going down!")
            }

            for (var i: Int = 0; i < 3; i = i + 1) {
                print("\\(i)")
            }
        }
        """

        // Full pipeline
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(declarations)

        var output: [String] = []
        let interpreter = Interpreter(printHandler: { output.append($0) })
        try interpreter.interpret(declarations)

        #expect(output == ["Sum: 7", "Going up!", "0", "1", "2"])
    }

    @Test("Error location is accurate")
    func errorLocationAccuracy() throws {
        let source = """
        func main() {
            var x: Int = true
        }
        """

        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let typeChecker = TypeChecker()

        do {
            try typeChecker.check(declarations)
            Issue.record("Should have thrown")
        } catch let error as TypeCheckError {
            let diagnostic = error.diagnostics[0]
            // The error should point to line 2 where the type mismatch is
            #expect(diagnostic.range.start.line == 2)
        }
    }
}
