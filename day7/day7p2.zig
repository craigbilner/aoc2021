const std = @import("std");
const builtin = @import("builtin");

const Optimum = struct { fuel: i32, position: i32 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile(
        "day7_input.txt",
        .{ .read = true },
    );
    defer file.close();

    const reader = file.reader();

    var buffer: [4000]u8 = undefined;
    var positions = std.ArrayList(i32).init(allocator);
    defer positions.deinit();

    var line = try reader.readUntilDelimiterOrEof(&buffer, '\n');
    var ln: []const u8 = undefined;
    if (builtin.os.tag == .windows) {
        ln = std.mem.trimRight(u8, line.?, "\r");
    }

    var lineIter = std.mem.split(u8, ln, ",");

    var max: i32 = 0;
    var min: i32 = 0;
    while (lineIter.next()) |s| {
        const n = try std.fmt.parseInt(i32, s, 10);

        if (n > max) {
            max = n;
        }

        if (n < min) {
            min = n;
        }

        try positions.append(n);
    }

    var i = min;
    var optimum: ?Optimum = null;
    while (i <= max) {
        var fuel: i32 = 0;
        for (positions.items) |p| {
            const d = try std.math.absInt(p - i);
            fuel += @divExact(d * (d + 1), 2);
        }
        if (optimum == null or fuel < optimum.?.fuel) {
            optimum = Optimum{ .position = i, .fuel = fuel };
        }

        i += 1;
    }

    std.debug.print("{any}\n", .{optimum});
}
