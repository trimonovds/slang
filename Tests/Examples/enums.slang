// Demonstrates enum and switch

enum TrafficLight {
    case red
    case yellow
    case green
}

func describe(light: TrafficLight) -> String {
    var result: String = ""
    switch (light) {
        TrafficLight.red -> result = "Stop"
        TrafficLight.yellow -> result = "Caution"
        TrafficLight.green -> result = "Go"
    }
    return result
}

func main() {
    var light: TrafficLight = TrafficLight.red
    print("Red means: \(describe(light))")

    light = TrafficLight.yellow
    print("Yellow means: \(describe(light))")

    light = TrafficLight.green
    print("Green means: \(describe(light))")
}
