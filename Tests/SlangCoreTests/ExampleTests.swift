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
        let interpreter = ExampleTestInterpreter(printHandler: { output.append($0) })
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

// MARK: - Test Interpreter for Examples

typealias ExampleExpression = SlangCore.Expression

class ExampleTestInterpreter {
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
        } catch let returnValue as ExampleReturnValue {
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
            throw ExampleReturnValue(value: retValue)
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

    private func evaluate(_ expr: ExampleExpression) throws -> Value {
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

    private func evaluateBinary(left: ExampleExpression, op: BinaryOperator, right: ExampleExpression) throws -> Value {
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

    private func evalCompound(_ left: ExampleExpression, _ right: ExampleExpression, _ fn: (Int, Int) -> Int) throws -> Value {
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

private struct ExampleReturnValue: Error {
    let value: Value
}
