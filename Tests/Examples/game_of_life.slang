// Conway's Game of Life - demonstrates arrays, optionals, and control flow

func main() {
    // Create a 5x5 grid (represented as array of arrays)
    // 1 = alive, 0 = dead
    // Starting with a "blinker" pattern (oscillates)
    var grid: [[Int]] = [
        [0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 0, 0]
    ]

    print("=== Game of Life ===")
    print("Initial state:")
    printGrid(grid)

    // Run 3 generations
    for (var gen: Int = 1; gen <= 3; gen = gen + 1) {
        grid = nextGeneration(grid)
        print("Generation \(gen):")
        printGrid(grid)
    }

    print("=== Done ===")
}

func printGrid(grid: [[Int]]) {
    for (var row: Int = 0; row < 5; row = row + 1) {
        var line: String = ""
        for (var col: Int = 0; col < 5; col = col + 1) {
            var cell: Int = grid[row][col]
            if (cell == 1) {
                line = line + "#"
            } else {
                line = line + "."
            }
        }
        print(line)
    }
}

func nextGeneration(grid: [[Int]]) -> [[Int]] {
    // Create new grid
    var newGrid: [[Int]] = [
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0]
    ]

    for (var row: Int = 0; row < 5; row = row + 1) {
        for (var col: Int = 0; col < 5; col = col + 1) {
            var neighbors: Int = countNeighbors(grid, row, col)
            var alive: Int = grid[row][col]

            // Apply rules:
            // 1. Live cell with 2-3 neighbors survives
            // 2. Dead cell with exactly 3 neighbors becomes alive
            // 3. All other cells die or stay dead
            if (alive == 1) {
                if (neighbors == 2) {
                    newGrid[row][col] = 1
                } else {
                    if (neighbors == 3) {
                        newGrid[row][col] = 1
                    } else {
                        newGrid[row][col] = 0
                    }
                }
            } else {
                if (neighbors == 3) {
                    newGrid[row][col] = 1
                } else {
                    newGrid[row][col] = 0
                }
            }
        }
    }

    return newGrid
}

func countNeighbors(grid: [[Int]], row: Int, col: Int) -> Int {
    var count: Int = 0

    // Check all 8 directions
    for (var dr: Int = -1; dr <= 1; dr = dr + 1) {
        for (var dc: Int = -1; dc <= 1; dc = dc + 1) {
            // Skip the cell itself
            if (dr == 0) {
                if (dc == 0) {
                    // skip this iteration - do nothing
                } else {
                    var nr: Int = row + dr
                    var nc: Int = col + dc
                    // Check bounds
                    if (nr >= 0) {
                        if (nr < 5) {
                            if (nc >= 0) {
                                if (nc < 5) {
                                    count = count + grid[nr][nc]
                                }
                            }
                        }
                    }
                }
            } else {
                var nr: Int = row + dr
                var nc: Int = col + dc
                // Check bounds
                if (nr >= 0) {
                    if (nr < 5) {
                        if (nc >= 0) {
                            if (nc < 5) {
                                count = count + grid[nr][nc]
                            }
                        }
                    }
                }
            }
        }
    }

    return count
}
