import ArgumentParser
import SlangCore
import Foundation

@main
struct Slang: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slang",
        abstract: "The Slang programming language",
        version: "0.1.0",
        subcommands: [Run.self, Tokenize.self, Parse.self, Check.self],
        defaultSubcommand: Run.self
    )
}

// MARK: - Run Command

struct Run: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run a Slang program"
    )

    @Argument(help: "The source file to run")
    var file: String

    mutating func run() throws {
        let source = try String(contentsOfFile: file, encoding: .utf8)
        print("Running \(file)...")
        print("Source has \(source.count) characters")
        // TODO: Implement full pipeline
    }
}

// MARK: - Tokenize Command

struct Tokenize: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Tokenize a Slang program and print tokens"
    )

    @Argument(help: "The source file to tokenize")
    var file: String

    mutating func run() throws {
        let source = try String(contentsOfFile: file, encoding: .utf8)
        let lexer = Lexer(source: source, filename: file)

        do {
            let tokens = try lexer.tokenize()
            for token in tokens {
                print("\(token.range.start): \(token.kind)")
            }
            print("\nTotal: \(tokens.count) tokens")
        } catch let error as LexerError {
            for diagnostic in error.diagnostics {
                print(diagnostic)
            }
            throw ExitCode.failure
        }
    }
}

// MARK: - Parse Command

struct Parse: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parse a Slang program and print the AST"
    )

    @Argument(help: "The source file to parse")
    var file: String

    mutating func run() throws {
        let source = try String(contentsOfFile: file, encoding: .utf8)
        let lexer = Lexer(source: source, filename: file)

        do {
            let tokens = try lexer.tokenize()
            var parser = Parser(tokens: tokens)
            let declarations = try parser.parse()

            for decl in declarations {
                printDeclaration(decl, indent: 0)
            }
            print("\nTotal: \(declarations.count) declarations")
        } catch let error as LexerError {
            for diagnostic in error.diagnostics {
                print(diagnostic)
            }
            throw ExitCode.failure
        } catch let error as ParserError {
            for diagnostic in error.diagnostics {
                print(diagnostic)
            }
            throw ExitCode.failure
        }
    }

    private func printDeclaration(_ decl: Declaration, indent: Int) {
        let pad = String(repeating: "  ", count: indent)
        switch decl.kind {
        case .function(let name, let params, let returnType, let body):
            let paramStr = params.map { "\($0.name): \($0.type.name)" }.joined(separator: ", ")
            let retStr = returnType.map { " -> \($0.name)" } ?? ""
            print("\(pad)func \(name)(\(paramStr))\(retStr)")
            printStatement(body, indent: indent + 1)

        case .structDecl(let name, let fields):
            print("\(pad)struct \(name)")
            for field in fields {
                print("\(pad)  \(field.name): \(field.type.name)")
            }

        case .enumDecl(let name, let cases):
            print("\(pad)enum \(name)")
            for enumCase in cases {
                print("\(pad)  case \(enumCase.name)")
            }
        }
    }

    private func printStatement(_ stmt: Statement, indent: Int) {
        let pad = String(repeating: "  ", count: indent)
        switch stmt.kind {
        case .block(let statements):
            print("\(pad){")
            for s in statements {
                printStatement(s, indent: indent + 1)
            }
            print("\(pad)}")

        case .varDecl(let name, let type, let initializer):
            print("\(pad)var \(name): \(type.name) = \(exprString(initializer))")

        case .expression(let expr):
            print("\(pad)\(exprString(expr))")

        case .returnStmt(let value):
            if let v = value {
                print("\(pad)return \(exprString(v))")
            } else {
                print("\(pad)return")
            }

        case .ifStmt(let condition, let thenBranch, let elseBranch):
            print("\(pad)if (\(exprString(condition)))")
            printStatement(thenBranch, indent: indent + 1)
            if let elseB = elseBranch {
                print("\(pad)else")
                printStatement(elseB, indent: indent + 1)
            }

        case .forStmt(let initializer, let condition, let increment, let body):
            let initStr = initializer.map { stmtString($0) } ?? ""
            let condStr = condition.map { exprString($0) } ?? ""
            let incrStr = increment.map { exprString($0) } ?? ""
            print("\(pad)for (\(initStr); \(condStr); \(incrStr))")
            printStatement(body, indent: indent + 1)

        case .switchStmt(let subject, let cases):
            print("\(pad)switch (\(exprString(subject)))")
            for c in cases {
                print("\(pad)  \(exprString(c.pattern)) ->")
                printStatement(c.body, indent: indent + 2)
            }
        }
    }

    private func stmtString(_ stmt: Statement) -> String {
        switch stmt.kind {
        case .varDecl(let name, let type, let initializer):
            return "var \(name): \(type.name) = \(exprString(initializer))"
        default:
            return "<stmt>"
        }
    }

    private func exprString(_ expr: SlangCore.Expression) -> String {
        switch expr.kind {
        case .intLiteral(let value):
            return "\(value)"
        case .floatLiteral(let value):
            return "\(value)"
        case .stringLiteral(let value):
            return "\"\(value)\""
        case .boolLiteral(let value):
            return "\(value)"
        case .stringInterpolation(let parts):
            let str = parts.map { part -> String in
                switch part {
                case .literal(let s): return s
                case .interpolation(let e): return "\\(\(exprString(e)))"
                }
            }.joined()
            return "\"\(str)\""
        case .identifier(let name):
            return name
        case .binary(let left, let op, let right):
            return "(\(exprString(left)) \(op.rawValue) \(exprString(right)))"
        case .unary(let op, let operand):
            return "(\(op.rawValue)\(exprString(operand)))"
        case .call(let callee, let args):
            let argsStr = args.map { exprString($0) }.joined(separator: ", ")
            return "\(exprString(callee))(\(argsStr))"
        case .memberAccess(let object, let member):
            return "\(exprString(object)).\(member)"
        case .structInit(let typeName, let fields):
            let fieldsStr = fields.map { "\($0.name): \(exprString($0.value))" }.joined(separator: ", ")
            return "\(typeName) { \(fieldsStr) }"
        }
    }
}

// MARK: - Check Command

struct Check: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Type-check a Slang program"
    )

    @Argument(help: "The source file to type-check")
    var file: String

    mutating func run() throws {
        let source = try String(contentsOfFile: file, encoding: .utf8)
        let lexer = Lexer(source: source, filename: file)

        do {
            let tokens = try lexer.tokenize()
            var parser = Parser(tokens: tokens)
            let declarations = try parser.parse()

            let typeChecker = TypeChecker()
            try typeChecker.check(declarations)

            print("Type check passed for \(file)")
        } catch let error as LexerError {
            for diagnostic in error.diagnostics {
                print(diagnostic)
            }
            throw ExitCode.failure
        } catch let error as ParserError {
            for diagnostic in error.diagnostics {
                print(diagnostic)
            }
            throw ExitCode.failure
        } catch let error as TypeCheckError {
            for diagnostic in error.diagnostics {
                print(diagnostic)
            }
            throw ExitCode.failure
        }
    }
}
