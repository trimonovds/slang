import ArgumentParser
import SlangCore
import Foundation

@main
struct Slang: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slang",
        abstract: "The Slang programming language",
        version: "0.1.0",
        subcommands: [Run.self, Tokenize.self],
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
