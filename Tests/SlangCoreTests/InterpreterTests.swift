import Testing
@testable import SlangCore

@Suite("Interpreter Tests")
struct InterpreterTests {
    // MARK: - Helper

    func run(_ source: String, expectOutput: [String]) throws {
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(decls)

        // Capture print output
        var output: [String] = []
        let interpreter = TestInterpreter(printHandler: { output.append($0) })
        try interpreter.interpret(decls)

        #expect(output == expectOutput, "Expected \(expectOutput), got \(output)")
    }

    // MARK: - Basic Tests

    @Test("Hello World")
    func helloWorld() throws {
        let source = """
        func main() {
            print("Hello, World!")
        }
        """
        try run(source, expectOutput: ["Hello, World!"])
    }

    @Test("Variable declaration and use")
    func variableDeclaration() throws {
        let source = """
        func main() {
            var x: Int = 42
            print("\\(x)")
        }
        """
        try run(source, expectOutput: ["42"])
    }

    @Test("Arithmetic operations")
    func arithmetic() throws {
        let source = """
        func main() {
            var x: Int = 10
            var y: Int = 3
            print("\\(x + y)")
            print("\\(x - y)")
            print("\\(x * y)")
            print("\\(x / y)")
            print("\\(x % y)")
        }
        """
        try run(source, expectOutput: ["13", "7", "30", "3", "1"])
    }

    @Test("Function call")
    func functionCall() throws {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }

        func main() {
            var result: Int = add(5, 3)
            print("\\(result)")
        }
        """
        try run(source, expectOutput: ["8"])
    }

    @Test("Struct initialization and field access")
    func structUsage() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func main() {
            var p = Point { x: 3, y: 4 }
            print("x = \\(p.x), y = \\(p.y)")
        }
        """
        try run(source, expectOutput: ["x = 3, y = 4"])
    }

    @Test("If/else - true branch")
    func ifElseTrue() throws {
        let source = """
        func main() {
            var x: Int = 10
            if (x > 5) {
                print("big")
            } else {
                print("small")
            }
        }
        """
        try run(source, expectOutput: ["big"])
    }

    @Test("If/else - false branch")
    func ifElseFalse() throws {
        let source = """
        func main() {
            var x: Int = 3
            if (x > 5) {
                print("big")
            } else {
                print("small")
            }
        }
        """
        try run(source, expectOutput: ["small"])
    }

    @Test("For loop")
    func forLoop() throws {
        let source = """
        func main() {
            for (var i: Int = 0; i < 5; i = i + 1) {
                print("\\(i)")
            }
        }
        """
        try run(source, expectOutput: ["0", "1", "2", "3", "4"])
    }

    @Test("Switch statement")
    func switchStatement() throws {
        let source = """
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
        """
        try run(source, expectOutput: ["Green!"])
    }

    @Test("String interpolation")
    func stringInterpolation() throws {
        let source = """
        func main() {
            var name: String = "World"
            var age: Int = 42
            print("Hello, \\(name)! Age: \\(age)")
        }
        """
        try run(source, expectOutput: ["Hello, World! Age: 42"])
    }

    @Test("Boolean operations")
    func booleanOperations() throws {
        let source = """
        func main() {
            var a: Bool = true
            var b: Bool = false
            if (a && b) {
                print("both")
            } else {
                print("not both")
            }
            if (a || b) {
                print("at least one")
            }
            if (!b) {
                print("not false")
            }
        }
        """
        try run(source, expectOutput: ["not both", "at least one", "not false"])
    }

    @Test("Comparison operations")
    func comparisonOperations() throws {
        let source = """
        func main() {
            var x: Int = 5
            var y: Int = 10
            if (x < y) { print("less") }
            if (x <= 5) { print("less or equal") }
            if (y > x) { print("greater") }
            if (y >= 10) { print("greater or equal") }
            if (x == 5) { print("equal") }
            if (x != y) { print("not equal") }
        }
        """
        try run(source, expectOutput: ["less", "less or equal", "greater", "greater or equal", "equal", "not equal"])
    }

    @Test("Unary operators")
    func unaryOperators() throws {
        let source = """
        func main() {
            var x: Int = 5
            print("\\(-x)")
            var b: Bool = true
            if (!b) {
                print("false")
            } else {
                print("true")
            }
        }
        """
        try run(source, expectOutput: ["-5", "true"])
    }

    @Test("Recursive function")
    func recursiveFunction() throws {
        let source = """
        func factorial(n: Int) -> Int {
            if (n <= 1) {
                return 1
            }
            return n * factorial(n - 1)
        }

        func main() {
            print("\\(factorial(5))")
        }
        """
        try run(source, expectOutput: ["120"])
    }

    @Test("Variable scoping")
    func variableScoping() throws {
        let source = """
        func main() {
            var x: Int = 1
            if (true) {
                var x: Int = 2
                print("\\(x)")
            }
            print("\\(x)")
        }
        """
        try run(source, expectOutput: ["2", "1"])
    }

    @Test("Assignment")
    func assignment() throws {
        let source = """
        func main() {
            var x: Int = 5
            print("\\(x)")
            x = 10
            print("\\(x)")
        }
        """
        try run(source, expectOutput: ["5", "10"])
    }

    @Test("Compound assignment")
    func compoundAssignment() throws {
        let source = """
        func main() {
            var x: Int = 10
            x += 5
            print("\\(x)")
            x -= 3
            print("\\(x)")
            x *= 2
            print("\\(x)")
            x /= 4
            print("\\(x)")
        }
        """
        try run(source, expectOutput: ["15", "12", "24", "6"])
    }

    @Test("String concatenation")
    func stringConcatenation() throws {
        let source = """
        func main() {
            var a: String = "Hello"
            var b: String = " World"
            print(a + b)
        }
        """
        try run(source, expectOutput: ["Hello World"])
    }

    @Test("Equality comparison for enums")
    func enumEquality() throws {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var a: Direction = Direction.up
            var b: Direction = Direction.up
            if (a == b) {
                print("equal")
            } else {
                print("not equal")
            }
        }
        """
        try run(source, expectOutput: ["equal"])
    }
}

// MARK: - Test Interpreter

/// Custom interpreter for testing that captures print output
class TestInterpreter {
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
        } catch let returnValue as ReturnValue {
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
            throw ReturnValue(value: retValue)
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

    private func evaluate(_ expr: Expression) throws -> Value {
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

    private func evaluateBinary(left: Expression, op: BinaryOperator, right: Expression) throws -> Value {
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

    private func evalCompound(_ left: Expression, _ right: Expression, _ fn: (Int, Int) -> Int) throws -> Value {
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

// Re-use ReturnValue from Interpreter (won't be visible so we redefine)
private struct ReturnValue: Error {
    let value: Value
}
