// Fibonacci sequence using recursion

func fib(n: Int) -> Int {
    if (n <= 1) {
        return n
    }
    return fib(n - 1) + fib(n - 2)
}

func main() {
    print("Fibonacci sequence:")
    for (var i: Int = 0; i < 10; i = i + 1) {
        print("fib(\(i)) = \(fib(i))")
    }
}
