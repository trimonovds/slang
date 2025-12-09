// Demonstrates for loops

func main() {
    // Count up
    print("Counting up:")
    for (var i: Int = 1; i <= 5; i = i + 1) {
        print("\(i)")
    }

    // Count down
    print("Counting down:")
    for (var i: Int = 5; i >= 1; i = i - 1) {
        print("\(i)")
    }

    // Sum numbers 1 to 10
    var sum: Int = 0
    for (var i: Int = 1; i <= 10; i = i + 1) {
        sum = sum + i
    }
    print("Sum of 1 to 10: \(sum)")

    // Multiplication table
    print("5 times table:")
    for (var i: Int = 1; i <= 5; i = i + 1) {
        print("5 x \(i) = \(5 * i)")
    }
}
