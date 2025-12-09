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

    // MARK: - Switch Expression Tests (v0.1.1)

    @Test("Switch expression - basic enum return")
    func switchExpressionBasic() throws {
        let source = """
        enum Direction {
            case up
            case down
            case left
            case right
        }

        func main() {
            var dir: Direction = Direction.up
            var opposite: Direction = switch (dir) {
                Direction.up -> return Direction.down
                Direction.down -> return Direction.up
                Direction.left -> return Direction.right
                Direction.right -> return Direction.left
            }
            switch (opposite) {
                Direction.up -> print("up")
                Direction.down -> print("down")
                Direction.left -> print("left")
                Direction.right -> print("right")
            }
        }
        """
        try run(source, expectOutput: ["down"])
    }

    @Test("Switch expression - with block bodies")
    func switchExpressionBlockBodies() throws {
        let source = """
        enum Color {
            case red
            case green
            case blue
        }

        func main() {
            var c: Color = Color.green
            var value: Int = switch (c) {
                Color.red -> { return 1 }
                Color.green -> { return 2 }
                Color.blue -> { return 3 }
            }
            print("\\(value)")
        }
        """
        try run(source, expectOutput: ["2"])
    }

    @Test("Switch expression - mixed single-line and block")
    func switchExpressionMixed() throws {
        let source = """
        enum Status {
            case active
            case inactive
        }

        func main() {
            var s: Status = Status.active
            var msg: String = switch (s) {
                Status.active -> return "on"
                Status.inactive -> {
                    return "off"
                }
            }
            print(msg)
        }
        """
        try run(source, expectOutput: ["on"])
    }

    @Test("Switch expression - returning Int")
    func switchExpressionInt() throws {
        let source = """
        enum Size {
            case small
            case medium
            case large
        }

        func main() {
            var size: Size = Size.large
            var pixels: Int = switch (size) {
                Size.small -> return 100
                Size.medium -> return 200
                Size.large -> return 300
            }
            print("\\(pixels)")
        }
        """
        try run(source, expectOutput: ["300"])
    }

    @Test("Switch expression - returning String")
    func switchExpressionString() throws {
        let source = """
        enum Level {
            case low
            case high
        }

        func main() {
            var lvl: Level = Level.low
            var desc: String = switch (lvl) {
                Level.low -> return "Low level"
                Level.high -> return "High level"
            }
            print(desc)
        }
        """
        try run(source, expectOutput: ["Low level"])
    }

    @Test("Switch expression - all cases covered")
    func switchExpressionAllCases() throws {
        let source = """
        enum TrafficLight {
            case red
            case yellow
            case green
        }

        func main() {
            var light: TrafficLight = TrafficLight.yellow
            var action: String = switch (light) {
                TrafficLight.red -> return "Stop"
                TrafficLight.yellow -> return "Caution"
                TrafficLight.green -> return "Go"
            }
            print(action)
        }
        """
        try run(source, expectOutput: ["Caution"])
    }

    // MARK: - Union Tests (v0.1.2)

    @Test("Union construction with struct")
    func unionConstructionStruct() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
            switch (pet) {
                Pet.Dog -> print("It's a dog!")
                Pet.Cat -> print("It's a cat!")
            }
        }
        """
        try run(source, expectOutput: ["It's a dog!"])
    }

    @Test("Union with primitives")
    func unionPrimitives() throws {
        let source = """
        union Value = Int | String

        func main() {
            var v: Value = Value.Int(42)
            switch (v) {
                Value.Int -> print("integer")
                Value.String -> print("string")
            }
        }
        """
        try run(source, expectOutput: ["integer"])
    }

    @Test("Union multiple cases")
    func unionMultipleCases() throws {
        let source = """
        struct Success { value: Int }
        struct Error { message: String }
        struct Pending { id: Int }
        union Result = Success | Error | Pending

        func main() {
            var r: Result = Result.Error(Error { message: "oops" })
            switch (r) {
                Result.Success -> print("success")
                Result.Error -> print("error")
                Result.Pending -> print("pending")
            }
        }
        """
        try run(source, expectOutput: ["error"])
    }

    @Test("Union switch expression")
    func unionSwitchExpression() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func describePet(pet: Pet) -> String {
            return switch (pet) {
                Pet.Dog -> return "dog"
                Pet.Cat -> return "cat"
            }
        }

        func main() {
            var pet: Pet = Pet.Cat(Cat { name: "Whiskers" })
            print(describePet(pet))
        }
        """
        try run(source, expectOutput: ["cat"])
    }

    @Test("Union with String primitive")
    func unionStringPrimitive() throws {
        let source = """
        union Value = Int | String

        func main() {
            var v: Value = Value.String("hello world")
            switch (v) {
                Value.Int -> print("number")
                Value.String -> print("text")
            }
        }
        """
        try run(source, expectOutput: ["text"])
    }

    @Test("Union in function parameter")
    func unionFunctionParameter() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func describe(pet: Pet) -> String {
            var result: String = ""
            switch (pet) {
                Pet.Dog -> result = "woof"
                Pet.Cat -> result = "meow"
            }
            return result
        }

        func main() {
            var d: Dog = Dog { name: "Rex" }
            var pet: Pet = Pet.Dog(d)
            print(describe(pet))
        }
        """
        try run(source, expectOutput: ["woof"])
    }

    // MARK: - Union Type Narrowing Tests (v0.1.2)

    @Test("Union type narrowing - access struct field")
    func unionTypeNarrowingStructField() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
            switch (pet) {
                Pet.Dog -> print(pet.name)
                Pet.Cat -> print(pet.name)
            }
        }
        """
        try run(source, expectOutput: ["Buddy"])
    }

    @Test("Union type narrowing - access cat variant")
    func unionTypeNarrowingCatVariant() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var pet: Pet = Pet.Cat(Cat { name: "Whiskers" })
            switch (pet) {
                Pet.Dog -> print(pet.name)
                Pet.Cat -> print(pet.name)
            }
        }
        """
        try run(source, expectOutput: ["Whiskers"])
    }

    @Test("Union type narrowing - primitive Int")
    func unionTypeNarrowingPrimitiveInt() throws {
        let source = """
        union Value = Int | String

        func main() {
            var v: Value = Value.Int(42)
            switch (v) {
                Value.Int -> print("number: \\(v)")
                Value.String -> print("text: \\(v)")
            }
        }
        """
        try run(source, expectOutput: ["number: 42"])
    }

    @Test("Union type narrowing - primitive String")
    func unionTypeNarrowingPrimitiveString() throws {
        let source = """
        union Value = Int | String

        func main() {
            var v: Value = Value.String("hello")
            switch (v) {
                Value.Int -> print("number: \\(v)")
                Value.String -> print("text: \\(v)")
            }
        }
        """
        try run(source, expectOutput: ["text: hello"])
    }

    @Test("Union type narrowing - switch expression")
    func unionTypeNarrowingSwitchExpr() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var pet: Pet = Pet.Dog(Dog { name: "Rex" })
            var name: String = switch (pet) {
                Pet.Dog -> return pet.name
                Pet.Cat -> return pet.name
            }
            print(name)
        }
        """
        try run(source, expectOutput: ["Rex"])
    }

    @Test("Union type narrowing - complex struct")
    func unionTypeNarrowingComplexStruct() throws {
        let source = """
        struct Loading { progress: Int }
        struct Success { value: Int }
        struct Error { message: String }
        union State = Loading | Success | Error

        func main() {
            var state: State = State.Loading(Loading { progress: 50 })
            switch (state) {
                State.Loading -> print("Loading: \\(state.progress)%")
                State.Success -> print("Success: \\(state.value)")
                State.Error -> print("Error: \\(state.message)")
            }
        }
        """
        try run(source, expectOutput: ["Loading: 50%"])
    }

    @Test("Union type narrowing - in function")
    func unionTypeNarrowingInFunction() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func getPetName(pet: Pet) -> String {
            return switch (pet) {
                Pet.Dog -> return pet.name
                Pet.Cat -> return pet.name
            }
        }

        func main() {
            var p: Pet = Pet.Cat(Cat { name: "Felix" })
            print(getPetName(p))
        }
        """
        try run(source, expectOutput: ["Felix"])
    }
}
