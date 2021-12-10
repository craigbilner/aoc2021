const std = @import("std");
const builtin = @import("builtin");

const Point = struct { x: u16, y: u16 };
const Direction = enum { diagonalRight, diagonalLeft, across, down };
const Vector = struct { d: Direction, from: Point, to: Point };

const Map = struct {
    m: std.StringHashMap(u8),

    fn init(allocator: *std.mem.Allocator) Map {
        return Map{ .m = std.StringHashMap(u8).init(allocator) };
    }

    fn toVector(p1: Point, p2: Point) Vector {
        if (p1.x == p2.x and p1.y < p2.y) {
            return Vector{ .d = Direction.down, .from = p1, .to = p2 };
        }

        if (p1.x == p2.x and p1.y > p2.y) {
            return Vector{ .d = Direction.down, .from = p2, .to = p1 };
        }

        if (p1.y == p2.y and p1.x < p2.x) {
            return Vector{ .d = Direction.across, .from = p1, .to = p2 };
        }

        if (p1.y == p2.y and p1.x > p2.x) {
            return Vector{ .d = Direction.across, .from = p2, .to = p1 };
        }

        if (p1.x < p2.x and p1.y < p2.y) {
            return Vector{ .d = Direction.diagonalRight, .from = p1, .to = p2 };
        }

        if (p1.x > p2.x and p1.y > p2.y) {
            return Vector{ .d = Direction.diagonalRight, .from = p2, .to = p1 };
        }

        if (p1.x > p2.x and p1.y < p2.y) {
            return Vector{ .d = Direction.diagonalLeft, .from = p1, .to = p2 };
        }

        return Vector{ .d = Direction.diagonalLeft, .from = p2, .to = p1 };
    }

    fn add(self: *Map, p1: Point, p2: Point) !void {
        var lineBuffer: [12]u8 = undefined;
        const v = toVector(p1, p2);

        switch (v.d) {
            .down => {
                var y = v.from.y;
                while (true) {
                    const key = try std.fmt.bufPrint(lineBuffer[0..], "{d}|{d}", .{ v.from.x, y });
                    try self.put(key);

                    if (y == v.to.y) {
                        break;
                    }

                    y += 1;
                }
            },
            .across => {
                var x = v.from.x;
                while (true) {
                    const key = try std.fmt.bufPrint(lineBuffer[0..], "{d}|{d}", .{ x, v.from.y });
                    try self.put(key);

                    if (x == v.to.x) {
                        break;
                    }

                    x += 1;
                }
            },
            .diagonalLeft => {
                var x = v.from.x;
                var y = v.from.y;
                while (true) {
                    const key = try std.fmt.bufPrint(lineBuffer[0..], "{d}|{d}", .{ x, y });
                    try self.put(key);

                    if (x == v.to.x) {
                        break;
                    }

                    y += 1;
                    x -= 1;
                }
            },
            .diagonalRight => {
                var x = v.from.x;
                var y = v.from.y;
                while (true) {
                    const key = try std.fmt.bufPrint(lineBuffer[0..], "{d}|{d}", .{ x, y });
                    try self.put(key);

                    if (x == v.to.x) {
                        break;
                    }

                    y += 1;
                    x += 1;
                }
            },
        }
    }

    fn put(self: *Map, key: []u8) !void {
        const get_or_put = try self.m.getOrPut(key);
        if (!get_or_put.found_existing) {
            get_or_put.key_ptr.* = self.m.allocator.dupe(u8, key) catch |err| {
                _ = self.m.remove(key);
                return err;
            };
            get_or_put.value_ptr.* = 1;
        } else {
            get_or_put.value_ptr.* += 1;
        }
    }

    fn sum(self: *Map) u16 {
        var linesIter = self.m.valueIterator();
        var total: u16 = 0;
        while (linesIter.next()) |v| {
            if (v.* > 1) {
                total += 1;
            }
        }

        return total;
    }

    fn deinit(self: *Map) void {
        var it = self.m.keyIterator();
        while (it.next()) |key_ptr| {
            self.m.allocator.free(key_ptr.*);
        }

        self.m.deinit();
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile(
        "day5_input.txt",
        .{ .read = true },
    );
    defer file.close();

    const reader = file.reader();

    var map = Map.init(allocator);
    defer map.deinit();

    var buffer: [20]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var ln: []const u8 = undefined;
        if (builtin.os.tag == .windows) {
            ln = std.mem.trimRight(u8, line[0..], "\r");
        }

        var lineIter = std.mem.split(u8, ln, " -> ");
        var startInput = lineIter.next();

        var startIter = std.mem.split(u8, startInput.?, ",");
        var startX = startIter.next();
        var startY = startIter.next();
        var x0 = try std.fmt.parseInt(u16, startX.?, 10);
        var y0 = try std.fmt.parseInt(u16, startY.?, 10);

        var endInput = lineIter.next();

        var endIter = std.mem.split(u8, endInput.?, ",");
        var endX = endIter.next();
        var endY = endIter.next();
        var x1 = try std.fmt.parseInt(u16, endX.?, 10);
        var y1 = try std.fmt.parseInt(u16, endY.?, 10);

        // std.debug.print("({d},{d}) => ({d},{d})\n", .{ x0, y0, x1, y1 });

        try map.add(Point{ .x = x0, .y = y0 }, Point{ .x = x1, .y = y1 });
    }

    std.debug.print("Total {d}\n", .{map.sum()});
}
