const core = @import("core.zig");

fn scoreBoard(brd: core.Board) i32 {
    var score: i32 = 0;
    for (brd.pieces) |col| {
        for (col) |piece| {
            score += switch (piece) {
                .empty => 0,
                .white_pawn => 1,
                .white_knight => 3,
                .white_bishop => 3,
                .white_rook => 5,
                .white_queen => 10,
                .white_king => 9999,
                .black_pawn => -1,
                .black_knight => -3,
                .black_bishop => -3,
                .black_rook => -5,
                .black_queen => -10,
                .black_king => -9999,
            };
        }
    }
    return score;
}

const asd = struct {
    move: core.MoveDescription,
    score: i32,
};

pub fn play(brd: core.Board, depth_limit: i32) asd {
    var best_score: i32 = 99999;
    var best_move: core.MoveDescription = undefined;

    var choices: [4096]core.MoveDescription = undefined;
    var choiceCnt: usize = core.getAllLegalMoves(brd, &choices);

    for (choices[0..choiceCnt]) |m| {
        var cp = brd;
        core.makeMove(&cp, m);

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
