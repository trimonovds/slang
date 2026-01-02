// Sources/SlangCore/SymbolCollector/SymbolCollector.swift

/// Walks an AST to collect symbol definitions and references
public class SymbolCollector {
    private var definitions: [SymbolDefinition] = []
    private var references: [SymbolReference] = []
    private var scope: Scope

    /// A scope containing symbol definitions
    private class Scope {
        var symbols: [String: SymbolDefinition] = [:]
        var parent: Scope?

        init(parent: Scope? = nil) {
            self.parent = parent
        }

        func lookup(_ name: String) -> SymbolDefinition? {
            if let def = symbols[name] {
                return def
            }
            return parent?.lookup(name)
        }

        func define(_ def: SymbolDefinition) {
            symbols[def.name] = def
        }
    }

    public init() {
        self.scope = Scope()
    }

    /// Collect symbols from a list of declarations
    public func collect(declarations: [Declaration], file: String) -> FileSymbols {
        definitions = []
        references = []
        scope = Scope()

        // First pass: register all top-level declarations
        for decl in declarations {
            registerDeclaration(decl)
        }

        // Second pass: process bodies to find references
        for decl in declarations {
            processDeclaration(decl)
        }

        return FileSymbols(file: file, definitions: definitions, references: references)
    }

    // MARK: - First Pass: Register Definitions

    /// Create a name range for a keyword-prefixed declaration (e.g., "func name", "struct name")
    /// keywordLength is the length of the keyword + 1 for the space (e.g., "func " = 5)
    private func makeNameRange(declRange: SourceRange, keywordLength: Int, nameLength: Int) -> SourceRange {
        let nameStart = SourceLocation(
            line: declRange.start.line,
            column: declRange.start.column + keywordLength,
            offset: declRange.start.offset + keywordLength
        )
        let nameEnd = SourceLocation(
            line: declRange.start.line,
            column: declRange.start.column + keywordLength + nameLength,
            offset: declRange.start.offset + keywordLength + nameLength
        )
        return SourceRange(start: nameStart, end: nameEnd, file: declRange.file)
    }

    private func registerDeclaration(_ decl: Declaration) {
        switch decl.kind {
        case .function(let name, let parameters, let returnType, _):
            let paramTypes = parameters.map { resolveType($0.type) }
            let retType = returnType.map { resolveType($0) } ?? .void
            let funcType = SlangType.function(params: paramTypes, returnType: retType)

            // "func " = keyword + space
            let keywordLength = Keyword.func.rawValue.count + 1
            let nameRange = makeNameRange(declRange: decl.range, keywordLength: keywordLength, nameLength: name.count)

            let def = SymbolDefinition(
                name: name,
                kind: .function,
                range: decl.range,
                nameRange: nameRange,
                type: funcType
            )
            definitions.append(def)
            scope.define(def)

        case .structDecl(let name, let fields):
            // "struct " = keyword + space
            let keywordLength = Keyword.struct.rawValue.count + 1
            let nameRange = makeNameRange(declRange: decl.range, keywordLength: keywordLength, nameLength: name.count)

            let def = SymbolDefinition(
                name: name,
                kind: .structType,
                range: decl.range,
                nameRange: nameRange,
                type: .structType(name: name)
            )
            definitions.append(def)
            scope.define(def)

            // Register fields (fields already have precise ranges)
            for field in fields {
                let fieldDef = SymbolDefinition(
                    name: field.name,
                    kind: .field,
                    range: field.range,
                    type: resolveType(field.type),
                    container: name
                )
                definitions.append(fieldDef)
            }

        case .enumDecl(let name, let cases):
            // "enum " = keyword + space
            let keywordLength = Keyword.enum.rawValue.count + 1
            let nameRange = makeNameRange(declRange: decl.range, keywordLength: keywordLength, nameLength: name.count)

            let def = SymbolDefinition(
                name: name,
                kind: .enumType,
                range: decl.range,
                nameRange: nameRange,
                type: .enumType(name: name)
            )
            definitions.append(def)
            scope.define(def)

            // Register enum cases (cases already have precise ranges from "case name")
            for enumCase in cases {
                let caseDef = SymbolDefinition(
                    name: enumCase.name,
                    kind: .enumCase,
                    range: enumCase.range,
                    type: .enumType(name: name),
                    container: name
                )
                definitions.append(caseDef)
            }

        case .unionDecl(let name, let variants):
            // "union " = keyword + space
            let keywordLength = Keyword.union.rawValue.count + 1
            let nameRange = makeNameRange(declRange: decl.range, keywordLength: keywordLength, nameLength: name.count)

            let def = SymbolDefinition(
                name: name,
                kind: .unionType,
                range: decl.range,
                nameRange: nameRange,
                type: .unionType(name: name)
            )
            definitions.append(def)
            scope.define(def)

            // Register union variants
            for variant in variants {
                let variantDef = SymbolDefinition(
                    name: variant.typeName,
                    kind: .unionVariant,
                    range: variant.range,
                    type: resolveType(TypeAnnotation(name: variant.typeName, range: variant.range)),
                    container: name
                )
                definitions.append(variantDef)
            }
        }
    }

    // MARK: - Second Pass: Process Bodies for References

    private func processDeclaration(_ decl: Declaration) {
        switch decl.kind {
        case .function(_, let parameters, let returnType, let body):
            // Create child scope for function body
            let funcScope = Scope(parent: scope)
            let outerScope = scope
            scope = funcScope

            // Register parameters
            for param in parameters {
                let def = SymbolDefinition(
                    name: param.name,
                    kind: .parameter,
                    range: param.range,
                    type: resolveType(param.type)
                )
                definitions.append(def)
                scope.define(def)

                // Type annotation is a reference
                addTypeReference(param.type)
            }

            // Return type annotation is a reference
            if let retType = returnType {
                addTypeReference(retType)
            }

            processStatement(body)
            scope = outerScope

        case .structDecl(_, let fields):
            for field in fields {
                addTypeReference(field.type)
            }

        case .enumDecl:
            // Enum cases don't have type annotations to reference
            break

        case .unionDecl(_, let variants):
            for variant in variants {
                // Each variant type name is a reference
                let typeAnnotation = TypeAnnotation(name: variant.typeName, range: variant.range)
                addTypeReference(typeAnnotation)
            }
        }
    }

    private func processStatement(_ stmt: Statement) {
        switch stmt.kind {
        case .block(let statements):
            let blockScope = Scope(parent: scope)
            let outerScope = scope
            scope = blockScope
            for s in statements {
                processStatement(s)
            }
            scope = outerScope

        case .varDecl(let name, let type, let initializer):
            addTypeReference(type)
            processExpression(initializer)

            // "var " = keyword + space
            let keywordLength = Keyword.var.rawValue.count + 1
            let nameRange = makeNameRange(declRange: stmt.range, keywordLength: keywordLength, nameLength: name.count)

            let def = SymbolDefinition(
                name: name,
                kind: .variable,
                range: stmt.range,
                nameRange: nameRange,
                type: resolveType(type)
            )
            definitions.append(def)
            scope.define(def)

        case .expression(let expr):
            processExpression(expr)

        case .returnStmt(let value):
            if let value = value {
                processExpression(value)
            }

        case .ifStmt(let condition, let thenBranch, let elseBranch):
            processExpression(condition)
            processStatement(thenBranch)
            if let elseBranch = elseBranch {
                processStatement(elseBranch)
            }

        case .forStmt(let initializer, let condition, let increment, let body):
            let forScope = Scope(parent: scope)
            let outerScope = scope
            scope = forScope

            if let init_ = initializer {
                processStatement(init_)
            }
            if let cond = condition {
                processExpression(cond)
            }
            if let inc = increment {
                processExpression(inc)
            }
            processStatement(body)
            scope = outerScope

        case .switchStmt(let subject, let cases):
            processExpression(subject)
            for switchCase in cases {
                processExpression(switchCase.pattern)
                processStatement(switchCase.body)
            }
        }
    }

    private func processExpression(_ expr: Expression) {
        switch expr.kind {
        case .intLiteral, .floatLiteral, .stringLiteral, .boolLiteral, .nilLiteral:
            break

        case .stringInterpolation(let parts):
            for part in parts {
                if case .interpolation(let innerExpr) = part {
                    processExpression(innerExpr)
                }
            }

        case .identifier(let name):
            // Look up the identifier and add a reference
            if let def = scope.lookup(name) {
                references.append(SymbolReference(range: expr.range, definition: def))
            }

        case .binary(let left, _, let right):
            processExpression(left)
            processExpression(right)

        case .unary(_, let operand):
            processExpression(operand)

        case .call(let callee, let arguments):
            processExpression(callee)
            for arg in arguments {
                processExpression(arg)
            }

        case .memberAccess(let object, let member):
            processExpression(object)

            // Try to resolve member access for enum cases and struct fields
            if case .identifier(let identifierName) = object.kind {
                if let identifierDef = scope.lookup(identifierName) {
                    // Calculate member range (after "identifier.")
                    let memberStart = SourceLocation(
                        line: expr.range.start.line,
                        column: expr.range.start.column + identifierName.count + 1,
                        offset: expr.range.start.offset + identifierName.count + 1
                    )
                    let memberEnd = SourceLocation(
                        line: expr.range.end.line,
                        column: expr.range.end.column,
                        offset: expr.range.end.offset
                    )
                    let memberRange = SourceRange(start: memberStart, end: memberEnd, file: expr.range.file)

                    // Case 1: Type.member (enum case, union variant)
                    // identifier is a type (enum, union, struct type name)
                    if identifierDef.kind == .enumType || identifierDef.kind == .unionType || identifierDef.kind == .structType {
                        for def in definitions {
                            if def.container == identifierName && def.name == member {
                                references.append(SymbolReference(range: memberRange, definition: def))
                                break
                            }
                        }
                    }
                    // Case 2: variable.field (struct field access)
                    // identifier is a variable with a struct type
                    else if identifierDef.kind == .variable || identifierDef.kind == .parameter {
                        if let varType = identifierDef.type, case .structType(let structName) = varType {
                            for def in definitions {
                                if def.container == structName && def.name == member && def.kind == .field {
                                    references.append(SymbolReference(range: memberRange, definition: def))
                                    break
                                }
                            }
                        }
                        // Handle union types with type narrowing - check for struct fields
                        else if let varType = identifierDef.type, case .unionType(let unionName) = varType {
                            // For unions, we need to check all possible variant types for the field
                            for def in definitions {
                                if def.kind == .unionVariant && def.container == unionName {
                                    // Look for fields in the variant's underlying type
                                    if let variantType = def.type, case .structType(let structName) = variantType {
                                        for fieldDef in definitions {
                                            if fieldDef.container == structName && fieldDef.name == member && fieldDef.kind == .field {
                                                references.append(SymbolReference(range: memberRange, definition: fieldDef))
                                                return  // Found a match
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        case .structInit(let typeName, let fields):
            // Type name is a reference
            if let def = scope.lookup(typeName) {
                references.append(SymbolReference(
                    range: expr.range,  // Use expression range for now
                    definition: def
                ))
            }
            for field in fields {
                processExpression(field.value)
            }

        case .switchExpr(let subject, let cases):
            processExpression(subject)
            for switchCase in cases {
                processExpression(switchCase.pattern)
                processStatement(switchCase.body)
            }

        case .subscriptAccess(let object, let index):
            processExpression(object)
            processExpression(index)

        case .arrayLiteral(let elements):
            for element in elements {
                processExpression(element)
            }

        case .dictionaryLiteral(let pairs):
            for pair in pairs {
                processExpression(pair.key)
                processExpression(pair.value)
            }
        }
    }

    // MARK: - Helpers

    private func addTypeReference(_ type: TypeAnnotation) {
        switch type.kind {
        case .simple(let name):
            // Check if it's a user-defined type (not a builtin)
            if type.asBuiltin == nil {
                if let def = scope.lookup(name) {
                    references.append(SymbolReference(range: type.range, definition: def))
                }
            }
        case .optional(let wrapped):
            addTypeReference(wrapped)
        case .array(let element):
            addTypeReference(element)
        case .dictionary(let key, let value):
            addTypeReference(key)
            addTypeReference(value)
        case .set(let element):
            addTypeReference(element)
        }
    }

    private func resolveType(_ type: TypeAnnotation) -> SlangType {
        switch type.kind {
        case .simple(let name):
            if let builtin = type.asBuiltin {
                return SlangType.from(builtin: builtin)
            }
            // For user-defined types, we check what kind it is
            if let def = scope.lookup(name) {
                switch def.kind {
                case .structType:
                    return .structType(name: name)
                case .enumType:
                    return .enumType(name: name)
                case .unionType:
                    return .unionType(name: name)
                default:
                    return .error
                }
            }
            return .error
        case .optional(let wrapped):
            return .optionalType(wrappedType: resolveType(wrapped))
        case .array(let element):
            return .arrayType(elementType: resolveType(element))
        case .dictionary(let key, let value):
            return .dictionaryType(keyType: resolveType(key), valueType: resolveType(value))
        case .set(let element):
            return .setType(elementType: resolveType(element))
        }
    }
}
