const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

pub const Color = enum { empty, white, black };

pub const Piece = enum {
    empty,
    white_pawn,
    white_knight,
    white_bishop,
    white_rook,
    white_queen,
    white_king,
    black_pawn,
    black_knight,
    black_bishop,
    black_rook,
    black_queen,
    black_king,
};

pub fn pieceToChar(p: Piece) u8 {
    return switch (p) {
        .empty => '.',
        .white_pawn => 'P',
        .white_knight => 'N',
        .white_bishop => 'B',
        .white_rook => 'R',
        .white_queen => 'Q',
        .white_king => 'K',
        .black_pawn => 'p',
        .black_knight => 'n',
        .black_bishop => 'b',
        .black_rook => 'r',
        .black_queen => 'q',
        .black_king => 'k',
    };
}

pub fn charToPiece(c: u8) Piece {
    return switch (c) {
        '.' => .empty,
        'P' => .white_pawn,
        'N' => .white_knight,
        'B' => .white_bishop,
        'R' => .white_rook,
        'Q' => .white_queen,
        'K' => .white_king,
        'p' => .black_pawn,
        'n' => .black_knight,
        'b' => .black_bishop,
        'r' => .black_rook,
        'q' => .black_queen,
        'k' => .black_king,
        else => unreachable,
    };
}

pub fn colorOf(p: Piece) Color {
    return switch (p) {
        .empty => .empty,
        .white_pawn => .white,
        .white_knight => .white,
        .white_bishop => .white,
        .white_rook => .white,
        .white_queen => .white,
        .white_king => .white,
        .black_pawn => .black,
        .black_knight => .black,
        .black_bishop => .black,
        .black_rook => .black,
        .black_queen => .black,
        .black_king => .black,
    };
}

pub const Board = struct {
    pieces: [8][8]Piece,
    to_move: Color,
    // Ignoring castling and en passant for now.

    pub fn print(self: Board) void {
        const ORANGE = "\x1B[38;2;250;120;10m";
        const RESET = "\x1B[0m";

        if (self.to_move == .white) {
            std.debug.print("White to move\n", .{});
        } else {
            std.debug.print("Black to move\n", .{});
        }
        for (self.pieces, 0..) |col, rankIndex| {
            for (col) |piece| {
                std.debug.print("{c}", .{pieceToChar(piece)});
            }
            std.debug.print("{s} {d}{s}\n", .{ ORANGE, rankIndex + 1, RESET });
        }

        std.debug.print("{s}abcdefgh{s}\n", .{ ORANGE, RESET });
    }

    pub fn fromFEN(fen: []const u8) Board {
        var it = std.mem.split(u8, fen, " ");

        var b: Board = undefined;

        const brd = it.next() orelse unreachable;
        var row: u8 = 7;
        var col: u8 = 0;
        for (brd) |char| {
            switch (char) {
                '/' => {
                    row -= 1;
                    col = 0;
                },
                '1'...'8' => {
                    var emptyCnt: i8 = @bitCast(i8, char - '0');
                    while (emptyCnt > 0) {
                        b.pieces[row][col] = .empty;
                        emptyCnt -= 1;
                        col += 1;
                    }
                },
                else => {
                    b.pieces[row][col] = charToPiece(char);
                    col += 1;
                },
            }
        }

        const to_move = it.next() orelse unreachable;
        switch (to_move[0]) {
            'w' => b.to_move = .white,
            'b' => b.to_move = .black,
            else => unreachable,
        }

        return b;
    }
};

test "Board: .fromFEN player to move" {
    try expectEqual(Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1").to_move, .white);
    try expectEqual(Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1").to_move, .black);
}

test "Board: .fromFEN empty rows" {
    try expectEqual(
        Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1"),
        Board.fromFEN("rnbqkbnr/pppppppp/44/35/17/71/PPPPPPPP/RNBQKBNR b KQkq - 0 1"),
    );
    try expectEqual(
        Board.fromFEN("rnbqkbnr/pppppppp/2p5/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1"),
        Board.fromFEN("rnbqkbnr/pppppppp/11p32/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1"),
    );
}

pub const Pos = struct {
    row: i8,
    col: i8,
    pub fn inBounds(self: Pos) bool {
        return self.row >= 0 and self.row < 8 and self.col >= 0 and self.col < 8;
    }
};

const Move = struct {
    pos: Pos,
    becomes: Piece,
};

pub fn get(brd: Board, pos: Pos) Piece {
    return brd.pieces[@intCast(usize, pos.row)][@intCast(usize, pos.col)];
}

fn fillWhitePawnMoves(pos: Pos, brd: Board, moves: []Move) usize {
    var i: usize = 0;

    const push1 = Pos{ .row = pos.row + 1, .col = pos.col };
    const push2 = Pos{ .row = pos.row + 2, .col = pos.col };
    const take1 = Pos{ .row = pos.row + 1, .col = pos.col + 1 };
    const take2 = Pos{ .row = pos.row + 1, .col = pos.col - 1 };

    // Normal push forward
    if (push1.inBounds() and get(brd, push1) == .empty) {
        moves[i] = Move{ .pos = push1, .becomes = .white_pawn };
        i += 1;
    }

    // Jump push forward, if the pawn is not yet pushed and push1 is possible
    if (pos.row == 1 and i == 1 and push2.inBounds() and get(brd, push2) == .empty) {
        moves[i] = Move{ .pos = push2, .becomes = .white_pawn };
        i += 1;
    }

    // Attacks
    if (take1.inBounds() and colorOf(get(brd, take1)) == .black) {
        moves[i] = Move{ .pos = take1, .becomes = .white_pawn };
        i += 1;
    }

    if (take2.inBounds() and colorOf(get(brd, take2)) == .black) {
        moves[i] = Move{ .pos = take2, .becomes = .white_pawn };
        i += 1;
    }

    // Promotions
    for (0..i) |idx| {
        if (moves[idx].pos.row == 7 and moves[idx].becomes == .white_pawn) {
            moves[i + 0] = Move{ .pos = moves[idx].pos, .becomes = .white_knight };
            moves[i + 1] = Move{ .pos = moves[idx].pos, .becomes = .white_bishop };
            moves[i + 2] = Move{ .pos = moves[idx].pos, .becomes = .white_rook };
            i += 3;
            moves[idx].becomes = .white_queen;
        }
    }

    return i;
}

fn fillBlackPawnMoves(pos: Pos, brd: Board, moves: []Move) usize {
    var i: usize = 0;

    const push1 = Pos{ .row = pos.row - 1, .col = pos.col };
    const push2 = Pos{ .row = pos.row - 2, .col = pos.col };
    const take1 = Pos{ .row = pos.row - 1, .col = pos.col + 1 };
    const take2 = Pos{ .row = pos.row - 1, .col = pos.col - 1 };

    // Normal push forward
    if (push1.inBounds() and get(brd, push1) == .empty) {
        moves[i] = Move{ .pos = push1, .becomes = .black_pawn };
        i += 1;
    }

    // Jump push forward, if the pawn is not yet pushed and push 1 is possible
    if (pos.row == 6 and i == 1 and push2.inBounds() and get(brd, push2) == .empty) {
        moves[i] = Move{ .pos = push2, .becomes = .black_pawn };
        i += 1;
    }

    // Attacks
    if (take1.inBounds() and colorOf(get(brd, take1)) == .white) {
        moves[i] = Move{ .pos = take1, .becomes = .black_pawn };
        i += 1;
    }

    if (take2.inBounds() and colorOf(get(brd, take2)) == .white) {
        moves[i] = Move{ .pos = take2, .becomes = .black_pawn };
        i += 1;
    }

    // Promotions
    for (0..i) |idx| {
        if (moves[idx].pos.row == 0 and moves[idx].becomes == .black_pawn) {
            moves[i + 0] = Move{ .pos = moves[idx].pos, .becomes = .black_knight };
            moves[i + 1] = Move{ .pos = moves[idx].pos, .becomes = .black_bishop };
            moves[i + 2] = Move{ .pos = moves[idx].pos, .becomes = .black_rook };
            i += 3;
            moves[idx].becomes = .black_queen;
        }
    }

    return i;
}

fn fillLineMoves(pos: Pos, brd: Board, moves: []Move, me: Piece, comptime dirs: []const Pos) usize {
    var i: usize = 0;
    const myColor = colorOf(me);

    inline for (dirs) |dir| {
        var np = pos;
        while (true) {
            np.row += dir.row;
            np.col += dir.col;
            if (!np.inBounds()) break;

            const p = get(brd, np);
            if (p == .empty) {
                moves[i] = Move{ .pos = np, .becomes = me };
                i += 1;
                continue;
            }

            if (colorOf(p) != myColor) {
                moves[i] = Move{ .pos = np, .becomes = me };
                i += 1;
            }

            break;
        }
    }

    return i;
}

fn fillRookMoves(pos: Pos, brd: Board, moves: []Move, me: Piece) usize {
    const dirs = [_]Pos{
        .{ .row = 1, .col = 0 },
        .{ .row = -1, .col = 0 },
        .{ .row = 0, .col = 1 },
        .{ .row = 0, .col = -1 },
    };
    return fillLineMoves(pos, brd, moves, me, dirs[0..]);
}

fn fillBishopMoves(pos: Pos, brd: Board, moves: []Move, me: Piece) usize {
    const dirs = [_]Pos{
        .{ .row = 1, .col = 1 },
        .{ .row = 1, .col = -1 },
        .{ .row = -1, .col = 1 },
        .{ .row = -1, .col = -1 },
    };
    return fillLineMoves(pos, brd, moves, me, dirs[0..]);
}

fn fillQueenMoves(pos: Pos, brd: Board, moves: []Move, me: Piece) usize {
    const dirs = [_]Pos{
        .{ .row = 1, .col = 0 },
        .{ .row = -1, .col = 0 },
        .{ .row = 0, .col = 1 },
        .{ .row = 0, .col = -1 },
        .{ .row = 1, .col = 1 },
        .{ .row = 1, .col = -1 },
        .{ .row = -1, .col = 1 },
        .{ .row = -1, .col = -1 },
    };
    return fillLineMoves(pos, brd, moves, me, dirs[0..]);
}

fn fillKnightMoves(pos: Pos, brd: Board, moves: []Move, me: Piece) usize {
    const myColor = colorOf(me);
    var i: usize = 0;
    const toCheck = [_]Pos{
        .{ .row = pos.row - 1, .col = pos.col - 2 },
        .{ .row = pos.row - 1, .col = pos.col + 2 },
        .{ .row = pos.row + 1, .col = pos.col - 2 },
        .{ .row = pos.row + 1, .col = pos.col + 2 },
        .{ .row = pos.row - 2, .col = pos.col - 1 },
        .{ .row = pos.row - 2, .col = pos.col + 1 },
        .{ .row = pos.row + 2, .col = pos.col - 1 },
        .{ .row = pos.row + 2, .col = pos.col + 1 },
    };

    for (toCheck) |p| {
        if (!p.inBounds()) continue;
        if (colorOf(get(brd, p)) == myColor) continue;
        moves[i] = .{ .pos = p, .becomes = me };
        i += 1;
    }
    return i;
}

fn fillKingMoves(pos: Pos, brd: Board, moves: []Move, me: Piece) usize {
    var i: usize = 0;

    const myColor = colorOf(me);
    const delta = [3]i8{ -1, 0, 1 };
    for (delta) |dr| {
        for (delta) |dc| {
            if (dr == 0 and dc == 0) continue;
            const np = Pos{ .row = pos.row - dr, .col = pos.col - dc };
            if (!np.inBounds()) continue;
            if (colorOf(get(brd, np)) != myColor) {
                moves[i] = .{ .pos = np, .becomes = me };
                i += 1;
            }
        }
    }

    return i;
}

// Extended Move -> it has from added to Move
pub const MoveDescription = struct {
    from: Pos,
    to: Pos,
    becomes: Piece,
};

fn moveIsLegal(brd: Board, mvd: MoveDescription) bool {
    _ = mvd;
    _ = brd;
    return true;
}

pub fn getAllLegalMoves(brd: Board, output: *[4096]MoveDescription) usize {
    var lastPos: Pos = Pos{ .row = 0, .col = 0 };

    var output_size: usize = 0;

    while (true) {
        // Traverse the board in search of a piece.
        lastPos.col += 1;
        if (lastPos.col == 8) {
            lastPos.col = 0;
            lastPos.row += 1;
            if (lastPos.row == 8) break;
        }

        const piece = get(brd, lastPos);
        if (colorOf(piece) != brd.to_move) continue;

        var rawMoveBuf: [64]Move = undefined; // *Some part* of this array will be populated with valid moves.

        // Get all the moves for this piece.
        var moveCnt = switch (piece) {
            .empty => unreachable,
            .white_pawn => fillWhitePawnMoves(lastPos, brd, rawMoveBuf[0..]),
            .white_knight => fillKnightMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .white_bishop => fillBishopMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .white_rook => fillRookMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .white_queen => fillQueenMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .white_king => fillKingMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .black_pawn => fillBlackPawnMoves(lastPos, brd, rawMoveBuf[0..]),
            .black_knight => fillKnightMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .black_bishop => fillBishopMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .black_rook => fillRookMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .black_queen => fillQueenMoves(lastPos, brd, rawMoveBuf[0..], piece),
            .black_king => fillKingMoves(lastPos, brd, rawMoveBuf[0..], piece),
        };

        for (rawMoveBuf[0..moveCnt]) |mv| {
            const mvd = MoveDescription{ .from = lastPos, .to = mv.pos, .becomes = mv.becomes };
            if (!moveIsLegal(brd, mvd)) continue;
            output[output_size] = mvd;
            output_size += 1;
        }
    }

    return output_size;
}

pub fn makeMove(brd: *Board, mv: MoveDescription) void {
    brd.pieces[@intCast(usize, mv.from.row)][@intCast(usize, mv.from.col)] = .empty;
    brd.pieces[@intCast(usize, mv.to.row)][@intCast(usize, mv.to.col)] = mv.becomes;
    brd.to_move = if (brd.to_move == .white) .black else .white;
}
