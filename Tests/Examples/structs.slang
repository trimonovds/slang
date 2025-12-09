// Demonstrates struct usage

struct Point {
    x: Int
    y: Int
}

func describe(p: Point) -> String {
    return "(\(p.x), \(p.y))"
}

func distance(p: Point) -> Int {
    // Simplified: just return sum of absolute values
    var absX: Int = p.x
    var absY: Int = p.y
    if (absX < 0) {
        absX = -absX
    }
    if (absY < 0) {
        absY = -absY
    }
    return absX + absY
}

func main() {
    var origin = Point { x: 0, y: 0 }
    print("Origin: \(describe(origin))")

    var p1 = Point { x: 3, y: 4 }
    print("Point 1: \(describe(p1))")
    print("Manhattan distance from origin: \(distance(p1))")

    var p2 = Point { x: -5, y: 10 }
    print("Point 2: \(describe(p2))")
    print("Manhattan distance from origin: \(distance(p2))")
}
