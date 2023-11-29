const std = @import("std");
const expect = std.testing.expect;

/// One megabyte
const mb = (1 << 10) << 10;
// Ansi escape codes
const esc = "\x1B";
const csi = esc ++ "[";
const screen_clear = csi ++ "2J" ++ csi ++ "H";
/// Sleep timer
const sleep_timer = 500_000_000;

const GridOrdering = enum {
    row_major,
    column_major,
};

const GridError = error{
    IndexOutOfBounds,
};

pub const Game = struct {
    const Self = @This();

    data: []u8,
    helper_buffer: []u8,
    shape: [2]usize,
    allocator: std.mem.Allocator,
    ordering: GridOrdering = .row_major,

    const neighbours = [8][2]i8{
        [_]i8{ -1, -1 },
        [_]i8{ -1, 0 },
        [_]i8{ -1, 1 },
        [_]i8{ 0, 1 },
        [_]i8{ 1, 1 },
        [_]i8{ 1, 0 },
        [_]i8{ 1, -1 },
        [_]i8{ 0, -1 },
    };

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

        // Buffer where we construct the new step of the game
        const helper_buffer = try allocator.alloc(u8, total);

        return Self{
            .data = try buffer.toOwnedSlice(),
            .helper_buffer = helper_buffer,
            .allocator = allocator,
            .shape = .{ rows, total / rows },
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.data);
        self.allocator.free(self.helper_buffer);
    }

    pub fn loop(self: *Self) !void {
        const stdout_file = std.io.getStdOut().writer();
        while (true) {
            try stdout_file.print("{s}", .{screen_clear});
            try self.print(stdout_file);
            try self.step();
            std.time.sleep(sleep_timer);
        }
    }

    pub fn step(self: *Self) !void {
        for (0..self.shape[0]) |x| {
            for (0..self.shape[1]) |y| {
                const alive_neighbours = self.countAliveNeighbours(x, y);
                const current_value = self.get(x, y) orelse unreachable;
                var new_value: u8 = 0;
                // Update the cell in helper_buffer based (only cases where it becomes alive)
                if (current_value == 1) {
                    if (alive_neighbours == 2 or alive_neighbours == 3) {
                        new_value = 1;
                    }
                } else {
                    if (alive_neighbours == 3) {
                        new_value = 1;
                    }
                }
                const idx = self.index(x, y);
                self.helper_buffer[idx] = new_value;
            }
        }
        @memcpy(self.data, self.helper_buffer);
    }

    fn countAliveNeighbours(self: Self, x: usize, y: usize) usize {
        var alive: u8 = 0;
        for (neighbours) |value| {
            const coord_x = @as(i32, @intCast(x)) + @as(i32, value[0]);
            const coord_y = @as(i32, @intCast(y)) + @as(i32, value[1]);
            if (coord_x >= 0 and coord_y >= 0) {
                const neighbour = self.get(@as(usize, @intCast(coord_x)), @as(usize, @intCast(coord_y)));
                if (neighbour != null) {
                    alive += neighbour.?;
                }
            }
        }
        return alive;
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
        for (self.data, 0..) |value, i| {
            if (i != 0 and i % self.shape[1] == 0) {
                try writer.writeAll("\n");
            }
            try writer.print("{d}", .{value});
        }
        try writer.writeAll("\n");
    }

    /// Returns the value in the grid at the given coordinates.
    pub fn get(self: Self, x: usize, y: usize) ?u8 {
        const idx = self.index(x, y);
        if (idx >= self.data.len) {
            return null;
        }
        return self.data[idx];
    }

    /// Sets the value in the grid at the given coordinates.
    pub fn set(self: Self, x: usize, y: usize, value: u8) !void {
        const idx = self.index(x, y);
        if (idx >= self.data.len) {
            return error.IndexOutOfBounds;
        }
        self.data[idx] = value;
    }

    fn size(self: Self) usize {
        return self.shape[0] * self.shape[1];
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

/// Testing file
///
/// 0 0 1 0 0
/// 0 1 0 1 0
/// 0 0 0 0 0
/// 0 1 0 0 0
/// 0 0 0 0 0
const filepath = "/Users/bogdan/Workspace/personal/conway/seeds/test.txt";

test "creation" {
    var game = try Game.init(filepath, std.testing.allocator);
    defer game.deinit();
    try expect(game.size() == 25);
    try expect(game.data.len == 25);
    try expect(game.helper_buffer.len == 25);
}

test "set" {
    var game = try Game.init(filepath, std.testing.allocator);
    defer game.deinit();
    try game.set(0, 0, 5);
    try expect(game.data[0] == 5);
}

test "ordering" {
    var game = try Game.init(filepath, std.testing.allocator);
    defer game.deinit();
    var value = game.get(0, 2);
    try expect(value.? == 1);
    game.ordering = .column_major;
    value = game.get(0, 2);
    try expect(value.? == 0);
}

test "alive neighbours" {
    var game = try Game.init(filepath, std.testing.allocator);
    defer game.deinit();
    var alive_neighbours = game.countAliveNeighbours(0, 2);
    try expect(alive_neighbours == 2);
    alive_neighbours = game.countAliveNeighbours(1, 1);
    try expect(alive_neighbours == 1);
    alive_neighbours = game.countAliveNeighbours(4, 4);
    try expect(alive_neighbours == 0);
}

test "first step" {
    var game = try Game.init(filepath, std.testing.allocator);
    defer game.deinit();
    try game.step();
    try expect(game.get(0, 2).? == 1);
    try expect(game.get(1, 2).? == 1);
    try expect(game.get(2, 2).? == 1);
}
