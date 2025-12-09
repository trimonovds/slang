import ArgumentParser
import SlangCore
import Foundation

@main
struct Slang: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slang",
        abstract: "The Slang programming language",
        version: "0.1.0",
        subcommands: [Run.self, Check.self, Parse.self, Tokenize.self],
        defaultSubcommand: Run.self
    )
}

// MARK: - Utility Functions

func readFile(_ path: String) throws -> String {
    guard FileManager.default.fileExists(atPath: path) else {
        printError("File not found: \(path)")
        throw ExitCode.failure
    }

    guard path.hasSuffix(".slang") else {
        printError("File must have .slang extension: \(path)")
        throw ExitCode.failure
    }

    return try String(contentsOfFile: path, encoding: .utf8)
}

func printDiagnostics(_ diagnostics: [Diagnostic], source: String) {
    let printer = DiagnosticPrinter(source: source)
    for diagnostic in diagnostics {
        printer.print(diagnostic)
    }
}

func printRuntimeError(_ error: RuntimeError, source: String) {
    let red = "\u{001B}[31m"
    let reset = "\u{001B}[0m"
    let bold = "\u{001B}[1m"

    print("\(red)\(bold)runtime error:\(reset)\(bold) \(error.message)\(reset)")
    if let range = error.range {
        print("  \(red)-->\(reset) \(range.file):\(range.start.line):\(range.start.column)")
        printSourceLine(source: source, line: range.start.line, column: range.start.column)
    }
}

func printSourceLine(source: String, line: Int, column: Int) {
    let red = "\u{001B}[31m"
    let reset = "\u{001B}[0m"
    let lines = source.components(separatedBy: "\n")
    guard line > 0 && line <= lines.count else { return }

    let sourceLine = lines[line - 1]
    let lineNum = String(line)
    let padding = String(repeating: " ", count: lineNum.count)

    print("   \(padding)\(red)|\(reset)")
    print(" \(red)\(lineNum)\(reset) \(red)|\(reset) \(sourceLine)")
    print("   \(padding)\(red)|\(reset) " + String(repeating: " ", count: column - 1) + "\(red)^\(reset)")
}

func printError(_ message: String) {
    let red = "\u{001B}[31m"
    let reset = "\u{001B}[0m"
    let bold = "\u{001B}[1m"
    print("\(red)\(bold)error:\(reset)\(bold) \(message)\(reset)")
}

func printSuccess(_ message: String) {
    let green = "\u{001B}[32m"
    let reset = "\u{001B}[0m"
    print("\(green)✓\(reset) \(message)")
}

// MARK: - Run Command

struct Run: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run a Slang program"
    )

    @Argument(help: "The .slang file to run")
    var file: String

    mutating func run() throws {
        let source = try readFile(file)
        let lexer = Lexer(source: source, filename: file)

        do {
            let tokens = try lexer.tokenize()
            var parser = Parser(tokens: tokens)
            let declarations = try parser.parse()

            let typeChecker = TypeChecker()
            try typeChecker.check(declarations)

            let interpreter = Interpreter()
            try interpreter.interpret(declarations)
        } catch let error as LexerError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        } catch let error as ParserError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        } catch let error as TypeCheckError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        } catch let error as RuntimeError {
            printRuntimeError(error, source: source)
            throw ExitCode.failure
        }
    }
}

// MARK: - Check Command

struct Check: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Type-check a Slang program without running it"
    )

    @Argument(help: "The .slang file to check")
    var file: String

    mutating func run() throws {
        let source = try readFile(file)
        let lexer = Lexer(source: source, filename: file)

        do {
            let tokens = try lexer.tokenize()
            var parser = Parser(tokens: tokens)
            let declarations = try parser.parse()

            let typeChecker = TypeChecker()
            try typeChecker.check(declarations)

            printSuccess("No errors found in \(file)")
        } catch let error as LexerError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        } catch let error as ParserError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        } catch let error as TypeCheckError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        }
    }
}

// MARK: - Parse Command

struct Parse: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parse a Slang program and print the AST (for debugging)"
    )

    @Argument(help: "The .slang file to parse")
    var file: String

    mutating func run() throws {
        let source = try readFile(file)
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
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        } catch let error as ParserError {
            printDiagnostics(error.diagnostics, source: source)
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

        case .unionDecl(let name, let variants):
            let variantStr = variants.map { $0.typeName }.joined(separator: " | ")
            print("\(pad)union \(name) = \(variantStr)")
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
        case .switchExpr(let subject, let cases):
            let casesStr = cases.map { "\(exprString($0.pattern)) -> ..." }.joined(separator: ", ")
            return "switch (\(exprString(subject))) { \(casesStr) }"
        }
    }
}

// MARK: - Tokenize Command

struct Tokenize: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Tokenize a Slang program and print tokens (for debugging)"
    )

    @Argument(help: "The .slang file to tokenize")
    var file: String

    mutating func run() throws {
        let source = try readFile(file)
        let lexer = Lexer(source: source, filename: file)

        do {
            let tokens = try lexer.tokenize()
            for token in tokens {
                print("\(token.range.start.line):\(token.range.start.column)\t\(token.kind)\t'\(token.lexeme)'")
            }
            print("\nTotal: \(tokens.count) tokens")
        } catch let error as LexerError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        }
    }
}
