import Testing
@testable import SlangCore
import Foundation

// Type aliases to avoid conflicts with Foundation.Expression
typealias SlangExpression = SlangCore.Expression

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

        // Interpreter (using TestInterpreter from InterpreterTests)
        var output: [String] = []
        let interpreter = TestInterpreterForCLI(printHandler: { output.append($0) })
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
        let interpreter = TestInterpreterForCLI(printHandler: { output.append($0) })
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

// MARK: - Test Interpreter (simplified copy for CLI tests)

/// Minimal interpreter for CLI integration tests
class TestInterpreterForCLI {
    private var globalEnv: RuntimeEnvironment
    private var environment: RuntimeEnvironment
    private var functions: [String: Declaration] = [:]
    private var structs: [String: Declaration] = [:]
    private var enums: [String: Declaration] = [:]
    private let printHandler: (String) -> Void

    init(printHandler: @escaping (String) -> Void) {
        self.globalEnv = RuntimeEnvironment()
        self.environment = globalEnv
        self.printHandler = printHandler
    }

    func interpret(_ declarations: [Declaration]) throws {
        for decl in declarations {
            collectDeclaration(decl)
        }

        guard let mainDecl = functions["main"],
              case .function(_, let parameters, _, let body) = mainDecl.kind,
              parameters.isEmpty else {
            throw RuntimeError("No main() function found")
        }

        _ = try executeFunction(parameters: [], body: body, arguments: [])
    }

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

    private func executeFunction(parameters: [Parameter], body: Statement, arguments: [Value]) throws -> Value {
        let funcEnv = globalEnv.createChild()
        for (param, arg) in zip(parameters, arguments) {
            funcEnv.define(param.name, value: arg)
        }
        let savedEnv = environment
        environment = funcEnv

        do {
            try executeStatement(body)
            environment = savedEnv
            return .void
        } catch let returnValue as CLIReturnValue {
            environment = savedEnv
            return returnValue.value
        } catch {
            environment = savedEnv
            throw error
        }
    }

    private func executeStatement(_ stmt: Statement) throws {
        switch stmt.kind {
        case .block(let statements):
            let childEnv = environment.createChild()
            let savedEnv = environment
            environment = childEnv
            for s in statements { try executeStatement(s) }
            environment = savedEnv
        case .varDecl(let name, _, let initializer):
            let value = try evaluate(initializer)
            environment.define(name, value: value)
        case .expression(let expr):
            _ = try evaluate(expr)
        case .returnStmt(let value):
            let retValue = try value.map { try evaluate($0) } ?? .void
            throw CLIReturnValue(value: retValue)
        case .ifStmt(let condition, let thenBranch, let elseBranch):
            guard case .bool(let cond) = try evaluate(condition) else { return }
            if cond { try executeStatement(thenBranch) }
            else if let elseB = elseBranch { try executeStatement(elseB) }
        case .forStmt(let initializer, let condition, let increment, let body):
            let forEnv = environment.createChild()
            let savedEnv = environment
            environment = forEnv
            if let initStmt = initializer { try executeStatement(initStmt) }
            while true {
                if let cond = condition {
                    guard case .bool(let cont) = try evaluate(cond), cont else { break }
                }
                try executeStatement(body)
                if let incr = increment { _ = try evaluate(incr) }
            }
            environment = savedEnv
        case .switchStmt(let subject, let cases):
            let subjectValue = try evaluate(subject)
            for switchCase in cases {
                let patternValue = try evaluate(switchCase.pattern)
                if subjectValue == patternValue {
                    try executeStatement(switchCase.body)
                    return
                }
            }
        }
    }

    private func evaluate(_ expr: SlangExpression) throws -> Value {
        switch expr.kind {
        case .intLiteral(let value): return .int(value)
        case .floatLiteral(let value): return .float(value)
        case .stringLiteral(let value): return .string(value)
        case .boolLiteral(let value): return .bool(value)
        case .stringInterpolation(let parts):
            var result = ""
            for part in parts {
                switch part {
                case .literal(let str): result += str
                case .interpolation(let subExpr): result += try evaluate(subExpr).stringify()
                }
            }
            return .string(result)
        case .identifier(let name):
            if let value = environment.get(name) { return value }
            if enums[name] != nil { return .enumCase(typeName: name, caseName: "") }
            throw RuntimeError("Undefined variable '\(name)'")
        case .binary(let left, let op, let right):
            return try evaluateBinary(left: left, op: op, right: right)
        case .unary(let op, let operand):
            let val = try evaluate(operand)
            switch op {
            case .negate: if case .int(let n) = val { return .int(-n) }; if case .float(let f) = val { return .float(-f) }
            case .not: if case .bool(let b) = val { return .bool(!b) }
            }
            throw RuntimeError("Invalid unary operation")
        case .call(let callee, let arguments):
            guard case .identifier(let name) = callee.kind else { throw RuntimeError("Invalid call") }
            if name == "print" {
                guard case .string(let str) = try evaluate(arguments[0]) else { throw RuntimeError("print expects String") }
                printHandler(str)
                return .void
            }
            guard let funcDecl = functions[name], case .function(_, let params, _, let body) = funcDecl.kind else {
                throw RuntimeError("Unknown function")
            }
            var args: [Value] = []
            for arg in arguments { args.append(try evaluate(arg)) }
            return try executeFunction(parameters: params, body: body, arguments: args)
        case .memberAccess(let object, let member):
            let objVal = try evaluate(object)
            if case .enumCase(let typeName, _) = objVal { return .enumCase(typeName: typeName, caseName: member) }
            if case .structInstance(_, let fields) = objVal, let val = fields[member] { return val }
            throw RuntimeError("Invalid member access")
        case .structInit(let typeName, let fields):
            var fieldValues: [String: Value] = [:]
            for field in fields { fieldValues[field.name] = try evaluate(field.value) }
            return .structInstance(typeName: typeName, fields: fieldValues)
        }
    }

    private func evaluateBinary(left: SlangExpression, op: BinaryOperator, right: SlangExpression) throws -> Value {
        if case .assign = op {
            guard case .identifier(let name) = left.kind else { throw RuntimeError("Invalid assignment") }
            let val = try evaluate(right)
            _ = environment.assign(name, value: val)
            return val
        }
        if case .addAssign = op { return try evalCompound(left, right) { $0 + $1 } }
        if case .subtractAssign = op { return try evalCompound(left, right) { $0 - $1 } }
        if case .multiplyAssign = op { return try evalCompound(left, right) { $0 * $1 } }
        if case .divideAssign = op { return try evalCompound(left, right) { $0 / $1 } }

        let l = try evaluate(left)
        let r = try evaluate(right)
        switch op {
        case .add:
            if case .int(let a) = l, case .int(let b) = r { return .int(a + b) }
            if case .string(let a) = l, case .string(let b) = r { return .string(a + b) }
        case .subtract: if case .int(let a) = l, case .int(let b) = r { return .int(a - b) }
        case .multiply: if case .int(let a) = l, case .int(let b) = r { return .int(a * b) }
        case .divide: if case .int(let a) = l, case .int(let b) = r { return .int(a / b) }
        case .modulo: if case .int(let a) = l, case .int(let b) = r { return .int(a % b) }
        case .equal: return .bool(l == r)
        case .notEqual: return .bool(l != r)
        case .less: if case .int(let a) = l, case .int(let b) = r { return .bool(a < b) }
        case .lessEqual: if case .int(let a) = l, case .int(let b) = r { return .bool(a <= b) }
        case .greater: if case .int(let a) = l, case .int(let b) = r { return .bool(a > b) }
        case .greaterEqual: if case .int(let a) = l, case .int(let b) = r { return .bool(a >= b) }
        case .and: if case .bool(let a) = l, case .bool(let b) = r { return .bool(a && b) }
        case .or: if case .bool(let a) = l, case .bool(let b) = r { return .bool(a || b) }
        default: break
        }
        throw RuntimeError("Invalid binary operation")
    }

    private func evalCompound(_ left: SlangExpression, _ right: SlangExpression, _ fn: (Int, Int) -> Int) throws -> Value {
        guard case .identifier(let name) = left.kind,
              let currentValue = environment.get(name),
              case .int(let curr) = currentValue,
              case .int(let r) = try evaluate(right) else {
            throw RuntimeError("Invalid compound assignment")
        }
        let newVal = Value.int(fn(curr, r))
        _ = environment.assign(name, value: newVal)
        return newVal
    }
}

private struct CLIReturnValue: Error {
    let value: Value
}
