# Slang Language Implementation Roadmap

## Summary of Design Decisions

| Aspect | Decision |
|--------|----------|
| Implementation language | Swift |
| Execution model | Tree-walking interpreter first, LLVM later |
| Types | Int, Float, String, Bool (explicit, no inference) |
| Structs | No methods initially, C-style init: `Person { name: "Alice" }` |
| Enums | Simple: `enum Color { case red, green, blue }` |
| Unions | Separate: `union Pet = Dog \| Cat` (Phase 7+) |
| Variables | `var` only (no `let`), must initialize |
| Semicolons | Optional (required only for multiple statements on same line) |
| Entry point | `func main()` |
| Switch | Exhaustive required, `switch (value) { }` with `->` syntax |
| Error handling | Return unions (Result-like) |
| Memory | Reference counting |
| Generics | Simple `<T>` only (Phase 10+) |
| Comments | `//` single-line |
| String interpolation | `\(expr)` Swift-style |
| Enum access | Always qualified: `Direction.up` |
| For loop | C-style with parens: `for (init; cond; incr) { }` |
| If/else | Parens required: `if (cond) { }` |
| print() | Only accepts String |
| Imports | Swift-style: `import Utils` |
| CLI | `slang run/build/check/format` |

---

## Architecture

```
Source → Lexer → Parser → Type Checker → Interpreter
         ↓        ↓           ↓              ↓
       Tokens    AST     Typed AST        Output
```

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

## Phase 1: Lexer (Foundation)

**Goal:** Transform source text into tokens.

### Components

1. **SourceLocation.swift** - Track line/column/offset for error messages and LSP
2. **Token.swift** - Token struct with kind, range, trivia (whitespace preserved for formatter)
3. **Lexer.swift** - Scanner that produces token stream

### Token Types
- Literals: `intLiteral`, `floatLiteral`, `stringLiteral`, `boolLiteral`
- Keywords: `func`, `var`, `struct`, `enum`, `if`, `else`, `for`, `switch`, `case`, `return`
- Operators: `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `&&`, `||`, `!`, `=`, `+=`, `-=`
- Delimiters: `(`, `)`, `{`, `}`, `,`, `:`, `;`, `.`, `->`
- Special: `newline` (for optional semicolon), `eof`

### String Interpolation Strategy
`"Hello \(name)!"` becomes tokens: `stringLiteral("Hello ")`, `backslash`, `(`, `identifier(name)`, `)`, `stringLiteral("!")`

### Milestone 1 Deliverable
- `slang tokenize <file>` dumps tokens
- Unit tests for all token types

---

## Phase 2: Parser & AST

**Goal:** Build abstract syntax tree from tokens.

### AST Node Categories

**Declarations:**
- `FunctionDecl` - name, parameters, returnType, body
- `StructDecl` - name, fields
- `EnumDecl` - name, cases

**Statements:**
- `BlockStmt`, `VarDeclStmt`, `ExpressionStmt`, `ReturnStmt`
- `IfStmt`, `ForStmt`, `SwitchStmt` (Kotlin-style `when`)

**Expressions:**
- Literals: `IntLiteralExpr`, `FloatLiteralExpr`, `StringLiteralExpr`, `BoolLiteralExpr`
- `StringInterpolationExpr` - parts: literal or interpolated expression
- `IdentifierExpr`, `BinaryExpr`, `UnaryExpr`
- `CallExpr`, `MemberAccessExpr`, `StructInitExpr`

### Parser Approach
- Recursive descent for declarations/statements
- Pratt parsing for expressions (handles precedence)

### Operator Precedence (low to high)
1. `||`
2. `&&`
3. `==`, `!=`
4. `<`, `<=`, `>`, `>=`
5. `+`, `-`
6. `*`, `/`, `%`
7. Unary `-`, `!`
8. Call `()`, member `.`

### Optional Semicolon
Newline acts as statement terminator unless:
- Inside parentheses/braces
- Line ends with operator expecting continuation

### Milestone 2 Deliverable
- `slang parse <file>` prints AST
- All v0.1 syntax parseable
- Good error messages with source locations

---

## Phase 3: Type Checker

**Goal:** Verify type correctness before execution.

### Type Representation
```swift
enum SlangType {
    case int, float, string, bool, void
    case structType(name: String, fields: [FieldType])
    case enumType(name: String, cases: [String])
    case function(params: [SlangType], returnType: SlangType)
    case error  // Prevents cascading errors
}
```

### Type Environment
- Scoped symbol table (parent chain for nested scopes)
- Pre-populated with built-ins: Int, Float, String, Bool, print()

### Checking Rules
- Variable: declared type must match initializer type
- Binary ops: operands must be compatible, result type determined by operator
- Function calls: argument count/types must match signature
- Switch: must cover all enum cases (exhaustive)
- Return: value type must match function return type

### Milestone 3 Deliverable
- `slang check <file>` reports type errors
- Clear error messages with locations
- All type rules enforced

---

## Phase 4: Tree-Walking Interpreter

**Goal:** Execute type-checked programs.

### Runtime Values
```swift
enum Value {
    case int(Int), float(Double), string(String), bool(Bool), void
    case structInstance(name: String, fields: [String: Value])
    case enumCase(typeName: String, caseName: String)
}
```

### Execution Flow
1. Collect all declarations (functions, structs, enums)
2. Find `main()` function
3. Execute statements, evaluate expressions
4. Handle control flow (if/for/switch/return)

### Return Handling
Use Swift's error throwing: `throw ReturnValue(value)` caught by function executor

### Built-in Functions
- `print(...)` - outputs stringified values to stdout

### Milestone 4 Deliverable
- `slang run <file>` executes program
- All v0.1 features working end-to-end
- Runtime error messages

---

## Phase 5: CLI Polish

**Goal:** Professional developer experience.

### Commands
| Command | Description |
|---------|-------------|
| `slang run <file>` | Execute program |
| `slang check <file>` | Type-check only |
| `slang parse <file>` | Show AST (debug) |
| `slang tokenize <file>` | Show tokens (debug) |
| `slang --version` | Show version |

### Error Presentation
```
error: type mismatch
  --> main.slang:5:12
   |
 5 |     var x: Int = "hello"
   |            ^^^   ^^^^^^^ expected Int, got String
```

### Milestone 5 Deliverable
- All CLI commands working
- Colored terminal output
- Helpful error context

---

## Phase 6: Testing & Documentation

**Goal:** Quality assurance and learning materials.

### Test Categories
- **Unit tests:** Each component (Lexer, Parser, TypeChecker, Interpreter)
- **Integration tests:** End-to-end program execution
- **Error tests:** Verify correct error detection

### Example Programs
- `examples/hello.slang` - Hello World
- `examples/fibonacci.slang` - Recursion
- `examples/structs.slang` - Struct usage
- `examples/enums.slang` - Enum and switch
- `examples/loops.slang` - For loop examples

### Milestone 6 Deliverable (v0.1 Complete)
- All tests passing
- Example programs working
- README with getting started

---

## Dependency Graph

```
Phase 1: Lexer
    ↓
Phase 2: Parser ←──────┐
    ↓                  │ (CLI skeleton parallel)
Phase 3: Type Checker  │
    ↓                  │
Phase 4: Interpreter ──┘
    ↓
Phase 5: CLI Polish
    ↓
Phase 6: Testing
```

---

## Post v0.1 Roadmap

| Phase | Feature | Description |
|-------|---------|-------------|
| 7 | ~~Unions~~ | ~~`union Pet = Dog \| Cat` with pattern matching~~ (v0.1.2) |
| 8 | Methods | Functions on structs |
| 9 | Modules | Directory-based module system, imports |
| 10 | Generics | Simple `<T>` parameter |
| 11 | Build System | `Slang.json`, `slang build`, project structure |
| 12 | Formatter | `slang format` |
| 13 | LSP | Editor support (VS Code) |
| 14 | LLVM | Compiled executables |

---

## Critical Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `Package.swift` | Modify | Add SlangCore library, test targets |
| `Sources/SlangCore/Lexer/SourceLocation.swift` | Create | Position tracking |
| `Sources/SlangCore/Lexer/Token.swift` | Create | Token definitions |
| `Sources/SlangCore/Lexer/Lexer.swift` | Create | Tokenization |
| `Sources/SlangCore/Parser/AST.swift` | Create | AST node types |
| `Sources/SlangCore/Parser/Parser.swift` | Create | Parsing logic |
| `Sources/SlangCore/TypeChecker/Type.swift` | Create | Type representation |
| `Sources/SlangCore/TypeChecker/TypeChecker.swift` | Create | Type checking |
| `Sources/SlangCore/Interpreter/Value.swift` | Create | Runtime values |
| `Sources/SlangCore/Interpreter/Environment.swift` | Create | Variable scopes |
| `Sources/SlangCore/Interpreter/Interpreter.swift` | Create | Execution |
| `Sources/SlangCore/Diagnostics/Diagnostic.swift` | Create | Error reporting |
| `Sources/slang/slang.swift` | Modify | CLI commands |

---

## v0.1 Test Program

This program should work when v0.1 is complete:

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

Expected output:
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

### Syntax Notes

**Switch (with parentheses, arrow syntax):**
```slang
switch (value) {
    Pattern1 -> expression
    Pattern2 -> {
        // block for multiple statements
    }
}
```

**For loop (C-style with parentheses):**
```slang
for (var i: Int = 0; i < 10; i = i + 1) {
    // body
}
```

**If/else (parentheses required):**
```slang
if (condition) {
    // then
} else if (other) {
    // else if
} else {
    // else
}
```

**Print (String only):**
```slang
print("Hello")           // OK
print("\(someInt)")      // OK - interpolate to String
// print(42)             // Error - must be String
```

## v0.1.1 - Switch Expressions

**Goal:** Add switch expressions that return values.

### New Feature: Switch Expression

Switch can now be used as an expression that returns a value, allowing assignment to variables:

```slang
var dir: Direction = Direction.up
var oppositeDirection: Direction = switch (dir) {
    Direction.up -> return Direction.down
    Direction.down -> return Direction.up
    Direction.left -> return Direction.right
    Direction.right -> return Direction.left
}
```

### Syntax Options

**Single-line return:**
```slang
Direction.up -> return Direction.down
```

**Block body with return:**
```slang
Direction.up -> {
    return Direction.down
}
```

### Type Checking

- All cases must return the same type
- Switch must be exhaustive (cover all enum cases)
- Each case must have a `return` statement

### Example Program

```slang
enum Direction {
    case up
    case down
    case left
    case right
}

func opposite(dir: Direction) -> Direction {
    return switch (dir) {
        Direction.up -> return Direction.down
        Direction.down -> return Direction.up
        Direction.left -> return Direction.right
        Direction.right -> return Direction.left
    }
}

func main() {
    var dir: Direction = Direction.up
    var opp: Direction = opposite(dir)
    // opp is Direction.down
}
```

### Changes

| Component | Change |
|-----------|--------|
| AST | Added `ExpressionKind.switchExpr` |
| Parser | Added `parseSwitchExpr()`, modified `parsePrimary()` |
| TypeChecker | Added `checkSwitchExpr()` with type validation |
| Interpreter | Added `evaluateSwitchExpr()` |

### Tests Added

- Parser tests for switch expression parsing
- TypeChecker tests for error cases (non-exhaustive, type mismatch, missing return)
- Interpreter tests for execution
- Example test: `switch_expr.slang`

## v0.1.2 - Union Types

**Goal:** Add union types for grouping existing types.

### New Feature: Unions

Unions allow creating a type that can hold values from multiple existing types (structs, enums, or primitives):

```slang
struct Dog { name: String }
struct Cat { name: String }
union Pet = Dog | Cat

union Value = Int | String
```

### Value Creation

Values are created using qualified constructors:

```slang
var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
var val: Value = Value.Int(42)
```

### Pattern Matching

Switch statements and expressions work with unions using exhaustiveness checking:

```slang
switch (pet) {
    Pet.Dog -> print("woof")
    Pet.Cat -> print("meow")
}

var sound: String = switch (pet) {
    Pet.Dog -> return "woof"
    Pet.Cat -> return "meow"
}
```

### Type Narrowing

In switch cases for unions, the subject variable is automatically narrowed to the underlying type:

```slang
switch (pet) {
    Pet.Dog -> print("Dog: \(pet.name)")  // 'pet' is narrowed to Dog
    Pet.Cat -> print("Cat: \(pet.name)")  // 'pet' is narrowed to Cat
}

// Works with primitives too
union Value = Int | String
var v: Value = Value.Int(42)
switch (v) {
    Value.Int -> print("number: \(v)")     // 'v' is narrowed to Int
    Value.String -> print("text: \(v)")    // 'v' is narrowed to String
}

// Also works in switch expressions
func getPetName(pet: Pet) -> String {
    return switch (pet) {
        Pet.Dog -> return pet.name
        Pet.Cat -> return pet.name
    }
}
```

### Example Program

```slang
struct Dog { name: String }
struct Cat { name: String }
union Pet = Dog | Cat

union Value = Int | String

func describePet(pet: Pet) -> String {
    return switch (pet) {
        Pet.Dog -> return "dog"
        Pet.Cat -> return "cat"
    }
}

func getPetName(pet: Pet) -> String {
    return switch (pet) {
        Pet.Dog -> return pet.name
        Pet.Cat -> return pet.name
    }
}

func main() {
    var myDog: Dog = Dog { name: "Buddy" }
    var pet: Pet = Pet.Dog(myDog)
    print("Pet is: \(describePet(pet))")

    // Type narrowing: 'pet' is narrowed to Dog in this case
    switch (pet) {
        Pet.Dog -> print("It's a dog named \(pet.name)!")
        Pet.Cat -> print("It's a cat named \(pet.name)!")
    }

    var v: Value = Value.Int(42)
    switch (v) {
        Value.Int -> print("integer: \(v)")
        Value.String -> print("string: \(v)")
    }

    var myCat: Cat = Cat { name: "Whiskers" }
    var pet2: Pet = Pet.Cat(myCat)
    print("Pet 2 name: \(getPetName(pet2))")
}
```

Expected output:
```
Pet is: dog
It's a dog named Buddy!
integer: 42
Pet 2 name: Whiskers
```

### Changes

| Component | Change |
|-----------|--------|
| Lexer | Added `union` keyword, `\|` (pipe) token |
| AST | Added `UnionVariant`, `DeclarationKind.unionDecl` |
| Parser | Added `parseUnionDecl()` |
| Type.swift | Added `SlangType.unionType`, `UnionTypeInfo` |
| TypeChecker | Union registration, checking, member access, switch exhaustiveness, type narrowing in switch cases |
| Value.swift | Added `Value.unionInstance` |
| Interpreter | Union construction, switch matching, type narrowing (shadows subject variable with narrowed type) |

### Tests Added

- Lexer tests for union keyword and pipe operator
- Parser tests for union declarations
- TypeChecker tests for valid unions, error cases (unknown type, duplicate variant, non-exhaustive switch)
- Interpreter tests for union construction, switch, switch expression
- Type narrowing tests: struct field access, primitive narrowing, switch expressions with narrowing