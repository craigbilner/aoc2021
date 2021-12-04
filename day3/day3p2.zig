const std = @import("std");
const builtin = @import("builtin");

fn decimalFromList(l: [12]usize) u16 {
    const last: u8 = l.len - 1;
    var i: u8 = last;
    var sum: u16 = 0;

    while (i >= 0) {
        if (l[i] == 1)
            sum += std.math.pow(u16, 2, last - i);

        if (i == 0) {
            break;
        }

        i -= 1;
    }

    return sum;
}

const RateError = error{NoMatch};

fn rateFromReport(allocator: *std.mem.Allocator, criteria: usize, pos: u8, l: *std.ArrayList([12]usize)) RateError!u16 {
    if (l.items.len == 0) {
        return RateError.NoMatch;
    }

    if (l.items.len == 1) {
        return decimalFromList(l.items[0]);
    }

    var i = l.items.len - 1;
    var zeroes = std.ArrayList([12]usize).init(allocator);
    defer zeroes.deinit();
    while (true) {
        if (l.items[i][pos] == 0) {
            const zero = l.orderedRemove(i);
            zeroes.append(zero) catch return RateError.NoMatch;
        }

        if (i == 0) {
            break;
        }

        i -= 1;
    }

    if ((criteria == 0 and (zeroes.items.len < l.items.len or zeroes.items.len == l.items.len)) or (criteria == 1 and zeroes.items.len > l.items.len)) {
        return rateFromReport(allocator, criteria, pos + 1, &zeroes);
    }

    return rateFromReport(allocator, criteria, pos + 1, l);
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "day3_input.txt",
        .{ .read = true },
    );
    defer file.close();

    const reader = file.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var buffer: [14]u8 = undefined;
    var o2 = std.ArrayList([12]usize).init(allocator);
    defer o2.deinit();
    var co2 = std.ArrayList([12]usize).init(allocator);
    defer co2.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var ln: []const u8 = "";
        if (builtin.os.tag == .windows) {
            ln = std.mem.trimRight(u8, line[0..], "\r");
        }

        var n = [12]usize{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
        for (ln) |c, i| {
            if (c == '1')
                n[i] = 1;
        }
        try o2.append(n);
        try co2.append(n);
    }

    const o2Rating = try rateFromReport(allocator, 1, 0, &o2);
    const co2Rating = try rateFromReport(allocator, 0, 0, &co2);

    std.debug.print("{d}\n", .{@as(u32, o2Rating) * @as(u32, co2Rating)});
}
