// Sources/SlangCore/Diagnostics/Diagnostic.swift

/// Severity level of a diagnostic message
public enum DiagnosticSeverity: Sendable {
    case error
    case warning
    case note
}

/// A diagnostic message (error, warning, or note)
public struct Diagnostic: Error, CustomStringConvertible, Sendable {
    public let severity: DiagnosticSeverity
    public let message: String
    public let range: SourceRange

    public init(severity: DiagnosticSeverity, message: String, range: SourceRange) {
        self.severity = severity
        self.message = message
        self.range = range
    }

    public static func error(_ message: String, at range: SourceRange) -> Diagnostic {
        Diagnostic(severity: .error, message: message, range: range)
    }

    public var description: String {
        let severityStr: String
        switch severity {
        case .error: severityStr = "error"
        case .warning: severityStr = "warning"
        case .note: severityStr = "note"
        }
        return "\(severityStr): \(message)\n  --> \(range.file):\(range.start)"
    }
}

/// Error thrown when lexing fails
public struct LexerError: Error {
    public let diagnostics: [Diagnostic]

    public init(_ diagnostics: [Diagnostic]) {
        self.diagnostics = diagnostics
    }

    public init(_ diagnostic: Diagnostic) {
        self.diagnostics = [diagnostic]
    }
}
