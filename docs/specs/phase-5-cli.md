# Phase 5: CLI Polish

## Overview

This phase focuses on creating a professional command-line interface with proper subcommands, helpful error messages, and debugging tools.

**Input:** Command-line arguments
**Output:** Program execution or diagnostic output

---

## Prerequisites

- Phase 1-4 complete (full compilation pipeline working)

---

## Files to Modify/Create

| File | Purpose |
|------|---------|
| `Sources/slang/slang.swift` | Main CLI entry point with subcommands |
| `Sources/SlangCore/Diagnostics/DiagnosticPrinter.swift` | Pretty error printing |

---

## Step 1: Update slang.swift - Main Structure

```swift
// Sources/slang/slang.swift

import ArgumentParser
import Foundation
import SlangCore

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
```

---

## Step 2: Run Subcommand

```swift
// MARK: - Run Command

struct Run: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run a Slang program"
    )

    @Argument(help: "The .slang file to run")
    var file: String

    mutating func run() throws {
        let source = try readFile(file)

        do {
            // Lexer
            let lexer = Lexer(source: source, filename: file)
            let tokens = try lexer.tokenize()

            // Parser
            let parser = Parser(tokens: tokens)
            let ast = try parser.parse()

            // Type Checker
            let typeChecker = TypeChecker()
            try typeChecker.check(ast)

            // Interpreter
            let interpreter = Interpreter()
            try interpreter.interpret(ast)

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
```

---

## Step 3: Check Subcommand

```swift
// MARK: - Check Command

struct Check: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Type-check a Slang program without running it"
    )

    @Argument(help: "The .slang file to check")
    var file: String

    mutating func run() throws {
        let source = try readFile(file)

        do {
            // Lexer
            let lexer = Lexer(source: source, filename: file)
            let tokens = try lexer.tokenize()

            // Parser
            let parser = Parser(tokens: tokens)
            let ast = try parser.parse()

            // Type Checker
            let typeChecker = TypeChecker()
            try typeChecker.check(ast)

            print("\u{001B}[32m✓\u{001B}[0m No errors found in \(file)")

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
```

---

## Step 4: Parse Subcommand (Debug)

```swift
// MARK: - Parse Command

struct Parse: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parse a Slang program and print the AST (for debugging)"
    )

    @Argument(help: "The .slang file to parse")
    var file: String

    mutating func run() throws {
        let source = try readFile(file)

        do {
            // Lexer
            let lexer = Lexer(source: source, filename: file)
            let tokens = try lexer.tokenize()

            // Parser
            let parser = Parser(tokens: tokens)
            let ast = try parser.parse()

            // Print AST
            let printer = ASTPrinter()
            for decl in ast {
                print(printer.print(decl))
            }

        } catch let error as LexerError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        } catch let error as ParserError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        }
    }
}
```

---

## Step 5: Tokenize Subcommand (Debug)

```swift
// MARK: - Tokenize Command

struct Tokenize: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Tokenize a Slang program and print tokens (for debugging)"
    )

    @Argument(help: "The .slang file to tokenize")
    var file: String

    mutating func run() throws {
        let source = try readFile(file)

        do {
            let lexer = Lexer(source: source, filename: file)
            let tokens = try lexer.tokenize()

            for token in tokens {
                print("\(token.range.start.line):\(token.range.start.column)\t\(token.kind)\t'\(token.lexeme)'")
            }

        } catch let error as LexerError {
            printDiagnostics(error.diagnostics, source: source)
            throw ExitCode.failure
        }
    }
}
```

---

## Step 6: Utility Functions

```swift
// MARK: - Utility Functions

func readFile(_ path: String) throws -> String {
    let url = URL(fileURLWithPath: path)

    guard FileManager.default.fileExists(atPath: path) else {
        print("\u{001B}[31merror:\u{001B}[0m File not found: \(path)")
        throw ExitCode.failure
    }

    guard path.hasSuffix(".slang") else {
        print("\u{001B}[31merror:\u{001B}[0m File must have .slang extension: \(path)")
        throw ExitCode.failure
    }

    return try String(contentsOf: url, encoding: .utf8)
}

func printDiagnostics(_ diagnostics: [Diagnostic], source: String) {
    let printer = DiagnosticPrinter(source: source)
    for diagnostic in diagnostics {
        printer.print(diagnostic)
    }
}

func printRuntimeError(_ error: RuntimeError, source: String) {
    print("\u{001B}[31mruntime error:\u{001B}[0m \(error.message)")
    if let range = error.range {
        print("  --> \(range.file):\(range.start.line):\(range.start.column)")
        printSourceLine(source: source, line: range.start.line, column: range.start.column)
    }
}

func printSourceLine(source: String, line: Int, column: Int) {
    let lines = source.components(separatedBy: "\n")
    guard line > 0 && line <= lines.count else { return }

    let sourceLine = lines[line - 1]
    let lineNum = String(line)
    let padding = String(repeating: " ", count: lineNum.count)

    print("   \(padding)|")
    print(" \(lineNum) | \(sourceLine)")
    print("   \(padding)| " + String(repeating: " ", count: column - 1) + "\u{001B}[31m^\u{001B}[0m")
}
```

---

## Step 7: DiagnosticPrinter.swift

```swift
// Sources/SlangCore/Diagnostics/DiagnosticPrinter.swift

import Foundation

/// Pretty-prints diagnostic messages with source context
public class DiagnosticPrinter {
    private let source: String
    private let lines: [String]

    public init(source: String) {
        self.source = source
        self.lines = source.components(separatedBy: "\n")
    }

    public func print(_ diagnostic: Diagnostic) {
        let severityColor: String
        let severityText: String

        switch diagnostic.severity {
        case .error:
            severityColor = "\u{001B}[31m"  // Red
            severityText = "error"
        case .warning:
            severityColor = "\u{001B}[33m"  // Yellow
            severityText = "warning"
        case .note:
            severityColor = "\u{001B}[34m"  // Blue
            severityText = "note"
        }

        let reset = "\u{001B}[0m"
        let bold = "\u{001B}[1m"

        // Print the main message
        Swift.print("\(severityColor)\(bold)\(severityText):\(reset)\(bold) \(diagnostic.message)\(reset)")

        // Print the location
        Swift.print("  \(severityColor)-->\(reset) \(diagnostic.range.file):\(diagnostic.range.start.line):\(diagnostic.range.start.column)")

        // Print the source context
        printSourceContext(diagnostic.range, color: severityColor)

        Swift.print()  // Empty line after each diagnostic
    }

    private func printSourceContext(_ range: SourceRange, color: String) {
        let reset = "\u{001B}[0m"
        let line = range.start.line
        let column = range.start.column

        guard line > 0 && line <= lines.count else { return }

        let sourceLine = lines[line - 1]
        let lineNumStr = String(line)
        let padding = String(repeating: " ", count: lineNumStr.count)

        // Print the gutter
        Swift.print("   \(padding)\(color)|\(reset)")

        // Print the source line
        Swift.print(" \(color)\(lineNumStr)\(reset) \(color)|\(reset) \(sourceLine)")

        // Print the underline
        let spaces = String(repeating: " ", count: column - 1)
        let underline: String
        if range.start.line == range.end.line && range.end.column > range.start.column {
            underline = String(repeating: "^", count: range.end.column - range.start.column)
        } else {
            underline = "^"
        }
        Swift.print("   \(padding)\(color)|\(reset) \(spaces)\(color)\(underline)\(reset)")
    }
}
```

---

## Step 8: ASTPrinter.swift

Create an AST printer for debugging:

```swift
// Sources/SlangCore/Parser/ASTPrinter.swift

import Foundation

/// Pretty-prints AST nodes for debugging
public class ASTPrinter {
    public init() {}

    public func print(_ node: ASTNode, indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)

        switch node {
        case let decl as FunctionDecl:
            var result = "\(prefix)FunctionDecl '\(decl.name)'\n"
            result += "\(prefix)  Parameters:\n"
            for param in decl.parameters {
                result += "\(prefix)    \(param.name): \(param.type.name)\n"
            }
            if let ret = decl.returnType {
                result += "\(prefix)  Returns: \(ret.name)\n"
            }
            result += "\(prefix)  Body:\n"
            result += print(decl.body, indent: indent + 2)
            return result

        case let decl as StructDecl:
            var result = "\(prefix)StructDecl '\(decl.name)'\n"
            for field in decl.fields {
                result += "\(prefix)  \(field.name): \(field.type.name)\n"
            }
            return result

        case let decl as EnumDecl:
            var result = "\(prefix)EnumDecl '\(decl.name)'\n"
            for c in decl.cases {
                result += "\(prefix)  case \(c.name)\n"
            }
            return result

        case let stmt as BlockStmt:
            var result = "\(prefix)Block\n"
            for s in stmt.statements {
                result += print(s, indent: indent + 1)
            }
            return result

        case let stmt as VarDeclStmt:
            var result = "\(prefix)VarDecl '\(stmt.name)': \(stmt.type.name)\n"
            result += "\(prefix)  Initializer:\n"
            result += print(stmt.initializer, indent: indent + 2)
            return result

        case let stmt as ReturnStmt:
            var result = "\(prefix)Return\n"
            if let value = stmt.value {
                result += print(value, indent: indent + 1)
            }
            return result

        case let stmt as IfStmt:
            var result = "\(prefix)If\n"
            result += "\(prefix)  Condition:\n"
            result += print(stmt.condition, indent: indent + 2)
            result += "\(prefix)  Then:\n"
            result += print(stmt.thenBranch, indent: indent + 2)
            if let elseBranch = stmt.elseBranch {
                result += "\(prefix)  Else:\n"
                result += print(elseBranch, indent: indent + 2)
            }
            return result

        case let stmt as ForStmt:
            var result = "\(prefix)For\n"
            if let init_ = stmt.initializer {
                result += "\(prefix)  Init:\n"
                result += print(init_, indent: indent + 2)
            }
            if let cond = stmt.condition {
                result += "\(prefix)  Condition:\n"
                result += print(cond, indent: indent + 2)
            }
            if let incr = stmt.increment {
                result += "\(prefix)  Increment:\n"
                result += print(incr, indent: indent + 2)
            }
            result += "\(prefix)  Body:\n"
            result += print(stmt.body, indent: indent + 2)
            return result

        case let stmt as SwitchStmt:
            var result = "\(prefix)Switch\n"
            result += "\(prefix)  Subject:\n"
            result += print(stmt.subject, indent: indent + 2)
            for c in stmt.cases {
                result += "\(prefix)  Case:\n"
                result += "\(prefix)    Pattern:\n"
                result += print(c.pattern, indent: indent + 3)
                result += "\(prefix)    Body:\n"
                result += print(c.body, indent: indent + 3)
            }
            return result

        case let stmt as ExpressionStmt:
            var result = "\(prefix)ExpressionStmt\n"
            result += print(stmt.expression, indent: indent + 1)
            return result

        case let expr as IntLiteralExpr:
            return "\(prefix)IntLiteral(\(expr.value))\n"

        case let expr as FloatLiteralExpr:
            return "\(prefix)FloatLiteral(\(expr.value))\n"

        case let expr as StringLiteralExpr:
            return "\(prefix)StringLiteral(\"\(expr.value)\")\n"

        case let expr as BoolLiteralExpr:
            return "\(prefix)BoolLiteral(\(expr.value))\n"

        case let expr as IdentifierExpr:
            return "\(prefix)Identifier(\(expr.name))\n"

        case let expr as BinaryExpr:
            var result = "\(prefix)Binary(\(expr.op.rawValue))\n"
            result += print(expr.left, indent: indent + 1)
            result += print(expr.right, indent: indent + 1)
            return result

        case let expr as UnaryExpr:
            var result = "\(prefix)Unary(\(expr.op.rawValue))\n"
            result += print(expr.operand, indent: indent + 1)
            return result

        case let expr as CallExpr:
            var result = "\(prefix)Call\n"
            result += "\(prefix)  Callee:\n"
            result += print(expr.callee, indent: indent + 2)
            result += "\(prefix)  Arguments:\n"
            for arg in expr.arguments {
                result += print(arg, indent: indent + 2)
            }
            return result

        case let expr as MemberAccessExpr:
            var result = "\(prefix)MemberAccess .\(expr.member)\n"
            result += print(expr.object, indent: indent + 1)
            return result

        case let expr as StructInitExpr:
            var result = "\(prefix)StructInit '\(expr.typeName)'\n"
            for field in expr.fields {
                result += "\(prefix)  \(field.name):\n"
                result += print(field.value, indent: indent + 2)
            }
            return result

        case let expr as StringInterpolationExpr:
            var result = "\(prefix)StringInterpolation\n"
            for part in expr.parts {
                switch part {
                case .literal(let str):
                    result += "\(prefix)  Literal(\"\(str)\")\n"
                case .interpolation(let e):
                    result += "\(prefix)  Interpolation:\n"
                    result += print(e, indent: indent + 2)
                }
            }
            return result

        default:
            return "\(prefix)Unknown node\n"
        }
    }
}
```

---

## CLI Usage Examples

### Running a Program

```bash
$ slang run hello.slang
Hello, World!

$ slang hello.slang  # 'run' is default
Hello, World!
```

### Type Checking

```bash
$ slang check hello.slang
✓ No errors found in hello.slang

$ slang check broken.slang
error: Cannot assign value of type 'String' to variable of type 'Int'
  --> broken.slang:3:5
   |
 3 |     var x: Int = "hello"
   |     ^^^^^^^^^^^^^^^^^^^^
```

### Debugging - Tokenize

```bash
$ slang tokenize hello.slang
1:1     keyword(func)   'func'
1:6     identifier(main)        'main'
1:10    (       '('
1:11    )       ')'
1:13    {       '{'
...
```

### Debugging - Parse

```bash
$ slang parse hello.slang
FunctionDecl 'main'
  Parameters:
  Body:
    Block
      ExpressionStmt
        Call
          Callee:
            Identifier(print)
          Arguments:
            StringLiteral("Hello, World!")
```

---

## Error Output Examples

### Lexer Error

```
error: Unterminated string literal
  --> test.slang:3:12
   |
 3 |     var s = "hello
   |             ^
```

### Parser Error

```
error: Expected ')' after arguments
  --> test.slang:5:15
   |
 5 |     print("hi"
   |               ^
```

### Type Error

```
error: Cannot assign value of type 'String' to variable of type 'Int'
  --> test.slang:2:5
   |
 2 |     var x: Int = "hello"
   |     ^^^^^^^^^^^^^^^^^^^^
```

### Runtime Error

```
runtime error: Division by zero
  --> test.slang:3:14
   |
 3 |     var x = 5 / 0
   |              ^
```

---

## Acceptance Criteria

- [x] CLI has proper subcommands: `run`, `check`, `parse`, `tokenize`
- [x] `slang run <file>` executes programs
- [x] `slang check <file>` type-checks without running
- [x] `slang parse <file>` prints AST for debugging
- [x] `slang tokenize <file>` prints tokens for debugging
- [x] `slang --version` shows version
- [x] `slang --help` shows help
- [x] Errors display with:
  - [x] Colored severity (red for errors)
  - [x] File location (file:line:column)
  - [x] Source context with underline
- [x] Non-zero exit code on errors
- [x] File validation (.slang extension, file exists)
- [x] All commands work end-to-end

---

## Next Phase

Once this phase is complete, proceed to [Phase 6: Testing](phase-6-testing.md).
