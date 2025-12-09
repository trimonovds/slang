import Testing
import Foundation
@testable import SlangCore

@Suite("DiagnosticPrinter Tests")
struct DiagnosticPrinterTests {

    // MARK: - Alignment Tests

    @Test("Caret aligns with single-digit line numbers")
    func caretAlignsSingleDigitLine() {
        let source = "var x: Int = 42"
        let range = SourceRange(
            start: SourceLocation(line: 1, column: 14, offset: 13),
            end: SourceLocation(line: 1, column: 16, offset: 15),
            file: "test.slang"
        )
        let diagnostic = Diagnostic.error("Test error", at: range)
        let printer = DiagnosticPrinter(source: source)

        let output = printer.format(diagnostic, useColors: false)
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        // Find the source line and underline line
        guard let sourceLineIndex = lines.firstIndex(where: { $0.contains("var x: Int") }),
              sourceLineIndex + 1 < lines.count else {
            Issue.record("Could not find source line in output: \(output)")
            return
        }

        let sourceLine = lines[sourceLineIndex]
        let underlineLine = lines[sourceLineIndex + 1]

        // The caret should be under "42"
        guard let sourcePos = sourceLine.range(of: "42")?.lowerBound,
              let caretPos = underlineLine.range(of: "^")?.lowerBound else {
            Issue.record("Could not find '42' or '^' in output:\n\(output)")
            return
        }

        let sourceOffset = sourceLine.distance(from: sourceLine.startIndex, to: sourcePos)
        let caretOffset = underlineLine.distance(from: underlineLine.startIndex, to: caretPos)

        #expect(sourceOffset == caretOffset, "Caret position (\(caretOffset)) should match source position (\(sourceOffset))\nOutput:\n\(output)")
    }

    @Test("Caret aligns with double-digit line numbers")
    func caretAlignsDoubleDigitLine() {
        // Create source with enough lines to reach line 15
        var sourceLines = [String]()
        for i in 1...14 {
            sourceLines.append("// line \(i)")
        }
        sourceLines.append("var x: Int = 42")
        let source = sourceLines.joined(separator: "\n")

        // Calculate offset: sum of previous lines + newlines
        var offset = 0
        for i in 0..<14 {
            offset += sourceLines[i].count + 1  // +1 for newline
        }
        offset += 13  // Position of "42" within line 15

        let range = SourceRange(
            start: SourceLocation(line: 15, column: 14, offset: offset),
            end: SourceLocation(line: 15, column: 16, offset: offset + 2),
            file: "test.slang"
        )
        let diagnostic = Diagnostic.error("Test error", at: range)
        let printer = DiagnosticPrinter(source: source)

        let output = printer.format(diagnostic, useColors: false)
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        // Find the source line and underline line
        guard let sourceLineIndex = lines.firstIndex(where: { $0.contains("var x: Int") }),
              sourceLineIndex + 1 < lines.count else {
            Issue.record("Could not find source line in output: \(output)")
            return
        }

        let sourceLine = lines[sourceLineIndex]
        let underlineLine = lines[sourceLineIndex + 1]

        guard let sourcePos = sourceLine.range(of: "42")?.lowerBound,
              let caretPos = underlineLine.range(of: "^")?.lowerBound else {
            Issue.record("Could not find '42' or '^' in output:\n\(output)")
            return
        }

        let sourceOffset = sourceLine.distance(from: sourceLine.startIndex, to: sourcePos)
        let caretOffset = underlineLine.distance(from: underlineLine.startIndex, to: caretPos)

        #expect(sourceOffset == caretOffset, "Caret position (\(caretOffset)) should match source position (\(sourceOffset))\nOutput:\n\(output)")
    }

    @Test("Underline spans multiple characters")
    func underlineSpansMultipleChars() {
        let source = "var x: Int = hello"
        let range = SourceRange(
            start: SourceLocation(line: 1, column: 14, offset: 13),
            end: SourceLocation(line: 1, column: 19, offset: 18),
            file: "test.slang"
        )
        let diagnostic = Diagnostic.error("Test error", at: range)
        let printer = DiagnosticPrinter(source: source)

        let output = printer.format(diagnostic, useColors: false)

        // Verify underline is 5 characters (for "hello")
        #expect(output.contains("^^^^^"), "Underline should have 5 carets for 'hello'\nOutput:\n\(output)")
    }

    @Test("Caret aligns with indented code")
    func caretAlignsWithIndentedCode() {
        let source = "func main() {\n    var x: Int = 42\n}"
        // Error on "42" at line 2
        // Line 2 is: "    var x: Int = 42" (4 spaces + "var x: Int = " + "42")
        // "4" is at column 18 (1-indexed): 4 spaces + 13 chars ("var x: Int = ") + 1 = 18
        // Offset: 14 (line 1 + newline) + 17 = 31
        let range = SourceRange(
            start: SourceLocation(line: 2, column: 18, offset: 31),
            end: SourceLocation(line: 2, column: 20, offset: 33),
            file: "test.slang"
        )
        let diagnostic = Diagnostic.error("Test error", at: range)
        let printer = DiagnosticPrinter(source: source)

        let output = printer.format(diagnostic, useColors: false)
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        guard let sourceLineIndex = lines.firstIndex(where: { $0.contains("var x: Int") }),
              sourceLineIndex + 1 < lines.count else {
            Issue.record("Could not find source line in output: \(output)")
            return
        }

        let sourceLine = lines[sourceLineIndex]
        let underlineLine = lines[sourceLineIndex + 1]

        guard let sourcePos = sourceLine.range(of: "42")?.lowerBound,
              let caretPos = underlineLine.range(of: "^")?.lowerBound else {
            Issue.record("Could not find '42' or '^' in output:\n\(output)")
            return
        }

        let sourceOffset = sourceLine.distance(from: sourceLine.startIndex, to: sourcePos)
        let caretOffset = underlineLine.distance(from: underlineLine.startIndex, to: caretPos)

        #expect(sourceOffset == caretOffset, "Caret position (\(caretOffset)) should match source position (\(sourceOffset))\nOutput:\n\(output)")
    }
}
