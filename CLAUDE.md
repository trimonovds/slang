# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

```bash
# Build the project
swift build

# Run tests
swift test

# Run a single test
swift test --filter <TestName>

# Run a Slang program
swift run slang run <file>.slang

# Type-check only (no execution)
swift run slang check <file>.slang

# Debug: show AST
swift run slang parse <file>.slang

# Debug: show tokens
swift run slang tokenize <file>.slang
```

## Architecture

Slang is a statically-typed programming language implemented as a tree-walking interpreter in Swift. The pipeline flows:

```
Source → Lexer → Parser → TypeChecker → Interpreter
         ↓        ↓           ↓             ↓
       Tokens    AST      Typed AST       Output
```

### Core Components (Sources/SlangCore/)

- **Lexer/** - Tokenization with source location tracking for error messages
  - `Token.swift` - Token types including keywords, operators, literals
  - `Lexer.swift` - Scanner producing token stream, handles string interpolation `\(expr)`
  - `SourceLocation.swift` - Line/column/offset tracking

- **Parser/** - Recursive descent parser with Pratt parsing for expressions
  - `AST.swift` - Node types: `Declaration`, `Statement`, `Expression` (each with `Kind` enum + `SourceRange`)
  - `Parser.swift` - Builds AST from tokens

- **TypeChecker/** - Static type verification before execution
  - `Type.swift` - `SlangType` enum (int, float, string, bool, void, structType, enumType, unionType, function, error)
  - `TypeChecker.swift` - Scoped symbol table, type inference, exhaustiveness checking for switch

- **Interpreter/** - Tree-walking execution
  - `Value.swift` - Runtime values (int, float, string, bool, structInstance, enumCase, unionInstance)
  - `Environment.swift` - Variable scopes with parent chain
  - `Interpreter.swift` - Statement/expression evaluation, finds and runs `main()`

- **Diagnostics/** - Colored terminal error output with source context
  - `Diagnostic.swift` - Error types with source ranges
  - `DiagnosticPrinter.swift` - Formatted error display

### CLI (Sources/slang/)

Uses swift-argument-parser. Commands: `run`, `check`, `parse`, `tokenize`.

### Tests

- `Tests/SlangCoreTests/` - Unit tests for each component (uses Swift Testing framework with `@Test` macros)
- `Tests/Examples/` - Complete `.slang` example programs

## Language Features (v0.1)

- Types: `Int`, `Float`, `String`, `Bool`
- Structs: `struct Point { x: Int; y: Int }`, init with `Point { x: 3, y: 4 }`
- Enums: `enum Direction { case up; case down }`, access as `Direction.up`
- Functions: `func add(a: Int, b: Int) -> Int { return a + b }`
- Control flow: `if/else`, C-style `for (var i: Int = 0; i < 10; i = i + 1) {}`, `switch` with arrow syntax
- String interpolation: `"Value: \(x)"`
- Entry point: `func main() {}`
- `print()` only accepts String (use interpolation for other types)

## Language Features (v0.1.1)

- **Switch expressions**: Switch can return a value and be assigned to variables
  ```slang
  var opposite: Direction = switch (dir) {
      Direction.up -> return Direction.down
      Direction.down -> return Direction.up
  }
  ```
- Cases use `return` to provide values (single-line or block body)
- Type checker validates: exhaustiveness, consistent return types, return presence

## Language Features (v0.1.2)

- **Union types**: Create a type that can hold values from multiple existing types
  ```slang
  struct Dog { name: String }
  struct Cat { name: String }
  union Pet = Dog | Cat

  var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
  ```
- Unions can contain structs, enums, or primitives: `union Value = Int | String`
- Values created with qualified constructors: `UnionType.VariantName(value)`
- Pattern matching on unions in switch statements with exhaustiveness checking
- **Pattern binding**: In switch cases, the lowercase variant name is automatically bound to the underlying value
  ```slang
  switch (pet) {
      Pet.Dog -> print("Dog: \(dog.name)")  // 'dog' is bound to Dog value
      Pet.Cat -> print("Cat: \(cat.name)")  // 'cat' is bound to Cat value
  }
  ```
- Works with primitives too:
  ```slang
  union Value = Int | String
  var v: Value = Value.Int(42)
  switch (v) {
      Value.Int -> print("number: \(int)")     // 'int' is bound
      Value.String -> print("text: \(string)") // 'string' is bound
  }
  ```
- Union switch expressions return values just like enum switch expressions

## Key Patterns

- AST nodes use wrapper structs (e.g., `Expression`) containing a `Kind` enum and `SourceRange`
- Error types (`LexerError`, `ParserError`, `TypeCheckError`, `RuntimeError`) carry diagnostic arrays
- TypeChecker uses `.error` type to prevent cascading errors after first failure
- Interpreter uses `printHandler` closure for testable output capture
