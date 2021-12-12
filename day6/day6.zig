const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile(
        "day6_input.txt",
        .{ .read = true },
    );
    defer file.close();

    const reader = file.reader();

    var buffer: [600]u8 = undefined;
    var school = std.ArrayList(u16).init(allocator);
    defer school.deinit();

    var line = try reader.readUntilDelimiterOrEof(&buffer, '\n');
    var ln: []const u8 = undefined;
    if (builtin.os.tag == .windows) {
        ln = std.mem.trimRight(u8, line.?, "\r");
    }

    var lineIter = std.mem.split(u8, ln, ",");

    while (lineIter.next()) |n| {
        try school.append(try std.fmt.parseInt(u16, n, 10));
    }

    var new = std.ArrayList(u16).init(allocator);
    defer new.deinit();
    var day: u8 = 0;
    while (true) : (day += 1) {
        if (day == 80) {
            break;
        }

        for (school.items) |*fish| {
            switch (fish.*) {
                0 => {
                    try new.append(8);
                    fish.* = 6;
                },
                else => fish.* = fish.* - 1,
            }
        }

        for (new.items) |n| {
            try school.append(n);
        }
        try new.resize(0);
    }

    std.debug.print("Total {d}\n", .{school.items.len});
}
