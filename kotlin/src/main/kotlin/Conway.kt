import java.io.File

enum class CellState(private val display: String) {
    ALIVE("1"), DEAD("0");

    override fun toString(): String {
        return display
    }
}

fun newConwayGameFromFile(filename: String): Conway {
    val grid = mutableListOf<MutableList<CellState>>()
    File(filename).forEachLine {
        val row = mutableListOf<CellState>()
        it.split(" ").forEach { cell ->
            when (cell) {
                "0" -> row.add(CellState.DEAD)
                "1" -> row.add(CellState.ALIVE)
                else -> throw IllegalArgumentException(cell)
            }
        }
        grid.add(row)
    }
    return Conway(grid[0].size, grid.size, grid)
}

class Conway(private val width: Int, private val height: Int, private val grid: MutableList<MutableList<CellState>>) {

    fun step() {
        val toUpdate = mutableListOf<Pair<Pair<Int, Int>, CellState>>()
        for (i in 0 until height) {
            for (j in 0 until width) {
                val aliveNeighbours = countAliveNeighbours(i, j)
                if (aliveNeighbours == 3 && grid[i][j] == CellState.DEAD) {
                    toUpdate.add(Pair(Pair(i, j), CellState.ALIVE))
                }
                if (aliveNeighbours != 3 && aliveNeighbours != 2 && grid[i][j] == CellState.ALIVE) {
                    toUpdate.add(Pair(Pair(i, j), CellState.DEAD))
                }
            }
        }
        updateCellsAfterStep(toUpdate)
    }

    private fun updateCellsAfterStep(cellsToUpdate: List<Pair<Pair<Int, Int>, CellState>>) {
        for ((cell, cellState) in cellsToUpdate) {
            grid[cell.first][cell.second] = cellState
        }
    }

    private fun isCellAlive(i: Int, j: Int): Boolean {
        return grid[i][j] == CellState.ALIVE
    }

    private fun countAliveNeighbours(i: Int, j: Int): Int {
        val neighbours = listOf(
            Pair(i - 1, j - 1),
            Pair(i - 1, j),
            Pair(i - 1, j + 1),
            Pair(i, j - 1),
            Pair(i, j + 1),
            Pair(i + 1, j - 1),
            Pair(i + 1, j),
            Pair(i + 1, j + 1)
        )
        var aliveNeighbours = 0
        for ((r, c) in neighbours) {
            if (r >= 0 && r < grid.size && c >= 0 && c < grid[0].size && isCellAlive(r, c)) {
                aliveNeighbours += 1
            }
        }
        return aliveNeighbours
    }

    override fun toString(): String {
        var str = ""
        for (line in grid) {
            for (cell in line) {
                str += "$cell "
            }
            str += "\n"
        }
        return str
    }
}