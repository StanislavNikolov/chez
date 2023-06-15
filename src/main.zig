const std = @import("std");
const core = @import("core.zig");
const termui = @import("termui.zig");
const bot = @import("bot.zig");
const raylib = @import("raylib");

fn getAtlasLoc(piece: core.Piece) raylib.Rectangle {
    return switch (piece) {
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
}

pub fn main() !void {
    var brd = core.Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");

    // // var b = board.Board.fromFEN("8/8/8/7p/6P1/8/8/8 w KQkq - 0 1");
    //
    // var term_renderer: ui.TerminalRenderer = .{};
    // try term_renderer.init();
    // defer term_renderer.deinit() catch {};
    //
    // while (true) {
    //     var choices: [64]core.MoveDescription = undefined;
    //     var it = core.MoveIterator{ .board = b };
    //     var idx: usize = 0;
    //     while (it.next()) |m| {
    //         choices[idx] = m;
    //         idx += 1;
    //     }
    //
    //     // Play with the bot.
    //     if (b.to_move == .black) {
    //         const selectedMove = try term_renderer.interactiveRender(b, choices[0..idx]);
    //         core.makeMove(&b, selectedMove);
    //     } else {
    //         try term_renderer.renderBoard(b, choices[0..0]);
    //         const selectedMove = bot.play(b, 3).move;
    //         core.makeMove(&b, selectedMove);
    //     }
    //
    //     // Play with yourself.
    //     // const selectedMove = try term_renderer.interactiveRender(b, choices[0..idx]);
    //     // core.makeMove(&b, selectedMove);
    // }

    std.debug.print("test\n", .{});

    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true, .FLAG_VSYNC_HINT = true });
    raylib.InitWindow(800, 800, "Chez");
    defer raylib.CloseWindow();

    // // raylib.SetTargetFPS(10);

    const texture = raylib.LoadTexture("sprites.png");
    defer raylib.UnloadTexture(texture);

    const whiteBg = raylib.ColorFromNormalized(.{ .x = 0.96, .y = 0.90, .z = 0.75, .w = 1.0 });
    const blackBg = raylib.ColorFromNormalized(.{ .x = 0.40, .y = 0.26, .z = 0.22, .w = 1.0 });

    var picked: ?core.Pos = null;

    var choices: [4096]core.MoveDescription = undefined;
    var choiceCnt: usize = core.getAllLegalMoves(brd, &choices);
    std.debug.print("cl={}\n", .{choiceCnt});

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.BLUE);

        var width = raylib.GetScreenWidth();
        var height = raylib.GetScreenHeight();
        const min = @min(width, height);
        const size = @divFloor(min, 8);

        if (min * size != width or width != height) {
            raylib.SetWindowSize(size * 8, size * 8);
        }

        if (raylib.IsMouseButtonDown(.MOUSE_BUTTON_LEFT) and picked == null) {
            const pos = core.Pos{
                .col = @intCast(i8, @divFloor(raylib.GetMouseX(), size)),
                .row = @intCast(i8, @divFloor(raylib.GetMouseY(), size)),
            };
            const piece = core.get(brd, pos);
            if (piece != .empty and core.colorOf(piece) == brd.to_move) {
                picked = pos;
            }
        }

        if (raylib.IsMouseButtonUp(.MOUSE_BUTTON_LEFT) and picked != null) {
            const pos = core.Pos{
                .col = @intCast(i8, @divFloor(raylib.GetMouseX(), size)),
                .row = @intCast(i8, @divFloor(raylib.GetMouseY(), size)),
            };

            for (choices[0..choiceCnt]) |mvd| {
                std.debug.print("{},{} - {},{}\n", .{ mvd.from.row, mvd.from.col, mvd.to.row, mvd.to.col });
                if (mvd.from.row != picked.?.row or mvd.from.col != picked.?.col or mvd.to.row != pos.row or mvd.to.col != pos.col) continue;
                core.makeMove(&brd, mvd);
                choiceCnt = core.getAllLegalMoves(brd, &choices);
                break;
            }
            picked = null;
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

                // Do not draw the picked piece.
                if (picked != null and picked.?.row == rowIdx and picked.?.col == colIdx) continue;

                raylib.DrawTexturePro(texture, getAtlasLoc(piece), rec, .{ .x = 0, .y = 0 }, 0, raylib.WHITE);
            }
        }

        // Now draw the picked piece
        if (picked != null) {
            const piece = core.get(brd, picked.?);
            const dest = raylib.Rectangle{
                .x = @intToFloat(f32, raylib.GetMouseX() - @divFloor(size, 2)),
                .y = @intToFloat(f32, raylib.GetMouseY() - @divFloor(size, 2)),
                .width = @intToFloat(f32, size),
                .height = @intToFloat(f32, size),
            };
            raylib.DrawTexturePro(texture, getAtlasLoc(piece), dest, .{ .x = 0, .y = 0 }, 0, raylib.WHITE);
        }

        raylib.DrawFPS(0, 0);
    }
}

test {
    @import("std").testing.refAllDecls(@This());
}
