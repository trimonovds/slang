import Testing
@testable import SlangCore

@Suite("Collection Tests")
struct CollectionTests {
    // MARK: - Helper

    func run(_ source: String, expectOutput: [String]) throws {
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(decls)

        var output: [String] = []
        let interpreter = Interpreter(printHandler: { output.append($0) })
        try interpreter.interpret(decls)

        #expect(output == expectOutput, "Expected \(expectOutput), got \(output)")
    }

    func expectTypeError(_ source: String, containing: String) throws {
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        let typeChecker = TypeChecker()

        do {
            try typeChecker.check(decls)
            Issue.record("Expected type error containing '\(containing)'")
        } catch let error as TypeCheckError {
            let messages = error.diagnostics.map { $0.message }
            let found = messages.contains { $0.contains(containing) }
            #expect(found, "Expected error containing '\(containing)', got: \(messages)")
        }
    }

    func expectRuntimeError(_ source: String, containing: String) throws {
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        let typeChecker = TypeChecker()
        try typeChecker.check(decls)

        do {
            let interpreter = Interpreter()
            try interpreter.interpret(decls)
            Issue.record("Expected runtime error containing '\(containing)'")
        } catch let error as RuntimeError {
            let found = error.message.contains(containing)
            #expect(found, "Expected error containing '\(containing)', got: \(error.message)")
        }
    }

    // MARK: - Optional Tests

    @Test("Optional type annotation")
    func optionalTypeAnnotation() throws {
        let source = """
        func main() {
            var x: Int? = nil
            print("done")
        }
        """
        try run(source, expectOutput: ["done"])
    }

    @Test("Optional with value")
    func optionalWithValue() throws {
        let source = """
        func main() {
            var x: Int? = 42
            print("\\(x)")
        }
        """
        try run(source, expectOutput: ["some(42)"])
    }

    @Test("Optional nil literal")
    func optionalNilLiteral() throws {
        let source = """
        func main() {
            var x: String? = nil
            print("\\(x)")
        }
        """
        try run(source, expectOutput: ["nil"])
    }

    @Test("Assign value to optional variable")
    func assignValueToOptional() throws {
        let source = """
        func main() {
            var x: Int? = nil
            x = 42
            print("\\(x)")
        }
        """
        try run(source, expectOutput: ["some(42)"])
    }

    @Test("Assign nil to optional variable")
    func assignNilToOptional() throws {
        let source = """
        func main() {
            var x: Int? = 42
            x = nil
            print("\\(x)")
        }
        """
        try run(source, expectOutput: ["nil"])
    }

    @Test("Optional nil comparison - equals nil")
    func optionalNilComparisonEquals() throws {
        let source = """
        func main() {
            var x: Int? = nil
            print("\\(x == nil)")
            x = 42
            print("\\(x == nil)")
        }
        """
        try run(source, expectOutput: ["true", "false"])
    }

    @Test("Optional nil comparison - not equals nil")
    func optionalNilComparisonNotEquals() throws {
        let source = """
        func main() {
            var x: String? = "hello"
            print("\\(x != nil)")
            x = nil
            print("\\(x != nil)")
        }
        """
        try run(source, expectOutput: ["true", "false"])
    }

    @Test("Optional nil comparison - assign to variable")
    func optionalNilComparisonAssign() throws {
        let source = """
        func main() {
            var x: Int? = nil
            var isNil: Bool = x == nil
            var notNil: Bool = x != nil
            print("\\(isNil)")
            print("\\(notNil)")
        }
        """
        try run(source, expectOutput: ["true", "false"])
    }

    @Test("Optional switch statement")
    func optionalSwitchStatement() throws {
        let source = """
        func main() {
            var x: Int? = 42
            switch (x) {
                some -> print("has value")
                none -> print("nil")
            }
            x = nil
            switch (x) {
                some -> print("has value")
                none -> print("nil")
            }
        }
        """
        try run(source, expectOutput: ["has value", "nil"])
    }

    @Test("Optional switch statement with type narrowing")
    func optionalSwitchTypeNarrowing() throws {
        let source = """
        func double(n: Int) -> Int { return n * 2 }
        func main() {
            var x: Int? = 5
            switch (x) {
                some -> print("\\(double(x))")
                none -> print("nil")
            }
        }
        """
        try run(source, expectOutput: ["10"])
    }

    @Test("Optional switch expression")
    func optionalSwitchExpression() throws {
        let source = """
        func main() {
            var x: Int? = 10
            var result: Int = switch (x) {
                some -> return x * 2
                none -> return 0
            }
            print("\\(result)")

            x = nil
            var result2: Int = switch (x) {
                some -> return x
                none -> return -1
            }
            print("\\(result2)")
        }
        """
        try run(source, expectOutput: ["20", "-1"])
    }

    @Test("Optional switch exhaustiveness error")
    func optionalSwitchExhaustivenessError() throws {
        let source = """
        func main() {
            var x: Int? = 42
            switch (x) {
                some -> print("value")
            }
        }
        """
        try expectTypeError(source, containing: "Missing cases: none")
    }

    // Note: Nested optionals (Int??) are not currently supported
    // @Test("Nested optional")
    // func nestedOptional() throws { ... }

    // MARK: - Array Tests

    @Test("Array literal")
    func arrayLiteral() throws {
        let source = """
        func main() {
            var arr: [Int] = [1, 2, 3]
            print("\\(arr)")
        }
        """
        try run(source, expectOutput: ["[1, 2, 3]"])
    }

    @Test("Empty array")
    func emptyArray() throws {
        let source = """
        func main() {
            var arr: [Int] = []
            print("\\(arr)")
        }
        """
        try run(source, expectOutput: ["[]"])
    }

    @Test("Array subscript read")
    func arraySubscriptRead() throws {
        let source = """
        func main() {
            var arr: [Int] = [10, 20, 30]
            print("\\(arr[0])")
            print("\\(arr[1])")
            print("\\(arr[2])")
        }
        """
        try run(source, expectOutput: ["10", "20", "30"])
    }

    @Test("Array subscript write")
    func arraySubscriptWrite() throws {
        let source = """
        func main() {
            var arr: [Int] = [1, 2, 3]
            arr[1] = 42
            print("\\(arr[1])")
        }
        """
        try run(source, expectOutput: ["42"])
    }

    @Test("Array count property")
    func arrayCount() throws {
        let source = """
        func main() {
            var arr: [Int] = [1, 2, 3, 4, 5]
            print("\\(arr.count)")
        }
        """
        try run(source, expectOutput: ["5"])
    }

    @Test("Array isEmpty property")
    func arrayIsEmpty() throws {
        let source = """
        func main() {
            var arr: [Int] = []
            print("\\(arr.isEmpty)")
            var arr2: [Int] = [1]
            print("\\(arr2.isEmpty)")
        }
        """
        try run(source, expectOutput: ["true", "false"])
    }

    @Test("Array first property")
    func arrayFirst() throws {
        let source = """
        func main() {
            var arr: [Int] = [10, 20, 30]
            var first: Int? = arr.first
            print("\\(first)")
            var empty: [Int] = []
            var emptyFirst: Int? = empty.first
            print("\\(emptyFirst)")
        }
        """
        try run(source, expectOutput: ["some(10)", "nil"])
    }

    @Test("Array last property")
    func arrayLast() throws {
        let source = """
        func main() {
            var arr: [Int] = [10, 20, 30]
            var last: Int? = arr.last
            print("\\(last)")
        }
        """
        try run(source, expectOutput: ["some(30)"])
    }

    @Test("Array append method")
    func arrayAppend() throws {
        let source = """
        func main() {
            var arr: [Int] = [1, 2]
            arr.append(3)
            print("\\(arr.count)")
            print("\\(arr[2])")
        }
        """
        try run(source, expectOutput: ["3", "3"])
    }

    @Test("Array removeAt method")
    func arrayRemoveAt() throws {
        let source = """
        func main() {
            var arr: [Int] = [1, 2, 3]
            arr.removeAt(1)
            print("\\(arr.count)")
            print("\\(arr[1])")
        }
        """
        try run(source, expectOutput: ["2", "3"])
    }

    @Test("Array out of bounds - runtime error")
    func arrayOutOfBounds() throws {
        let source = """
        func main() {
            var arr: [Int] = [1, 2, 3]
            print("\\(arr[10])")
        }
        """
        try expectRuntimeError(source, containing: "out of bounds")
    }

    @Test("Nested arrays")
    func nestedArrays() throws {
        let source = """
        func main() {
            var arr: [[Int]] = [[1, 2], [3, 4]]
            print("\\(arr[0][1])")
            print("\\(arr[1][0])")
        }
        """
        try run(source, expectOutput: ["2", "3"])
    }

    @Test("Array of strings")
    func arrayOfStrings() throws {
        let source = """
        func main() {
            var arr: [String] = ["hello", "world"]
            print(arr[0])
            print(arr[1])
        }
        """
        try run(source, expectOutput: ["hello", "world"])
    }

    // MARK: - Dictionary Tests

    @Test("Dictionary literal")
    func dictionaryLiteral() throws {
        let source = """
        func main() {
            var dict: [String: Int] = ["a": 1, "b": 2]
            print("\\(dict.count)")
        }
        """
        try run(source, expectOutput: ["2"])
    }

    @Test("Empty dictionary")
    func emptyDictionary() throws {
        let source = """
        func main() {
            var dict: [String: Int] = [:]
            print("\\(dict.count)")
            print("\\(dict.isEmpty)")
        }
        """
        try run(source, expectOutput: ["0", "true"])
    }

    @Test("Dictionary subscript returns optional")
    func dictionarySubscriptReturnsOptional() throws {
        let source = """
        func main() {
            var dict: [String: Int] = ["a": 1]
            var val: Int? = dict["a"]
            print("\\(val)")
            var missing: Int? = dict["b"]
            print("\\(missing)")
        }
        """
        try run(source, expectOutput: ["some(1)", "nil"])
    }

    @Test("Dictionary subscript assignment - add")
    func dictionarySubscriptAdd() throws {
        let source = """
        func main() {
            var dict: [String: Int] = ["a": 1]
            dict["b"] = 2
            print("\\(dict.count)")
            var val: Int? = dict["b"]
            print("\\(val)")
        }
        """
        try run(source, expectOutput: ["2", "some(2)"])
    }

    @Test("Dictionary subscript assignment - update")
    func dictionarySubscriptUpdate() throws {
        let source = """
        func main() {
            var dict: [String: Int] = ["a": 1]
            dict["a"] = 42
            var val: Int? = dict["a"]
            print("\\(val)")
        }
        """
        try run(source, expectOutput: ["some(42)"])
    }

    @Test("Dictionary keys property")
    func dictionaryKeys() throws {
        let source = """
        func main() {
            var dict: [String: Int] = ["a": 1, "b": 2]
            var keys: [String] = dict.keys
            print("\\(keys.count)")
        }
        """
        try run(source, expectOutput: ["2"])
    }

    @Test("Dictionary values property")
    func dictionaryValues() throws {
        let source = """
        func main() {
            var dict: [String: Int] = ["a": 1, "b": 2]
            var values: [Int] = dict.values
            print("\\(values.count)")
        }
        """
        try run(source, expectOutput: ["2"])
    }

    @Test("Dictionary removeKey method")
    func dictionaryRemoveKey() throws {
        let source = """
        func main() {
            var dict: [String: Int] = ["a": 1, "b": 2]
            dict.removeKey("a")
            print("\\(dict.count)")
            var val: Int? = dict["a"]
            print("\\(val)")
        }
        """
        try run(source, expectOutput: ["1", "nil"])
    }

    @Test("Dictionary with Int keys")
    func dictionaryIntKeys() throws {
        let source = """
        func main() {
            var dict: [Int: String] = [1: "one", 2: "two"]
            var val: String? = dict[1]
            print("\\(val)")
        }
        """
        try run(source, expectOutput: ["some(one)"])
    }

    // MARK: - Set Tests

    @Test("Set creation")
    func setCreation() throws {
        let source = """
        func main() {
            var s: Set<Int> = [1, 2, 3]
            print("\\(s.count)")
        }
        """
        try run(source, expectOutput: ["3"])
    }

    @Test("Set deduplication")
    func setDeduplication() throws {
        let source = """
        func main() {
            var s: Set<Int> = [1, 2, 2, 3, 3, 3]
            print("\\(s.count)")
        }
        """
        try run(source, expectOutput: ["3"])
    }

    @Test("Empty set")
    func emptySet() throws {
        let source = """
        func main() {
            var s: Set<Int> = []
            print("\\(s.count)")
            print("\\(s.isEmpty)")
        }
        """
        try run(source, expectOutput: ["0", "true"])
    }

    @Test("Set contains method")
    func setContains() throws {
        let source = """
        func main() {
            var s: Set<Int> = [1, 2, 3]
            print("\\(s.contains(2))")
            print("\\(s.contains(5))")
        }
        """
        try run(source, expectOutput: ["true", "false"])
    }

    @Test("Set insert method")
    func setInsert() throws {
        let source = """
        func main() {
            var s: Set<Int> = [1, 2]
            s.insert(3)
            print("\\(s.count)")
            print("\\(s.contains(3))")
        }
        """
        try run(source, expectOutput: ["3", "true"])
    }

    @Test("Set insert duplicate")
    func setInsertDuplicate() throws {
        let source = """
        func main() {
            var s: Set<Int> = [1, 2]
            s.insert(2)
            print("\\(s.count)")
        }
        """
        try run(source, expectOutput: ["2"])
    }

    @Test("Set remove method")
    func setRemove() throws {
        let source = """
        func main() {
            var s: Set<Int> = [1, 2, 3]
            var removed: Bool = s.remove(2)
            print("\\(removed)")
            print("\\(s.count)")
            print("\\(s.contains(2))")
        }
        """
        try run(source, expectOutput: ["true", "2", "false"])
    }

    @Test("Set remove non-existent")
    func setRemoveNonExistent() throws {
        let source = """
        func main() {
            var s: Set<Int> = [1, 2, 3]
            var removed: Bool = s.remove(5)
            print("\\(removed)")
            print("\\(s.count)")
        }
        """
        try run(source, expectOutput: ["false", "3"])
    }

    @Test("Set of strings")
    func setOfStrings() throws {
        let source = #"""
        func main() {
            var s: Set<String> = ["apple", "banana", "apple"]
            print("\(s.count)")
            print("\(s.contains("apple"))")
        }
        """#
        try run(source, expectOutput: ["2", "true"])
    }

    // MARK: - Type Error Tests

    @Test("Array type mismatch")
    func arrayTypeMismatch() throws {
        let source = #"""
        func main() {
            var arr: [Int] = [1, "two", 3]
        }
        """#
        try expectTypeError(source, containing: "expected 'Int', got 'String'")
    }

    @Test("Array subscript with non-Int index")
    func arrayNonIntIndex() throws {
        let source = #"""
        func main() {
            var arr: [Int] = [1, 2, 3]
            print("\(arr["a"])")
        }
        """#
        try expectTypeError(source, containing: "Array subscript index must be Int")
    }

    @Test("Dictionary key type mismatch")
    func dictionaryKeyTypeMismatch() throws {
        let source = #"""
        func main() {
            var dict: [String: Int] = [1: 1]
        }
        """#
        try expectTypeError(source, containing: "Expected key of type 'String', got 'Int'")
    }

    @Test("Dictionary value type mismatch")
    func dictionaryValueTypeMismatch() throws {
        let source = #"""
        func main() {
            var dict: [String: Int] = ["a": "one"]
        }
        """#
        try expectTypeError(source, containing: "Expected value of type 'Int', got 'String'")
    }

    @Test("Assign wrong type to optional")
    func assignWrongTypeToOptional() throws {
        let source = """
        func main() {
            var x: Int? = "hello"
        }
        """
        try expectTypeError(source, containing: "Cannot assign")
    }

    // MARK: - Complex Collection Tests

    // Note: Arrays of optionals require proper type propagation to elements
    // This is a known limitation - we would need to pass expected element type
    // @Test("Array of optionals")
    // func arrayOfOptionals() throws { ... }

    @Test("Optional array")
    func optionalArray() throws {
        let source = """
        func main() {
            var arr: [Int]? = [1, 2, 3]
            print("done")
        }
        """
        try run(source, expectOutput: ["done"])
    }

    @Test("Dictionary in array")
    func dictionaryInArray() throws {
        let source = """
        func main() {
            var arr: [[String: Int]] = [["a": 1], ["b": 2]]
            var val: Int? = arr[0]["a"]
            print("\\(val)")
        }
        """
        try run(source, expectOutput: ["some(1)"])
    }

    @Test("Array in dictionary")
    func arrayInDictionary() throws {
        let source = """
        func main() {
            var dict: [String: [Int]] = ["nums": [1, 2, 3]]
            var arr: [Int]? = dict["nums"]
            print("done")
        }
        """
        try run(source, expectOutput: ["done"])
    }
}
