const std = @import("std");
const expect = std.testing.expect;

/// One megabyte
const mb = (1 << 10) << 10;
// Ansi escape codes
const esc = "\x1B";
const csi = esc ++ "[";
const screen_clear = csi ++ "2J" ++ csi ++ "H";
/// Sleep timer
const sleep_timer = 10_000_000;

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
        allocator: std.mem.Allocator,

        pub fn init(data: []T, shape: [2]usize, ordering: GridOrdering, allocator: std.mem.Allocator) Self {
            const len = shape[0] * shape[1];
            return Self{
                .data = data[0..len],
                .shape = shape,
                .ordering = ordering,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
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

const GameGrid = Grid(u8);

pub const Game = struct {
    const Self = @This();

    grid: GameGrid,
    allocator: std.mem.Allocator,

    pub fn init(absolute_path: []const u8, allocator: std.mem.Allocator) !Self {
        const file = try std.fs.openFileAbsolute(absolute_path, .{ .mode = .read_only });
        defer file.close();

        const content = try file.readToEndAlloc(allocator, 1 * mb);
        defer allocator.free(content);
        var lines = std.mem.splitSequence(u8, content, "\n");
        var rows: u32 = 0;
        var total: u32 = 0;
        var buffer = std.ArrayList(u8).init(allocator);
        while (lines.next()) |line| {
            var it = std.mem.splitSequence(u8, line, " ");
            while (it.next()) |char| {
                const cell = try std.fmt.parseInt(u8, char, 10);
                try buffer.append(cell);
                total += 1;
            }
            rows += 1;
        }

        const grid = GameGrid.init(try buffer.toOwnedSlice(), .{ rows, total / rows }, .row_major, allocator);
        return Self{
            .grid = grid,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.grid.deinit();
    }

    pub fn play(self: Self) !void {
        const stdout_file = std.io.getStdOut().writer();
        while (true) {
            try stdout_file.print("{s}", .{screen_clear});
            try self.print(stdout_file);
            std.time.sleep(sleep_timer);
        }
    }

    /// Debug print the grid
    pub fn debug(self: Self) void {
        for (self.grid.data, 0..) |value, i| {
            if (i != 0 and i % self.grid.shape[1] == 0) {
                std.debug.print("\n", .{});
            }
            std.debug.print("{d}", .{value});
        }
        std.debug.print("\n", .{});
        std.debug.print("==================\n", .{});
    }

    // TODO: write the whole buffer at once into a buffered writer of exactly the size of the grid.
    pub fn print(self: Self, writer: std.fs.File.Writer) !void {
        for (self.grid.data, 0..) |value, i| {
            if (i != 0 and i % self.grid.shape[1] == 0) {
                try writer.writeAll("\n");
            }
            try writer.print("{d}", .{value});
        }
        try writer.writeAll("\n");
    }
};

test "grid creation" {
    const IntGrid = Grid(i32);
    var data = [_]i32{ 1, 2, 3, 4 };
    const grid = IntGrid.init(
        data[0..data.len],
        .{ 2, 2 },
        .row_major,
        std.testing.allocator,
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
        std.testing.allocator,
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
        std.testing.allocator,
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

test "game creation" {
    const filepath = "/Users/bogdan/Workspace/personal/conway/seeds/test.txt";
    var game = try Game.init(filepath, std.testing.allocator);
    game.deinit();
}
