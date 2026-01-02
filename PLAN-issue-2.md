# Implementation Plan: Add Array/Set/Dictionary (Issue #2)

This plan outlines the implementation of collection types for the Slang language.

## Overview

Add three collection types to Slang:
- **Array**: Ordered, indexed collection of homogeneous elements
- **Set**: Unordered collection of unique elements
- **Dictionary**: Key-value pairs with homogeneous keys and values

## Proposed Syntax

```slang
// Array
var numbers: [Int] = [1, 2, 3, 4, 5]
var first: Int = numbers[0]
numbers[0] = 10

// Set
var tags: Set<String> = Set<String>{"swift", "slang"}
var hasTag: Bool = tags.contains("swift")

// Dictionary
var ages: [String: Int] = ["alice": 30, "bob": 25]
var aliceAge: Int = ages["alice"]
ages["charlie"] = 35
```

## Implementation Phases

---

## Phase 1: Array Type (Foundation)

Arrays are the most fundamental collection and will establish patterns for the others.

### Step 1.1: Add Tokens (Lexer)

**File**: `Sources/SlangCore/Lexer/Token.swift`

Add new token kinds:
```swift
case leftBracket     // [
case rightBracket    // ]
```

**File**: `Sources/SlangCore/Lexer/Lexer.swift`

Add scanning for `[` and `]` characters in the main scan switch.

### Step 1.2: Add Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

Add to `SlangType` enum:
```swift
case arrayType(elementType: SlangType)
```

Update `description` property to return `"[\(elementType)]"` format.

### Step 1.3: Add Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

Add to `Value` enum:
```swift
case arrayInstance(elements: [Value])
```

Update `description` and `stringify()` to format arrays as `[elem1, elem2, ...]`.

### Step 1.4: Add AST Nodes

**File**: `Sources/SlangCore/Parser/AST.swift`

Add to `ExpressionKind`:
```swift
case arrayLiteral(elements: [Expression])
case subscriptAccess(object: Expression, index: Expression)
```

Extend `TypeAnnotation` to support array type syntax `[ElementType]`:
- Either modify `TypeAnnotation` to have an optional element type
- Or create a new `TypeSyntax` enum that can represent compound types

### Step 1.5: Parser Changes

**File**: `Sources/SlangCore/Parser/Parser.swift`

1. **Parse array literals** in `parsePrimary()`:
   - When encountering `[`, parse comma-separated expressions until `]`
   - Handle empty arrays: `[]`

2. **Parse subscript access** in `parseCall()`:
   - After parsing primary expression, check for `[`
   - Parse index expression, consume `]`
   - Create `subscriptAccess` node

3. **Parse array type annotations**:
   - Modify `parseTypeAnnotation()` to handle `[Type]` syntax
   - Return appropriate type annotation structure

### Step 1.6: Type Checker Changes

**File**: `Sources/SlangCore/TypeChecker/TypeChecker.swift`

1. **Type resolution**: Handle array type annotations, resolve element type recursively

2. **Check array literals**:
   - Infer element type from first element (or from context if empty)
   - Verify all elements have same type
   - Return `arrayType(elementType:)`

3. **Check subscript access**:
   - Verify object is array type
   - Verify index is `Int`
   - Return element type

4. **Built-in properties/methods** (member access):
   - `array.count` → `Int`
   - `array.isEmpty` → `Bool`

### Step 1.7: Interpreter Changes

**File**: `Sources/SlangCore/Interpreter/Interpreter.swift`

1. **Evaluate array literals**: Evaluate each element, create `arrayInstance`

2. **Evaluate subscript access**:
   - Get array value
   - Get index value
   - Bounds check (runtime error if out of bounds)
   - Return element at index

3. **Evaluate subscript assignment**:
   - Handle `array[i] = value` in assignment evaluation
   - Bounds check
   - Mutate array

4. **Built-in properties**:
   - Handle `array.count` and `array.isEmpty` in member access

### Step 1.8: Tests

**File**: `Tests/SlangCoreTests/ArrayTests.swift`

Test cases:
- Array literal parsing and evaluation
- Array type annotation parsing
- Subscript read access
- Subscript write access (mutation)
- Bounds checking (runtime error)
- Empty arrays
- Nested arrays `[[Int]]`
- Type checking errors (mixed element types)
- `.count` and `.isEmpty` properties

---

## Phase 2: Dictionary Type

### Step 2.1: Type Representation

**File**: `Sources/SlangCore/TypeChecker/Type.swift`

```swift
case dictionaryType(keyType: SlangType, valueType: SlangType)
```

Description: `"[\(keyType): \(valueType)]"` (Swift-style)

### Step 2.2: Runtime Value

**File**: `Sources/SlangCore/Interpreter/Value.swift`

```swift
case dictionaryInstance(pairs: [(key: Value, value: Value)])
```

Note: Using array of tuples rather than Dictionary since `Value` would need `Hashable` conformance, which is complex for struct/enum instances.

### Step 2.3: AST Nodes

**File**: `Sources/SlangCore/Parser/AST.swift`

```swift
case dictionaryLiteral(pairs: [(key: Expression, value: Expression)])
```

### Step 2.4: Parser Changes

1. **Disambiguate `[` token**:
   - `[expr, expr, ...]` → array literal
   - `[key: value, ...]` → dictionary literal
   - `[:]` → empty dictionary
   - Look ahead after first expression to check for `:`

2. **Parse dictionary type annotations**: `[KeyType: ValueType]`

### Step 2.5: Type Checker Changes

1. **Validate key types**: Only allow hashable types as keys (primitives: Int, String, Bool)
2. **Check all keys have same type, all values have same type**
3. **Subscript access returns optional or error on missing key** (design decision needed)

### Step 2.6: Interpreter Changes

1. **Evaluate dictionary literals**
2. **Subscript access**: Linear search through pairs (or implement proper hashing)
3. **Subscript assignment**: Update existing or add new pair

### Step 2.7: Tests

- Dictionary literal parsing
- Key-value access
- Missing key handling
- Type checking for keys/values
- Nested dictionaries

---

## Phase 3: Set Type

### Step 3.1: Syntax Decision

Sets need distinct syntax from arrays. Options:
- **Option A**: `Set<Int>{1, 2, 3}` (explicit type constructor)
- **Option B**: `{1, 2, 3}` with type annotation (ambiguous with blocks)
- **Option C**: `#[1, 2, 3]` (new syntax)

**Recommended**: Option A - explicit and unambiguous

### Step 3.2: Type Representation

```swift
case setType(elementType: SlangType)
```

### Step 3.3: Runtime Value

```swift
case setInstance(elements: [Value])  // Use array, enforce uniqueness at runtime
```

### Step 3.4: Built-in Operations

- `set.contains(element)` → Bool
- `set.count` → Int
- `set.isEmpty` → Bool
- `set.insert(element)` → mutating
- `set.remove(element)` → mutating

### Step 3.5: Type Constraints

Only allow hashable/equatable element types (primitives).

---

## Phase 4: Advanced Features (Optional/Future)

### 4.1: Array Methods
- `array.append(element)`
- `array.insert(element, at: index)`
- `array.remove(at: index)`
- `array.first`, `array.last` (optional return type needed)

### 4.2: Iteration Support
- `for item in array { ... }` syntax
- `for (key, value) in dictionary { ... }`
- Requires adding for-in loop variant

### 4.3: Array/Collection Literals with Type Inference
- `var x = [1, 2, 3]` infers `[Int]`
- `var y: [Int] = []` empty with explicit type

### 4.4: Optional Type for Safe Access
- `array.first` returns `Optional<T>`
- `dictionary[key]` returns `Optional<V>`
- Requires implementing optional types first

---

## File Change Summary

| File | Changes |
|------|---------|
| `Token.swift` | Add `leftBracket`, `rightBracket` |
| `Lexer.swift` | Scan `[` and `]` |
| `Type.swift` | Add `arrayType`, `dictionaryType`, `setType` |
| `Value.swift` | Add `arrayInstance`, `dictionaryInstance`, `setInstance` |
| `AST.swift` | Add `arrayLiteral`, `dictionaryLiteral`, `subscriptAccess`; extend type annotations |
| `Parser.swift` | Parse array/dict literals, subscripts, compound type annotations |
| `TypeChecker.swift` | Check collection types, subscript access, built-in properties |
| `Interpreter.swift` | Evaluate collections, subscript access/assignment, built-in properties |
| New: `ArrayTests.swift` | Array test cases |
| New: `DictionaryTests.swift` | Dictionary test cases |
| New: `SetTests.swift` | Set test cases |
| `Examples/` | Add example `.slang` files demonstrating collections |

---

## Implementation Order

1. **Phase 1 (Arrays)**: Complete implementation including tests
2. **Phase 2 (Dictionaries)**: Build on array infrastructure
3. **Phase 3 (Sets)**: Add set-specific syntax and semantics
4. **Phase 4 (Advanced)**: Methods, iteration, etc. (future work)

Each phase should be a separate PR to keep changes reviewable.

---

## Open Design Questions

1. **Empty collection type inference**: How to handle `var x = []`? Require explicit type?
2. **Dictionary missing key**: Return error, nil/optional, or crash?
3. **Set syntax**: Which option (A/B/C) is preferred?
4. **Mutability**: Are collections mutable by default? Copy-on-write semantics?
5. **Iteration**: Should for-in loops be part of initial implementation?

---

## Success Criteria

- [ ] Array literals parse and evaluate correctly
- [ ] Array subscript read/write works
- [ ] Array type annotations work
- [ ] Dictionary literals parse and evaluate
- [ ] Dictionary subscript access works
- [ ] Set creation and membership testing work
- [ ] All collection types have `.count` and `.isEmpty`
- [ ] Type checker catches type mismatches
- [ ] Runtime errors for out-of-bounds access
- [ ] Comprehensive test coverage
- [ ] Example programs in `Tests/Examples/`
