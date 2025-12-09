# VS Code Extension for Slang Language

## Overview

This plan outlines the implementation of a VS Code extension for the Slang programming language with:
1. **Syntax Highlighting** - TextMate grammar for colorization
2. **Jump to Definition** - Navigate to symbol declarations
3. **Find References** - Find all usages of a symbol

## Architecture Decision

**Recommended Approach: TextMate Grammar + Language Server Protocol (LSP)**

- **Syntax Highlighting**: TextMate grammar (`.tmLanguage.json`) - declarative, fast, no runtime cost
- **Jump to Definition & Find References**: LSP server written in Swift, reusing existing SlangCore modules

**Why LSP?**
- Reuses existing Lexer, Parser, TypeChecker infrastructure
- Single implementation works across editors (VS Code, Neovim, etc.)
- Provides accurate semantic analysis (not just regex pattern matching)
- Can be extended later for hover info, completions, diagnostics

## Directory Structure

```
slang/
├── Sources/
│   ├── SlangCore/           # Existing - shared by CLI and LSP
│   ├── slang/               # Existing CLI
│   └── slang-lsp/           # NEW - Language Server
│       └── main.swift
├── editors/
│   └── vscode/              # NEW - VS Code extension
│       ├── package.json
│       ├── syntaxes/
│       │   └── slang.tmLanguage.json
│       ├── language-configuration.json
│       └── src/
│           └── extension.ts
└── Package.swift            # Update to add slang-lsp target
```

## Implementation Steps

### Phase 1: Syntax Highlighting (TextMate Grammar)

Create `editors/vscode/syntaxes/slang.tmLanguage.json` with patterns for:

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

Language configuration (`language-configuration.json`):
- Bracket pairs: `{}`, `()`, `[]`
- Auto-closing pairs
- Comment toggling: `//`
- Indentation rules

### Phase 2: LSP Server Foundation

**Add to `Package.swift`:**
```swift
.executableTarget(
    name: "slang-lsp",
    dependencies: ["SlangCore"]
)
```

**LSP Server (`Sources/slang-lsp/`):**

The LSP server will:
1. Communicate via JSON-RPC over stdin/stdout
2. Handle LSP lifecycle: `initialize`, `initialized`, `shutdown`, `exit`
3. Track open documents with `textDocument/didOpen`, `didChange`, `didClose`
4. Implement `textDocument/definition` and `textDocument/references`

**Core Components:**

1. **Document Manager** - Tracks open files and their parsed state
2. **Symbol Index** - Maps symbol names to definition locations and references
3. **LSP Handler** - Routes JSON-RPC messages to appropriate handlers

### Phase 3: Symbol Indexing

**New module in SlangCore: `SymbolCollector.swift`**

Walk the AST to collect:
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
```

**Symbol Kinds:**
- `function` - Function declarations
- `struct` - Struct declarations
- `enum` - Enum declarations
- `union` - Union declarations
- `field` - Struct fields
- `enumCase` - Enum cases
- `variable` - Variable declarations
- `parameter` - Function parameters

### Phase 4: Jump to Definition

**LSP Method:** `textDocument/definition`

**Implementation:**
1. Receive position (file, line, column)
2. Find token at position using Lexer
3. If identifier, look up in symbol index
4. Return definition location

**Cases to handle:**
- Variable usage → variable declaration
- Function call → function declaration
- Type annotation → struct/enum/union declaration
- Member access (`x.field`) → struct field declaration
- Enum case access (`Direction.up`) → enum case declaration
- Union variant (`Pet.Dog`) → union variant / underlying type

### Phase 5: Find References

**LSP Method:** `textDocument/references`

**Implementation:**
1. Find symbol at cursor position
2. Determine what it defines (function, variable, type, etc.)
3. Search all indexed files for references to that symbol
4. Return list of locations

**Scope awareness:**
- Local variables only referenced within their scope
- Parameters only referenced within function body
- Types and functions referenced across all files

### Phase 6: VS Code Extension Integration

**`package.json` contributions:**
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

**Extension activation (`src/extension.ts`):**
1. Find or download `slang-lsp` binary
2. Start LSP server as child process
3. Connect VS Code's language client to server

## File-by-File Implementation Order

### Step 1: VS Code Extension Scaffold
- [x] `editors/vscode/package.json` - Extension manifest
- [x] `editors/vscode/language-configuration.json` - Brackets, comments
- [x] `editors/vscode/syntaxes/slang.tmLanguage.json` - Syntax highlighting
- [x] `editors/vscode/tsconfig.json` - TypeScript config
- [x] `editors/vscode/src/extension.ts` - Extension entry point

### Step 2: Symbol Infrastructure
- [x] `Sources/SlangCore/SymbolCollector/SymbolInfo.swift` - Symbol data structures
- [x] `Sources/SlangCore/SymbolCollector/SymbolCollector.swift` - AST walker for symbols

### Step 3: LSP Server
- [x] Update `Package.swift` - Add slang-lsp target
- [x] `Sources/slang-lsp/LSPTypes.swift` - LSP protocol types
- [x] `Sources/slang-lsp/JSONRPCTransport.swift` - stdin/stdout communication
- [x] `Sources/slang-lsp/DocumentManager.swift` - Track open documents
- [x] `Sources/slang-lsp/LSPServer.swift` - Main server with handlers
- [x] `Sources/slang-lsp/PositionConverter.swift` - VS Code ↔ Slang position conversion
- [x] `Sources/slang-lsp/main.swift` - Server entry point

### Step 4: Testing
- [x] Test syntax highlighting with example files
- [x] Test go-to-definition for all symbol types
- [x] Test find-references across files
- [x] Swift unit tests (200 tests in 15 suites)

## Technical Notes

### Reusing Existing Infrastructure

The existing codebase provides:
- **Lexer** - Token stream with precise source locations
- **Parser** - Full AST with SourceRange on every node
- **TypeChecker** - Type resolution and scope management

For LSP, we need to:
1. Add symbol collection during parsing/type-checking
2. Build an index mapping positions → symbols
3. Wrap in JSON-RPC transport layer

### Position Mapping

VS Code uses 0-indexed lines and UTF-16 code unit columns.
Slang uses 1-indexed lines and byte offsets.

Need conversion utilities:
```swift
func vscodeToSlang(line: Int, character: Int, in source: String) -> SourceLocation
func slangToVscode(_ location: SourceLocation, in source: String) -> (line: Int, character: Int)
```

### Incremental Updates

For large files, full re-parsing on every keystroke is slow. Options:
1. **Simple approach** (Phase 1): Re-parse entire file on save only
2. **Better** (Future): Debounced re-parsing on change with 200ms delay
3. **Best** (Future): Incremental parsing with tree-sitter

## Dependencies

**VS Code Extension:**
- `vscode-languageclient` - LSP client library

**LSP Server:**
- SlangCore (existing)
- Foundation (JSON encoding/decoding)

## Success Criteria

1. **Syntax Highlighting**: Keywords, strings, comments, types all colored distinctly
2. **Jump to Definition**: Works for functions, variables, types, fields, enum cases
3. **Find References**: Finds all usages of any defined symbol
4. **Performance**: <100ms response time for definition/references in typical files
