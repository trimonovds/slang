// Sources/slang-lsp/LSPTypes.swift

import Foundation

// MARK: - JSON-RPC Types

struct JSONRPCRequest: Codable {
    let jsonrpc: String
    let id: RequestId?
    let method: String
    let params: AnyCodable?

    init(id: RequestId?, method: String, params: AnyCodable? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

struct JSONRPCResponse: Codable {
    let jsonrpc: String
    let id: RequestId?
    let result: AnyCodable?
    let error: JSONRPCError?

    init(id: RequestId?, result: AnyCodable? = nil, error: JSONRPCError? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = error
    }
}

struct JSONRPCError: Codable, @unchecked Sendable {
    let code: Int
    let message: String
    let data: AnyCodable?

    static let parseError = JSONRPCError(code: -32700, message: "Parse error", data: nil)
    static let invalidRequest = JSONRPCError(code: -32600, message: "Invalid Request", data: nil)
    static let methodNotFound = JSONRPCError(code: -32601, message: "Method not found", data: nil)
    static let invalidParams = JSONRPCError(code: -32602, message: "Invalid params", data: nil)
    static let internalError = JSONRPCError(code: -32603, message: "Internal error", data: nil)
}

enum RequestId: Codable, Equatable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(RequestId.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

// MARK: - LSP Types

struct InitializeParams: Codable {
    let processId: Int?
    let rootUri: String?
    let rootPath: String?
    let capabilities: ClientCapabilities?
}

struct ClientCapabilities: Codable {
    // Simplified - just need basics
}

struct InitializeResult: Codable {
    let capabilities: ServerCapabilities

    static var `default`: InitializeResult {
        InitializeResult(capabilities: ServerCapabilities(
            textDocumentSync: TextDocumentSyncOptions(
                openClose: true,
                change: 1,  // Full sync
                save: SaveOptions(includeText: true)
            ),
            definitionProvider: true,
            referencesProvider: true
        ))
    }
}

struct ServerCapabilities: Codable {
    let textDocumentSync: TextDocumentSyncOptions?
    let definitionProvider: Bool?
    let referencesProvider: Bool?
}

struct TextDocumentSyncOptions: Codable {
    let openClose: Bool?
    let change: Int?  // 0 = None, 1 = Full, 2 = Incremental
    let save: SaveOptions?
}

struct SaveOptions: Codable {
    let includeText: Bool?
}

struct TextDocumentIdentifier: Codable {
    let uri: String
}

struct VersionedTextDocumentIdentifier: Codable {
    let uri: String
    let version: Int?
}

struct TextDocumentItem: Codable {
    let uri: String
    let languageId: String
    let version: Int
    let text: String
}

struct DidOpenTextDocumentParams: Codable {
    let textDocument: TextDocumentItem
}

struct DidCloseTextDocumentParams: Codable {
    let textDocument: TextDocumentIdentifier
}

struct DidChangeTextDocumentParams: Codable {
    let textDocument: VersionedTextDocumentIdentifier
    let contentChanges: [TextDocumentContentChangeEvent]
}

struct TextDocumentContentChangeEvent: Codable {
    let text: String
}

struct DidSaveTextDocumentParams: Codable {
    let textDocument: TextDocumentIdentifier
    let text: String?
}

struct Position: Codable {
    let line: Int      // 0-indexed
    let character: Int // 0-indexed, UTF-16 code units
}

struct Range: Codable {
    let start: Position
    let end: Position
}

struct Location: Codable {
    let uri: String
    let range: Range
}

struct TextDocumentPositionParams: Codable {
    let textDocument: TextDocumentIdentifier
    let position: Position
}

struct ReferenceParams: Codable {
    let textDocument: TextDocumentIdentifier
    let position: Position
    let context: ReferenceContext
}

struct ReferenceContext: Codable {
    let includeDeclaration: Bool
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let number as NSNumber:
            // NSNumber can hold both Bool and numeric types
            // Check the type encoding to distinguish
            let objCType = String(cString: number.objCType)
            if objCType == "c" || objCType == "B" {
                // 'c' is char (used for BOOL on some platforms), 'B' is C++ bool
                try container.encode(number.boolValue)
            } else if objCType == "d" || objCType == "f" {
                // 'd' is double, 'f' is float
                try container.encode(number.doubleValue)
            } else {
                // Integer types: 'i', 'l', 'q', etc.
                try container.encode(number.intValue)
            }
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case let codable as Codable:
            try codable.encode(to: encoder)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}
