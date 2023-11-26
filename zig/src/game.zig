const std = @import("std");
const expect = std.testing.expect;

const GridOrdering = enum {
    row_major,
    column_major,
};

const GridError = error{
    IndexOutOfBounds,
};

fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T,
        shape: [2]usize,
        ordering: GridOrdering,

        pub fn init(data: []T, shape: [2]usize, ordering: GridOrdering) Self {
            const len = shape[0] * shape[1];
            return Self{
                .data = data[0..len],
                .shape = shape,
                .ordering = ordering,
            };
        }

        /// Returns the value in the grid at the given coordinates.
        pub fn get(self: Self, x: usize, y: usize) !T {
            const idx = self.index(x, y);
            if (idx >= self.data.len) {
                return error.IndexOutOfBounds;
            }
            return self.data[idx];
        }

        /// Sets the value in the grid at the given coordinates.
        pub fn set(self: Self, x: usize, y: usize, value: T) !void {
            const idx = self.index(x, y);
            if (idx >= self.data.len) {
                return error.IndexOutOfBounds;
            }
            self.data[idx] = value;
        }

        /// Returns the index in the data array for the
        /// given coordinates according to the memory ordering.
        fn index(self: Self, x: usize, y: usize) usize {
            switch (self.ordering) {
                .row_major => return x * self.shape[0] + y,
                .column_major => return y * self.shape[1] + x,
            }
        }
    };
}

const Cell = enum {
    alive,
    dead,
};

const ConwayGrid = Grid(Cell);

test "grid creation" {
    const IntGrid = Grid(i32);
    var data = [_]i32{ 1, 2, 3, 4 };
    const grid = IntGrid.init(
        data[0..data.len],
        .{ 2, 2 },
        .row_major,
    );
    try expect(grid.data[0] == data[0]);
}

test "grid set" {
    const IntGrid = Grid(i32);
    var data = [_]i32{ 1, 2, 3, 4 };
    const grid = IntGrid.init(
        data[0..data.len],
        .{ 2, 2 },
        .row_major,
    );
    try grid.set(0, 0, 5);
    try expect(grid.data[0] == 5);
}

test "grid ordering" {
    const IntGrid = Grid(i32);
    var data = [_]i32{ 1, 2, 3, 4 };
    var grid = IntGrid.init(
        data[0..data.len],
        .{ 2, 2 },
        .row_major,
    );
    try expect(try grid.get(0, 0) == 1);
    try expect(try grid.get(0, 1) == 2);
    try expect(try grid.get(1, 0) == 3);
    try expect(try grid.get(1, 1) == 4);
    grid.ordering = .column_major;
    try expect(try grid.get(0, 0) == 1);
    try expect(try grid.get(0, 1) == 3);
    try expect(try grid.get(1, 0) == 2);
    try expect(try grid.get(1, 1) == 4);
}
