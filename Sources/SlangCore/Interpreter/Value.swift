// Sources/SlangCore/Interpreter/Value.swift

/// Runtime values in Slang
public indirect enum Value: Equatable, CustomStringConvertible, Sendable {
    case int(Int)
    case float(Double)
    case string(String)
    case bool(Bool)
    case void
    case structInstance(typeName: String, fields: [String: Value])
    case enumCase(typeName: String, caseName: String)

    public var description: String {
        switch self {
        case .int(let n): return String(n)
        case .float(let f): return String(f)
        case .string(let s): return s
        case .bool(let b): return b ? "true" : "false"
        case .void: return "()"
        case .structInstance(let name, let fields):
            let fieldStrs = fields.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")
            return "\(name) { \(fieldStrs) }"
        case .enumCase(let typeName, let caseName):
            return "\(typeName).\(caseName)"
        }
    }

    /// Convert value to string for printing/interpolation
    public func stringify() -> String {
        description
    }
}
