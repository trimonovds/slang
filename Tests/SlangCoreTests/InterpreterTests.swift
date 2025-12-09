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

        // Capture print output using the real Interpreter with custom handler
        var output: [String] = []
        let interpreter = Interpreter(printHandler: { output.append($0) })
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
