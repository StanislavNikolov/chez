const std = @import("std");
const tty = std.io.tty;
const board = @import("board.zig");
const moves = @import("moves.zig");

pub const TerminalRenderer = struct {
    stdin: std.fs.File = std.io.getStdIn(),
    stdout: std.fs.File = std.io.getStdOut(),
    original_termios: std.os.termios = undefined,
    cursorRow: i8 = 0,
    cursorCol: i8 = 0,

    pub fn init(self: *@This()) !void {
        // Enable "raw" mode - tell the terminal to tell us what the user is doing
        // in real time, without waiting for enter.
        self.original_termios = try std.os.tcgetattr(self.stdin.handle);

        var termios = self.original_termios;
        termios.lflag &= ~std.os.system.ECHO;
        termios.lflag &= ~std.os.system.ICANON;
        try std.os.tcsetattr(self.stdin.handle, .FLUSH, termios);
    }

    pub fn deinit(self: @This()) !void {
        try std.os.tcsetattr(self.stdin.handle, .FLUSH, self.original_termios);
    }

    fn setColor(self: @This(), fg: u8, bg: u8) !void {
        const wrt = self.stdout.writer();
        try self.stdout.writeAll("\x1b[38;5;");
        try std.fmt.formatInt(fg, 10, .lower, .{}, wrt);
        try self.stdout.writeAll(";48;5;");
        try std.fmt.formatInt(bg, 10, .lower, .{}, wrt);
        try self.stdout.writeAll("m");
    }

    fn clearScreen(self: @This()) !void {
        try self.stdout.writeAll("\x1b[2J\x1b[1;1H");
    }

    pub fn renderBoard(self: @This(), brd: board.Board, possMoves: []moves.MoveDescription) !void {
        if (brd.to_move == .white) {
            try self.stdout.writeAll("White to move\n");
        } else {
            try self.stdout.writeAll("Black to move\n");
        }

        for (brd.pieces, 0..) |col, rowIdx| {
            for (col, 0..) |piece, colIdx| {
                var cellBg: u8 = if (rowIdx % 2 == colIdx % 2) 243 else 245;

                if (rowIdx == self.cursorRow and colIdx == self.cursorCol) {
                    cellBg = 130;
                }

                var cellFg = cellBg; // Invisible

                // Check if this square is the target of any MoveDescription
                var target: bool = false;
                for (possMoves) |md| {
                    if (md.to.row != rowIdx or md.to.col != colIdx) continue;
                    target = true;
                }

                if (target) {
                    cellFg = 51;
                } else {
                    cellFg = switch (board.colorOf(piece)) {
                        .white => 231,
                        .black => 232,
                        .empty => cellBg,
                    };
                }

                try self.setColor(cellFg, cellBg);
                try self.stdout.writer().writeByte(board.pieceToChar(piece));
            }
            try self.setColor(51, 232);
            try self.stdout.writer().print(" {d}\n", .{rowIdx + 1});
            try self.setColor(0, 0);
        }

        try self.setColor(51, 232);
        try self.stdout.writer().print("ABCDEFGH\n", .{});
        try self.stdout.writeAll("\x1b[0m");
    }

    pub fn interactiveRender(self: *@This(), brd: board.Board, choices: []moves.MoveDescription) !moves.MoveDescription {
        var possMoves: [64]moves.MoveDescription = undefined;
        var possMovesCnt: usize = 0;

        var first: bool = true;

        while (true) {
            if (!first) {
                try self.stdout.writeAll("\x1b[10F");
            }
            first = false;

            // try self.clearScreen();
            try self.renderBoard(brd, possMoves[0..possMovesCnt]);

            var buf: [20]u8 = undefined;
            const c = try self.stdin.read(&buf);

            if (c == 0) {
                std.debug.print("uuuh, why is c=0\n", .{});
                return choices[0];
            }

            if (c > 1) continue;

            if (buf[0] == 'h') self.cursorCol -= 1;
            if (buf[0] == 'j') self.cursorRow += 1;
            if (buf[0] == 'k') self.cursorRow -= 1;
            if (buf[0] == 'l') self.cursorCol += 1;
            self.cursorRow = @mod(self.cursorRow, 8);
            self.cursorCol = @mod(self.cursorCol, 8);

            if (buf[0] == 10) { // Enter
                if (possMovesCnt == 0) {
                    for (choices) |mv| {
                        if (mv.from.row != self.cursorRow or mv.from.col != self.cursorCol) continue;
                        possMoves[possMovesCnt] = mv;
                        possMovesCnt += 1;
                    }
                } else {
                    for (possMoves[0..possMovesCnt]) |mv| {
                        if (mv.to.row != self.cursorRow or mv.to.col != self.cursorCol) continue;
                        return mv;
                    }
                    possMovesCnt = 0;
                }
            }
        }
    }
};
