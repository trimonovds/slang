# Phase 9: LSP & IDE Support

## Status: ✅ Complete

This phase adds IDE support for Slang via Language Server Protocol (LSP) and a VS Code extension.

Features implemented:
- **Syntax Highlighting** - TextMate grammar for colorization
- **Jump to Definition** - Navigate to symbol declarations
- **Find References** - Find all usages of a symbol
- **Diagnostics** - Show errors on file save

---

## Prerequisites

- Phase 1-6 complete (v0.1 core language)
- Phase 7 complete (unions support in LSP)

---

## Architecture

**TextMate Grammar + Language Server Protocol (LSP)**

- **Syntax Highlighting**: TextMate grammar (`.tmLanguage.json`) - declarative, fast, no runtime cost
- **Jump to Definition & Find References**: LSP server written in Swift, reusing existing SlangCore modules

**Why LSP?**
- Reuses existing Lexer, Parser, TypeChecker infrastructure
- Single implementation works across editors (VS Code, Neovim, etc.)
- Provides accurate semantic analysis (not just regex pattern matching)
- Can be extended later for hover info, completions, diagnostics

---

## Directory Structure

```
slang/
├── Sources/
│   ├── SlangCore/           # Existing - shared by CLI and LSP
│   │   └── SymbolCollector/ # NEW - for LSP
│   │       ├── SymbolInfo.swift
│   │       └── SymbolCollector.swift
│   ├── slang/               # Existing CLI
│   └── slang-lsp/           # NEW - Language Server
│       ├── main.swift
│       ├── LSPServer.swift
│       ├── LSPTypes.swift
│       ├── JSONRPCTransport.swift
│       ├── DocumentManager.swift
│       └── PositionConverter.swift
├── editors/
│   └── vscode/              # NEW - VS Code extension
│       ├── package.json
│       ├── language-configuration.json
│       ├── syntaxes/
│       │   └── slang.tmLanguage.json
│       ├── tsconfig.json
│       └── src/
│           └── extension.ts
└── Package.swift            # Update to add slang-lsp target
```

---

## Implementation Steps

### Step 9.1: TextMate Grammar

**File**: `editors/vscode/syntaxes/slang.tmLanguage.json`

| Scope | Patterns |
|-------|----------|
| `keyword.control` | `if`, `else`, `for`, `switch`, `return` |
| `keyword.declaration` | `func`, `var`, `struct`, `enum`, `union`, `case` |
| `constant.language` | `true`, `false` |
| `storage.type` | `Int`, `Float`, `String`, `Bool`, `Void` |
| `comment.line` | `// ...` |
| `string.quoted.double` | `"..."` with interpolation support `\(...)` |
| `constant.numeric` | Integer and float literals |
| `entity.name.function` | Function names after `func` |
| `entity.name.type` | Type names after `struct`, `enum`, `union` |
| `variable.parameter` | Function parameters |

### Step 9.2: Language Configuration

**File**: `editors/vscode/language-configuration.json`

- Bracket pairs: `{}`, `()`, `[]`
- Auto-closing pairs
- Comment toggling: `//`
- Indentation rules

### Step 9.3: Symbol Infrastructure

**File**: `Sources/SlangCore/SymbolCollector/SymbolInfo.swift`

```swift
struct SymbolInfo {
    let name: String
    let kind: SymbolKind  // function, struct, enum, union, variable, parameter, field
    let definitionRange: SourceRange
    let type: SlangType?
}

struct SymbolReference {
    let symbolName: String
    let range: SourceRange
    let definitionRange: SourceRange  // Link back to definition
}

enum SymbolKind {
    case function
    case `struct`
    case `enum`
    case union
    case field
    case enumCase
    case variable
    case parameter
}
```

**File**: `Sources/SlangCore/SymbolCollector/SymbolCollector.swift`

AST walker that collects symbol definitions and references.

### Step 9.4: LSP Server

**Add to `Package.swift`:**

```swift
.executableTarget(
    name: "slang-lsp",
    dependencies: ["SlangCore"]
)
```

**Core files:**

| File | Purpose |
|------|---------|
| `LSPTypes.swift` | LSP protocol message types |
| `JSONRPCTransport.swift` | stdin/stdout JSON-RPC communication |
| `DocumentManager.swift` | Track open documents and parsed state |
| `LSPServer.swift` | Main server with message handlers |
| `PositionConverter.swift` | VS Code ↔ Slang position conversion |
| `main.swift` | Server entry point |

**LSP Methods Implemented:**

- `initialize` / `initialized` / `shutdown` / `exit` - Lifecycle
- `textDocument/didOpen` / `didChange` / `didClose` - Document sync
- `textDocument/definition` - Jump to definition
- `textDocument/references` - Find all references
- `textDocument/publishDiagnostics` - Error reporting

### Step 9.5: Jump to Definition

**LSP Method:** `textDocument/definition`

**Cases handled:**
- Variable usage → variable declaration
- Function call → function declaration
- Type annotation → struct/enum/union declaration
- Member access (`x.field`) → struct field declaration
- Enum case access (`Direction.up`) → enum case declaration
- Union variant (`Pet.Dog`) → union variant / underlying type

### Step 9.6: Find References

**LSP Method:** `textDocument/references`

**Scope awareness:**
- Local variables only referenced within their scope
- Parameters only referenced within function body
- Types and functions referenced across all files

### Step 9.7: VS Code Extension

**File**: `editors/vscode/package.json`

```json
{
  "contributes": {
    "languages": [{
      "id": "slang",
      "extensions": [".slang"],
      "configuration": "./language-configuration.json"
    }],
    "grammars": [{
      "language": "slang",
      "scopeName": "source.slang",
      "path": "./syntaxes/slang.tmLanguage.json"
    }]
  }
}
```

**File**: `editors/vscode/src/extension.ts`

1. Find `slang-lsp` binary (from PATH or workspace build)
2. Start LSP server as child process
3. Connect VS Code's language client to server

---

## Position Mapping

VS Code uses 0-indexed lines and UTF-16 code unit columns.
Slang uses 1-indexed lines and byte offsets.

**File**: `Sources/slang-lsp/PositionConverter.swift`

```swift
func vscodeToSlang(line: Int, character: Int, in source: String) -> SourceLocation
func slangToVscode(_ location: SourceLocation, in source: String) -> (line: Int, character: Int)
```

---

## Running the Extension

```bash
# Build LSP server
swift build

# Install VS Code extension dependencies
cd editors/vscode
npm install
npm run compile

# Launch VS Code with extension
code --extensionDevelopmentPath=. ../..

# Or package for distribution
npm run package
```

---

## File-by-File Checklist

### VS Code Extension Scaffold
- [x] `editors/vscode/package.json` - Extension manifest
- [x] `editors/vscode/language-configuration.json` - Brackets, comments
- [x] `editors/vscode/syntaxes/slang.tmLanguage.json` - Syntax highlighting
- [x] `editors/vscode/tsconfig.json` - TypeScript config
- [x] `editors/vscode/src/extension.ts` - Extension entry point

### Symbol Infrastructure
- [x] `Sources/SlangCore/SymbolCollector/SymbolInfo.swift` - Symbol data structures
- [x] `Sources/SlangCore/SymbolCollector/SymbolCollector.swift` - AST walker

### LSP Server
- [x] Update `Package.swift` - Add slang-lsp target
- [x] `Sources/slang-lsp/LSPTypes.swift` - LSP protocol types
- [x] `Sources/slang-lsp/JSONRPCTransport.swift` - stdin/stdout communication
- [x] `Sources/slang-lsp/DocumentManager.swift` - Track open documents
- [x] `Sources/slang-lsp/LSPServer.swift` - Main server with handlers
- [x] `Sources/slang-lsp/PositionConverter.swift` - Position conversion
- [x] `Sources/slang-lsp/main.swift` - Server entry point

### Testing
- [x] Test syntax highlighting with example files
- [x] Test go-to-definition for all symbol types
- [x] Test find-references across files
- [x] Swift unit tests (200 tests in 15 suites)

---

## Acceptance Criteria

- [x] **Syntax Highlighting**: Keywords, strings, comments, types all colored distinctly
- [x] **Jump to Definition**: Works for functions, variables, types, fields, enum cases
- [x] **Find References**: Finds all usages of any defined symbol
- [x] **Performance**: <100ms response time for definition/references in typical files
- [x] **Diagnostics**: Type errors shown in Problems panel on save

---

## Future Enhancements (v0.2+)

When collection types are added, update:

### TextMate Grammar
- `nil` keyword → `constant.language.nil`
- `Set` type → `storage.type`
- `?` in type annotations → `keyword.operator.optional`

### LSP
- Symbol collection for collection type annotations
- Go-to-definition for built-in collection methods
- Hover information for collection types
