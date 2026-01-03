import Testing
@testable import SlangCore

@Suite("TypeChecker Tests")
struct TypeCheckerTests {
    // MARK: - Helper

    func typeCheck(_ source: String) throws {
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        let checker = TypeChecker()
        try checker.check(decls)
    }

    func expectTypeError(_ source: String, containing message: String) {
        do {
            try typeCheck(source)
            Issue.record("Expected type error but none thrown")
        } catch let error as TypeCheckError {
            let messages = error.diagnostics.map { $0.message }
            let found = messages.contains { $0.contains(message) }
            #expect(found, "Expected error containing '\(message)', got: \(messages)")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Valid Programs

    @Test("Valid: Simple function")
    func validSimpleFunction() throws {
        let source = """
        func main() {
            var x: Int = 42
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Function with return")
    func validFunctionWithReturn() throws {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }

        func main() {
            var result: Int = add(1, 2)
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Struct usage")
    func validStructUsage() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func main() {
            var p = Point { x: 3, y: 4 }
            var x: Int = p.x
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Enum and switch")
    func validEnumAndSwitch() throws {
        let source = """
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
                Direction.left -> print("left")
                Direction.right -> print("right")
            }
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: If statement")
    func validIfStatement() throws {
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
        try typeCheck(source)
    }

    @Test("Valid: For loop")
    func validForLoop() throws {
        let source = """
        func main() {
            for (var i: Int = 0; i < 10; i = i + 1) {
                print("loop")
            }
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: String interpolation")
    func validStringInterpolation() throws {
        let source = """
        func main() {
            var x: Int = 42
            print("Value: \\(x)")
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Boolean operations")
    func validBooleanOperations() throws {
        let source = """
        func main() {
            var a: Bool = true
            var b: Bool = false
            var c: Bool = a && b
            var d: Bool = a || b
            var e: Bool = !a
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Comparison operations")
    func validComparisonOperations() throws {
        let source = """
        func main() {
            var x: Int = 10
            var y: Int = 20
            var a: Bool = x < y
            var b: Bool = x <= y
            var c: Bool = x > y
            var d: Bool = x >= y
            var e: Bool = x == y
            var f: Bool = x != y
        }
        """
        try typeCheck(source)
    }

    // MARK: - Type Errors

    @Test("Error: Type mismatch in variable declaration")
    func errorTypeMismatch() {
        let source = """
        func main() {
            var x: Int = "hello"
        }
        """
        expectTypeError(source, containing: "Cannot assign value of type 'String' to variable of type 'Int'")
    }

    @Test("Error: Undefined variable")
    func errorUndefinedVariable() {
        let source = """
        func main() {
            print(x)
        }
        """
        expectTypeError(source, containing: "Undefined variable 'x'")
    }

    @Test("Error: Wrong argument type")
    func errorWrongArgumentType() {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }

        func main() {
            add("hello", 5)
        }
        """
        expectTypeError(source, containing: "Argument type 'String' does not match parameter type 'Int'")
    }

    @Test("Error: Wrong argument count")
    func errorWrongArgumentCount() {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }

        func main() {
            add(1)
        }
        """
        expectTypeError(source, containing: "Expected 2 argument(s), got 1")
    }

    @Test("Error: Non-Bool condition in if")
    func errorNonBoolCondition() {
        let source = """
        func main() {
            if (42) {
                print("wrong")
            }
        }
        """
        expectTypeError(source, containing: "Condition must be of type 'Bool', got 'Int'")
    }

    @Test("Error: Non-Bool condition in for loop")
    func errorNonBoolForCondition() {
        let source = """
        func main() {
            for (var i: Int = 0; i; i = i + 1) {
                print("wrong")
            }
        }
        """
        expectTypeError(source, containing: "For loop condition must be of type 'Bool', got 'Int'")
    }

    @Test("Error: Non-exhaustive switch")
    func errorNonExhaustiveSwitch() {
        let source = """
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
        """
        expectTypeError(source, containing: "Switch must be exhaustive")
    }

    @Test("Error: Unknown struct field")
    func errorUnknownStructField() {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func main() {
            var p = Point { x: 1, y: 2 }
            var z: Int = p.z
        }
        """
        expectTypeError(source, containing: "Struct 'Point' has no field 'z'")
    }

    @Test("Error: Missing struct field in initialization")
    func errorMissingStructField() {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func main() {
            var p = Point { x: 1 }
        }
        """
        expectTypeError(source, containing: "Missing fields in struct initialization")
    }

    @Test("Error: Wrong return type")
    func errorWrongReturnType() {
        let source = """
        func getValue() -> Int {
            return "hello"
        }

        func main() {
        }
        """
        expectTypeError(source, containing: "Cannot return value of type 'String' from function expecting 'Int'")
    }

    @Test("Error: Missing return")
    func errorMissingReturn() {
        let source = """
        func getValue() -> Int {
            var x: Int = 42
        }

        func main() {
        }
        """
        expectTypeError(source, containing: "Function 'getValue' must return a value of type 'Int'")
    }

    @Test("Error: Arithmetic on non-numeric types")
    func errorArithmeticOnNonNumeric() {
        let source = """
        func main() {
            var x: Bool = true
            var y: Int = x + 1
        }
        """
        expectTypeError(source, containing: "Cannot apply '+' to 'Bool' and 'Int'")
    }

    @Test("Error: Logical operators on non-Bool")
    func errorLogicalOnNonBool() {
        let source = """
        func main() {
            var x: Int = 1 && 2
        }
        """
        expectTypeError(source, containing: "Logical operators require Bool operands")
    }

    @Test("Error: Cannot call non-function")
    func errorCallNonFunction() {
        let source = """
        func main() {
            var x: Int = 42
            x()
        }
        """
        expectTypeError(source, containing: "Cannot call non-function type 'Int'")
    }

    @Test("Error: Unknown type")
    func errorUnknownType() {
        let source = """
        func main() {
            var x: Foo = 42
        }
        """
        expectTypeError(source, containing: "Unknown type 'Foo'")
    }

    @Test("Error: Duplicate enum case in switch")
    func errorDuplicateSwitchCase() {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var d: Direction = Direction.up
            switch (d) {
                Direction.up -> print("up")
                Direction.up -> print("up again")
                Direction.down -> print("down")
            }
        }
        """
        expectTypeError(source, containing: "Duplicate case 'up' in switch")
    }

    @Test("Error: Invalid enum case")
    func errorInvalidEnumCase() {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var d: Direction = Direction.left
        }
        """
        expectTypeError(source, containing: "'left' is not a case of enum 'Direction'")
    }

    // MARK: - Type Inference

    @Test("Valid: Type inference from struct init")
    func validTypeInference() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func main() {
            var p = Point { x: 1, y: 2 }
            var x: Int = p.x
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Type inference from function call")
    func validTypeInferenceFromCall() throws {
        let source = """
        func getInt() -> Int {
            return 42
        }

        func main() {
            var x = getInt()
            var y: Int = x + 1
        }
        """
        try typeCheck(source)
    }

    // MARK: - Switch Expression Tests (v0.1.1)

    @Test("Valid: Switch expression basic")
    func validSwitchExpression() throws {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var dir: Direction = Direction.up
            var opposite: Direction = switch (dir) {
                Direction.up -> return Direction.down
                Direction.down -> return Direction.up
            }
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Switch expression with blocks")
    func validSwitchExpressionBlocks() throws {
        let source = """
        enum Color {
            case red
            case green
        }

        func main() {
            var c: Color = Color.red
            var value: Int = switch (c) {
                Color.red -> { return 1 }
                Color.green -> { return 2 }
            }
        }
        """
        try typeCheck(source)
    }

    @Test("Error: Switch expression non-exhaustive")
    func errorSwitchExprNonExhaustive() {
        let source = """
        enum Direction {
            case up
            case down
            case left
            case right
        }

        func main() {
            var dir: Direction = Direction.up
            var x: Direction = switch (dir) {
                Direction.up -> return Direction.down
                Direction.down -> return Direction.up
            }
        }
        """
        expectTypeError(source, containing: "Switch expression must be exhaustive")
    }

    @Test("Error: Switch expression type mismatch between cases")
    func errorSwitchExprTypeMismatch() {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var dir: Direction = Direction.up
            var x: Int = switch (dir) {
                Direction.up -> return 1
                Direction.down -> return "two"
            }
        }
        """
        expectTypeError(source, containing: "Switch expression cases must all return the same type")
    }

    @Test("Error: Switch expression case without return")
    func errorSwitchExprNoReturn() {
        let source = """
        enum Color {
            case red
            case green
        }

        func main() {
            var c: Color = Color.red
            var x: Int = switch (c) {
                Color.red -> return 1
                Color.green -> print("green")
            }
        }
        """
        expectTypeError(source, containing: "Switch expression case must return a value")
    }

    @Test("Error: Switch expression duplicate case")
    func errorSwitchExprDuplicateCase() {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var dir: Direction = Direction.up
            var x: Direction = switch (dir) {
                Direction.up -> return Direction.down
                Direction.up -> return Direction.down
                Direction.down -> return Direction.up
            }
        }
        """
        expectTypeError(source, containing: "Duplicate case 'up' in switch expression")
    }

    @Test("Error: Switch expression on non-enum")
    func errorSwitchExprNonEnum() {
        let source = """
        func main() {
            var x: Int = 42
            var y: Int = switch (x) {
                1 -> return 10
                2 -> return 20
            }
        }
        """
        expectTypeError(source, containing: "Switch expression subject must be an enum, union, or optional type")
    }

    // MARK: - Union Tests (v0.1.2)

    @Test("Valid: Union with struct variants")
    func validUnionStructs() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var d: Dog = Dog { name: "Buddy" }
            var pet: Pet = Pet.Dog(d)
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Union with primitives")
    func validUnionPrimitives() throws {
        let source = """
        union Value = Int | String

        func main() {
            var v1: Value = Value.Int(42)
            var v2: Value = Value.String("hello")
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Union switch exhaustive")
    func validUnionSwitchExhaustive() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
            switch (pet) {
                Pet.Dog -> print("dog")
                Pet.Cat -> print("cat")
            }
        }
        """
        try typeCheck(source)
    }

    @Test("Valid: Union switch expression")
    func validUnionSwitchExpr() throws {
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
            var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
            print(describePet(pet))
        }
        """
        try typeCheck(source)
    }

    @Test("Error: Union switch non-exhaustive")
    func errorUnionSwitchNonExhaustive() {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
            switch (pet) {
                Pet.Dog -> print("dog")
            }
        }
        """
        expectTypeError(source, containing: "Switch must be exhaustive. Missing variants: Cat")
    }

    @Test("Error: Invalid union variant")
    func errorInvalidUnionVariant() {
        let source = """
        struct Dog { name: String }
        union Pet = Dog

        func main() {
            var pet: Pet = Pet.Cat(Dog { name: "Buddy" })
        }
        """
        expectTypeError(source, containing: "'Cat' is not a variant of union 'Pet'")
    }

    @Test("Error: Wrong type for union variant")
    func errorWrongUnionVariantType() {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var pet: Pet = Pet.Dog(Cat { name: "Whiskers" })
        }
        """
        expectTypeError(source, containing: "does not match parameter type")
    }

    @Test("Error: Unknown type in union variant")
    func errorUnknownTypeInUnion() {
        let source = """
        union Pet = Dog | Cat

        func main() {
        }
        """
        expectTypeError(source, containing: "Unknown type 'Dog' in union variant")
    }

    @Test("Error: Duplicate variant in union")
    func errorDuplicateUnionVariant() {
        let source = """
        struct Dog { name: String }
        union Pet = Dog | Dog

        func main() {
        }
        """
        expectTypeError(source, containing: "Duplicate variant 'Dog' in union 'Pet'")
    }

    @Test("Valid: Union with three variants")
    func validUnionThreeVariants() throws {
        let source = """
        struct Success { value: Int }
        struct Error { message: String }
        struct Pending { id: Int }
        union Result = Success | Error | Pending

        func main() {
            var r: Result = Result.Pending(Pending { id: 1 })
            switch (r) {
                Result.Success -> print("ok")
                Result.Error -> print("err")
                Result.Pending -> print("wait")
            }
        }
        """
        try typeCheck(source)
    }
}
