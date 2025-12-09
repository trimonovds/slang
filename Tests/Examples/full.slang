// Full example program for Slang v0.1

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
