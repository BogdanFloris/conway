package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strconv"
	"strings"
)

type CellState uint

const (
	Dead  CellState = 0
	Alive CellState = 1
)

func (c CellState) String() string {
	switch c {
	case Dead:
		return "."
	case Alive:
		return "#"
	default:
		return fmt.Sprintf("%d", int(c))
	}
}

type ConwayGrid struct {
	width  uint
	height uint
	data   [][]CellState
}

func (cg ConwayGrid) String() string {
	var stringGird string
	for _, row := range cg.data {
		for _, cell := range row {
			stringGird += fmt.Sprintf("%s", cell)
		}
		stringGird += "\n"
	}
	return stringGird
}

func (cg ConwayGrid) step() {
	oldGridData := make([][]CellState, len(cg.data), len(cg.data[0]))
	copy(oldGridData, cg.data)
	oldGrid := ConwayGrid{cg.width, cg.height, oldGridData}
	for r, _ := range cg.data {
		for c, _ := range cg.data[r] {
			cg.updateCell(r, c, &oldGrid)
		}
	}
}

func (cg ConwayGrid) updateCell(row int, col int, oldGrid *ConwayGrid) {
	aliveNeighbours := oldGrid.countAliveNeighbours(row, col)
	if aliveNeighbours == 3 && oldGrid.data[row][col] == Dead {
		cg.data[row][col] = Alive
	}
	if aliveNeighbours != 3 && aliveNeighbours != 2 && oldGrid.data[row][col] == Alive {
		cg.data[row][col] = Dead
	}
}

func (cg ConwayGrid) countAliveNeighbours(row int, col int) int {
	neighbours := [8][2]int{
		{row - 1, col - 1},
		{row - 1, col},
		{row - 1, col + 1},
		{row, col - 1},
		{row, col + 1},
		{row + 1, col - 1},
		{row + 1, col},
		{row + 1, col + 1},
	}
	aliveNeighbours := 0
	for _, neighbour := range neighbours {
		r := neighbour[0]
		c := neighbour[1]
		if r >= 0 && r < len(cg.data) && c >= 0 && c < len(cg.data[0]) {
			if cg.isAlive(r, c) {
				aliveNeighbours += 1
			}
		}
	}
	return aliveNeighbours
}

func (cg ConwayGrid) isAlive(row int, col int) bool {
	return cg.data[row][col] == Alive
}

func NewGridFromFile(path string) *ConwayGrid {
	gridFile, err := os.Open(path)
	if err != nil {
		log.Fatal(err)
	}
	data, err := ioutil.ReadAll(gridFile)
	if err != nil {
		log.Fatal(err)
	}
	cellStates := make([][]CellState, 0)
	rows := strings.Split(string(data), "\n")
	for i, row := range rows {
		cellStates = append(cellStates, make([]CellState, 0))
		cells := strings.Split(row, " ")
		for _, cell := range cells {
			cellInt, err := strconv.Atoi(cell)
			if err != nil {
				log.Fatal(err)
			}
			if cellInt == 0 {
				cellStates[i] = append(cellStates[i], Dead)
			} else if cellInt == 1 {
				cellStates[i] = append(cellStates[i], Alive)
			}
		}
	}
	height := uint(len(cellStates))
	width := uint(len(cellStates[0]))
	grid := ConwayGrid{width, height, cellStates}
	return &grid
}
