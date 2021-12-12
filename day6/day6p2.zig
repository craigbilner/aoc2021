const std = @import("std");
const builtin = @import("builtin");

fn put(m: *std.StringHashMap(u64), key: []u8, value: u64) !void {
    const get_or_put = try m.getOrPut(key);
    if (!get_or_put.found_existing) {
        get_or_put.key_ptr.* = m.allocator.dupe(u8, key) catch |err| {
            _ = m.remove(key);
            return err;
        };
        get_or_put.value_ptr.* = value;
    } else {
        get_or_put.value_ptr.* += value;
    }
}

fn totalAfterDays(projection: *std.StringHashMap(u64), fish: u64, days: u64) u64 {
    var buf: [8]u8 = undefined;
    const key = std.fmt.bufPrint(buf[0..], "{d}|{d}", .{ fish, days }) catch return 0;

    const cache = projection.get(key);

    if (cache != null) {
        return cache.?;
    }

    if ((fish + 1) > days) {
        const result = 1;
        put(projection, key, result) catch return result;
        return result;
    }

    if (fish == 6) {
        const result = switch (days) {
            0...6 => 1,
            7 => 2,
            else => totalAfterDays(projection, 5, days - 7 - 1) + totalAfterDays(projection, 7, days - 7 - 1),
        };

        put(projection, key, result) catch return result;
        return result;
    }

    const result = totalAfterDays(projection, 6, days - fish - 1) + totalAfterDays(projection, 8, days - fish - 1);
    put(projection, key, result) catch return result;
    return result;
}

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

    var projection = std.StringHashMap(u64).init(allocator);
    defer projection.deinit();

    var total: u64 = 0;
    var days: u16 = 256;
    for (school.items) |fish| {
        total += totalAfterDays(&projection, fish, days);
    }

    std.debug.print("Total: {d}\n", .{total});
}
