package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("Conway's Game of Life!")
	grid := NewGridFromFile("../seeds/oscillate.txt")
	fmt.Println(grid)
	for {
		fmt.Print("\033[H\033[2J")
		grid.step()
		fmt.Println(grid)
		time.Sleep(1000 * time.Millisecond)
	}
}
