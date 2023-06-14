const board = @import("board.zig");
const moves = @import("moves.zig");

fn scoreBoard(brd: board.Board) i32 {
    var score: i32 = 0;
    for (brd.pieces) |col| {
        for (col) |piece| {
            score += switch (piece) {
                .empty, .white_king, .black_king => 0,
                .white_pawn => 1,
                .white_knight => 3,
                .white_bishop => 3,
                .white_rook => 5,
                .white_queen => 10,
                .black_pawn => -1,
                .black_knight => -3,
                .black_bishop => -3,
                .black_rook => -5,
                .black_queen => -10,
            };
        }
    }
    return score;
}

const asd = struct {
    move: moves.MoveDescription,
    score: i32,
};

pub fn play(brd: board.Board, depth_limit: i32) asd {
    var it = moves.MoveIterator{ .board = brd };
    var best_score: i32 = 99999;
    var best_move: moves.MoveDescription = undefined;

    while (it.next()) |m| {
        var cp = brd;
        moves.makeMove(&cp, m);

        var cp_score: i32 = undefined;
        if (depth_limit > 0) {
            cp_score = play(cp, depth_limit - 1).score * -1;
        } else {
            cp_score = scoreBoard(cp);
        }
        // if (brd.to_move == .black) cp_score *= -1;

        if (cp_score >= best_score) continue;

        best_score = cp_score;
        best_move = m;
    }

    return .{ .move = best_move, .score = best_score };
}