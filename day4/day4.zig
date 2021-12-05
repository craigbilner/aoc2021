const std = @import("std");
const builtin = @import("builtin");

const Line = struct {
    count: u8,
    call: u8,
    cell: u8,

    fn init() Line {
        return Line{ .count = 0, .call = 0, .cell = 0 };
    }

    fn increment(self: *Line, call: u8, cell: u8) void {
        self.count += 1;

        if (call > self.call) {
            self.call = call;
            self.cell = cell;
        }
    }
};

const Square = struct {
    call: ?u8,
    cell: u8
};

const Board = struct {
    squares: std.ArrayList(Square),
    row: [5]Line,
    column: [5]Line,
    pos: u8,
    isComplete: bool,
    sum: u16,
    hasBingo: bool,
    final: Line,

    fn init(allocator: *std.mem.Allocator) Board {
         var squares = std.ArrayList(Square).init(allocator);

        return Board{
            .squares = squares,
            .row = [5]Line{ Line.init(), Line.init(), Line.init(), Line.init(), Line.init() },
            .column = [5]Line{ Line.init(), Line.init(), Line.init(), Line.init(), Line.init() },
            .pos = 0,
            .isComplete = false,
            .sum = 0,
            .hasBingo = false,
            .final = undefined,
        };
    }

    fn deinit(self: *Board) void {
        self.squares.deinit();
    }

    fn addCell(self: *Board, cell: u8, call: ?u8) !void {
        if (self.isComplete) {
            return;
        }

        try self.squares.append(Square{.cell = cell, .call = call });

        if (call != null) {
            const row = self.pos / 5;
            const column = self.pos % 5;

            self.row[row].increment(call.?, cell);

            if (self.row[row].count == 5) {
                if (self.final.call > self.row[row].call) {
                    self.final = self.row[row];
                }
                self.hasBingo = true;
            }

            self.column[column].increment(call.?, cell);

            if (self.column[column].count == 5) {
                if (self.final.call > self.column[column].call) {
                    self.final = self.column[column];
                }
                self.hasBingo = true;
            }
        }

        if (self.pos == 24) {
            for (self.squares.items) |s| {
                if (s.call.? > self.final.call) {
                    self.sum += s.cell;
                }
            }

            self.isComplete = true;
            return;
        }

        self.pos += 1;
    }
};

const Game = struct {
    calls: std.AutoHashMap(u8, u8),
    callPos: u8,
    boards: std.ArrayList(Board),

    fn init(allocator: *std.mem.Allocator) !Game {
        var calls = std.AutoHashMap(u8, u8).init(
            allocator,
        );
        var boards = std.ArrayList(Board).init(allocator);
        try boards.append(Board.init(allocator));

        return Game{
            .calls = calls,
            .callPos = 0,
            .boards = boards,
        };
    }

    fn addCall(self: *Game, n: u8) !void {
        try self.calls.put(n, self.callPos + 1);
        self.callPos += 1;
    }

    fn addCell(self: *Game, allocator: *std.mem.Allocator, cell: u8) !void {
        const board = &self.boards.pop();
        const call = self.calls.get(cell);

        try board.addCell(cell, call);
        try self.boards.append(board.*);

        if (board.isComplete) {
            try self.boards.append(Board.init(allocator));
        }
    }

    fn winner(self: *Game) ?Board {
        var first: ?Board = null;
        var id: usize = 0;
        for (self.boards.items) |b, i| {
            if (!b.hasBingo) {
                continue;
            }

            if (first == null) {
                first = b;
                continue;
            }

            if (b.final.call < first.?.final.call) {
                first = b;
                id = i;
            }
        }

        return first;
    }

    fn deinit(self: *Game) void {
        self.calls.deinit();

        for (self.boards.items) |*b| {
            b.*.deinit();
        }

        self.boards.deinit();
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const file = try std.fs.cwd().openFile(
        "day4_input.txt",
        .{ .read = true },
    );
    defer file.close();

    const reader = file.reader();

    var buffer: [300]u8 = undefined;
    var game = try Game.init(allocator);
    defer game.deinit();

    const callsLine = (try reader.readUntilDelimiterOrEof(&buffer, '\n')).?;

    var callsIter = std.mem.split(u8, std.mem.trimRight(u8, callsLine[0..], "\r"), ",");
    while (callsIter.next()) |call| {
        try game.addCall(try std.fmt.parseInt(u8, call, 10));
    }

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var ln: []const u8 = undefined;
        if (builtin.os.tag == .windows) {
            ln = std.mem.trimRight(u8, line[0..], "\r");
        }

        if (ln.len == 0) {
            continue;
        }

        var iter = std.mem.split(u8, ln, " ");
        while (iter.next()) |n| {
            if (n.len == 0) {
                continue;
            }

            try game.addCell(allocator, try std.fmt.parseInt(u8, n, 10));
        }
    }

    const winningBoard = game.winner().?;

    std.debug.print("{d}\n", .{@as(u32, winningBoard.sum) * @as(u32, winningBoard.final.cell)});
}
