import Testing
@testable import SlangCore

@Suite("Parser Tests")
struct ParserTests {
    // MARK: - Helper

    func parse(_ source: String) throws -> [Declaration] {
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        return try parser.parse()
    }

    // MARK: - Function Declarations

    @Test("Simple function")
    func simpleFunction() throws {
        let source = """
        func main() {
        }
        """
        let decls = try parse(source)

        #expect(decls.count == 1)
        guard case .function(let name, let params, let returnType, _) = decls[0].kind else {
            Issue.record("Expected function declaration")
            return
        }
        #expect(name == "main")
        #expect(params.isEmpty)
        #expect(returnType == nil)
    }

    @Test("Function with parameters and return type")
    func functionWithParams() throws {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }
        """
        let decls = try parse(source)

        #expect(decls.count == 1)
        guard case .function(let name, let params, let returnType, let body) = decls[0].kind else {
            Issue.record("Expected function declaration")
            return
        }
        #expect(name == "add")
        #expect(params.count == 2)
        #expect(params[0].name == "a")
        #expect(params[0].type.name == "Int")
        #expect(params[1].name == "b")
        #expect(params[1].type.name == "Int")
        #expect(returnType?.name == "Int")

        // Check body has a return statement
        guard case .block(let statements) = body.kind else {
            Issue.record("Expected block statement")
            return
        }
        #expect(statements.count == 1)
        guard case .returnStmt(let value) = statements[0].kind else {
            Issue.record("Expected return statement")
            return
        }
        #expect(value != nil)
    }

    // MARK: - Struct Declarations

    @Test("Struct declaration")
    func structDeclaration() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }
        """
        let decls = try parse(source)

        #expect(decls.count == 1)
        guard case .structDecl(let name, let fields) = decls[0].kind else {
            Issue.record("Expected struct declaration")
            return
        }
        #expect(name == "Point")
        #expect(fields.count == 2)
        #expect(fields[0].name == "x")
        #expect(fields[0].type.name == "Int")
        #expect(fields[1].name == "y")
        #expect(fields[1].type.name == "Int")
    }

    // MARK: - Enum Declarations

    @Test("Enum declaration")
    func enumDeclaration() throws {
        let source = """
        enum Direction {
            case up
            case down
            case left
            case right
        }
        """
        let decls = try parse(source)

        #expect(decls.count == 1)
        guard case .enumDecl(let name, let cases) = decls[0].kind else {
            Issue.record("Expected enum declaration")
            return
        }
        #expect(name == "Direction")
        #expect(cases.count == 4)
        #expect(cases[0].name == "up")
        #expect(cases[1].name == "down")
        #expect(cases[2].name == "left")
        #expect(cases[3].name == "right")
    }

    // MARK: - Expressions

    @Test("Integer literal")
    func intLiteral() throws {
        let source = """
        func main() {
            42
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .intLiteral(let value) = expr.kind else {
            Issue.record("Expected int literal")
            return
        }
        #expect(value == 42)
    }

    @Test("Binary expression")
    func binaryExpression() throws {
        let source = """
        func main() {
            1 + 2 * 3
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .binary(let left, let op, let right) = expr.kind else {
            Issue.record("Expected binary expression")
            return
        }

        // Should be (1) + (2 * 3) due to precedence
        #expect(op == .add)
        guard case .intLiteral(1) = left.kind else {
            Issue.record("Left should be 1")
            return
        }
        guard case .binary(let inner_left, let inner_op, let inner_right) = right.kind else {
            Issue.record("Right should be binary")
            return
        }
        #expect(inner_op == .multiply)
        guard case .intLiteral(2) = inner_left.kind, case .intLiteral(3) = inner_right.kind else {
            Issue.record("Inner operands should be 2 and 3")
            return
        }
    }

    @Test("Comparison expression")
    func comparisonExpression() throws {
        let source = """
        func main() {
            x < 10
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .binary(_, let op, _) = expr.kind else {
            Issue.record("Expected comparison expression")
            return
        }
        #expect(op == .less)
    }

    @Test("Logical expression")
    func logicalExpression() throws {
        let source = """
        func main() {
            x > 0 && y > 0
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .binary(_, let op, _) = expr.kind else {
            Issue.record("Expected logical expression")
            return
        }
        #expect(op == .and)
    }

    @Test("Unary expression")
    func unaryExpression() throws {
        let source = """
        func main() {
            -5
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .unary(let op, let operand) = expr.kind else {
            Issue.record("Expected unary expression")
            return
        }
        #expect(op == .negate)
        guard case .intLiteral(5) = operand.kind else {
            Issue.record("Expected int literal 5")
            return
        }
    }

    @Test("Function call")
    func functionCall() throws {
        let source = """
        func main() {
            print("hello")
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .call(let callee, let args) = expr.kind else {
            Issue.record("Expected call expression")
            return
        }
        guard case .identifier("print") = callee.kind else {
            Issue.record("Expected identifier 'print'")
            return
        }
        #expect(args.count == 1)
    }

    @Test("Member access")
    func memberAccess() throws {
        let source = """
        func main() {
            point.x
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .memberAccess(let object, let member) = expr.kind else {
            Issue.record("Expected member access expression")
            return
        }
        guard case .identifier("point") = object.kind else {
            Issue.record("Expected identifier 'point'")
            return
        }
        #expect(member == "x")
    }

    @Test("Struct initialization")
    func structInit() throws {
        let source = """
        func main() {
            Point { x: 1, y: 2 }
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .structInit(let typeName, let fields) = expr.kind else {
            Issue.record("Expected struct init expression")
            return
        }
        #expect(typeName == "Point")
        #expect(fields.count == 2)
        #expect(fields[0].name == "x")
        #expect(fields[1].name == "y")
    }

    // MARK: - Statements

    @Test("Variable declaration")
    func varDecl() throws {
        let source = """
        func main() {
            var x: Int = 42
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .varDecl(let name, let type, let initializer) = statements[0].kind else {
            Issue.record("Expected var declaration")
            return
        }
        #expect(name == "x")
        #expect(type.name == "Int")
        guard case .intLiteral(42) = initializer.kind else {
            Issue.record("Expected int literal 42")
            return
        }
    }

    @Test("If statement")
    func ifStatement() throws {
        let source = """
        func main() {
            if (x > 0) {
                print("positive")
            }
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .ifStmt(let condition, let thenBranch, let elseBranch) = statements[0].kind else {
            Issue.record("Expected if statement")
            return
        }
        guard case .binary(_, .greater, _) = condition.kind else {
            Issue.record("Expected comparison condition")
            return
        }
        guard case .block(_) = thenBranch.kind else {
            Issue.record("Expected block for then branch")
            return
        }
        #expect(elseBranch == nil)
    }

    @Test("If-else statement")
    func ifElseStatement() throws {
        let source = """
        func main() {
            if (x > 0) {
                print("positive")
            } else {
                print("non-positive")
            }
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .ifStmt(_, _, let elseBranch) = statements[0].kind else {
            Issue.record("Expected if statement")
            return
        }
        #expect(elseBranch != nil)
        guard case .block(_) = elseBranch?.kind else {
            Issue.record("Expected block for else branch")
            return
        }
    }

    @Test("For loop")
    func forLoop() throws {
        let source = """
        func main() {
            for (var i: Int = 0; i < 10; i = i + 1) {
                print("loop")
            }
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .forStmt(let initializer, let condition, let increment, let loopBody) = statements[0].kind else {
            Issue.record("Expected for statement")
            return
        }
        #expect(initializer != nil)
        guard case .varDecl("i", _, _) = initializer?.kind else {
            Issue.record("Expected var decl in for initializer")
            return
        }
        #expect(condition != nil)
        #expect(increment != nil)
        guard case .block(_) = loopBody.kind else {
            Issue.record("Expected block for loop body")
            return
        }
    }

    @Test("Switch statement")
    func switchStatement() throws {
        let source = """
        func main() {
            switch (dir) {
                Direction.up -> print("up")
                Direction.down -> print("down")
            }
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .switchStmt(let subject, let cases) = statements[0].kind else {
            Issue.record("Expected switch statement")
            return
        }
        guard case .identifier("dir") = subject.kind else {
            Issue.record("Expected identifier 'dir' as subject")
            return
        }
        #expect(cases.count == 2)
    }

    @Test("Return statement")
    func returnStatement() throws {
        let source = """
        func getValue() -> Int {
            return 42
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .returnStmt(let value) = statements[0].kind else {
            Issue.record("Expected return statement")
            return
        }
        #expect(value != nil)
        guard case .intLiteral(42) = value?.kind else {
            Issue.record("Expected int literal 42")
            return
        }
    }

    // MARK: - String Interpolation

    @Test("String interpolation")
    func stringInterpolation() throws {
        let source = """
        func main() {
            "Hello \\(name)!"
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .expression(let expr) = statements[0].kind,
              case .stringInterpolation(let parts) = expr.kind else {
            Issue.record("Expected string interpolation")
            return
        }
        #expect(parts.count == 3)
        guard case .literal("Hello ") = parts[0],
              case .interpolation(let interpolatedExpr) = parts[1],
              case .literal("!") = parts[2] else {
            Issue.record("Unexpected string parts")
            return
        }
        guard case .identifier("name") = interpolatedExpr.kind else {
            Issue.record("Expected identifier 'name'")
            return
        }
    }

    // MARK: - Full Program

    @Test("Full program")
    func fullProgram() throws {
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
        }
        """
        let decls = try parse(source)

        #expect(decls.count == 4)
        #expect(decls[0].name == "Point")
        #expect(decls[1].name == "Direction")
        #expect(decls[2].name == "add")
        #expect(decls[3].name == "main")
    }

    // MARK: - Switch Expression Tests (v0.1.1)

    @Test("Switch expression in variable initialization")
    func switchExpressionParsing() throws {
        let source = """
        func main() {
            var x: Direction = switch (dir) {
                Direction.up -> return Direction.down
                Direction.down -> return Direction.up
            }
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .varDecl("x", _, let initializer) = statements[0].kind,
              case .switchExpr(let subject, let cases) = initializer.kind else {
            Issue.record("Expected switch expression in variable initialization")
            return
        }
        guard case .identifier("dir") = subject.kind else {
            Issue.record("Expected identifier 'dir' as subject")
            return
        }
        #expect(cases.count == 2)
    }

    @Test("Switch expression with block bodies")
    func switchExpressionWithBlocks() throws {
        let source = """
        func main() {
            var x: Int = switch (c) {
                Color.red -> { return 1 }
                Color.green -> { return 2 }
            }
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .varDecl("x", _, let initializer) = statements[0].kind,
              case .switchExpr(_, let cases) = initializer.kind else {
            Issue.record("Expected switch expression")
            return
        }
        #expect(cases.count == 2)
        // First case should have a block body
        guard case .block(_) = cases[0].body.kind else {
            Issue.record("Expected block body for first case")
            return
        }
    }

    @Test("Switch expression mixed case styles")
    func switchExpressionMixedStyles() throws {
        let source = """
        func main() {
            var x: String = switch (s) {
                Status.on -> return "active"
                Status.off -> {
                    return "inactive"
                }
            }
        }
        """
        let decls = try parse(source)

        guard case .function(_, _, _, let body) = decls[0].kind,
              case .block(let statements) = body.kind,
              case .varDecl("x", _, let initializer) = statements[0].kind,
              case .switchExpr(_, let cases) = initializer.kind else {
            Issue.record("Expected switch expression")
            return
        }
        #expect(cases.count == 2)
        // First case should have return statement body
        guard case .returnStmt(_) = cases[0].body.kind else {
            Issue.record("Expected return statement for first case")
            return
        }
        // Second case should have block body
        guard case .block(_) = cases[1].body.kind else {
            Issue.record("Expected block body for second case")
            return
        }
    }

    // MARK: - Union Declaration Tests (v0.1.2)

    @Test("Union declaration with two variants")
    func unionDeclarationTwoVariants() throws {
        let source = """
        union Pet = Dog | Cat
        """
        let decls = try parse(source)

        #expect(decls.count == 1)
        guard case .unionDecl(let name, let variants) = decls[0].kind else {
            Issue.record("Expected union declaration")
            return
        }
        #expect(name == "Pet")
        #expect(variants.count == 2)
        #expect(variants[0].typeName == "Dog")
        #expect(variants[1].typeName == "Cat")
    }

    @Test("Union declaration with primitives")
    func unionDeclarationPrimitives() throws {
        let source = """
        union Value = Int | String
        """
        let decls = try parse(source)

        guard case .unionDecl(let name, let variants) = decls[0].kind else {
            Issue.record("Expected union declaration")
            return
        }
        #expect(name == "Value")
        #expect(variants.count == 2)
        #expect(variants[0].typeName == "Int")
        #expect(variants[1].typeName == "String")
    }

    @Test("Union declaration with multiple variants")
    func unionDeclarationMultipleVariants() throws {
        let source = """
        union Result = Success | Error | Pending
        """
        let decls = try parse(source)

        guard case .unionDecl(let name, let variants) = decls[0].kind else {
            Issue.record("Expected union declaration")
            return
        }
        #expect(name == "Result")
        #expect(variants.count == 3)
        #expect(variants[0].typeName == "Success")
        #expect(variants[1].typeName == "Error")
        #expect(variants[2].typeName == "Pending")
    }

    @Test("Program with union and structs")
    func programWithUnionAndStructs() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
        }
        """
        let decls = try parse(source)

        #expect(decls.count == 4)
        guard case .structDecl("Dog", _) = decls[0].kind else {
            Issue.record("Expected struct Dog")
            return
        }
        guard case .structDecl("Cat", _) = decls[1].kind else {
            Issue.record("Expected struct Cat")
            return
        }
        guard case .unionDecl("Pet", let variants) = decls[2].kind else {
            Issue.record("Expected union Pet")
            return
        }
        #expect(variants.count == 2)
    }
}
