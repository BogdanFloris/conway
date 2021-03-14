use conway_rs::conway::ConwayGrid;
use std::path::Path;

fn main() {
    let path = Path::new("./seeds/tryout.txt");
    let grid = ConwayGrid::from_file(path);
    println!("{:?}", grid);
}
