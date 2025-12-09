# Slang VS Code Extension

Language support for the Slang programming language, including syntax highlighting, jump to definition, and find references.

## Features

- **Syntax Highlighting**: Keywords, types, strings, numbers, comments, and string interpolation
- **Jump to Definition**: Navigate to symbol definitions (Cmd+Click / Ctrl+Click)
- **Find All References**: Find all usages of a symbol (Shift+Cmd+F12 / Shift+F12)

## Building

### Prerequisites

- Swift 6.0+
- Node.js 18+
- npm

### Build the LSP Server

From the repository root:

```bash
# Debug build
swift build

# Release build (recommended)
swift build -c release
```

The LSP binary will be at:
- Debug: `.build/debug/slang-lsp`
- Release: `.build/release/slang-lsp`

### Build the VS Code Extension

```bash
cd editors/vscode
npm install
npm run compile
```

## Installation

### Option 1: Development Mode (Recommended for Testing)

1. Open VS Code
2. Open the `editors/vscode` folder
3. Press `F5` to launch a new Extension Development Host window
4. Open any `.slang` file to test

### Option 2: Install Locally

1. Build the extension:
   ```bash
   cd editors/vscode
   npm install
   npm run compile
   ```

2. Create a symlink to your VS Code extensions folder:
   ```bash
   # macOS/Linux
   ln -s "$(pwd)" ~/.vscode/extensions/slang

   # Or copy the folder
   cp -r . ~/.vscode/extensions/slang
   ```

3. Restart VS Code

### Option 3: Package as VSIX

```bash
cd editors/vscode
npm install -g @vscode/vsce
vsce package
```

Then install the generated `.vsix` file via VS Code: Extensions → "..." menu → "Install from VSIX..."

## Configuration

Open VS Code settings (Cmd+, / Ctrl+,) and configure:

```json
{
  "slang.lspPath": "/absolute/path/to/slang/.build/release/slang-lsp"
}
```

If `slang.lspPath` is not set, the extension looks for `slang-lsp` in your PATH.

## Testing the Extension

### Quick Test

1. Create a test file `test.slang`:

```slang
struct Point {
    x: Int
    y: Int
}

func distance(p: Point) -> Int {
    return p.x + p.y
}

func main() {
    var pt: Point = Point { x: 3, y: 4 }
    var d: Int = distance(pt)
    print("Distance: \(d)")
}
```

2. Open in VS Code with the extension installed
3. Verify syntax highlighting is working
4. Cmd+Click on `Point` in `var pt: Point` to jump to the struct definition
5. Right-click on `distance` and select "Find All References"

### Test Files

The repository includes example Slang programs in `Tests/Examples/`:

- `hello.slang` - Basic hello world
- `structs.slang` - Struct definitions and usage
- `enums.slang` - Enum types and switch statements
- `unions.slang` - Union types with type narrowing
- `full.slang` - Comprehensive language demo

### LSP Server Logs

The LSP server writes logs to `/tmp/slang-lsp.log`. Check this file for debugging:

```bash
tail -f /tmp/slang-lsp.log
```

## Troubleshooting

### Extension not activating

- Ensure the file has `.slang` extension
- Check VS Code Output panel (View → Output) and select "Slang Language Server"

### LSP features not working

1. Verify `slang-lsp` is built:
   ```bash
   swift build -c release
   .build/release/slang-lsp --help  # Should show nothing (LSP reads stdin)
   ```

2. Check the LSP path in settings points to the correct binary

3. Check `/tmp/slang-lsp.log` for errors

### Syntax highlighting only (no LSP)

If only syntax highlighting works but not jump-to-definition:
- The LSP server may not be starting
- Check that the path to `slang-lsp` is correct
- Ensure the binary has execute permissions

## Development

### Extension Structure

```
editors/vscode/
├── package.json              # Extension manifest
├── language-configuration.json  # Brackets, comments, indentation
├── syntaxes/
│   └── slang.tmLanguage.json # TextMate grammar for highlighting
├── src/
│   └── extension.ts          # Extension entry point
└── out/                      # Compiled JavaScript (generated)
```

### LSP Server Structure

```
Sources/slang-lsp/
├── main.swift               # Entry point
├── LSPServer.swift          # Request handler routing
├── LSPTypes.swift           # LSP protocol types
├── JSONRPCTransport.swift   # stdin/stdout communication
├── DocumentManager.swift    # Open document tracking
└── PositionConverter.swift  # VS Code ↔ Slang position conversion
```

### Making Changes

1. Modify TypeScript: Run `npm run watch` for auto-compilation
2. Modify LSP server: Run `swift build` after changes
3. Press `Cmd+Shift+F5` in the Extension Development Host to reload

## Running Tests

### Swift Tests (LSP Server & Symbol Collector)

From the repository root:

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter SymbolCollectorTests
swift test --filter LSPTests
```

**Test Suites:**

| Suite | Description | Count |
|-------|-------------|-------|
| `SymbolCollector Tests` | Symbol collection from AST | 25 tests |
| `LSP Position Converter Tests` | Position/range conversions | 6 tests |
| `LSP URI Conversion Tests` | File URI handling | 4 tests |
| `LSP Definition Lookup Tests` | Go-to-definition logic | 4 tests |
| `LSP References Lookup Tests` | Find-all-references logic | 4 tests |
| `LSP Location in Range Tests` | Range containment checks | 8 tests |

### VS Code Extension Tests

```bash
cd editors/vscode
npm install
npm test
```

This launches VS Code in a test environment and runs:
- Language registration tests
- Syntax highlighting tests
- Language configuration tests
- Document parsing tests

**Note:** VS Code extension tests require a display. On CI, use `xvfb-run npm test`.

### Test Coverage

The test suite covers:

**Symbol Collection:**
- Function definitions and parameters
- Struct definitions and fields
- Enum definitions and cases
- Union definitions and variants
- Variable declarations (including for loops)
- Symbol references and scoping

**LSP Protocol:**
- Position conversion (LSP 0-indexed ↔ Slang 1-indexed)
- Range conversion
- URI encoding/decoding
- Location containment checks

**Definition Lookup:**
- Variables, functions, structs, enums, unions
- Parameters and fields
- Type annotations

**Reference Finding:**
- All usages of variables, functions, types
- Scope-aware references

**Grammar:**
- All keywords (control flow, declarations)
- All operators (arithmetic, comparison, logical, assignment)
- All literal types (int, float, string, bool)
- Comments and string interpolation
- All declaration types
- All statement types
- All expression types
