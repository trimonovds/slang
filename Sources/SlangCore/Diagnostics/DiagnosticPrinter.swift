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
        Swift.print(format(diagnostic))
    }

    /// Formats a diagnostic to a string (useful for testing)
    public func format(_ diagnostic: Diagnostic, useColors: Bool = true) -> String {
        var output: [String] = []

        let severityColor: String
        let severityText: String

        switch diagnostic.severity {
        case .error:
            severityColor = useColors ? "\u{001B}[31m" : ""  // Red
            severityText = "error"
        case .warning:
            severityColor = useColors ? "\u{001B}[33m" : ""  // Yellow
            severityText = "warning"
        case .note:
            severityColor = useColors ? "\u{001B}[34m" : ""  // Blue
            severityText = "note"
        }

        let reset = useColors ? "\u{001B}[0m" : ""
        let bold = useColors ? "\u{001B}[1m" : ""

        // Print the main message
        output.append("\(severityColor)\(bold)\(severityText):\(reset)\(bold) \(diagnostic.message)\(reset)")

        // Print the location
        output.append("  \(severityColor)-->\(reset) \(diagnostic.range.file):\(diagnostic.range.start.line):\(diagnostic.range.start.column)")

        // Print the source context
        output.append(contentsOf: formatSourceContext(diagnostic.range, color: severityColor, reset: reset))

        output.append("")  // Empty line after each diagnostic
        return output.joined(separator: "\n")
    }

    private func formatSourceContext(_ range: SourceRange, color: String, reset: String) -> [String] {
        var output: [String] = []
        let line = range.start.line
        let column = range.start.column

        guard line > 0 && line <= lines.count else { return output }

        let sourceLine = lines[line - 1]
        let lineNumStr = String(line)
        let padding = String(repeating: " ", count: lineNumStr.count)

        // Print the gutter
        output.append(" \(padding) \(color)|\(reset)")

        // Print the source line
        output.append(" \(color)\(lineNumStr)\(reset) \(color)|\(reset) \(sourceLine)")

        // Print the underline
        let spaces = String(repeating: " ", count: column - 1)
        let underline: String
        if range.start.line == range.end.line && range.end.column > range.start.column {
            underline = String(repeating: "^", count: range.end.column - range.start.column)
        } else {
            underline = "^"
        }
        output.append(" \(padding) \(color)|\(reset) \(spaces)\(color)\(underline)\(reset)")

        return output
    }
}
