// Sources/SlangCore/TypeChecker/Type.swift

/// Represents a type in the Slang type system
public indirect enum SlangType: Equatable, CustomStringConvertible, Sendable {
    // Built-in types
    case int
    case float
    case string
    case bool
    case void

    // User-defined types
    case structType(name: String)
    case enumType(name: String)

    // Function type (for type checking calls)
    case function(params: [SlangType], returnType: SlangType)

    // Error type - used when type checking fails to prevent cascading errors
    case error

    public var description: String {
        switch self {
        case .int: return "Int"
        case .float: return "Float"
        case .string: return "String"
        case .bool: return "Bool"
        case .void: return "Void"
        case .structType(let name): return name
        case .enumType(let name): return name
        case .function(let params, let ret):
            let paramStr = params.map { $0.description }.joined(separator: ", ")
            return "(\(paramStr)) -> \(ret)"
        case .error: return "<error>"
        }
    }

    /// Check if this type is numeric (Int or Float)
    public var isNumeric: Bool {
        self == .int || self == .float
    }

    /// Convert from BuiltinTypeName to SlangType
    public static func from(builtin: BuiltinTypeName) -> SlangType {
        switch builtin {
        case .int: return .int
        case .float: return .float
        case .string: return .string
        case .bool: return .bool
        case .void: return .void
        }
    }
}

/// Information about a struct type
public struct StructTypeInfo: Sendable {
    public let name: String
    public let fields: [String: SlangType]  // field name -> type
    public let fieldOrder: [String]  // preserve order for initialization

    public init(name: String, fields: [String: SlangType], fieldOrder: [String]) {
        self.name = name
        self.fields = fields
        self.fieldOrder = fieldOrder
    }
}

/// Information about an enum type
public struct EnumTypeInfo: Sendable {
    public let name: String
    public let cases: Set<String>

    public init(name: String, cases: Set<String>) {
        self.name = name
        self.cases = cases
    }
}
