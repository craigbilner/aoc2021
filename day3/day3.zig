const std = @import("std");
const builtin = @import("builtin");

const Rates = struct { gamma: u16, epsilon: u16 };

fn ratesFromList(l: [12]i16) Rates {
    const last: u8 = l.len - 1;
    var i: u8 = last;
    var g: u16 = 0;
    var e: u16 = 0;

    while (i >= 0) {
        if (l[i] > 0) {
            g += std.math.pow(u16, 2, last - i);
        } else {
            e += std.math.pow(u16, 2, last - i);
        }

        if (i == 0) {
            break;
        }

        i -= 1;
    }

    return Rates{ .gamma = g, .epsilon = e };
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "day3_input.txt",
        .{ .read = true },
    );
    defer file.close();

    const reader = file.reader();

    var buffer: [14]u8 = undefined;
    var counters = [12]i16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var ln: []const u8 = "";
        if (builtin.os.tag == .windows) {
            ln = std.mem.trimRight(u8, line[0..], "\r");
        }

        for (ln) |c, i| {
            if (c == '0') {
                counters[i] -= 1;
            } else {
                counters[i] += 1;
            }
        }
    }

    const rates = ratesFromList(counters);

    std.debug.print("{d}\n", .{@as(u32, rates.gamma) * @as(u32, rates.epsilon)});
}
