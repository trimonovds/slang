import Testing
@testable import SlangCore

@Suite("Lexer Tests")
struct LexerTests {
    @Test("Simple operators")
    func simpleOperators() throws {
        let source = "+ - * / = == != < > <= >= && ||"
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .plus, .minus, .star, .slash, .equal, .equalEqual, .bangEqual,
            .less, .greater, .lessEqual, .greaterEqual, .ampersandAmpersand, .pipePipe,
            .eof
        ])
    }

    @Test("Keywords and identifiers")
    func keywordsAndIdentifiers() throws {
        let source = "func main var x struct enum if else for switch return true false myVar _private"
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .keyword(.func), .identifier("main"), .keyword(.var), .identifier("x"),
            .keyword(.struct), .keyword(.enum), .keyword(.if), .keyword(.else),
            .keyword(.for), .keyword(.switch), .keyword(.return),
            .keyword(.true), .keyword(.false),
            .identifier("myVar"), .identifier("_private"),
            .eof
        ])
    }

    @Test("Integer literals")
    func integerLiterals() throws {
        let source = "42 0 100"
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .intLiteral(42), .intLiteral(0), .intLiteral(100), .eof
        ])
    }

    @Test("Float literals")
    func floatLiterals() throws {
        let source = "3.14 0.5 100.0"
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .floatLiteral(3.14), .floatLiteral(0.5), .floatLiteral(100.0), .eof
        ])
    }

    @Test("String literals")
    func stringLiterals() throws {
        let source = "\"hello\" \"world\""
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .stringLiteral("hello"), .stringLiteral("world"), .eof
        ])
    }

    @Test("String interpolation")
    func stringInterpolation() throws {
        let source = "\"Hello \\(name)!\""
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .stringLiteral("Hello "),
            .stringInterpolationStart,
            .identifier("name"),
            .stringInterpolationEnd,
            .stringLiteral("!"),
            .eof
        ])
    }

    @Test("Comments are skipped")
    func comments() throws {
        let source = """
        var x = 5 // this is a comment
        var y = 10
        """
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .keyword(.var), .identifier("x"), .equal, .intLiteral(5), .newline,
            .keyword(.var), .identifier("y"), .equal, .intLiteral(10),
            .eof
        ])
    }

    @Test("Delimiters")
    func delimiters() throws {
        let source = "( ) { } , : ; . ->"
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .leftParen, .rightParen, .leftBrace, .rightBrace,
            .comma, .colon, .semicolon, .dot, .arrow,
            .eof
        ])
    }

    @Test("Compound assignment operators")
    func compoundAssignment() throws {
        let source = "+= -= *= /="
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .plusEqual, .minusEqual, .starEqual, .slashEqual, .eof
        ])
    }

    @Test("Full program")
    func fullProgram() throws {
        let source = """
        func main() {
            var x: Int = 42
            print("Value: \\(x)")
        }
        """
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        // Just check that it parses without error and has reasonable token count
        #expect(tokens.count > 10)
        #expect(tokens.last?.kind == .eof)
    }

    @Test("Escape sequences in strings")
    func escapeSequences() throws {
        let source = "\"hello\\nworld\\t!\""
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [.stringLiteral("hello\nworld\t!"), .eof])
    }

    // MARK: - Union Tests (v0.1.2)

    @Test("Union keyword and pipe operator")
    func unionKeywordAndPipe() throws {
        let source = "union Pet = Dog | Cat"
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .keyword(.union), .identifier("Pet"), .equal,
            .identifier("Dog"), .pipe, .identifier("Cat"),
            .eof
        ])
    }

    @Test("Multiple pipe operators")
    func multiplePipes() throws {
        let source = "A | B | C"
        let lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()

        let kinds = tokens.map { $0.kind }
        #expect(kinds == [
            .identifier("A"), .pipe, .identifier("B"), .pipe, .identifier("C"),
            .eof
        ])
    }
}
