// Sources/SlangCore/Lexer/SourceLocation.swift

/// A position in source code
public struct SourceLocation: Equatable, CustomStringConvertible, Sendable {
    /// 1-indexed line number
    public let line: Int
    /// 1-indexed column number
    public let column: Int
    /// 0-indexed byte offset from start of file
    public let offset: Int

    public init(line: Int, column: Int, offset: Int) {
        self.line = line
        self.column = column
        self.offset = offset
    }

    public var description: String {
        "\(line):\(column)"
    }
}

/// A range in source code (start to end positions)
public struct SourceRange: Equatable, CustomStringConvertible, Sendable {
    public let start: SourceLocation
    public let end: SourceLocation
    public let file: String

    public init(start: SourceLocation, end: SourceLocation, file: String = "<stdin>") {
        self.start = start
        self.end = end
        self.file = file
    }

    public var description: String {
        "\(file):\(start)-\(end)"
    }

    /// Create a range spanning from this range's start to another range's end
    public func extended(to other: SourceRange) -> SourceRange {
        SourceRange(start: self.start, end: other.end, file: self.file)
    }
}
