use conway_rs::conway::ConwayGrid;
use std::path::Path;

use std::{thread, time};

fn main() {
    let path = Path::new("./seeds/spaceship.txt");
    let mut grid = ConwayGrid::from_file(path);
    print!("{esc}[2J{esc}[1;1H", esc = 27 as char);
    loop {
        grid.step().unwrap();
        print!("{:?}", grid);
        print!("{esc}[2J{esc}[1;1H", esc = 27 as char);
        thread::sleep(time::Duration::from_secs_f64(0.1));
    }
}
