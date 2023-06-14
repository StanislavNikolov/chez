const std = @import("std");
const board = @import("board.zig");
const moves = @import("moves.zig");
const ui = @import("ui.zig");

pub fn main() !void {
    var b = board.Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");

    var term_renderer: ui.TerminalRenderer = .{};
    try term_renderer.init();
    defer term_renderer.deinit() catch {};

    while (true) {
        var choices: [64]moves.MoveDescription = undefined;
        var it = moves.MoveIterator{ .board = b };
        var idx: usize = 0;
        while (it.next()) |m| {
            choices[idx] = m;
            idx += 1;
        }

        const selectedMove = try term_renderer.render(b, choices[0..idx]);
        moves.makeMove(&b, selectedMove);
    }
}

test {
    @import("std").testing.refAllDecls(@This());
}
