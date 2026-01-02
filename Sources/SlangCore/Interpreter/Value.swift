// Sources/SlangCore/Interpreter/Value.swift

/// Runtime values in Slang
public indirect enum Value: CustomStringConvertible, Sendable {
    case int(Int)
    case float(Double)
    case string(String)
    case bool(Bool)
    case void
    case structInstance(typeName: String, fields: [String: Value])
    case enumCase(typeName: String, caseName: String)
    case unionInstance(unionType: String, variantName: String, value: Value)
    // Optional
    case some(Value)
    case none
    // Collections
    case arrayInstance(elements: [Value])
    case dictionaryInstance(pairs: [(key: Value, value: Value)])
    case setInstance(elements: [Value])

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
        case .unionInstance(let unionType, let variantName, let value):
            return "\(unionType).\(variantName)(\(value))"
        case .some(let value):
            return "some(\(value))"
        case .none:
            return "nil"
        case .arrayInstance(let elements):
            let elemStrs = elements.map { $0.description }.joined(separator: ", ")
            return "[\(elemStrs)]"
        case .dictionaryInstance(let pairs):
            let pairStrs = pairs.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return "[\(pairStrs)]"
        case .setInstance(let elements):
            let elemStrs = elements.map { $0.description }.joined(separator: ", ")
            return "Set([\(elemStrs)])"
        }
    }

    /// Convert value to string for printing/interpolation
    public func stringify() -> String {
        description
    }

    /// Check equality of two values (used for dictionary/set key lookups)
    public static func valuesEqual(_ lhs: Value, _ rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (.int(let l), .int(let r)): return l == r
        case (.float(let l), .float(let r)): return l == r
        case (.string(let l), .string(let r)): return l == r
        case (.bool(let l), .bool(let r)): return l == r
        case (.void, .void): return true
        case (.enumCase(let t1, let c1), .enumCase(let t2, let c2)):
            return t1 == t2 && c1 == c2
        case (.structInstance(let t1, let f1), .structInstance(let t2, let f2)):
            guard t1 == t2, f1.count == f2.count else { return false }
            for (key, val) in f1 {
                guard let other = f2[key], valuesEqual(val, other) else { return false }
            }
            return true
        case (.unionInstance(let t1, let v1, let val1), .unionInstance(let t2, let v2, let val2)):
            return t1 == t2 && v1 == v2 && valuesEqual(val1, val2)
        case (.some(let l), .some(let r)):
            return valuesEqual(l, r)
        case (.none, .none):
            return true
        case (.arrayInstance(let l), .arrayInstance(let r)):
            guard l.count == r.count else { return false }
            for (lv, rv) in zip(l, r) {
                if !valuesEqual(lv, rv) { return false }
            }
            return true
        case (.dictionaryInstance(let l), .dictionaryInstance(let r)):
            guard l.count == r.count else { return false }
            for lPair in l {
                guard let rPair = r.first(where: { valuesEqual($0.key, lPair.key) }) else { return false }
                if !valuesEqual(lPair.value, rPair.value) { return false }
            }
            return true
        case (.setInstance(let l), .setInstance(let r)):
            guard l.count == r.count else { return false }
            for lv in l {
                if !r.contains(where: { valuesEqual($0, lv) }) { return false }
            }
            return true
        default:
            return false
        }
    }
}

extension Value: Equatable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        valuesEqual(lhs, rhs)
    }
}
