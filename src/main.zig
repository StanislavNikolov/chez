const std = @import("std");
const board = @import("board.zig");
const moves = @import("moves.zig");
const ui = @import("ui.zig");
const bot = @import("bot.zig");
const raylib = @import("raylib");

pub fn main() !void {
    var brd = board.Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");

    // // var b = board.Board.fromFEN("8/8/8/7p/6P1/8/8/8 w KQkq - 0 1");
    //
    // var term_renderer: ui.TerminalRenderer = .{};
    // try term_renderer.init();
    // defer term_renderer.deinit() catch {};
    //
    // while (true) {
    //     var choices: [64]moves.MoveDescription = undefined;
    //     var it = moves.MoveIterator{ .board = b };
    //     var idx: usize = 0;
    //     while (it.next()) |m| {
    //         choices[idx] = m;
    //         idx += 1;
    //     }
    //
    //     // Play with the bot.
    //     if (b.to_move == .black) {
    //         const selectedMove = try term_renderer.interactiveRender(b, choices[0..idx]);
    //         moves.makeMove(&b, selectedMove);
    //     } else {
    //         try term_renderer.renderBoard(b, choices[0..0]);
    //         const selectedMove = bot.play(b, 3).move;
    //         moves.makeMove(&b, selectedMove);
    //     }
    //
    //     // Play with yourself.
    //     // const selectedMove = try term_renderer.interactiveRender(b, choices[0..idx]);
    //     // moves.makeMove(&b, selectedMove);
    // }

    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true, .FLAG_VSYNC_HINT = true });
    raylib.InitWindow(800, 800, "Chez");
    // raylib.SetTargetFPS(60);

    defer raylib.CloseWindow();

    const texture = raylib.LoadTexture("sprites.png");
    defer raylib.UnloadTexture(texture);

    const whiteBg = raylib.ColorFromNormalized(.{ .x = 0.96, .y = 0.90, .z = 0.75, .w = 1.0 });
    const blackBg = raylib.ColorFromNormalized(.{ .x = 0.40, .y = 0.26, .z = 0.22, .w = 1.0 });

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        var width = raylib.GetScreenWidth();
        var height = raylib.GetScreenHeight();
        const min = @min(width, height);
        const size = @divFloor(min, 8);
        if (min * size != width or width != height) {
            raylib.SetWindowSize(size * 8, size * 8);
        }

        for (brd.pieces, 0..) |col, rowIdx| {
            for (col, 0..) |piece, colIdx| {
                const color = if (rowIdx % 2 == colIdx % 2) whiteBg else blackBg;

                const rec = raylib.Rectangle{
                    .x = @intToFloat(f32, @intCast(i32, colIdx) * size),
                    .y = @intToFloat(f32, @intCast(i32, rowIdx) * size),
                    .width = @intToFloat(f32, size),
                    .height = @intToFloat(f32, size),
                };

                raylib.DrawRectangleRec(rec, color);

                if (piece == .empty) continue;

                const atlasLoc = switch (piece) {
                    .white_pawn => raylib.Rectangle{ .x = 0 * 240, .y = 0, .width = 240, .height = 240 },
                    .white_knight => raylib.Rectangle{ .x = 1 * 240, .y = 0, .width = 240, .height = 240 },
                    .white_bishop => raylib.Rectangle{ .x = 2 * 240, .y = 0, .width = 240, .height = 240 },
                    .white_rook => raylib.Rectangle{ .x = 3 * 240, .y = 0, .width = 240, .height = 240 },
                    .white_queen => raylib.Rectangle{ .x = 4 * 240, .y = 0, .width = 240, .height = 240 },
                    .white_king => raylib.Rectangle{ .x = 5 * 240, .y = 0, .width = 240, .height = 240 },
                    .black_pawn => raylib.Rectangle{ .x = 0 * 240, .y = 240, .width = 240, .height = 240 },
                    .black_knight => raylib.Rectangle{ .x = 1 * 240, .y = 240, .width = 240, .height = 240 },
                    .black_bishop => raylib.Rectangle{ .x = 2 * 240, .y = 240, .width = 240, .height = 240 },
                    .black_rook => raylib.Rectangle{ .x = 3 * 240, .y = 240, .width = 240, .height = 240 },
                    .black_queen => raylib.Rectangle{ .x = 4 * 240, .y = 240, .width = 240, .height = 240 },
                    .black_king => raylib.Rectangle{ .x = 5 * 240, .y = 240, .width = 240, .height = 240 },
                    else => unreachable,
                };

                raylib.DrawTexturePro(texture, atlasLoc, rec, .{ .x = 0, .y = 0 }, 0, raylib.WHITE);
            }
        }

        raylib.DrawFPS(0, 0);
    }
}

test {
    @import("std").testing.refAllDecls(@This());
}
