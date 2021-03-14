//! Conway's Game of Life implementation

use crate::grid::Grid;
use std::fmt;
use std::fmt::{Debug, Display};
use std::fs;
use std::path::Path;
use std::str::FromStr;

#[derive(Copy, Clone)]
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
                    1 => grid.set((i, j), Cell::Alive).unwrap(),
                    _ => panic!("Wrong cell state parsed."),
                }
            })
        });

        grid
    }
}

macro_rules! impl_fmt_conway_grid {
    ($trait:ident, $str:expr) => {
        impl $trait for ConwayGrid {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                // plus one is for the newlines
                let string_size = (self.width() + 1) * self.height();
                let mut grid_display = String::with_capacity(string_size);

                for i in 0..self.height() {
                    for j in 0..=self.width() {
                        if j == self.width() {
                            grid_display += "\n";
                        } else {
                            match self.get((i, j)).unwrap() {
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
