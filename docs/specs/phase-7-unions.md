# Phase 7: Unions & Switch Expressions

## Status: ✅ Complete (v0.1.1 + v0.1.2)

This phase adds two features:
- **v0.1.1**: Switch expressions (switch as value-returning expression)
- **v0.1.2**: Union types with pattern matching

---

## Prerequisites

- Phase 1-6 complete (v0.1 core language)

---

## Part A: Switch Expressions (v0.1.1)

### Overview

Switch can now be used as an expression that returns a value:

```slang
var dir: Direction = Direction.up
var opposite: Direction = switch (dir) {
    Direction.up -> return Direction.down
    Direction.down -> return Direction.up
    Direction.left -> return Direction.right
    Direction.right -> return Direction.left
}
```

### Syntax

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

### Files Modified

| File | Changes |
|------|---------|
| `AST.swift` | Added `ExpressionKind.switchExpr` |
| `Parser.swift` | Added `parseSwitchExpr()`, modified `parsePrimary()` |
| `TypeChecker.swift` | Added `checkSwitchExpr()` with type validation |
| `Interpreter.swift` | Added `evaluateSwitchExpr()` |

### Type Checking Rules

1. All cases must return the same type
2. Switch must be exhaustive (cover all enum cases)
3. Each case must have a `return` statement

### Tests

- Parser tests for switch expression parsing
- TypeChecker tests for error cases (non-exhaustive, type mismatch, missing return)
- Interpreter tests for execution

---

## Part B: Union Types (v0.1.2)

### Overview

Unions allow creating a type that can hold values from multiple existing types:

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

Switch statements and expressions work with unions:

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

In switch cases, the subject variable is automatically narrowed to the underlying type:

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
```

### Files Modified

| File | Changes |
|------|---------|
| `Token.swift` | Added `union` keyword, `\|` (pipe) token |
| `Lexer.swift` | Scan `union` and `\|` |
| `AST.swift` | Added `UnionVariant`, `DeclarationKind.unionDecl` |
| `Parser.swift` | Added `parseUnionDecl()` |
| `Type.swift` | Added `SlangType.unionType`, `UnionTypeInfo` |
| `TypeChecker.swift` | Union registration, checking, switch exhaustiveness, type narrowing |
| `Value.swift` | Added `Value.unionInstance` |
| `Interpreter.swift` | Union construction, switch matching, type narrowing |

### Type Representation

```swift
case unionType(name: String, info: UnionTypeInfo)

struct UnionTypeInfo {
    let variants: [UnionVariant]
}

struct UnionVariant {
    let name: String        // e.g., "Dog"
    let type: SlangType     // The underlying type
}
```

### Runtime Value

```swift
case unionInstance(unionName: String, variantName: String, value: Value)
```

### Type Checking Rules

1. All variant types must exist (struct, enum, or primitive)
2. No duplicate variant names
3. Switch on union must be exhaustive
4. Type narrowing applies inside switch cases

---

## Example Program

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

    // Type narrowing in switch statement
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

**Expected output:**
```
Pet is: dog
It's a dog named Buddy!
integer: 42
Pet 2 name: Whiskers
```

---

## Acceptance Criteria

### v0.1.1 - Switch Expressions
- [x] Switch can be used as expression returning value
- [x] All cases must return same type
- [x] Exhaustiveness checking works
- [x] Both single-line and block syntax work

### v0.1.2 - Union Types
- [x] `union Name = Type1 | Type2` syntax parses
- [x] Qualified constructors work: `Pet.Dog(value)`
- [x] Switch pattern matching on unions works
- [x] Exhaustiveness checking for union switches
- [x] Type narrowing in switch cases
- [x] Works with structs, enums, and primitives
- [x] Union switch expressions return values

---

## Tests Added

- Lexer tests for union keyword and pipe operator
- Parser tests for union declarations
- TypeChecker tests for valid unions, error cases
- Interpreter tests for union construction and switch
- Type narrowing tests for structs and primitives
