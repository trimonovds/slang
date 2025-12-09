# Slang

A statically-typed programming language with a clean, modern syntax. Built in Swift.

## Features

- **Static typing** with type inference
- **Structs** and **enums** with pattern matching
- **String interpolation** using `\(expr)` syntax
- **C-style for loops** and **switch statements/expressions**
- **Switch expressions** that return values (v0.1.1)
- **Colored error messages** with source context

## Quick Start

```bash
# Build
swift build

# Run a program
swift run slang run program.slang

# Type-check without running
swift run slang check program.slang
```

## Syntax Overview

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

func distance(p: Point) -> Int {
    return p.x + p.y
}

func main() {
    var p = Point { x: 3, y: 4 }
    print("Distance: \(distance(p))")

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
    }
}
```

## Types

| Type | Description |
|------|-------------|
| `Int` | Integer numbers |
| `Float` | Floating-point numbers |
| `String` | Text strings |
| `Bool` | `true` or `false` |

## CLI Commands

```bash
slang run <file>       # Execute a program
slang check <file>     # Type-check only
slang parse <file>     # Show AST (debug)
slang tokenize <file>  # Show tokens (debug)
slang --version        # Show version
```

## Switch Expressions (v0.1.1)

Switch can be used as an expression that returns a value:

```slang
var dir: Direction = Direction.up
var opposite: Direction = switch (dir) {
    Direction.up -> return Direction.down
    Direction.down -> return Direction.up
    Direction.left -> return Direction.right
    Direction.right -> return Direction.left
}
```

## Examples

See [`Tests/Examples/`](Tests/Examples/) for complete example programs:

- `hello.slang` - Hello World
- `fibonacci.slang` - Recursive functions
- `structs.slang` - Struct usage
- `enums.slang` - Enums and switch
- `loops.slang` - For loops
- `full.slang` - Complete v0.1 feature demo
- `switch_expr.slang` - Switch expressions (v0.1.1)

## Project Structure

```
Sources/
├── SlangCore/           # Core library
│   ├── Lexer/           # Tokenization
│   ├── Parser/          # AST construction
│   ├── TypeChecker/     # Static type checking
│   ├── Interpreter/     # Tree-walking execution
│   └── Diagnostics/     # Error reporting
└── slang/               # CLI executable

Tests/
├── SlangCoreTests/      # Unit tests
└── Examples/            # Example programs
```

## Requirements

- Swift 6.0+
- macOS 13+

## License

MIT
