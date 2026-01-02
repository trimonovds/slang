# Implementation Plan: Add Array/Set/Dictionary (Issue #2)

This plan outlines the implementation of collection types for the Slang language.

## Overview

Add three collection types to Slang:
- **Array**: Ordered, indexed collection of homogeneous elements
- **Set**: Unordered collection of unique elements
- **Dictionary**: Key-value pairs with homogeneous keys and values

Plus **Optional type** as a prerequisite for safe dictionary access.

## Design Decisions

| Question | Decision |
|----------|----------|
| Type inference | **No** — all types must be explicitly annotated |
| Empty collections | Require explicit type: `var x: [Int] = []` |
| Set syntax | Swift-style with `[]`: `var s: Set<Int> = [1, 2, 3]` |
| Mutability | Collections are **mutable** |
| Copy-on-write | **No** — not needed |
| Array out-of-bounds | **Runtime error** (programmer error) |
| Dictionary missing key | **Optional** — returns `T?` |

## Proposed Syntax

```slang
// Array
var numbers: [Int] = [1, 2, 3, 4, 5]
var first: Int = numbers[0]
numbers[0] = 10

// Set (Swift-style)
var tags: Set<String> = ["swift", "slang"]
var hasTag: Bool = tags.contains("swift")

// Dictionary
var ages: [String: Int] = ["alice": 30, "bob": 25]
var maybeAge: Int? = ages["alice"]
ages["charlie"] = 35

// Optional
var name: String? = nil
var value: String? = "hello"
```

## Implementation Phases

---

## Phase 1: Optional Type (Prerequisite)

Optional is needed for safe dictionary access and will be useful for other features.

### Step 1.1: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case optionalType(wrappedType: SlangType)
```

Description: `"\(wrappedType)?"` format.

### Step 1.2: Add Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case some(Value)
case none
```

### Step 1.3: Add AST Nodes

**File**: `Sources/SlangCore/Parser/AST.swift`

Add to `ExpressionKind`:
```swift
case nilLiteral
```

### Step 1.4: Add Token

**File**: `Sources/SlangCore/Lexer/Token.swift`

```swift
case `nil`           // nil keyword
case questionMark    // ? for optional type syntax
```

### Step 1.5: Parser Changes

**File**: `Sources/SlangCore/Parser/Parser.swift`

1. **Parse `nil` literal** in `parsePrimary()`
2. **Parse optional type annotations**: `Type?` syntax
   - After parsing base type, check for `?` suffix
   - Return optional type annotation

### Step 1.6: Type Checker Changes

**File**: `Sources/SlangCore/TypeChecker/TypeChecker.swift`

1. **Resolve optional types**: Handle `T?` annotations
2. **Check nil literal**: Requires context to determine wrapped type
3. **Assignment compatibility**: `T` can be assigned to `T?`, `nil` can be assigned to any `T?`

### Step 1.7: Interpreter Changes

**File**: `Sources/SlangCore/Interpreter/Interpreter.swift`

1. **Evaluate nil**: Return `.none`
2. **Wrap values**: When assigning `T` to `T?`, wrap in `.some()`

### Step 1.8: Tests

**File**: `Tests/SlangCoreTests/OptionalTests.swift`

- Optional type annotations
- nil literal
- Assigning value to optional
- Assigning nil to optional
- Type checking errors

---

## Phase 2: Array Type

Arrays are the foundation for other collection types.

### Step 2.1: Add Tokens (Lexer)

**File**: `Sources/SlangCore/Lexer/Token.swift`

```swift
case leftBracket     // [
case rightBracket    // ]
```

**File**: `Sources/SlangCore/Lexer/Lexer.swift`

Add scanning for `[` and `]` characters.

### Step 2.2: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case arrayType(elementType: SlangType)
```

Description: `"[\(elementType)]"` format.

### Step 2.3: Add Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case arrayInstance(elements: [Value])
```

Format as `[elem1, elem2, ...]` in description.

### Step 2.4: Add AST Nodes

**File**: `Sources/SlangCore/Parser/AST.swift`

```swift
case arrayLiteral(elements: [Expression])
case subscriptAccess(object: Expression, index: Expression)
```

### Step 2.5: Parser Changes

**File**: `Sources/SlangCore/Parser/Parser.swift`

1. **Parse array literals** in `parsePrimary()`:
   - `[` → parse comma-separated expressions → `]`
   - Empty array: `[]` (type from annotation context)

2. **Parse subscript access** in `parseCall()`:
   - After primary, check for `[`
   - Parse index, consume `]`
   - Create `subscriptAccess` node

3. **Parse array type annotations** in `parseTypeAnnotation()`:
   - `[Type]` → array of Type

### Step 2.6: Type Checker Changes

**File**: `Sources/SlangCore/TypeChecker/TypeChecker.swift`

1. **Check array literals**:
   - Get expected type from context (variable declaration)
   - Verify all elements match expected element type
   - Empty array requires explicit type annotation
   - Error if elements have mismatched types

2. **Check subscript access**:
   - Verify object is array type
   - Verify index is `Int`
   - Return element type

3. **Built-in properties**:
   - `array.count` → `Int`
   - `array.isEmpty` → `Bool`

### Step 2.7: Interpreter Changes

**File**: `Sources/SlangCore/Interpreter/Interpreter.swift`

1. **Evaluate array literals**: Evaluate each element, create `arrayInstance`

2. **Evaluate subscript read**:
   - Get array and index values
   - **Runtime error if index < 0 or index >= count**
   - Return element

3. **Evaluate subscript write** (assignment):
   - Handle `array[i] = value`
   - **Runtime error if out of bounds**
   - Mutate array in place

4. **Built-in properties**:
   - `.count` → array length
   - `.isEmpty` → count == 0

### Step 2.8: Tests

**File**: `Tests/SlangCoreTests/ArrayTests.swift`

- Array literal parsing and evaluation
- Array type annotation `[Int]`
- Subscript read: `arr[0]`
- Subscript write: `arr[0] = 5`
- Out-of-bounds runtime error
- Empty arrays with explicit type
- Nested arrays `[[Int]]`
- Type errors: mixed element types
- `.count` and `.isEmpty`

---

## Phase 3: Dictionary Type

### Step 3.1: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case dictionaryType(keyType: SlangType, valueType: SlangType)
```

Description: `"[\(keyType): \(valueType)]"`

### Step 3.2: Add Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case dictionaryInstance(pairs: [(key: Value, value: Value)])
```

Note: Array of tuples for simplicity (no Hashable requirement on Value).

### Step 3.3: Add AST Nodes

**File**: `Sources/SlangCore/Parser/AST.swift`

```swift
case dictionaryLiteral(pairs: [(key: Expression, value: Expression)])
```

### Step 3.4: Parser Changes

1. **Disambiguate `[` token**:
   - Parse first expression
   - If next is `:` → dictionary literal
   - If next is `,` or `]` → array literal
   - `[:]` → empty dictionary

2. **Parse dictionary type**: `[KeyType: ValueType]`

### Step 3.5: Type Checker Changes

1. **Validate key types**: Only primitives (Int, String, Bool) allowed as keys
2. **Check homogeneity**: All keys same type, all values same type
3. **Subscript access**: Returns `Optional<ValueType>` (may be missing)
4. **Subscript assignment**: Adds or updates key-value pair

### Step 3.6: Interpreter Changes

1. **Evaluate dictionary literals**
2. **Subscript read**:
   - Search for key (linear scan)
   - Return `.some(value)` if found, `.none` if not
3. **Subscript write**: Update existing or append new pair

### Step 3.7: Tests

**File**: `Tests/SlangCoreTests/DictionaryTests.swift`

- Dictionary literal parsing
- Type annotation `[String: Int]`
- Key access returns Optional
- Missing key returns nil
- Subscript assignment (update and insert)
- Type errors for invalid keys/values
- Empty dictionary `[:]`

---

## Phase 4: Set Type

### Step 4.1: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case setType(elementType: SlangType)
```

Description: `"Set<\(elementType)>"`

### Step 4.2: Add Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case setInstance(elements: [Value])
```

Uniqueness enforced at insertion time.

### Step 4.3: Syntax

Sets use array literal syntax with `Set<T>` type annotation:
```slang
var s: Set<Int> = [1, 2, 3]
var empty: Set<String> = []
```

The type annotation disambiguates from array.

### Step 4.4: Parser Changes

No new literal syntax needed — reuse array literal `[...]`.
Parser doesn't distinguish; type checker handles based on annotation.

### Step 4.5: Type Checker Changes

1. **Check set literal**: Array literal assigned to `Set<T>` type
2. **Element type constraints**: Only primitives (hashable/equatable)
3. **Built-in methods**:
   - `set.contains(element)` → `Bool`
   - `set.count` → `Int`
   - `set.isEmpty` → `Bool`
   - `set.insert(element)` → mutating, returns `Void`
   - `set.remove(element)` → mutating, returns `Bool`

### Step 4.6: Interpreter Changes

1. **Create set from array literal**: Deduplicate elements
2. **contains()**: Linear search, return Bool
3. **insert()**: Add if not present
4. **remove()**: Remove if present, return success

### Step 4.7: Tests

**File**: `Tests/SlangCoreTests/SetTests.swift`

- Set creation with literal
- Automatic deduplication
- `.contains()` method
- `.insert()` and `.remove()`
- `.count` and `.isEmpty`
- Type errors for non-primitive elements

---

## Phase 5: Collection Methods (Enhancement)

### Step 5.1: Array Methods

- `array.append(element)` → mutating
- `array.removeAt(index: Int)` → mutating, runtime error if invalid
- `array.first` → `T?` (Optional)
- `array.last` → `T?` (Optional)

### Step 5.2: Dictionary Methods

- `dict.keys` → `[KeyType]`
- `dict.values` → `[ValueType]`
- `dict.removeKey(key)` → mutating

---

## File Change Summary

| File | Changes |
|------|---------|
| `Token.swift` | Add `leftBracket`, `rightBracket`, `nil`, `questionMark` |
| `Lexer.swift` | Scan `[`, `]`, `?`, `nil` keyword |
| `Type.swift` | Add `optionalType`, `arrayType`, `dictionaryType`, `setType` |
| `Value.swift` | Add `some`, `none`, `arrayInstance`, `dictionaryInstance`, `setInstance` |
| `AST.swift` | Add `nilLiteral`, `arrayLiteral`, `dictionaryLiteral`, `subscriptAccess` |
| `Parser.swift` | Parse optionals, array/dict literals, subscripts, compound type annotations |
| `TypeChecker.swift` | Check all new types, subscript access, built-in properties/methods |
| `Interpreter.swift` | Evaluate all new expressions, handle mutations |
| New: `OptionalTests.swift` | Optional type tests |
| New: `ArrayTests.swift` | Array tests |
| New: `DictionaryTests.swift` | Dictionary tests |
| New: `SetTests.swift` | Set tests |
| `Examples/` | Example `.slang` files |

---

## Implementation Order

1. **Phase 1 (Optional)**: Foundation for safe dictionary access
2. **Phase 2 (Array)**: Core collection, establishes patterns
3. **Phase 3 (Dictionary)**: Builds on array + optional
4. **Phase 4 (Set)**: Reuses array literal syntax
5. **Phase 5 (Methods)**: Enhancement, can be separate PR

---

## Success Criteria

- [ ] Optional type works (`T?`, `nil`, assignment)
- [ ] Array literals parse and evaluate correctly
- [ ] Array subscript read/write works with runtime bounds check
- [ ] Array type annotations work (`[Int]`, `[[String]]`)
- [ ] Dictionary literals parse and evaluate
- [ ] Dictionary subscript returns `Optional<Value>`
- [ ] Dictionary subscript assignment works
- [ ] Set creation from array literal with deduplication
- [ ] Set `.contains()`, `.insert()`, `.remove()` work
- [ ] All collections have `.count` and `.isEmpty`
- [ ] Type checker catches type mismatches
- [ ] No type inference anywhere — all types explicit
- [ ] Comprehensive test coverage
- [ ] Example programs in `Tests/Examples/`
