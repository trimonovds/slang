// Tests/SlangCoreTests/LSPTests.swift

import Testing
import Foundation
@testable import SlangCore

@Suite("LSP Position Converter Tests")
struct PositionConverterTests {

    // MARK: - Source Location Conversion

    @Test("Convert LSP position to Slang location - simple")
    func lspToSlangSimple() {
        let source = "var x: Int = 42"
        let converter = TestPositionConverter(source: source)

        // LSP position (0, 4) = "x" in "var x: Int"
        let location = converter.toSourceLocation(line: 0, character: 4)

        #expect(location.line == 1)  // 1-indexed
        #expect(location.column == 5)  // 1-indexed
    }

    @Test("Convert LSP position to Slang location - multiline")
    func lspToSlangMultiline() {
        let source = """
        func main() {
            var x: Int = 42
        }
        """
        let converter = TestPositionConverter(source: source)

        // LSP position (1, 8) = "x" in second line
        let location = converter.toSourceLocation(line: 1, character: 8)

        #expect(location.line == 2)  // 1-indexed
        #expect(location.column == 9)  // 1-indexed
    }

    @Test("Convert Slang location to LSP position")
    func slangToLsp() {
        let source = "var x: Int = 42"
        let converter = TestPositionConverter(source: source)

        let location = SourceLocation(line: 1, column: 5, offset: 4)
        let position = converter.toPosition(location)

        #expect(position.line == 0)  // 0-indexed
        #expect(position.character == 4)  // 0-indexed
    }

    @Test("Convert Slang range to LSP range")
    func slangRangeToLspRange() {
        let source = "var x: Int = 42"
        let converter = TestPositionConverter(source: source)

        let range = SourceRange(
            start: SourceLocation(line: 1, column: 5, offset: 4),
            end: SourceLocation(line: 1, column: 6, offset: 5),
            file: "test.slang"
        )
        let lspRange = converter.toRange(range)

        #expect(lspRange.start.line == 0)
        #expect(lspRange.start.character == 4)
        #expect(lspRange.end.line == 0)
        #expect(lspRange.end.character == 5)
    }

    @Test("Position at end of line")
    func positionAtEndOfLine() {
        let source = "var x: Int = 42\nvar y: Int = 10"
        let converter = TestPositionConverter(source: source)

        // End of first line
        let location = converter.toSourceLocation(line: 0, character: 15)
        #expect(location.line == 1)
        #expect(location.column == 16)
    }

    @Test("Position on empty line")
    func positionOnEmptyLine() {
        let source = "line1\n\nline3"
        let converter = TestPositionConverter(source: source)

        // Position on empty line 2
        let location = converter.toSourceLocation(line: 1, character: 0)
        #expect(location.line == 2)
        #expect(location.column == 1)
    }
}

@Suite("LSP URI Conversion Tests")
struct URIConversionTests {

    @Test("Convert file URI to path")
    func uriToPath() {
        let uri = "file:///Users/test/project/main.slang"
        let path = testUriToPath(uri)
        #expect(path == "/Users/test/project/main.slang")
    }

    @Test("Convert path to file URI")
    func pathToUri() {
        let path = "/Users/test/project/main.slang"
        let uri = testPathToUri(path)
        #expect(uri == "file:///Users/test/project/main.slang")
    }

    @Test("Handle URL-encoded spaces")
    func urlEncodedSpaces() {
        let uri = "file:///Users/test/my%20project/main.slang"
        let path = testUriToPath(uri)
        #expect(path == "/Users/test/my project/main.slang")
    }

    @Test("Non-file URI returns as-is")
    func nonFileUri() {
        let uri = "untitled:Untitled-1"
        let path = testUriToPath(uri)
        #expect(path == "untitled:Untitled-1")
    }
}

@Suite("LSP Definition Lookup Tests")
struct DefinitionLookupTests {

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    @Test("Find definition of variable usage")
    func findVariableDefinition() throws {
        let source = """
        func main() {
            var x: Int = 42
            print("\\(x)")
        }
        """

        let symbols = try collectSymbols(from: source)

        // Find references to x
        let xRefs = symbols.references.filter { $0.definition.name == "x" }
        #expect(!xRefs.isEmpty)

        // The definition should point to the variable declaration
        let def = xRefs.first?.definition
        #expect(def?.kind == .variable)
        #expect(def?.name == "x")
    }

    @Test("Find definition of function call")
    func findFunctionDefinition() throws {
        let source = """
        func greet(name: String) {
            print(name)
        }

        func main() {
            greet("world")
        }
        """

        let symbols = try collectSymbols(from: source)

        let greetRefs = symbols.references.filter { $0.definition.name == "greet" }
        #expect(!greetRefs.isEmpty)

        let def = greetRefs.first?.definition
        #expect(def?.kind == .function)
    }

    @Test("Find definition of struct type")
    func findStructDefinition() throws {
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
        #expect(!pointRefs.isEmpty)

        let def = pointRefs.first?.definition
        #expect(def?.kind == .structType)
    }

    @Test("Find definition of parameter")
    func findParameterDefinition() throws {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }
        """

        let symbols = try collectSymbols(from: source)

        let aRefs = symbols.references.filter { $0.definition.name == "a" }
        #expect(!aRefs.isEmpty)

        let def = aRefs.first?.definition
        #expect(def?.kind == .parameter)
    }
}

@Suite("LSP References Lookup Tests")
struct ReferencesLookupTests {

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    @Test("Find all references to variable")
    func findAllVariableReferences() throws {
        let source = """
        func main() {
            var count: Int = 0
            count = count + 1
            count = count + 1
            print("\\(count)")
        }
        """

        let symbols = try collectSymbols(from: source)

        let countRefs = symbols.references.filter { $0.definition.name == "count" }
        // count is used multiple times: count + 1 (x2), count + 1 (x2), print interpolation
        #expect(countRefs.count >= 4)
    }

    @Test("Find all references to function")
    func findAllFunctionReferences() throws {
        let source = """
        func helper() -> Int {
            return 42
        }

        func main() {
            var a: Int = helper()
            var b: Int = helper()
            var c: Int = helper()
        }
        """

        let symbols = try collectSymbols(from: source)

        let helperRefs = symbols.references.filter { $0.definition.name == "helper" }
        #expect(helperRefs.count == 3)
    }

    @Test("Find all references to struct type")
    func findAllStructReferences() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func origin() -> Point {
            return Point { x: 0, y: 0 }
        }

        func main() {
            var p1: Point = Point { x: 1, y: 2 }
            var p2: Point = origin()
        }
        """

        let symbols = try collectSymbols(from: source)

        let pointRefs = symbols.references.filter { $0.definition.name == "Point" }
        // Used in: return type, type annotation x2, struct init x2
        #expect(pointRefs.count >= 3)
    }

    @Test("References respect scope")
    func referencesRespectScope() throws {
        let source = """
        func foo() {
            var x: Int = 1
            print("\\(x)")
        }

        func bar() {
            var x: Int = 2
            print("\\(x)")
        }
        """

        let symbols = try collectSymbols(from: source)

        // Should have 2 variable definitions for x
        let xDefs = symbols.definitions.filter { $0.kind == .variable && $0.name == "x" }
        #expect(xDefs.count == 2)

        // Each x should have its own reference
        let xRefs = symbols.references.filter { $0.definition.name == "x" }
        #expect(xRefs.count == 2)
    }
}

@Suite("LSP Find References Comprehensive Tests")
struct FindReferencesComprehensiveTests {

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    /// Simulates LSP find references: given a position, find the symbol and return all reference ranges
    private func simulateFindReferences(from source: String, atLine: Int, atColumn: Int, includeDeclaration: Bool = true) throws -> [SourceRange] {
        let symbols = try collectSymbols(from: source)
        let location = SourceLocation(line: atLine, column: atColumn, offset: 0)

        // Find what symbol is at this position
        var targetDef: SymbolDefinition?

        // Check references first
        for ref in symbols.references {
            if isLocationInRange(location, ref.range) {
                targetDef = ref.definition
                break
            }
        }

        // Then check definitions
        if targetDef == nil {
            for def in symbols.definitions {
                if isLocationInRange(location, def.nameRange) {
                    targetDef = def
                    break
                }
            }
        }

        guard let definition = targetDef else {
            return []
        }

        var results: [SourceRange] = []

        // Include declaration if requested
        if includeDeclaration {
            results.append(definition.nameRange)
        }

        // Find all references to this symbol
        for ref in symbols.references {
            if ref.definition.name == definition.name &&
               ref.definition.kind == definition.kind &&
               ref.definition.container == definition.container {
                results.append(ref.range)
            }
        }

        return results
    }

    // MARK: - Function References

    @Test("Find references to function includes all call sites")
    func findFunctionReferencesIncludesAllCallSites() throws {
        let source = """
        func greet(name: String) {
            print(name)
        }

        func main() {
            greet("Alice")
            greet("Bob")
            greet("Charlie")
        }
        """

        // Click on "greet" at the function definition (line 1, col 6)
        let refs = try simulateFindReferences(from: source, atLine: 1, atColumn: 6)

        // Should find: 1 definition + 3 call sites = 4 total
        #expect(refs.count == 4, "Should find definition + 3 call sites")
    }

    @Test("Find references from call site finds definition")
    func findReferencesFromCallSite() throws {
        let source = """
        func helper() -> Int {
            return 42
        }

        func main() {
            var x: Int = helper()
        }
        """

        // Click on "helper" at the call site (line 6, col 18)
        let refs = try simulateFindReferences(from: source, atLine: 6, atColumn: 18)

        // Should find definition and the call site
        #expect(refs.count == 2)
        #expect(refs[0].start.line == 1, "First should be definition")
    }

    @Test("Find references to recursive function")
    func findReferencesToRecursiveFunction() throws {
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

        let refs = try simulateFindReferences(from: source, atLine: 1, atColumn: 6)

        // Definition + recursive call + call in main = 3
        #expect(refs.count == 3)
    }

    // MARK: - Variable References

    @Test("Find references to variable includes all usages")
    func findVariableReferencesIncludesAllUsages() throws {
        let source = """
        func main() {
            var counter: Int = 0
            counter = counter + 1
            counter = counter + 2
            print("\\(counter)")
        }
        """

        // Click on "counter" definition (line 2, col 9)
        let refs = try simulateFindReferences(from: source, atLine: 2, atColumn: 9)

        // Definition + assignment targets (2) + assignment values (2) + print = 6
        #expect(refs.count >= 5, "Should find definition + multiple usages")
    }

    @Test("Find references to variable excludes variables in other functions")
    func findVariableReferencesExcludesOtherFunctions() throws {
        let source = """
        func foo() {
            var x: Int = 1
            print("\\(x)")
        }
        func bar() {
            var y: Int = 2
            print("\\(y)")
        }
        """
        // Lines: 1=func foo, 2=var x, 3=print, 4=}, 5=func bar, 6=var y, 7=print, 8=}

        let symbols = try collectSymbols(from: source)

        // Verify we have two separate variable definitions
        let varDefs = symbols.definitions.filter { $0.kind == .variable }
        #expect(varDefs.count == 2, "Should have 2 variable definitions (x and y)")

        // Find x definition
        let xDef = varDefs.first { $0.name == "x" }
        #expect(xDef != nil, "Should find x definition")
        #expect(xDef!.nameRange.start.line == 2, "x should be on line 2")

        // Find y definition
        let yDef = varDefs.first { $0.name == "y" }
        #expect(yDef != nil, "Should find y definition")
        #expect(yDef!.nameRange.start.line == 6, "y should be on line 6")

        // Check references - each variable should only have references to itself
        let xRefs = symbols.references.filter { $0.definition.name == "x" }
        let yRefs = symbols.references.filter { $0.definition.name == "y" }

        #expect(xRefs.count >= 1, "x should have at least 1 reference")
        #expect(yRefs.count >= 1, "y should have at least 1 reference")

        // x references should only be in foo (lines 1-4)
        for ref in xRefs {
            #expect(ref.range.start.line <= 4, "x references should be in foo function")
        }

        // y references should only be in bar (lines 5-8)
        for ref in yRefs {
            #expect(ref.range.start.line >= 5, "y references should be in bar function")
        }
    }

    @Test("Find references to parameter")
    func findParameterReferences() throws {
        let source = """
        func greet(name: String) {
            print("Hello, ")
            print(name)
            print("!")
            print(name)
        }
        """

        // Click on "name" parameter (line 1, around col 12)
        let refs = try simulateFindReferences(from: source, atLine: 1, atColumn: 12)

        // Definition + 2 usages in print
        #expect(refs.count == 3)
    }

    // MARK: - Struct References

    @Test("Find references to struct type includes all usages")
    func findStructReferencesIncludesAllUsages() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func createPoint(x: Int, y: Int) -> Point {
            return Point { x: x, y: y }
        }

        func main() {
            var p1: Point = Point { x: 1, y: 2 }
            var p2: Point = createPoint(3, 4)
        }
        """

        // Click on "Point" definition (line 1, col 8)
        let refs = try simulateFindReferences(from: source, atLine: 1, atColumn: 8)

        // Definition + return type + struct init + type annotation (x2) + struct init
        #expect(refs.count >= 4, "Should find struct definition + all type usages")
    }

    @Test("Find references to struct field")
    func findStructFieldReferences() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func main() {
            var p: Point = Point { x: 1, y: 2 }
            print("\\(p.x)")
            print("\\(p.y)")
            print("\\(p.x)")
        }
        """

        // Click on "x" field access (line 8, around col 17)
        let refs = try simulateFindReferences(from: source, atLine: 8, atColumn: 17)

        // Field definition + 2 usages
        #expect(refs.count == 3, "Should find field definition + 2 usages")
    }

    // MARK: - Enum References

    @Test("Find references to enum type")
    func findEnumTypeReferences() throws {
        let source = """
        enum Direction {
            case up
            case down
            case left
            case right
        }

        func move(dir: Direction) {
            print("moving")
        }

        func main() {
            var d: Direction = Direction.up
            move(d)
        }
        """

        // Click on "Direction" definition (line 1, col 6)
        let refs = try simulateFindReferences(from: source, atLine: 1, atColumn: 6)

        // Definition + parameter type + type annotation + member access prefix
        #expect(refs.count >= 3, "Should find enum definition + type usages")
    }

    @Test("Find references to enum case")
    func findEnumCaseReferences() throws {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var d1: Direction = Direction.up
            var d2: Direction = Direction.up
            var d3: Direction = Direction.down
        }
        """

        // Click on "up" in Direction.up (line 7, around col 35)
        let refs = try simulateFindReferences(from: source, atLine: 7, atColumn: 35)

        // Case definition + 2 usages
        #expect(refs.count == 3, "Should find enum case definition + 2 usages")
    }

    @Test("Find references to enum case in switch")
    func findEnumCaseReferencesInSwitch() throws {
        let source = """
        enum Direction {
            case up
            case down
        }

        func describe(dir: Direction) -> String {
            return switch (dir) {
                Direction.up -> return "going up"
                Direction.down -> return "going down"
            }
        }

        func main() {
            var d: Direction = Direction.up
            print(describe(d))
        }
        """

        // Click on "up" case definition (line 2)
        let refs = try simulateFindReferences(from: source, atLine: 2, atColumn: 10)

        // Definition + switch pattern + assignment
        #expect(refs.count == 3, "Should find case definition + switch pattern + assignment")
    }

    // MARK: - Union References

    @Test("Find references to union type")
    func findUnionTypeReferences() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func describePet(pet: Pet) -> String {
            return "a pet"
        }

        func main() {
            var d: Dog = Dog { name: "Buddy" }
            var p: Pet = Pet.Dog(d)
            print(describePet(p))
        }
        """

        // Click on "Pet" definition (line 3, col 7)
        let refs = try simulateFindReferences(from: source, atLine: 3, atColumn: 7)

        // Definition + parameter type + type annotation + member access prefix
        #expect(refs.count >= 3, "Should find union definition + type usages")
    }

    @Test("Find references to union variant")
    func findUnionVariantReferences() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var d: Dog = Dog { name: "Buddy" }
            var p1: Pet = Pet.Dog(d)
            var p2: Pet = Pet.Dog(d)
            var p3: Pet = Pet.Cat(Cat { name: "Whiskers" })
        }
        """

        // Click on "Dog" variant in Pet.Dog (line 7)
        let refs = try simulateFindReferences(from: source, atLine: 7, atColumn: 23)

        // Variant definition + 2 usages
        #expect(refs.count == 3, "Should find union variant definition + 2 usages")
    }

    // MARK: - Complex Scenarios

    @Test("Find references across nested function calls")
    func findReferencesAcrossNestedCalls() throws {
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }

        func mul(a: Int, b: Int) -> Int {
            return a * b
        }

        func main() {
            var result: Int = add(mul(2, 3), mul(4, 5))
            print("\\(result)")
        }
        """

        // Click on "mul" definition (line 5, col 6)
        let refs = try simulateFindReferences(from: source, atLine: 5, atColumn: 6)

        // Definition + 2 nested calls
        #expect(refs.count == 3)
    }

    @Test("Find references in for loop")
    func findReferencesInForLoop() throws {
        let source = """
        func main() {
            var sum: Int = 0
            for (var i: Int = 0; i < 10; i = i + 1) {
                sum = sum + i
            }
            print("\\(sum)")
        }
        """

        // Click on "i" in for loop (line 3, col 14)
        let refs = try simulateFindReferences(from: source, atLine: 3, atColumn: 14)

        // Definition + condition + increment (x2) + loop body
        #expect(refs.count >= 4, "Should find loop variable definition + all usages")
    }

    @Test("Find references excludes declaration when requested")
    func findReferencesExcludesDeclaration() throws {
        let source = """
        func helper() -> Int {
            return 42
        }

        func main() {
            var x: Int = helper()
            var y: Int = helper()
        }
        """

        // Click on "helper" and exclude declaration
        let refs = try simulateFindReferences(from: source, atLine: 1, atColumn: 6, includeDeclaration: false)

        // Only call sites, no definition
        #expect(refs.count == 2, "Should find only 2 call sites without declaration")
    }

    @Test("Find references returns correct ranges for highlighting")
    func findReferencesReturnsCorrectRanges() throws {
        let source = """
        func greet() {
            print("Hello")
        }

        func main() {
            greet()
        }
        """

        let refs = try simulateFindReferences(from: source, atLine: 1, atColumn: 6)

        #expect(refs.count == 2)

        // First reference (definition) should be exactly "greet" on line 1
        let defRange = refs[0]
        #expect(defRange.start.line == 1)
        #expect(defRange.start.column == 6)  // After "func "
        #expect(defRange.end.column == 11)   // "greet" is 5 chars

        // Second reference (call) should be exactly "greet" on line 6
        let callRange = refs[1]
        #expect(callRange.start.line == 6)
    }
}

@Suite("LSP Name Range Tests")
struct NameRangeTests {

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    @Test("Function nameRange only covers function name, not body")
    func functionNameRangeIsJustName() throws {
        let source = """
        func main() {
            var x: Int = 42
        }
        """

        let symbols = try collectSymbols(from: source)

        let mainDef = symbols.definitions.first { $0.name == "main" && $0.kind == .function }
        #expect(mainDef != nil)

        // nameRange should only cover "main" (after "func ")
        // "func " is 5 characters, "main" is 4 characters
        // So nameRange should be from column 6 to column 10 (1-indexed)
        #expect(mainDef!.nameRange.start.line == 1)
        #expect(mainDef!.nameRange.start.column == 6)  // After "func "
        #expect(mainDef!.nameRange.end.column == 10)   // End of "main"

        // Full range should cover entire function including body
        #expect(mainDef!.range.start.line == 1)
        #expect(mainDef!.range.end.line == 3)  // Closing brace is on line 3
    }

    @Test("Cursor inside function body should NOT match function definition")
    func cursorInsideFunctionBodyNoMatch() throws {
        let source = """
        func main() {
            var x: Int = 42
        }
        """

        let symbols = try collectSymbols(from: source)

        let mainDef = symbols.definitions.first { $0.name == "main" && $0.kind == .function }
        #expect(mainDef != nil)

        // Cursor at line 2, column 10 (inside function body, on "x")
        let cursorInBody = SourceLocation(line: 2, column: 10, offset: 20)

        // Should NOT be in nameRange
        #expect(!isLocationInRange(cursorInBody, mainDef!.nameRange))

        // But WOULD be in full range (this is what caused the bug)
        #expect(isLocationInRange(cursorInBody, mainDef!.range))
    }

    @Test("Struct nameRange only covers struct name")
    func structNameRangeIsJustName() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }
        """

        let symbols = try collectSymbols(from: source)

        let pointDef = symbols.definitions.first { $0.name == "Point" && $0.kind == .structType }
        #expect(pointDef != nil)

        // "struct " is 7 characters, "Point" is 5 characters
        #expect(pointDef!.nameRange.start.column == 8)  // After "struct "
        #expect(pointDef!.nameRange.end.column == 13)   // End of "Point"
    }

    @Test("Enum nameRange only covers enum name")
    func enumNameRangeIsJustName() throws {
        let source = """
        enum Direction {
            case up
            case down
        }
        """

        let symbols = try collectSymbols(from: source)

        let dirDef = symbols.definitions.first { $0.name == "Direction" && $0.kind == .enumType }
        #expect(dirDef != nil)

        // "enum " is 5 characters, "Direction" is 9 characters
        #expect(dirDef!.nameRange.start.column == 6)   // After "enum "
        #expect(dirDef!.nameRange.end.column == 15)    // End of "Direction"
    }

    @Test("Union nameRange only covers union name")
    func unionNameRangeIsJustName() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat
        """

        let symbols = try collectSymbols(from: source)

        let petDef = symbols.definitions.first { $0.name == "Pet" && $0.kind == .unionType }
        #expect(petDef != nil)

        // "union " is 6 characters, "Pet" is 3 characters
        #expect(petDef!.nameRange.start.column == 7)   // After "union "
        #expect(petDef!.nameRange.end.column == 10)    // End of "Pet"
    }
}

@Suite("LSP Enum Member Access Tests")
struct EnumMemberAccessTests {

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    @Test("Enum member access creates reference to enum case")
    func enumMemberAccessCreatesReference() throws {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var dir: Direction = Direction.up
        }
        """

        let symbols = try collectSymbols(from: source)

        // Should have a reference to the enum case "up"
        let upRefs = symbols.references.filter {
            $0.definition.name == "up" && $0.definition.kind == .enumCase
        }
        #expect(!upRefs.isEmpty, "Should have reference to enum case 'up'")

        // The reference should point to the enum case definition
        let upDef = upRefs.first?.definition
        #expect(upDef?.container == "Direction")
    }

    @Test("Multiple enum member accesses create separate references")
    func multipleEnumMemberAccesses() throws {
        let source = """
        enum Direction {
            case up
            case down
            case left
            case right
        }

        func main() {
            var a: Direction = Direction.up
            var b: Direction = Direction.down
            var c: Direction = Direction.up
        }
        """

        let symbols = try collectSymbols(from: source)

        let upRefs = symbols.references.filter {
            $0.definition.name == "up" && $0.definition.kind == .enumCase
        }
        #expect(upRefs.count == 2, "Should have 2 references to 'up'")

        let downRefs = symbols.references.filter {
            $0.definition.name == "down" && $0.definition.kind == .enumCase
        }
        #expect(downRefs.count == 1, "Should have 1 reference to 'down'")
    }

    @Test("Enum member access in switch pattern creates reference")
    func enumMemberAccessInSwitch() throws {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var dir: Direction = Direction.up
            switch (dir) {
                Direction.up -> print("up")
                Direction.down -> print("down")
            }
        }
        """

        let symbols = try collectSymbols(from: source)

        // Should have references from both the assignment and switch patterns
        let upRefs = symbols.references.filter {
            $0.definition.name == "up" && $0.definition.kind == .enumCase
        }
        #expect(upRefs.count >= 2, "Should have at least 2 references to 'up' (assignment + switch)")

        let downRefs = symbols.references.filter {
            $0.definition.name == "down" && $0.definition.kind == .enumCase
        }
        #expect(downRefs.count >= 1, "Should have at least 1 reference to 'down' (switch)")
    }

    @Test("Enum member reference range covers only the member name")
    func enumMemberReferenceRangeIsJustMember() throws {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var dir: Direction = Direction.up
        }
        """

        let symbols = try collectSymbols(from: source)

        let upRefs = symbols.references.filter {
            $0.definition.name == "up" && $0.definition.kind == .enumCase
        }
        #expect(!upRefs.isEmpty)

        // The reference range should cover just "up", not "Direction.up"
        let ref = upRefs.first!
        let rangeLength = ref.range.end.column - ref.range.start.column
        #expect(rangeLength == 2, "Range should cover 'up' (2 characters), not 'Direction.up'")
    }
}

@Suite("LSP Location in Range Tests")
struct LocationInRangeTests {

    @Test("Location at start of range")
    func locationAtStart() {
        let range = SourceRange(
            start: SourceLocation(line: 1, column: 5, offset: 4),
            end: SourceLocation(line: 1, column: 10, offset: 9),
            file: "test.slang"
        )
        let location = SourceLocation(line: 1, column: 5, offset: 4)
        #expect(isLocationInRange(location, range))
    }

    @Test("Location at end of range")
    func locationAtEnd() {
        let range = SourceRange(
            start: SourceLocation(line: 1, column: 5, offset: 4),
            end: SourceLocation(line: 1, column: 10, offset: 9),
            file: "test.slang"
        )
        let location = SourceLocation(line: 1, column: 10, offset: 9)
        #expect(isLocationInRange(location, range))
    }

    @Test("Location in middle of range")
    func locationInMiddle() {
        let range = SourceRange(
            start: SourceLocation(line: 1, column: 5, offset: 4),
            end: SourceLocation(line: 1, column: 10, offset: 9),
            file: "test.slang"
        )
        let location = SourceLocation(line: 1, column: 7, offset: 6)
        #expect(isLocationInRange(location, range))
    }

    @Test("Location before range")
    func locationBeforeRange() {
        let range = SourceRange(
            start: SourceLocation(line: 1, column: 5, offset: 4),
            end: SourceLocation(line: 1, column: 10, offset: 9),
            file: "test.slang"
        )
        let location = SourceLocation(line: 1, column: 3, offset: 2)
        #expect(!isLocationInRange(location, range))
    }

    @Test("Location after range")
    func locationAfterRange() {
        let range = SourceRange(
            start: SourceLocation(line: 1, column: 5, offset: 4),
            end: SourceLocation(line: 1, column: 10, offset: 9),
            file: "test.slang"
        )
        let location = SourceLocation(line: 1, column: 15, offset: 14)
        #expect(!isLocationInRange(location, range))
    }

    @Test("Location on different line before")
    func locationOnDifferentLineBefore() {
        let range = SourceRange(
            start: SourceLocation(line: 5, column: 1, offset: 50),
            end: SourceLocation(line: 5, column: 10, offset: 59),
            file: "test.slang"
        )
        let location = SourceLocation(line: 4, column: 5, offset: 40)
        #expect(!isLocationInRange(location, range))
    }

    @Test("Location on different line after")
    func locationOnDifferentLineAfter() {
        let range = SourceRange(
            start: SourceLocation(line: 5, column: 1, offset: 50),
            end: SourceLocation(line: 5, column: 10, offset: 59),
            file: "test.slang"
        )
        let location = SourceLocation(line: 6, column: 1, offset: 60)
        #expect(!isLocationInRange(location, range))
    }

    @Test("Multiline range - location in middle")
    func multilineRangeMiddle() {
        let range = SourceRange(
            start: SourceLocation(line: 1, column: 1, offset: 0),
            end: SourceLocation(line: 3, column: 10, offset: 50),
            file: "test.slang"
        )
        let location = SourceLocation(line: 2, column: 5, offset: 25)
        #expect(isLocationInRange(location, range))
    }
}

// MARK: - Test Helpers

/// Test implementation of position converter
struct TestPositionConverter {
    let source: String

    struct Position {
        let line: Int
        let character: Int
    }

    struct Range {
        let start: Position
        let end: Position
    }

    func toSourceLocation(line: Int, character: Int) -> SlangCore.SourceLocation {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)

        var offset = 0
        for i in 0..<line {
            if i < lines.count {
                offset += lines[i].utf8.count + 1  // +1 for newline
            }
        }

        if line < lines.count {
            let lineContent = String(lines[line])
            var utf16Count = 0
            var byteCount = 0

            for char in lineContent {
                if utf16Count >= character {
                    break
                }
                utf16Count += char.utf16.count
                byteCount += char.utf8.count
            }
            offset += byteCount
        }

        return SlangCore.SourceLocation(
            line: line + 1,
            column: character + 1,
            offset: offset
        )
    }

    func toPosition(_ location: SlangCore.SourceLocation) -> Position {
        return Position(
            line: location.line - 1,
            character: location.column - 1
        )
    }

    func toRange(_ sourceRange: SourceRange) -> Range {
        return Range(
            start: toPosition(sourceRange.start),
            end: toPosition(sourceRange.end)
        )
    }
}

/// Test URI conversion functions
func testUriToPath(_ uri: String) -> String {
    if uri.hasPrefix("file://") {
        var path = String(uri.dropFirst(7))
        path = path.removingPercentEncoding ?? path
        return path
    }
    return uri
}

func testPathToUri(_ path: String) -> String {
    let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
    return "file://\(encoded)"
}

/// Check if a location is within a range
func isLocationInRange(_ location: SlangCore.SourceLocation, _ range: SourceRange) -> Bool {
    if location.line < range.start.line {
        return false
    }
    if location.line == range.start.line && location.column < range.start.column {
        return false
    }
    if location.line > range.end.line {
        return false
    }
    if location.line == range.end.line && location.column > range.end.column {
        return false
    }
    return true
}

// MARK: - LSP Jump Destination Tests (Regression: LSP server must use nameRange, not range)

@Suite("LSP Jump Destination Tests")
struct JumpDestinationTests {

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    /// Simulates what the LSP server does: find definition and return its nameRange
    private func simulateLSPJumpDestination(from source: String, atLine: Int, atColumn: Int) throws -> SourceRange? {
        let symbols = try collectSymbols(from: source)

        // Convert to 1-indexed (Slang uses 1-indexed)
        let location = SourceLocation(line: atLine, column: atColumn, offset: 0)

        // First check references (like the LSP server does)
        for ref in symbols.references {
            if isLocationInRange(location, ref.range) {
                // LSP server should return nameRange, not range
                return ref.definition.nameRange
            }
        }

        // Then check definitions
        for def in symbols.definitions {
            if isLocationInRange(location, def.nameRange) {
                return def.nameRange
            }
        }

        return nil
    }

    @Test("Jump to function definition lands on function name, not 'func' keyword")
    func jumpToFunctionLandsOnName() throws {
        let source = """
        func describePet(pet: Int) -> String {
            return "pet"
        }

        func main() {
            print(describePet(42))
        }
        """

        // Click on "describePet" in the function call on line 6
        // "    print(describePet" - describePet starts at column 11
        let jumpDest = try simulateLSPJumpDestination(from: source, atLine: 6, atColumn: 11)

        #expect(jumpDest != nil, "Should find jump destination")

        // Jump should land on "describePet" name (line 1, column 6-17), NOT on "func" (column 1)
        #expect(jumpDest!.start.line == 1)
        #expect(jumpDest!.start.column == 6, "Should start at 'describePet', not at 'func'")  // After "func "
        #expect(jumpDest!.end.column == 17, "Should end after 'describePet'")  // "describePet" is 11 chars
    }

    @Test("Jump to variable definition lands on variable name, not 'var' keyword")
    func jumpToVariableLandsOnName() throws {
        let source = """
        func main() {
            var myDog: Int = 42
            print("\\(myDog)")
        }
        """

        // Click on "myDog" in the print statement on line 3
        // "    print(\"\\(myDog" - myDog starts around column 15
        let jumpDest = try simulateLSPJumpDestination(from: source, atLine: 3, atColumn: 15)

        #expect(jumpDest != nil, "Should find jump destination")

        // Jump should land on "myDog" name (line 2), NOT on "var"
        #expect(jumpDest!.start.line == 2)
        #expect(jumpDest!.start.column == 9, "Should start at 'myDog', not at 'var'")  // After "    var "
    }

    @Test("Jump to struct definition lands on struct name, not 'struct' keyword")
    func jumpToStructLandsOnName() throws {
        let source = """
        struct Dog {
            name: String
        }

        func main() {
            var d: Dog = Dog { name: "Buddy" }
        }
        """

        // Click on "Dog" type annotation on line 6
        // "    var d: Dog" - Dog starts at column 12
        let jumpDest = try simulateLSPJumpDestination(from: source, atLine: 6, atColumn: 12)

        #expect(jumpDest != nil, "Should find jump destination")

        // Jump should land on "Dog" name (line 1, column 8-11), NOT on "struct" (column 1)
        #expect(jumpDest!.start.line == 1)
        #expect(jumpDest!.start.column == 8, "Should start at 'Dog', not at 'struct'")  // After "struct "
    }

    @Test("Jump to enum definition lands on enum name, not 'enum' keyword")
    func jumpToEnumLandsOnName() throws {
        let source = """
        enum Direction {
            case up
            case down
        }

        func main() {
            var d: Direction = Direction.up
        }
        """

        // Click on "Direction" type annotation on line 7
        // "    var d: Direction" - Direction starts at column 12
        let jumpDest = try simulateLSPJumpDestination(from: source, atLine: 7, atColumn: 12)

        #expect(jumpDest != nil, "Should find jump destination")

        // Jump should land on "Direction" name, NOT on "enum"
        #expect(jumpDest!.start.line == 1)
        #expect(jumpDest!.start.column == 6, "Should start at 'Direction', not at 'enum'")  // After "enum "
    }

    @Test("Jump to union definition lands on union name, not 'union' keyword")
    func jumpToUnionLandsOnName() throws {
        let source = """
        struct Dog { name: String }
        struct Cat { name: String }
        union Pet = Dog | Cat

        func main() {
            var p: Pet = Pet.Dog(Dog { name: "Buddy" })
        }
        """

        // Click on "Pet" type annotation on line 6
        // "    var p: Pet" - Pet starts at column 12
        let jumpDest = try simulateLSPJumpDestination(from: source, atLine: 6, atColumn: 12)

        #expect(jumpDest != nil, "Should find jump destination")

        // Jump should land on "Pet" name (line 3), NOT on "union"
        #expect(jumpDest!.start.line == 3)
        #expect(jumpDest!.start.column == 7, "Should start at 'Pet', not at 'union'")  // After "union "
    }
}

// MARK: - Variable Name Range Tests (Regression for bug: clicking variable jumped to 'var' keyword)

@Suite("LSP Variable Name Range Tests")
struct VariableNameRangeTests {

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    @Test("Variable nameRange only covers variable name, not 'var' keyword")
    func variableNameRangeIsJustName() throws {
        let source = """
        func main() {
            var myDog: Int = 42
        }
        """

        let symbols = try collectSymbols(from: source)

        let varDef = symbols.definitions.first { $0.name == "myDog" && $0.kind == .variable }
        #expect(varDef != nil)

        // "var " is 4 characters, "myDog" is 5 characters
        // So nameRange should start at column 9 (after "    var ") and end at column 14
        #expect(varDef!.nameRange.start.column == 9)   // After "    var "
        #expect(varDef!.nameRange.end.column == 14)    // End of "myDog"

        // Cursor on 'myDog' should be in nameRange
        let cursorOnName = SourceLocation(line: 2, column: 10, offset: 20)
        #expect(isLocationInRange(cursorOnName, varDef!.nameRange))

        // Cursor on 'var' keyword should NOT be in nameRange
        let cursorOnKeyword = SourceLocation(line: 2, column: 6, offset: 16)
        #expect(!isLocationInRange(cursorOnKeyword, varDef!.nameRange))
    }

    @Test("Multiple variables have correct nameRanges")
    func multipleVariablesHaveCorrectNameRanges() throws {
        let source = """
        func main() {
            var first: Int = 1
            var second: Int = 2
            var third: Int = 3
        }
        """

        let symbols = try collectSymbols(from: source)

        let firstDef = symbols.definitions.first { $0.name == "first" && $0.kind == .variable }
        let secondDef = symbols.definitions.first { $0.name == "second" && $0.kind == .variable }
        let thirdDef = symbols.definitions.first { $0.name == "third" && $0.kind == .variable }

        #expect(firstDef != nil)
        #expect(secondDef != nil)
        #expect(thirdDef != nil)

        // Each variable name should have correct length in nameRange
        let firstLen = firstDef!.nameRange.end.column - firstDef!.nameRange.start.column
        let secondLen = secondDef!.nameRange.end.column - secondDef!.nameRange.start.column
        let thirdLen = thirdDef!.nameRange.end.column - thirdDef!.nameRange.start.column

        #expect(firstLen == 5, "first should be 5 chars")
        #expect(secondLen == 6, "second should be 6 chars")
        #expect(thirdLen == 5, "third should be 5 chars")
    }

    @Test("Variable in for loop has correct nameRange")
    func forLoopVariableNameRange() throws {
        let source = """
        func main() {
            for (var i: Int = 0; i < 10; i = i + 1) {
                print("\\(i)")
            }
        }
        """

        let symbols = try collectSymbols(from: source)

        let iDef = symbols.definitions.first { $0.name == "i" && $0.kind == .variable }
        #expect(iDef != nil)

        // "for (var " is 9 characters from start of line
        let nameLen = iDef!.nameRange.end.column - iDef!.nameRange.start.column
        #expect(nameLen == 1, "i should be 1 char")
    }
}

// MARK: - Variable Field Access Tests (Regression for bug: pet.name didn't resolve)

@Suite("LSP Variable Field Access Tests")
struct VariableFieldAccessTests {

    private func collectSymbols(from source: String) throws -> FileSymbols {
        let lexer = Lexer(source: source, filename: "test.slang")
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        let collector = SymbolCollector()
        return collector.collect(declarations: declarations, file: "test.slang")
    }

    @Test("Struct field access via variable creates reference")
    func structFieldAccessViaVariable() throws {
        let source = """
        struct Dog {
            name: String
        }

        func main() {
            var myDog: Dog = Dog { name: "Buddy" }
            print(myDog.name)
        }
        """

        let symbols = try collectSymbols(from: source)

        // Should have a reference to the "name" field
        let nameRefs = symbols.references.filter {
            $0.definition.name == "name" && $0.definition.kind == .field
        }
        #expect(!nameRefs.isEmpty, "Should have reference to field 'name'")

        // The reference should point to the field definition in Dog
        let ref = nameRefs.first!
        #expect(ref.definition.container == "Dog")
    }

    @Test("Parameter field access creates reference")
    func parameterFieldAccess() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func getX(p: Point) -> Int {
            return p.x
        }

        func main() {
            var pt: Point = Point { x: 1, y: 2 }
            print("\\(getX(pt))")
        }
        """

        let symbols = try collectSymbols(from: source)

        // Should have a reference to "x" field via parameter access
        let xRefs = symbols.references.filter {
            $0.definition.name == "x" && $0.definition.kind == .field
        }
        #expect(!xRefs.isEmpty, "Should have reference to field 'x'")
        #expect(xRefs.first!.definition.container == "Point")
    }

    @Test("Multiple field accesses on same variable")
    func multipleFieldAccesses() throws {
        let source = """
        struct Point {
            x: Int
            y: Int
        }

        func main() {
            var p: Point = Point { x: 1, y: 2 }
            print("\\(p.x)")
            print("\\(p.y)")
            print("\\(p.x)")
        }
        """

        let symbols = try collectSymbols(from: source)

        let xRefs = symbols.references.filter {
            $0.definition.name == "x" && $0.definition.kind == .field
        }
        let yRefs = symbols.references.filter {
            $0.definition.name == "y" && $0.definition.kind == .field
        }

        #expect(xRefs.count == 2, "Should have 2 references to 'x'")
        #expect(yRefs.count == 1, "Should have 1 reference to 'y'")
    }

    @Test("Union variable field access after type narrowing")
    func unionFieldAccessWithTypeNarrowing() throws {
        let source = """
        struct Dog {
            name: String
        }
        struct Cat {
            name: String
        }
        union Pet = Dog | Cat

        func describePet(pet: Pet) {
            switch (pet) {
                Pet.Dog -> print(pet.name)
                Pet.Cat -> print(pet.name)
            }
        }

        func main() {
            var myDog: Dog = Dog { name: "Buddy" }
            describePet(Pet.Dog(myDog))
        }
        """

        let symbols = try collectSymbols(from: source)

        // Union field access with type narrowing should find references
        // Both Dog.name and Cat.name should be referenced
        let nameRefs = symbols.references.filter {
            $0.definition.name == "name" && $0.definition.kind == .field
        }
        #expect(nameRefs.count >= 1, "Should have at least one reference to 'name' field")
    }
}
