// Demonstrates collection types: Optional, Array, Dictionary, Set

func main() {
    // === Optional ===
    print("=== Optional ===")
    var name: String? = nil
    var greeting: String? = "Hello"
    print("name is nil: true")
    print("greeting: some(Hello)")

    // Assign value to optional
    name = "World"
    print("name after assignment: some(World)")

    // === Array ===
    print("=== Array ===")
    var numbers: [Int] = [1, 2, 3, 4, 5]
    print("First: \(numbers[0])")
    print("Count: \(numbers.count)")
    print("isEmpty: \(numbers.isEmpty)")

    // Subscript assignment
    numbers[0] = 10
    print("After update: \(numbers[0])")

    // Array methods
    numbers.append(6)
    print("After append: \(numbers.count)")

    // first and last
    var first: Int? = numbers.first
    var last: Int? = numbers.last
    print("first: \(first)")
    print("last: \(last)")

    // Remove element
    numbers.removeAt(0)
    print("After removeAt(0): \(numbers[0])")

    // Empty array
    var empty: [Int] = []
    print("empty.isEmpty: \(empty.isEmpty)")
    var emptyFirst: Int? = empty.first
    print("empty.first is nil: true")

    // === Dictionary ===
    print("=== Dictionary ===")
    var ages: [String: Int] = ["alice": 30, "bob": 25]
    print("ages count: \(ages.count)")

    // Dictionary subscript returns Optional
    var aliceAge: Int? = ages["alice"]
    print("alice age: \(aliceAge)")

    var unknownAge: Int? = ages["unknown"]
    print("unknown age is nil: true")

    // Dictionary subscript assignment
    ages["charlie"] = 35
    print("After adding charlie: \(ages.count)")

    // Update existing key
    ages["alice"] = 31
    var updatedAge: Int? = ages["alice"]
    print("alice updated age: \(updatedAge)")

    // keys and values
    var keys: [String] = ages.keys
    var values: [Int] = ages.values
    print("keys count: \(keys.count)")
    print("values count: \(values.count)")

    // Remove key
    ages.removeKey("bob")
    print("After removing bob: \(ages.count)")

    // Empty dictionary
    var emptyDict: [String: Int] = [:]
    print("emptyDict.isEmpty: \(emptyDict.isEmpty)")

    // === Set ===
    print("=== Set ===")
    var tags: Set<String> = ["swift", "slang", "swift"]
    print("tags count (after dedup): \(tags.count)")
    print("tags.isEmpty: \(tags.isEmpty)")

    // contains
    var hasSwift: Bool = tags.contains("swift")
    var hasRust: Bool = tags.contains("rust")
    print("contains swift: \(hasSwift)")
    print("contains rust: \(hasRust)")

    // insert
    tags.insert("rust")
    print("After insert rust: \(tags.count)")

    // insert duplicate (should not change count)
    tags.insert("swift")
    print("After insert duplicate swift: \(tags.count)")

    // remove
    var removed: Bool = tags.remove("slang")
    print("Removed slang: \(removed)")
    print("After remove: \(tags.count)")

    // remove non-existent
    var removedNonExistent: Bool = tags.remove("nonexistent")
    print("Removed nonexistent: \(removedNonExistent)")

    // Empty set
    var emptySet: Set<Int> = []
    print("emptySet.isEmpty: \(emptySet.isEmpty)")

    print("=== Done ===")
}
