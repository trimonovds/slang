// Tests/SlangCoreTests/SymbolCollectorTests.swift

import Testing
@testable import SlangCore

@Suite("SymbolCollector Tests")
struct SymbolCollectorTests {

    // MARK: - Helper

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    // MARK: - Function Definitions

    @Test("Collects function definition")
    func functionDefinition() throws {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }
        """

        let symbols = try collectSymbols(from: source)

        let funcDef = symbols.definitions.first { $0.kind == .function && $0.name == "add" }
        #expect(funcDef != nil)
        #expect(funcDef?.type?.description == "(Int, Int) -> Int")
    }

    @Test("Collects function parameters")
    func functionParameters() throws {
        let source = """
        func greet(name: String, age: Int) {
            print(name)
        }
        """

        let symbols = try collectSymbols(from: source)

        let params = symbols.definitions.filter { $0.kind == .parameter }
        #expect(params.count == 2)

        let nameParam = params.first { $0.name == "name" }
        #expect(nameParam != nil)
        #expect(nameParam?.type == .string)

        let ageParam = params.first { $0.name == "age" }
        #expect(ageParam != nil)
        #expect(ageParam?.type == .int)
    }

    // MARK: - Struct Definitions

    @Test("Collects struct definition")
    func structDefinition() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }
        """

        let symbols = try collectSymbols(from: source)

        let structDef = symbols.definitions.first { $0.kind == .structType && $0.name == "Point" }
        #expect(structDef != nil)
        #expect(structDef?.type == .structType(name: "Point"))
    }

    @Test("Collects struct fields")
    func structFields() throws {
        let source = """
        struct Rectangle {
            width: Int
            height: Int
            name: String
        }
        """

        let symbols = try collectSymbols(from: source)

        let fields = symbols.definitions.filter { $0.kind == .field }
        #expect(fields.count == 3)

        let widthField = fields.first { $0.name == "width" }
        #expect(widthField != nil)
        #expect(widthField?.container == "Rectangle")
        #expect(widthField?.type == .int)

        let nameField = fields.first { $0.name == "name" }
        #expect(nameField != nil)
        #expect(nameField?.type == .string)
    }

    @Test("Struct field qualified name")
    func structFieldQualifiedName() throws {
        let source = """
        struct Point {
            x: Int
        }
        """

        let symbols = try collectSymbols(from: source)

        let field = symbols.definitions.first { $0.kind == .field }
        #expect(field?.qualifiedName == "Point.x")
    }

    // MARK: - Enum Definitions

    @Test("Collects enum definition")
    func enumDefinition() throws {
        let source = """
        enum Direction {
            case up
            case down
            case left
            case right
        }
        """

        let symbols = try collectSymbols(from: source)

        let enumDef = symbols.definitions.first { $0.kind == .enumType && $0.name == "Direction" }
        #expect(enumDef != nil)
        #expect(enumDef?.type == .enumType(name: "Direction"))
    }

    @Test("Collects enum cases")
    func enumCases() throws {
        let source = """
        enum Color {
            case red
            case green
            case blue
        }
        """

        let symbols = try collectSymbols(from: source)

        let cases = symbols.definitions.filter { $0.kind == .enumCase }
        #expect(cases.count == 3)

        let redCase = cases.first { $0.name == "red" }
        #expect(redCase != nil)
        #expect(redCase?.container == "Color")
        #expect(redCase?.qualifiedName == "Color.red")
    }

    // MARK: - Union Definitions

    @Test("Collects union definition")
    func unionDefinition() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat
        """

        let symbols = try collectSymbols(from: source)

        let unionDef = symbols.definitions.first { $0.kind == .unionType && $0.name == "Pet" }
        #expect(unionDef != nil)
        #expect(unionDef?.type == .unionType(name: "Pet"))
    }

    @Test("Collects union variants")
    func unionVariants() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat
        """

        let symbols = try collectSymbols(from: source)

        let variants = symbols.definitions.filter { $0.kind == .unionVariant }
        #expect(variants.count == 2)

        let dogVariant = variants.first { $0.name == "Dog" }
        #expect(dogVariant != nil)
        #expect(dogVariant?.container == "Pet")
    }

    @Test("Union with primitives")
    func unionWithPrimitives() throws {
        let source = """
        union Value = Int | String
        """

        let symbols = try collectSymbols(from: source)

        let variants = symbols.definitions.filter { $0.kind == .unionVariant }
        #expect(variants.count == 2)

        let intVariant = variants.first { $0.name == "Int" }
        #expect(intVariant != nil)
        #expect(intVariant?.type == .int)
    }

    // MARK: - Variable Definitions

    @Test("Collects variable declaration")
    func variableDeclaration() throws {
        let source = """
        func main() {
            var x: Int = 42
            var name: String = "hello"
        }
        """

        let symbols = try collectSymbols(from: source)

        let variables = symbols.definitions.filter { $0.kind == .variable }
        #expect(variables.count == 2)

        let xVar = variables.first { $0.name == "x" }
        #expect(xVar != nil)
        #expect(xVar?.type == .int)

        let nameVar = variables.first { $0.name == "name" }
        #expect(nameVar != nil)
        #expect(nameVar?.type == .string)
    }

    @Test("Collects for loop variable")
    func forLoopVariable() throws {
        let source = """
        func main() {
            for (var i: Int = 0; i < 10; i = i + 1) {
                print("\\(i)")
            }
        }
        """

        let symbols = try collectSymbols(from: source)

        let iVar = symbols.definitions.first { $0.kind == .variable && $0.name == "i" }
        #expect(iVar != nil)
        #expect(iVar?.type == .int)
    }

    // MARK: - References

    @Test("Collects variable references")
    func variableReferences() throws {
        let source = """
        func main() {
            var x: Int = 42
            var y: Int = x + 1
            print("\\(x)")
        }
        """

        let symbols = try collectSymbols(from: source)

        let xRefs = symbols.references.filter { $0.definition.name == "x" }
        #expect(xRefs.count >= 2)  // Used in y = x + 1 and print
    }

    @Test("Collects function call references")
    func functionCallReferences() throws {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }

        func main() {
            var result: Int = add(1, 2)
        }
        """

        let symbols = try collectSymbols(from: source)

        let addRefs = symbols.references.filter { $0.definition.name == "add" }
        #expect(addRefs.count >= 1)
    }

    @Test("Collects type annotation references")
    func typeAnnotationReferences() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func main() {
            var p: Point = Point { x: 1, y: 2 }
        }
        """

        let symbols = try collectSymbols(from: source)

        let pointRefs = symbols.references.filter { $0.definition.name == "Point" }
        #expect(pointRefs.count >= 1)  // At least the type annotation
    }

    @Test("Parameter references in function body")
    func parameterReferences() throws {
        let source = """
        func double(n: Int) -> Int {
            return n + n
        }
        """

        let symbols = try collectSymbols(from: source)

        let nRefs = symbols.references.filter { $0.definition.name == "n" }
        #expect(nRefs.count == 2)  // n + n
    }

    // MARK: - Scoping

    @Test("Variable scoping - block scope")
    func blockScoping() throws {
        let source = """
        func main() {
            var x: Int = 1
            if (true) {
                var x: Int = 2
            }
        }
        """

        let symbols = try collectSymbols(from: source)

        // Should have two separate variable definitions named x
        let xVars = symbols.definitions.filter { $0.kind == .variable && $0.name == "x" }
        #expect(xVars.count == 2)
    }

    @Test("Function scope isolation")
    func functionScopeIsolation() throws {
        let source = """
        func foo() {
            var x: Int = 1
        }

        func bar() {
            var x: Int = 2
        }
        """

        let symbols = try collectSymbols(from: source)

        let xVars = symbols.definitions.filter { $0.kind == .variable && $0.name == "x" }
        #expect(xVars.count == 2)
    }

    // MARK: - Complex Programs

    @Test("Complex program with all declaration types")
    func complexProgram() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        enum Direction {
            case north
            case south
        }

        union Shape = Point | Int

        func distance(p: Point) -> Int {
            return p.x + p.y
        }

        func main() {
            var pt: Point = Point { x: 3, y: 4 }
            var d: Int = distance(pt)
            var dir: Direction = Direction.north
        }
        """

        let symbols = try collectSymbols(from: source)

        // Check all definition types are present
        #expect(symbols.definitions.contains { $0.kind == .structType && $0.name == "Point" })
        #expect(symbols.definitions.contains { $0.kind == .enumType && $0.name == "Direction" })
        #expect(symbols.definitions.contains { $0.kind == .unionType && $0.name == "Shape" })
        #expect(symbols.definitions.contains { $0.kind == .function && $0.name == "distance" })
        #expect(symbols.definitions.contains { $0.kind == .function && $0.name == "main" })
        #expect(symbols.definitions.contains { $0.kind == .field && $0.name == "x" })
        #expect(symbols.definitions.contains { $0.kind == .enumCase && $0.name == "north" })
        #expect(symbols.definitions.contains { $0.kind == .variable && $0.name == "pt" })
        #expect(symbols.definitions.contains { $0.kind == .parameter && $0.name == "p" })
    }

    @Test("Switch statement references")
    func switchStatementReferences() throws {
        let source = """
        enum Color {
            case red
            case blue
        }

        func main() {
            var c: Color = Color.red
            switch (c) {
                Color.red -> print("red")
                Color.blue -> print("blue")
            }
        }
        """

        let symbols = try collectSymbols(from: source)

        // Should reference Color type and c variable
        let colorRefs = symbols.references.filter { $0.definition.name == "Color" }
        #expect(colorRefs.count >= 1)

        let cRefs = symbols.references.filter { $0.definition.name == "c" }
        #expect(cRefs.count >= 1)
    }

    @Test("String interpolation references")
    func stringInterpolationReferences() throws {
        let source = """
        func main() {
            var x: Int = 42
            var y: Int = 10
            print("x=\\(x), y=\\(y), sum=\\(x + y)")
        }
        """

        let symbols = try collectSymbols(from: source)

        let xRefs = symbols.references.filter { $0.definition.name == "x" }
        #expect(xRefs.count >= 2)  // At least in interpolations

        let yRefs = symbols.references.filter { $0.definition.name == "y" }
        #expect(yRefs.count >= 2)
    }
}
