//! Conway's Game of Life implementation

use crate::grid::Grid;
use std::fmt;

#[derive(Debug, Copy, Clone)]
pub enum Cell {
    Alive,
    Dead,
}

impl fmt::Display for Cell {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match *self {
            Cell::Alive => write!(f, "\u{2B1C}"),
            Cell::Dead => write!(f, "\u{2B1B}"),
        }
    }
}

pub type ConwayGrid = Grid<Cell>;

impl ConwayGrid {}

impl fmt::Display for ConwayGrid {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        // plus one is for the newlines
        let string_size = (self.width() + 1) * self.height();
        let mut grid_display = String::with_capacity(string_size);

        for i in 0..self.height() {
            for j in 0..=self.height() {
                if j == self.width() {
                    grid_display += "\n";
                } else {
                    match self.get((i, j)).unwrap() {
                        Cell::Alive => { grid_display += format!("{}", Cell::Alive).as_str() }
                        Cell::Dead => { grid_display += format!("{}", Cell::Dead).as_str() }
                    }
                }
            }
        }

        write!(f, "{}", grid_display)
    }
}
