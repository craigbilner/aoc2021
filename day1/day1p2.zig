const std = @import("std");
const builtin = @import("builtin");

fn countWindowIncreases(depths: std.ArrayList(u16)) u16 {
    var increases: u16 = 0;
    var cur = depths.items[0] + depths.items[1] + depths.items[2];
    var min2: u16 = depths.items[1];
    var min1: u16 = depths.items[2];
    for (depths.items[3..]) |d| {
        if ((d + min1 + min2) > cur) {
            increases += 1;
        }
        cur = d + min1 + min2;
        min2 = min1;
        min1 = d;
    }
    return increases;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile(
        "day1_input.txt",
        .{ .read = true },
    );
    defer file.close();

    const reader = file.reader();

    var buffer: [6]u8 = undefined;
    var list = std.ArrayList(u16).init(allocator);
    defer list.deinit();
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (builtin.os.tag == .windows) {
            try list.append(try std.fmt.parseInt(u16, std.mem.trimRight(u8, line[0..], "\r"), 10));
        } else {
            try list.append(try std.fmt.parseInt(u16, line[0..], 10));
        }
    }

    const result = countWindowIncreases(list);

    std.debug.print("{d}\n", .{result});
}
