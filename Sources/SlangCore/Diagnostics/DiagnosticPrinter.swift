// Sources/SlangCore/Diagnostics/DiagnosticPrinter.swift

import Foundation

/// Pretty-prints diagnostic messages with source context and colors
public struct DiagnosticPrinter: Sendable {
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
