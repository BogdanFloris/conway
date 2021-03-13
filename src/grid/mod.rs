/// Represents a two dimensional coordinate.
pub type Coord = (usize, usize);

/// Enum used to represent different grid errors.
pub enum GridError {
    IndexOutOfBounds,
}

/// A generic fixed size two-dimensional grid.
///
/// Uses a one-dimensional vector to hold the data,
/// in order to be more performant.
#[derive(Clone, Debug, Default, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct Grid<T> {
    width: usize,
    height: usize,
    data: Vec<T>,
}

impl<T> Grid<T> where T: Copy {
    /// Creates a new Grid<T> of size (width, height)
    /// with a default value for T.
    pub fn new(width: usize, height: usize, default: T) -> Self {
        Self {
            width,
            height,
            data: vec![default; width * height],
        }
    }
}

impl<T> Grid<T> {
    /// Two dimensional coordinate to one dimensional index.
    fn flatten(&self, (col, row): Coord) -> usize {
        col + self.width * row
    }

    /// Get an immutable reference to a grid cell.
    pub fn get(&self, coord: Coord) -> Result<&T, GridError> {
        match self.data.get(self.flatten(coord)) {
            Some(val) => Ok(val),
            None => Err(GridError::IndexOutOfBounds),
        }
    }

    /// Get a mutable reference to a grid cell.
    fn get_mut(&mut self, coord: Coord) -> Result<&mut T, GridError> {
        let flattened_index = self.flatten(coord);
        match self.data.get_mut(flattened_index) {
            Some(val) => Ok(val),
            None => Err(GridError::IndexOutOfBounds),
        }
    }

    /// Get the width of the grid.
    pub fn width(&self) -> usize {
        self.width
    }

    /// Get the height of the grid.
    pub fn height(&self) -> usize {
        self.height
    }

    /// Determines if the given coordinate is valid in the grid.
    pub fn is_valid_coord(&self, (col, row): Coord) -> bool {
        col < self.width && row < self.height
    }

    pub fn set(&mut self, coord: Coord, new: T) -> Result<(), GridError> {
        match self.get_mut(coord) {
            Ok(val) => {
                *val = new;
                Ok(())
            },
            Err(err) => Err(err),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new() {
        let grid = Grid::new(1, 1, 0);
        assert_eq!(grid.width(), 1);
        assert_eq!(grid.height(), 1);
        assert!(grid.get((0, 0)).is_ok());
        assert!(grid.get((0, 1)).is_err());
        match grid.get((0, 0)) {
            Ok(val) => assert_eq!(*val, 0),
            Err(_) => panic!(),
        };
    }

    #[test]
    fn test_is_valid_coord() {
        let grid = Grid::new(1, 1, 0);
        assert!(grid.is_valid_coord((0, 0)));
        assert!(!grid.is_valid_coord((0, 1)));
    }

    #[test]
    fn test_set() {
        let mut grid = Grid::new(1, 1, 0);
        match grid.get((0, 0)) {
            Ok(val) => assert_eq!(*val, 0),
            Err(_) => panic!(),
        };
        match grid.set((0, 0), 1) {
            Ok(_) => {
                match grid.get((0, 0)) {
                    Ok(val) => assert_eq!(*val, 1),
                    Err(_) => panic!(),
                };
            },
            Err(_) => panic!(),
        };
    }
}
