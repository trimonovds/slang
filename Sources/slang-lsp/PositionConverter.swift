// Sources/slang-lsp/PositionConverter.swift

import Foundation
import SlangCore

/// Converts between VS Code positions and Slang source locations
struct PositionConverter {
    let source: String

    /// Convert LSP position (0-indexed line, UTF-16 character) to Slang SourceLocation (1-indexed)
    func toSourceLocation(_ position: Position) -> SourceLocation {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        let line = position.line  // 0-indexed
        let character = position.character  // 0-indexed, UTF-16

        // Calculate byte offset
        var offset = 0
        for i in 0..<line {
            if i < lines.count {
                offset += lines[i].utf8.count + 1  // +1 for newline
            }
        }

        // Add character offset (converting from UTF-16 to bytes)
        if line < lines.count {
            let lineContent = String(lines[line])
            var utf16Count = 0
            var byteCount = 0

            for char in lineContent {
                if utf16Count >= character {
                    break
                }
                utf16Count += char.utf16.count
                byteCount += char.utf8.count
            }
            offset += byteCount
        }

        return SourceLocation(
            line: line + 1,  // Convert to 1-indexed
            column: character + 1,  // Convert to 1-indexed
            offset: offset
        )
    }

    /// Convert Slang SourceLocation (1-indexed) to LSP position (0-indexed)
    func toPosition(_ location: SourceLocation) -> Position {
        return Position(
            line: location.line - 1,  // Convert to 0-indexed
            character: location.column - 1  // Convert to 0-indexed
        )
    }

    /// Convert Slang SourceRange to LSP Range
    func toRange(_ sourceRange: SourceRange) -> Range {
        return Range(
            start: toPosition(sourceRange.start),
            end: toPosition(sourceRange.end)
        )
    }

    /// Find the token at a given position
    func findTokenAt(_ position: Position, in tokens: [Token]) -> Token? {
        let location = toSourceLocation(position)

        for token in tokens {
            if isLocationInRange(location, token.range) {
                return token
            }
        }
        return nil
    }

    /// Check if a location is within a range
    private func isLocationInRange(_ location: SourceLocation, _ range: SourceRange) -> Bool {
        // Check if location is after start
        if location.line < range.start.line {
            return false
        }
        if location.line == range.start.line && location.column < range.start.column {
            return false
        }

        // Check if location is before end
        if location.line > range.end.line {
            return false
        }
        if location.line == range.end.line && location.column > range.end.column {
            return false
        }

        return true
    }
}
