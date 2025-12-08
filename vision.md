# SLANG - Simple programming language
Easy to implement, easy to use!

## Vision
- more convenient then c, more simple then swift
- simple: syntax basically like c but with some features from swift like unions (enums with associated values) with syntaxis like in typescript
- built in types: Int, Float, String, Bool (like in swift)
- no classes - only functions and structs/enums/unions - not sure about enums/unions (i want syntaxis from typescript, but have both enum and union is absurd i think... probably swift enums with associated values are better, but i want typescript syntax for "difficult" unions and enum syntax for "basic" enums... need help here)
- i think it must be compiled (use llvm as a backend), but it would be greate to have an opportunity to run .slang files like python (i hope you will help me to figure out how to make it possible and which functionality must be implemented first)
- directory based modules system (my dream) - each folder must be a module by default. i'm not sure if i want to have manifest - something like Package.swift in swift package manager, but if it helps with implementation, i'm ok with it. i think it should help indexing be based only on file location, but i'm not sure yet. i like library/executable targets in swift package manager... maybe it woult be cool if to implement it similar to python but without ugly `if __name__ == 'main'
- i like single tool for dependencies and build like cargo or swift package manager. it would be nice if it could format code in single "right" format etc
- `.slang` extension for files
- i'm not sure if i want "stdlib" to be a library, but i want to be able to add functionality to slang as separate libs with its own versioning
- i want LSP support to be easily implemented (so i have syntax highlighting, jump to definition, find reference etc in vscode as soon as possible)
- at start everything must be public. in future it would be greate to add internal (or package) - i like how its done in swift, but i don't think adding public to each public func/struct is convinient - i think its better to hide what should be hidden
- Unions (enums with Associated values): i want syntaxis to be like `union A = B | C` (i'm not sure about keyword - should it be union or type or enum...)
- Optionals - ideally it should be implemented as in Swift (just generic enum/union), but as soon, as generics are difficult to implement it would be ok, to make more verbose and do concrete union for each new return type (`enum None { case instance }` or `struct None` as `nil` analogue in Swift lgtm but i'm not sure how easy it is to implement)
- variables must be initialized when defined
- contol flow: `if/else if/else`, `switch`, `for` (only c-like, no foreach)
- ideally arrays, dictionaries like in swift, but it needs generic - i'm not sure how to do it (maybe simplest possible generic should be added - i need help here)

## Code examples

```slang

enum Color {
    case red
    case green
    case blue
}

union Pet = Dog | Cat

struct Dog { var name }
struct Cat { var name }

struct Person {
    var name: String
    var age: Int
    var pet: Pet
}

func add(a: Int, b: Int) -> Int {
    return a + b // No implicit return
}

func sayHelloToPet(person: Person) {
    switch person.pet {
    case let .dog(dog): print("Hi $(dog.name)!")
    case let .cat(cat): print("Hi $(cat.name)!")
    }
}
```