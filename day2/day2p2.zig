const std = @import("std");
const builtin = @import("builtin");

const Position = struct { h: u16, d: u32 };

fn getPosition(instructions: std.ArrayList(Instruction)) Position {
    var h: u16 = 0;
    var d: u32 = 0;
    var aim: u16 = 0;

    for (instructions.items) |instr| {
        switch (instr) {
            .forward => |n| {
                h += n;
                d += (aim * n);
            },
            .down => |n| aim += n,
            .up => |n| aim -= n,
        }
    }

    return Position{ .h = h, .d = d };
}

const Direction = enum { forward, down, up };

const Instruction = union(Direction) { forward: u8, down: u8, up: u8 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile(
        "day2_input.txt",
        .{ .read = true },
    );
    defer file.close();

    const reader = file.reader();

    var buffer: [10]u8 = undefined;
    var list = std.ArrayList(Instruction).init(allocator);
    defer list.deinit();
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var ln: []const u8 = "";
        if (builtin.os.tag == .windows) {
            ln = std.mem.trimRight(u8, line[0..], "\r");
        }
        var iter = std.mem.split(u8, ln, " ");
        var d = iter.next().?;
        var n = try std.fmt.parseInt(u8, iter.next().?, 10);

        if (std.mem.eql(u8, d, "forward")) {
            try list.append(Instruction{ .forward = n });
        } else if (std.mem.eql(u8, d, "down")) {
            try list.append(Instruction{ .down = n });
        } else if (std.mem.eql(u8, d, "up")) {
            try list.append(Instruction{ .up = n });
        }
    }

    const position = getPosition(list);

    std.debug.print("{d}\n", .{@as(u32, position.h) * @as(u32, position.d)});
}
