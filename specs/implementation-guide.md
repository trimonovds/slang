# Slang Implementation Guide

This is the master document for implementing the Slang programming language. Each phase has a detailed specification linked below.

## Progress Tracker

| Phase | Status | Spec |
|-------|--------|------|
| 1. Lexer | Not Started | [phase-1-lexer.md](phase-1-lexer.md) |
| 2. Parser & AST | Not Started | [phase-2-parser.md](phase-2-parser.md) |
| 3. Type Checker | Not Started | [phase-3-typechecker.md](phase-3-typechecker.md) |
| 4. Interpreter | Not Started | [phase-4-interpreter.md](phase-4-interpreter.md) |
| 5. CLI Polish | Not Started | [phase-5-cli.md](phase-5-cli.md) |
| 6. Testing | Not Started | [phase-6-testing.md](phase-6-testing.md) |

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

---

## Dependency Graph

```
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
```

**Notes:**
- Each phase depends on the previous one
- CLI skeleton can be built in parallel with Phase 2-4
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
│   │   └── Diagnostics/
│   │       └── Diagnostic.swift
│   └── slang/               # CLI executable
│       └── slang.swift
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
