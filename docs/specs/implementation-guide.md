# Slang Implementation Guide

This is the master document for implementing the Slang programming language. Each phase has a detailed specification linked below.

## Progress Tracker

### v0.1 Core Language

| Phase | Status | Spec |
|-------|--------|------|
| 1. Lexer | ✅ Complete | [phase-1-lexer.md](phase-1-lexer.md) |
| 2. Parser & AST | ✅ Complete | [phase-2-parser.md](phase-2-parser.md) |
| 3. Type Checker | ✅ Complete | [phase-3-typechecker.md](phase-3-typechecker.md) |
| 4. Interpreter | ✅ Complete | [phase-4-interpreter.md](phase-4-interpreter.md) |
| 5. CLI Polish | ✅ Complete | [phase-5-cli.md](phase-5-cli.md) |
| 6. Testing | ✅ Complete | [phase-6-testing.md](phase-6-testing.md) |

### v0.1.1+ Language Extensions

| Phase | Status | Spec |
|-------|--------|------|
| 7. Unions & Switch Expressions | ✅ Complete | [phase-7-unions.md](phase-7-unions.md) |
| 8. Collections | 🚧 In Progress | [phase-8-collections.md](phase-8-collections.md) |
| 9. LSP & IDE Support | ✅ Complete | [phase-9-lsp.md](phase-9-lsp.md) |

### Future Phases

| Phase | Status | Spec |
|-------|--------|------|
| 10. Methods | Planned | - |
| 11. Modules | Planned | - |
| 12. Generics | Planned | - |
| 13. Build System | Planned | - |
| 14. Formatter | Planned | - |
| 15. LLVM Backend | Planned | - |

---

## Quick Reference: Design Decisions

| Aspect | Decision |
|--------|----------|
| Implementation language | Swift |
| Types | Int, Float, String, Bool (explicit, no inference) |
| Structs | No methods, init: `Person { name: "Alice" }` |
| Enums | Simple: `enum Color { case red, green, blue }` |
| Variables | `var` only, must initialize |
| Semicolons | Optional (required for multiple statements on same line) |
| Entry point | `func main()` |
| Control flow | `if (cond) { }`, `for (;;) { }`, `switch (val) { }` |
| Switch syntax | `Pattern -> expression` or `Pattern -> { block }` |
| String interpolation | `\(expr)` |
| Enum access | Always qualified: `Direction.up` |
| print() | Only accepts String |
| Unions | `union Pet = Dog \| Cat` (v0.1.2) |
| Switch expressions | `var x = switch (val) { ... }` (v0.1.1) |
| Optional | `T?`, `nil` (v0.2) |
| Array | `[T]`, subscript `arr[i]` (v0.2) |
| Dictionary | `[K: V]`, subscript returns `T?` (v0.2) |
| Set | `Set<T>` with array literal (v0.2) |

---

## Dependency Graph

```
                    v0.1 Core Language
                    ==================
Phase 1: Lexer
    │
    ▼
Phase 2: Parser & AST
    │
    ▼
Phase 3: Type Checker
    │
    ▼
Phase 4: Interpreter
    │
    ▼
Phase 5: CLI Polish
    │
    ▼
Phase 6: Testing
    │
    ├─────────────────────────────────────┐
    │                                     │
    ▼                                     ▼
    v0.1.1+ Extensions              v0.2 Collections
    ==================              =================
Phase 7: Unions &                 Phase 8: Collections
         Switch Expressions       (Optional, Array,
         (v0.1.1, v0.1.2)          Dictionary, Set)
    │
    ▼
Phase 9: LSP & IDE Support
```

**Notes:**
- Phases 1-6 form the core v0.1 language
- Phases 7-9 are language extensions (can be done in parallel)
- Phase 8 depends on core language only
- Phase 9 depends on Phase 7 for union support in LSP
- Tests should be written alongside each phase

---

## Project Structure

```
slang/
├── Package.swift
├── Sources/
│   ├── SlangCore/           # Shared library
│   │   ├── Lexer/
│   │   │   ├── Token.swift
│   │   │   ├── SourceLocation.swift
│   │   │   └── Lexer.swift
│   │   ├── Parser/
│   │   │   ├── AST.swift
│   │   │   └── Parser.swift
│   │   ├── TypeChecker/
│   │   │   ├── Type.swift
│   │   │   └── TypeChecker.swift
│   │   ├── Interpreter/
│   │   │   ├── Value.swift
│   │   │   ├── Environment.swift
│   │   │   └── Interpreter.swift
│   │   ├── Diagnostics/
│   │   │   └── Diagnostic.swift
│   │   └── SymbolCollector/     # For LSP (Phase 9)
│   │       ├── SymbolInfo.swift
│   │       └── SymbolCollector.swift
│   ├── slang/               # CLI executable
│   │   └── slang.swift
│   └── slang-lsp/           # Language Server (Phase 9)
│       ├── main.swift
│       ├── LSPServer.swift
│       ├── LSPTypes.swift
│       ├── JSONRPCTransport.swift
│       ├── DocumentManager.swift
│       └── PositionConverter.swift
├── editors/
│   └── vscode/              # VS Code extension (Phase 9)
│       ├── package.json
│       ├── language-configuration.json
│       ├── syntaxes/
│       │   └── slang.tmLanguage.json
│       └── src/
│           └── extension.ts
└── Tests/
    └── SlangCoreTests/
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          CLI Layer                               │
│  slang run <file>  |  slang check  |  slang parse | tokenize    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Compiler Pipeline                          │
│                                                                  │
│   Source     Lexer      Parser     TypeChecker    Interpreter   │
│   String  ──────────▶ ──────────▶ ──────────────▶ ──────────▶   │
│            [Token]      [AST]     [Typed AST]      Output       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## How to Use This Guide

### For AI Agents

Each phase spec is self-contained and includes:
1. **Prerequisites** - What must be completed before starting
2. **Files to Create** - Exact file paths and purposes
3. **Implementation Steps** - Ordered list of tasks
4. **Code Structure** - Swift types and signatures to implement
5. **Test Cases** - Input/output pairs for verification
6. **Acceptance Criteria** - Checklist to confirm completion

When implementing a phase:
1. Read the entire spec first
2. Create files in the order specified
3. Implement step by step
4. Run tests after each major step
5. Verify all acceptance criteria before marking complete

### For Human Developers

- Start with Phase 1 and work sequentially
- Each phase builds on the previous
- The roadmap.md file has higher-level context
- Use `slang tokenize`, `slang parse`, `slang check` to debug each phase

---

## v0.1 Target Program

When all phases are complete, this program must work:

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

## What's Next?

After completing Phase 6, the v0.1 core language is complete. Continue with:

- [Phase 7: Unions & Switch Expressions](phase-7-unions.md) - Adds union types and switch as expression ✅
- [Phase 8: Collections](phase-8-collections.md) - Adds Optional, Array, Dictionary, Set 🚧
- [Phase 9: LSP & IDE Support](phase-9-lsp.md) - VS Code extension with go-to-definition ✅

Future phases (10+) are documented in [roadmap.md](../roadmap.md).
