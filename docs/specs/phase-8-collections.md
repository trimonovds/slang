# Phase 8: Collection Types

## Status: ✅ Complete (v0.2)

This phase adds collection types to Slang:
- **Optional**: Nullable types (`T?`, `nil`)
- **Array**: Ordered, indexed collection (`[T]`)
- **Dictionary**: Key-value pairs (`[K: V]`)
- **Set**: Unordered unique elements (`Set<T>`)

---

## Prerequisites

- Phase 1-6 complete (v0.1 core language)

---

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

---

## Proposed Syntax

```slang
// Optional
var name: String? = nil
var value: String? = "hello"

// Nil comparison
var isNil: Bool = name == nil
var hasValue: Bool = value != nil

// Switch on optional (with type narrowing)
switch (value) {
    some -> print("value is: \(value)")  // value narrowed to String
    none -> print("no value")
}

// Switch expression on optional
var length: Int = switch (value) {
    some -> return 5
    none -> return 0
}

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
```

---

## Implementation Phases

### Phase 8.1: Optional Type

Optional is needed for safe dictionary access.

#### Step 8.1.1: Add Tokens

**File**: `Sources/SlangCore/Lexer/Token.swift`

```swift
case `nil`           // nil keyword
case questionMark    // ? for optional type syntax
```

**File**: `Sources/SlangCore/Lexer/Lexer.swift`

Add scanning for `?` and `nil` keyword.

#### Step 8.1.2: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case optionalType(wrappedType: SlangType)
```

Description: `"\(wrappedType)?"` format.

#### Step 8.1.3: Add Runtime Values

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case some(Value)
case none
```

#### Step 8.1.4: Add AST Nodes

**File**: `Sources/SlangCore/Parser/AST.swift`

```swift
case nilLiteral
```

#### Step 8.1.5: Parser Changes

**File**: `Sources/SlangCore/Parser/Parser.swift`

1. **Parse `nil` literal** in `parsePrimary()`
2. **Parse optional type annotations**: `Type?` syntax
   - After parsing base type, check for `?` suffix
   - Return optional type annotation

#### Step 8.1.6: Type Checker Changes

**File**: `Sources/SlangCore/TypeChecker/TypeChecker.swift`

1. **Resolve optional types**: Handle `T?` annotations
2. **Check nil literal**: Requires context to determine wrapped type
3. **Assignment compatibility**: `T` can be assigned to `T?`, `nil` can be assigned to any `T?`
4. **Nil comparison**: `x == nil` and `x != nil` work for optional types
5. **Switch on optionals**: Support `some`/`none` patterns with exhaustiveness checking
6. **Type narrowing**: In `some` branch, variable is narrowed to wrapped type

#### Step 8.1.7: Interpreter Changes

**File**: `Sources/SlangCore/Interpreter/Interpreter.swift`

1. **Evaluate nil**: Return `.none`
2. **Wrap values**: When assigning `T` to `T?`, wrap in `.some()`
3. **Nil comparison**: Compare `.some`/`.none` values
4. **Switch on optionals**: Match `some`/`none` patterns, extract wrapped value for type narrowing

#### Step 8.1.8: Tests

**File**: `Tests/SlangCoreTests/CollectionTests.swift`

- Optional type annotations
- nil literal
- Assigning value to optional
- Assigning nil to optional
- Nil comparison (`== nil`, `!= nil`)
- Switch statement on optionals
- Switch expression on optionals
- Type narrowing in switch
- Exhaustiveness checking
- Type checking errors

---

### Phase 8.2: Array Type

Arrays are the foundation for other collection types.

#### Step 8.2.1: Add Tokens

**File**: `Sources/SlangCore/Lexer/Token.swift`

```swift
case leftBracket     // [
case rightBracket    // ]
```

**File**: `Sources/SlangCore/Lexer/Lexer.swift`

Add scanning for `[` and `]` characters.

#### Step 8.2.2: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case arrayType(elementType: SlangType)
```

Description: `"[\(elementType)]"` format.

#### Step 8.2.3: Add Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case arrayInstance(elements: [Value])
```

Format as `[elem1, elem2, ...]` in description.

#### Step 8.2.4: Add AST Nodes

**File**: `Sources/SlangCore/Parser/AST.swift`

```swift
case arrayLiteral(elements: [Expression])
case subscriptAccess(object: Expression, index: Expression)
```

#### Step 8.2.5: Parser Changes

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

#### Step 8.2.6: Type Checker Changes

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

#### Step 8.2.7: Interpreter Changes

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

#### Step 8.2.8: Tests

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

### Phase 8.3: Dictionary Type

#### Step 8.3.1: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case dictionaryType(keyType: SlangType, valueType: SlangType)
```

Description: `"[\(keyType): \(valueType)]"`

#### Step 8.3.2: Add Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case dictionaryInstance(pairs: [(key: Value, value: Value)])
```

Note: Array of tuples for simplicity (no Hashable requirement on Value).

#### Step 8.3.3: Add AST Nodes

**File**: `Sources/SlangCore/Parser/AST.swift`

```swift
case dictionaryLiteral(pairs: [(key: Expression, value: Expression)])
```

#### Step 8.3.4: Parser Changes

1. **Disambiguate `[` token**:
   - Parse first expression
   - If next is `:` → dictionary literal
   - If next is `,` or `]` → array literal
   - `[:]` → empty dictionary

2. **Parse dictionary type**: `[KeyType: ValueType]`

#### Step 8.3.5: Type Checker Changes

1. **Validate key types**: Only primitives (Int, String, Bool) allowed as keys
2. **Check homogeneity**: All keys same type, all values same type
3. **Subscript access**: Returns `Optional<ValueType>` (may be missing)
4. **Subscript assignment**: Adds or updates key-value pair

#### Step 8.3.6: Interpreter Changes

1. **Evaluate dictionary literals**
2. **Subscript read**:
   - Search for key (linear scan)
   - Return `.some(value)` if found, `.none` if not
3. **Subscript write**: Update existing or append new pair

#### Step 8.3.7: Tests

**File**: `Tests/SlangCoreTests/DictionaryTests.swift`

- Dictionary literal parsing
- Type annotation `[String: Int]`
- Key access returns Optional
- Missing key returns nil
- Subscript assignment (update and insert)
- Type errors for invalid keys/values
- Empty dictionary `[:]`

---

### Phase 8.4: Set Type

#### Step 8.4.1: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case setType(elementType: SlangType)
```

Description: `"Set<\(elementType)>"`

#### Step 8.4.2: Add Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case setInstance(elements: [Value])
```

Uniqueness enforced at insertion time.

#### Step 8.4.3: Syntax

Sets use array literal syntax with `Set<T>` type annotation:

```slang
var s: Set<Int> = [1, 2, 3]
var empty: Set<String> = []
```

The type annotation disambiguates from array.

#### Step 8.4.4: Parser Changes

No new literal syntax needed — reuse array literal `[...]`.
Parser doesn't distinguish; type checker handles based on annotation.

#### Step 8.4.5: Type Checker Changes

1. **Check set literal**: Array literal assigned to `Set<T>` type
2. **Element type constraints**: Only primitives (hashable/equatable)
3. **Built-in methods**:
   - `set.contains(element)` → `Bool`
   - `set.count` → `Int`
   - `set.isEmpty` → `Bool`
   - `set.insert(element)` → mutating, returns `Void`
   - `set.remove(element)` → mutating, returns `Bool`

#### Step 8.4.6: Interpreter Changes

1. **Create set from array literal**: Deduplicate elements
2. **contains()**: Linear search, return Bool
3. **insert()**: Add if not present
4. **remove()**: Remove if present, return success

#### Step 8.4.7: Tests

**File**: `Tests/SlangCoreTests/SetTests.swift`

- Set creation with literal
- Automatic deduplication
- `.contains()` method
- `.insert()` and `.remove()`
- `.count` and `.isEmpty`
- Type errors for non-primitive elements

---

### Phase 8.5: Collection Methods (Enhancement)

#### Array Methods

- `array.append(element)` → mutating
- `array.removeAt(index: Int)` → mutating, runtime error if invalid
- `array.first` → `T?` (Optional)
- `array.last` → `T?` (Optional)

#### Dictionary Methods

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

---

## Example Program

```slang
func main() {
    // Optional
    var name: String? = nil
    var greeting: String? = "Hello"

    // Nil comparison
    print("name == nil: \(name == nil)")      // true
    print("greeting != nil: \(greeting != nil)")  // true

    // Assign value to optional
    name = "World"

    // Switch on optional with type narrowing
    switch (name) {
        some -> print("name is: \(name)")  // name narrowed to String
        none -> print("name is nil")
    }

    // Switch expression on optional
    var length: Int = switch (name) {
        some -> return 5
        none -> return 0
    }
    print("length: \(length)")

    // Array
    var numbers: [Int] = [1, 2, 3, 4, 5]
    print("First: \(numbers[0])")
    print("Count: \(numbers.count)")
    numbers[0] = 10
    print("Updated first: \(numbers[0])")

    // Dictionary
    var ages: [String: Int] = ["alice": 30, "bob": 25]
    var aliceAge: Int? = ages["alice"]
    var unknownAge: Int? = ages["charlie"]
    print("unknown == nil: \(unknownAge == nil)")  // true
    ages["charlie"] = 35

    // Set
    var tags: Set<String> = ["swift", "slang", "swift"]  // deduplicates
    print("Tag count: \(tags.count)")  // 2
    var hasSwift: Bool = tags.contains("swift")
    print("Has swift: \(hasSwift)")
}
```

---

## Acceptance Criteria

### Phase 8.1 - Optional
- [x] `T?` type annotation works
- [x] `nil` literal works
- [x] `T` can be assigned to `T?`
- [x] `nil` can be assigned to any `T?`
- [x] Nil comparison: `x == nil` and `x != nil`
- [x] Switch statement on optionals with `some`/`none` patterns
- [x] Switch expression on optionals
- [x] Type narrowing: in `some` branch, variable is unwrapped type
- [x] Exhaustiveness checking for optional switch
- [x] Type errors for mismatched optional types

### Phase 8.2 - Array
- [x] Array literals parse and evaluate correctly
- [x] Array subscript read works: `arr[0]`
- [x] Array subscript write works: `arr[0] = 5`
- [x] Out-of-bounds causes runtime error
- [x] Array type annotations work: `[Int]`, `[[String]]`
- [x] Empty arrays require explicit type
- [x] `.count` and `.isEmpty` work

### Phase 8.3 - Dictionary
- [x] Dictionary literals parse and evaluate
- [x] Dictionary subscript returns `Optional<Value>`
- [x] Missing key returns `nil`
- [x] Dictionary subscript assignment works
- [x] Empty dictionary `[:]` works
- [x] Key types restricted to primitives

### Phase 8.4 - Set
- [x] Set creation from array literal with deduplication
- [x] `.contains()` method works
- [x] `.insert()` and `.remove()` work
- [x] `.count` and `.isEmpty` work
- [x] Element types restricted to primitives

### Phase 8.5 - Methods
- [x] `array.append()` works
- [x] `array.removeAt()` works
- [x] `array.first` and `array.last` return optionals
- [x] `dict.keys` and `dict.values` work
- [x] `dict.removeKey()` works

### General
- [x] Type checker catches type mismatches
- [x] No type inference anywhere — all types explicit
- [x] Comprehensive test coverage

### Known Limitations
- Nested optionals (`Int??`) are not supported
- Arrays of optionals (`[Int?]`) require all elements to be wrapped explicitly
