//! Conway's Game of Life implementation

use crate::grid::{Coord, Grid, GridError};
use std::convert::TryFrom;
use std::fmt;
use std::fmt::{Debug, Display};
use std::fs;
use std::path::Path;
use std::str::FromStr;

#[derive(Copy, Clone, PartialEq)]
pub enum Cell {
    Alive,
    Dead,
}

macro_rules! impl_fmt_cell {
    ($trait:ident, $cell_alive:expr, $cell_dead:expr) => {
        impl $trait for Cell {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                match *self {
                    Cell::Alive => write!(f, $cell_alive),
                    Cell::Dead => write!(f, $cell_dead),
                }
            }
        }
    };
}

impl_fmt_cell!(Display, "1", "0");
impl_fmt_cell!(Debug, "#", ".");

pub type ConwayGrid = Grid<Cell>;

impl ConwayGrid {
    /// Constructs a ConwayGrid from an input file of 0s and 1s,
    /// where 0s are dead cells and 1s are alive cells.
    pub fn from_file(path: &Path) -> Self {
        let content = fs::read_to_string(path).expect("Cannot open file");
        let grid_vec: Vec<Vec<&str>> = content
            .split('\n')
            .map(|s| s.split(' ').collect())
            .collect();

        let mut grid = Grid::new(grid_vec[0].len(), grid_vec.len(), Cell::Dead);
        grid_vec.iter().enumerate().for_each(|(i, row)| {
            row.iter().enumerate().for_each(|(j, s)| {
                let cell_number = usize::from_str(s).expect("Cannot parse input");
                match cell_number {
                    0 => {}
                    1 => grid.set((j, i), Cell::Alive).unwrap(),
                    _ => panic!("Wrong cell state parsed."),
                }
            })
        });

        grid
    }

    pub fn step(&mut self) -> Result<(), GridError> {
        let grid_copy = self.clone();
        for row in 0..self.height() {
            for col in 0..self.width() {
                match self.update_cell((col, row), &grid_copy) {
                    Ok(_) => {}
                    Err(e) => return Err(e),
                };
            }
        }
        Ok(())
    }

    fn update_cell(&mut self, coord: Coord, old_grid: &ConwayGrid) -> Result<(), GridError> {
        let new_state = match (
            old_grid.count_alive_neighbours(coord),
            old_grid.get(coord).unwrap(),
        ) {
            (2, Cell::Alive) => Cell::Alive,
            (3, Cell::Alive) => Cell::Alive,
            (3, Cell::Dead) => Cell::Alive,
            (_, Cell::Alive) => Cell::Dead,
            (_, _) => Cell::Dead,
        };
        self.set(coord, new_state)
    }

    /// Counts the number of alive neighbours of the given cell.
    fn count_alive_neighbours(&self, (col, row): Coord) -> usize {
        let (c, r) = (col as i32, row as i32);
        let neighbours: Vec<(i32, i32)> = vec![
            (c - 1, r - 1),
            (c, r - 1),
            (c + 1, r - 1),
            (c - 1, r),
            (c + 1, r),
            (c - 1, r + 1),
            (c, r + 1),
            (c + 1, r + 1),
        ];
        neighbours
            .iter()
            .filter(|(c, r)| {
                let col = match usize::try_from(*c) {
                    Ok(val) => val,
                    Err(_) => return false,
                };
                let row = match usize::try_from(*r) {
                    Ok(val) => val,
                    Err(_) => return false,
                };
                self.is_alive((col, row))
            })
            .count()
    }

    /// Returns true if a cell at a given coordinate is alive.
    fn is_alive(&self, coord: Coord) -> bool {
        match self.get(coord) {
            Ok(val) => *val == Cell::Alive,
            Err(_) => false,
        }
    }
}

macro_rules! impl_fmt_conway_grid {
    ($trait:ident, $str:expr) => {
        impl $trait for ConwayGrid {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                // plus one is for the newlines
                let string_size = (self.width() + 1) * self.height();
                let mut grid_display = String::with_capacity(string_size);

                for row in 0..self.height() {
                    for col in 0..=self.width() {
                        if col == self.width() {
                            grid_display += "\n";
                        } else {
                            match self.get((col, row)).unwrap() {
                                Cell::Alive => grid_display += format!($str, Cell::Alive).as_str(),
                                Cell::Dead => grid_display += format!($str, Cell::Dead).as_str(),
                            }
                        }
                    }
                }

                write!(f, "{}", grid_display)
            }
        }
    };
}

impl_fmt_conway_grid!(Display, "{}");
impl_fmt_conway_grid!(Debug, "{:?}");

#[cfg(test)]
mod tests {
    use crate::conway::{Cell, ConwayGrid};
    use rstest::*;
    use std::path::Path;

    #[fixture]
    pub fn grid() -> ConwayGrid {
        let path = Path::new("./seeds/test.txt");
        ConwayGrid::from_file(path)
    }

    #[rstest]
    pub fn test_creation(grid: ConwayGrid) {
        assert_eq!(grid.width(), 5);
        assert_eq!(grid.height(), 5);
        assert_eq!(*grid.get((2, 0)).unwrap(), Cell::Alive);
        assert_eq!(*grid.get((1, 1)).unwrap(), Cell::Alive);
        assert_eq!(*grid.get((3, 1)).unwrap(), Cell::Alive);
        assert_eq!(*grid.get((1, 3)).unwrap(), Cell::Alive);
    }

    #[rstest]
    pub fn test_count_alive_neighbours(grid: ConwayGrid) {
        assert_eq!(grid.count_alive_neighbours((1, 0)), 2);
        assert_eq!(grid.count_alive_neighbours((1, 1)), 1);
        assert_eq!(grid.count_alive_neighbours((1, 3)), 0);
        assert_eq!(grid.count_alive_neighbours((4, 4)), 0);
    }
}
