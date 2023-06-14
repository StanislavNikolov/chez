const std = @import("std");
const board = @import("board.zig");
const moves = @import("moves.zig");
const ui = @import("ui.zig");
const bot = @import("bot.zig");

pub fn main() !void {
    var b = board.Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    // var b = board.Board.fromFEN("8/8/8/7p/6P1/8/8/8 w KQkq - 0 1");

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

        // Play with the bot.
        if (b.to_move == .black) {
            const selectedMove = try term_renderer.interactiveRender(b, choices[0..idx]);
            moves.makeMove(&b, selectedMove);
        } else {
            try term_renderer.renderBoard(b, choices[0..0]);
            const selectedMove = bot.play(b, 3).move;
            moves.makeMove(&b, selectedMove);
        }

        // Play with yourself.
        // const selectedMove = try term_renderer.interactiveRender(b, choices[0..idx]);
        // moves.makeMove(&b, selectedMove);
    }
}

test {
    @import("std").testing.refAllDecls(@This());
}
