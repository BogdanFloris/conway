const std = @import("std");
const conway = @import("conway.zig");

const filepath = "/Users/bogdan/Workspace/personal/conway/seeds/test.txt";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var game = try conway.Game.init(filepath, arena.allocator());
    try game.loop();
}
