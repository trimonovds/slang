// Sources/SlangCore/Interpreter/Environment.swift

/// Runtime environment for storing variables
public final class RuntimeEnvironment: @unchecked Sendable {
    private var values: [String: Value] = [:]
    private let parent: RuntimeEnvironment?

    public init(parent: RuntimeEnvironment? = nil) {
        self.parent = parent
    }

    /// Define a new variable in the current scope
    public func define(_ name: String, value: Value) {
        values[name] = value
    }

    /// Get a variable's value, searching up the scope chain
    public func get(_ name: String) -> Value? {
        if let value = values[name] {
            return value
        }
        return parent?.get(name)
    }

    /// Assign to an existing variable
    public func assign(_ name: String, value: Value) -> Bool {
        if values[name] != nil {
            values[name] = value
            return true
        }
        if let parent = parent {
            return parent.assign(name, value: value)
        }
        return false
    }

    /// Create a child environment for a new scope
    public func createChild() -> RuntimeEnvironment {
        RuntimeEnvironment(parent: self)
    }
}
