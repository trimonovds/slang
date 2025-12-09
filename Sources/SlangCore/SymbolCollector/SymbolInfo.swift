// Sources/SlangCore/SymbolCollector/SymbolInfo.swift

/// The kind of symbol (function, type, variable, etc.)
public enum SymbolKind: String, Sendable {
    case function
    case structType
    case enumType
    case unionType
    case field
    case enumCase
    case unionVariant
    case variable
    case parameter
}

/// Information about a symbol definition
public struct SymbolDefinition: Sendable {
    /// The name of the symbol
    public let name: String
    /// What kind of symbol this is
    public let kind: SymbolKind
    /// The source range where the symbol is defined (full declaration for navigation)
    public let range: SourceRange
    /// The source range of just the symbol name (for cursor matching)
    public let nameRange: SourceRange
    /// The type of the symbol (if applicable)
    public let type: SlangType?
    /// The containing symbol (e.g., struct name for fields)
    public let container: String?

    public init(
        name: String,
        kind: SymbolKind,
        range: SourceRange,
        nameRange: SourceRange? = nil,
        type: SlangType? = nil,
        container: String? = nil
    ) {
        self.name = name
        self.kind = kind
        self.range = range
        self.nameRange = nameRange ?? range
        self.type = type
        self.container = container
    }

    /// Full qualified name (e.g., "Point.x" for struct field)
    public var qualifiedName: String {
        if let container = container {
            return "\(container).\(name)"
        }
        return name
    }
}

/// A reference to a symbol (usage site)
public struct SymbolReference: Sendable {
    /// The range where the reference occurs
    public let range: SourceRange
    /// The definition this reference points to
    public let definition: SymbolDefinition

    public init(range: SourceRange, definition: SymbolDefinition) {
        self.range = range
        self.definition = definition
    }
}

/// Collected symbols from a source file
public struct FileSymbols: Sendable {
    /// The file path
    public let file: String
    /// All symbol definitions in this file
    public let definitions: [SymbolDefinition]
    /// All symbol references in this file
    public let references: [SymbolReference]

    public init(file: String, definitions: [SymbolDefinition], references: [SymbolReference]) {
        self.file = file
        self.definitions = definitions
        self.references = references
    }
}
