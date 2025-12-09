// Demonstrates switch expressions (v0.1.1)
// Switch expressions return values and can be assigned to variables

enum Direction {
    case up
    case down
    case left
    case right
}

// Using switch expression to get opposite direction
func opposite(dir: Direction) -> Direction {
    return switch (dir) {
        Direction.up -> return Direction.down
        Direction.down -> return Direction.up
        Direction.left -> return Direction.right
        Direction.right -> return Direction.left
    }
}

// Using switch expression with block bodies
func directionValue(dir: Direction) -> Int {
    return switch (dir) {
        Direction.up -> { return 0 }
        Direction.down -> { return 1 }
        Direction.left -> { return 2 }
        Direction.right -> { return 3 }
    }
}

// Helper to print direction
func printDir(dir: Direction) {
    switch (dir) {
        Direction.up -> print("up")
        Direction.down -> print("down")
        Direction.left -> print("left")
        Direction.right -> print("right")
    }
}

func main() {
    var dir: Direction = Direction.up

    // Switch expression in variable initialization
    var opp: Direction = switch (dir) {
        Direction.up -> return Direction.down
        Direction.down -> return Direction.up
        Direction.left -> return Direction.right
        Direction.right -> return Direction.left
    }

    print("Original: up")
    print("Opposite:")
    printDir(opp)

    // Using the opposite function
    var leftDir: Direction = Direction.left
    var rightOpp: Direction = opposite(leftDir)
    print("Opposite of left:")
    printDir(rightOpp)

    // Switch expression returning Int
    var value: Int = directionValue(dir)
    print("Value of up: \(value)")
}
