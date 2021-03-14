use conway_rs::conway::{ConwayGrid, Cell};

fn main() {
    let mut grid = ConwayGrid::new(10, 10, Cell::Dead);
    grid.set((1, 2), Cell::Alive).unwrap();
    grid.set((3, 6), Cell::Alive).unwrap();
    grid.set((8, 2), Cell::Alive).unwrap();
    print!("{}", grid);
}
