# Slang Language Implementation Roadmap

## Summary of Design Decisions

| Aspect | Decision |
|--------|----------|
| Implementation language | Swift |
| Execution model | Tree-walking interpreter first, LLVM later |
| Types | Int, Float, String, Bool (explicit, no inference) |
| Structs | No methods initially, C-style init: `Person { name: "Alice" }` |
| Enums | Simple: `enum Color { case red, green, blue }` |
| Unions | `union Pet = Dog \| Cat` (v0.1.2) |
| Variables | `var` only (no `let`), must initialize |
| Semicolons | Optional (required only for multiple statements on same line) |
| Entry point | `func main()` |
| Switch | Exhaustive required, `switch (value) { }` with `->` syntax |
| Switch expressions | `var x = switch (val) { ... }` (v0.1.1) |
| Error handling | Return unions (Result-like) |
| Memory | Reference counting |
| Generics | Simple `<T>` only (Phase 12+) |
| Comments | `//` single-line |
| String interpolation | `\(expr)` Swift-style |
| Enum access | Always qualified: `Direction.up` |
| For loop | C-style with parens: `for (init; cond; incr) { }` |
| If/else | Parens required: `if (cond) { }` |
| print() | Only accepts String |
| Imports | Swift-style: `import Utils` |
| CLI | `slang run/build/check/format` |
| Optional | `T?` syntax, `nil` literal (v0.2) |
| Array | `[T]` syntax, subscript `arr[i]` (v0.2) |
| Dictionary | `[K: V]` syntax, subscript returns `T?` (v0.2) |
| Set | `Set<T>` with array literal (v0.2) |

---

## Implementation Phases

For detailed specifications, see [docs/specs/implementation-guide.md](specs/implementation-guide.md).

### v0.1 Core Language (Complete)

| Phase | Description | Status | Spec |
|-------|-------------|--------|------|
| 1 | Lexer | ✅ Complete | [phase-1-lexer.md](specs/phase-1-lexer.md) |
| 2 | Parser & AST | ✅ Complete | [phase-2-parser.md](specs/phase-2-parser.md) |
| 3 | Type Checker | ✅ Complete | [phase-3-typechecker.md](specs/phase-3-typechecker.md) |
| 4 | Interpreter | ✅ Complete | [phase-4-interpreter.md](specs/phase-4-interpreter.md) |
| 5 | CLI Polish | ✅ Complete | [phase-5-cli.md](specs/phase-5-cli.md) |
| 6 | Testing | ✅ Complete | [phase-6-testing.md](specs/phase-6-testing.md) |

### v0.1.1+ Language Extensions

| Phase | Description | Status | Spec |
|-------|-------------|--------|------|
| 7 | Unions & Switch Expressions | ✅ Complete | [phase-7-unions.md](specs/phase-7-unions.md) |
| 8 | Collections (Optional, Array, Dict, Set) | 🚧 In Progress | [phase-8-collections.md](specs/phase-8-collections.md) |
| 9 | LSP & IDE Support | ✅ Complete | [phase-9-lsp.md](specs/phase-9-lsp.md) |

### Future Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 10 | Methods on structs | Planned |
| 11 | Modules & imports | Planned |
| 12 | Generics (`<T>`) | Planned |
| 13 | Build system | Planned |
| 14 | Formatter | Planned |
| 15 | LLVM backend | Planned |

---

## Architecture

```
Source → Lexer → Parser → Type Checker → Interpreter
         ↓        ↓           ↓              ↓
       Tokens    AST     Typed AST        Output
```

---

## Project Structure

```
slang/
├── Package.swift
├── Sources/
│   ├── SlangCore/           # Shared library
│   │   ├── Lexer/
│   │   ├── Parser/
│   │   ├── TypeChecker/
│   │   ├── Interpreter/
│   │   ├── Diagnostics/
│   │   └── SymbolCollector/ # For LSP
│   ├── slang/               # CLI executable
│   └── slang-lsp/           # Language Server
├── editors/
│   └── vscode/              # VS Code extension
├── Tests/
│   ├── SlangCoreTests/
│   └── Examples/            # Example .slang files
└── docs/
    ├── roadmap.md           # This file
    └── specs/               # Detailed phase specs
```

---

## Version History

### v0.1 - Core Language
- Basic types: Int, Float, String, Bool
- Structs and enums
- Functions with explicit types
- Control flow: if/else, for, switch
- String interpolation

### v0.1.1 - Switch Expressions
- Switch can return a value
- Used in variable initialization and return statements

### v0.1.2 - Union Types
- `union Pet = Dog | Cat` syntax
- Pattern matching in switch
- Type narrowing in switch cases

### v0.2 - Collections (In Progress)
- Optional type (`T?`, `nil`)
- Array (`[T]`)
- Dictionary (`[K: V]`)
- Set (`Set<T>`)

---

## v0.1 Target Program

This program works with v0.1:

```slang
struct Point {
    x: Int
    y: Int
}

enum Direction {
    case up
    case down
    case left
    case right
}

func add(a: Int, b: Int) -> Int {
    return a + b
}

func describePoint(p: Point) -> String {
    return "Point at \(p.x), \(p.y)"
}

func main() {
    var p = Point { x: 3, y: 4 }
    print(describePoint(p))
    print("Sum: \(add(p.x, p.y))")

    var dir: Direction = Direction.up

    switch (dir) {
        Direction.up -> print("Going up!")
        Direction.down -> print("Going down!")
        Direction.left -> print("Going left!")
        Direction.right -> print("Going right!")
    }

    for (var i: Int = 0; i < 5; i = i + 1) {
        print("\(i)")
    }

    if (p.x > 0 && p.y > 0) {
        print("First quadrant")
    } else {
        print("Other quadrant")
    }
}
```

**Expected output:**
```
Point at 3, 4
Sum: 7
Going up!
0
1
2
3
4
First quadrant
```

---

## v0.2 Target Program

This program should work when v0.2 is complete:

```slang
func main() {
    // Optional
    var name: String? = nil
    var greeting: String? = "Hello"

    // Array
    var numbers: [Int] = [1, 2, 3, 4, 5]
    print("First: \(numbers[0])")
    print("Count: \(numbers.count)")
    numbers[0] = 10

    // Dictionary
    var ages: [String: Int] = ["alice": 30, "bob": 25]
    var aliceAge: Int? = ages["alice"]
    ages["charlie"] = 35

    // Set
    var tags: Set<String> = ["swift", "slang"]
    var hasSwift: Bool = tags.contains("swift")
    print("Has swift: \(hasSwift)")
}
```
