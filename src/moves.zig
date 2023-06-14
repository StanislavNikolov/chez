const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const board = @import("./board.zig");

// const Cell = struct {
//     row: i8 = 0,
//     col: i8 = 0,

//     // Moves the cell
//     pub fn advance(self: *Cell) error{CannotAdvance}!void {
//         self.col += 1;
//         if (self.col == 8) {
//             self.col = 0;
//             self.row += 1;

//             if (self.row == 8) {
//                 return error.CannotAdvance;
//             }
//         }
//     }
// };

// pub const Move = struct {
//     from: Cell = .{},
//     to: Cell = .{},

//     pub fn toStr(self: Move) [5]u8 {
//         return [5]u8{
//             'a' + @intCast(u8, self.from.col),
//             '1' + @intCast(u8, self.from.row),
//             '-',
//             'a' + @intCast(u8, self.to.col),
//             '1' + @intCast(u8, self.to.row),
//         };
//     }

//     pub fn fromStr(str: [5]u8) Move {
//         return Move{
//             .from = .{
//                 .col = @intCast(i8, str[0] - 'a'),
//                 .row = @intCast(i8, str[1] - '1'),
//             },
//             .to = .{
//                 .col = @intCast(i8, str[3] - 'a'),
//                 .row = @intCast(i8, str[4] - '1'),
//             },
//         };
//     }
// };

// fn isMoveValid(m: Move, b: Board) bool {
//     // Cannot make "stall" moves
//     if (m.from.row == m.to.row and m.from.col == m.to.col) return false;
//
//     const pieceFrom = b.pieces[@intCast(usize, m.from.row)][@intCast(usize, m.from.col)];
//     const pieceTo = b.pieces[@intCast(usize, m.to.row)][@intCast(usize, m.to.col)];
//
//     // Move your own pieces damnit!
//     if (colorOf(pieceFrom) == .white and !b.white_to_move) return false;
//     if (colorOf(pieceFrom) == .black and b.white_to_move) return false;
//
//     // If take a piece, it must be a different color
//     if (pieceTo != .empty and colorOf(pieceFrom) == colorOf(pieceTo)) return false;
//
//     return switch (pieceFrom) {
//         .empty => return false,
//         .white_pawn => {
//             switch (m.to.col - m.from.col) {
//                 0 => { // Push forward
//                     return switch (m.to.row - m.from.row) {
//                         1 => pieceTo == .empty,
//                         2 => pieceTo == .empty and m.from.row == 1, // Can push 2 squares if only on the initial rank
//                         else => false,
//                     };
//                 },
//                 1, -1 => { // Attack
//                     return switch (m.to.row - m.from.row) {
//                         -1, 1 => pieceTo != .empty,
//                         else => false,
//                     };
//                 },
//                 else => return false,
//             }
//         },
//         .black_pawn => { // This is copy-paste from .white_pawn, but with the values inverted
//             switch (m.to.col - m.from.col) {
//                 0 => { // Push forward
//                     return switch (m.to.row - m.from.row) {
//                         -1 => pieceTo == .empty,
//                         -2 => pieceTo == .empty and m.from.row == 6, // Can push 2 squares if only on the initial rank
//                         else => false,
//                     };
//                 },
//                 1, -1 => { // Attack
//                     return switch (m.to.row - m.from.row) {
//                         -1, 1 => pieceTo != .empty,
//                         else => false,
//                     };
//                 },
//                 else => return false,
//             }
//         },
//         .white_rook, .black_rook => {
//             const sameRow = m.from.row == m.to.row;
//             const sameCol = m.from.col == m.to.col;
//             if (sameRow) {
//             } else if (sameCol) {
//
//             } else { // different row and col
//                 return false;
//             }
//         },
//         else => return false,
//     };
// }

// const whitePawnMoveIterator = struct {
//     cell: Cell,
//     pub fn next() ?Move {
//         return Move{.from=cell, .to={.cell}}
//
//     }
// }

// const MoveIterator = struct {
//     board: Board,
//     m: Move = .{ .from = .{ .row = 0, .col = 0 }, .to = .{ .row = 0, .col = -1 } },

//     pub fn next(self: *MoveIterator) ?Move {
//         while (true) {
//             // std.debug.print("HERE", .{});
//             self.m.to.advance() catch |e1| {
//                 _ = e1 catch {};
//                 self.m.to.row = 0;
//                 self.m.to.col = 0;
//                 self.m.from.advance() catch |e2| {
//                     _ = e2 catch {};
//                     return null;
//                 };
//             };
//             if (isMoveValid(self.m, self.board)) {
//                 return self.m;
//             }
//         }
//     }
// };

const Pos = struct {
    row: i8,
    col: i8,
    pub fn inBounds(self: Pos) bool {
        return self.row >= 0 and self.row < 8 and self.col >= 0 and self.col < 8;
    }
};

const Move = struct {
    pos: Pos,
    becomes: board.Piece,
};

fn get(brd: board.Board, pos: Pos) board.Piece {
    return brd.pieces[@intCast(usize, pos.row)][@intCast(usize, pos.col)];
}

fn fillWhitePawnMoves(pos: Pos, brd: board.Board, moves: *[64]Move) usize {
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

    // Jump push forward, if the pawn is not yet pushed
    if (pos.row == 1 and push2.inBounds() and get(brd, push2) == .empty) {
        moves[i] = Move{ .pos = push2, .becomes = .white_pawn };
        i += 1;
    }

    // Attacks
    if (take1.inBounds() and board.colorOf(get(brd, take1)) == .black) {
        moves[i] = Move{ .pos = take1, .becomes = .white_pawn };
        i += 1;
    }

    if (take2.inBounds() and board.colorOf(get(brd, take2)) == .black) {
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

fn fillBlackPawnMoves(pos: Pos, brd: board.Board, moves: *[64]Move) usize {
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

    // Jump push forward, if the pawn is not yet pushed
    if (pos.row == 6 and push2.inBounds() and get(brd, push2) == .empty) {
        moves[i] = Move{ .pos = push2, .becomes = .black_pawn };
        i += 1;
    }

    // Attacks
    if (take1.inBounds() and board.colorOf(get(brd, take1)) == .black) {
        moves[i] = Move{ .pos = take1, .becomes = .black_pawn };
        i += 1;
    }

    if (take2.inBounds() and board.colorOf(get(brd, take2)) == .black) {
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

fn fillLineMoves(pos: Pos, brd: board.Board, moves: *[64]Move, me: board.Piece, comptime dirs: []const Pos) usize {
    var i: usize = 0;
    const myColor = board.colorOf(me);

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

            if (board.colorOf(p) != myColor) {
                moves[i] = Move{ .pos = np, .becomes = me };
                i += 1;
            }

            break;
        }
    }

    return i;
}

fn fillRookMoves(pos: Pos, brd: board.Board, moves: *[64]Move, me: board.Piece) usize {
    const dirs = [_]Pos{
        .{ .row = 1, .col = 0 },
        .{ .row = -1, .col = 0 },
        .{ .row = 0, .col = 1 },
        .{ .row = 0, .col = -1 },
    };
    return fillLineMoves(pos, brd, moves, me, dirs[0..]);
}

fn fillBishopMoves(pos: Pos, brd: board.Board, moves: *[64]Move, me: board.Piece) usize {
    const dirs = [_]Pos{
        .{ .row = 1, .col = 1 },
        .{ .row = 1, .col = -1 },
        .{ .row = -1, .col = 1 },
        .{ .row = -1, .col = -1 },
    };
    return fillLineMoves(pos, brd, moves, me, dirs[0..]);
}

fn fillQueenMoves(pos: Pos, brd: board.Board, moves: *[64]Move, me: board.Piece) usize {
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

// Extended Move -> it has from added to Move
pub const MoveDescription = struct {
    from: Pos,
    to: Pos,
    becomes: board.Piece,

    pub fn toStr(self: MoveDescription) [8]u8 {
        return [_]u8{
            'a' + @intCast(u8, self.from.col),
            '1' + @intCast(u8, self.from.row),
            '-',
            'a' + @intCast(u8, self.to.col),
            '1' + @intCast(u8, self.to.row),
            '(',
            board.pieceToChar(self.becomes),
            ')',
        };
    }

    pub fn fromStr(str: [8]u8) MoveDescription {
        return .{
            .from = .{
                .col = @intCast(i8, str[0] - 'a'),
                .row = @intCast(i8, str[1] - '1'),
            },
            .to = .{
                .col = @intCast(i8, str[3] - 'a'),
                .row = @intCast(i8, str[4] - '1'),
            },
            .becomes = board.charToPiece(str[6]),
        };
    }
};

pub const MoveIterator = struct {
    board: board.Board,

    lastPos: Pos = Pos{ .row = 0, .col = -1 },
    moveBuf: [64]Move = undefined, // *Some part* of this array will be populated with valid moves.
    unreturnedMoveCnt: usize = 0, // How many valid moves in moveBuf are left.

    fn pop(self: *MoveIterator) MoveDescription {
        self.unreturnedMoveCnt -= 1;
        return .{
            .from = self.lastPos,
            .to = self.moveBuf[self.unreturnedMoveCnt].pos,
            .becomes = self.moveBuf[self.unreturnedMoveCnt].becomes,
        };
    }

    pub fn next(self: *MoveIterator) ?MoveDescription {
        if (self.unreturnedMoveCnt > 0) return self.pop();

        while (true) {
            // Traverse the board in search of a piece.
            self.lastPos.col += 1;
            if (self.lastPos.col == 8) {
                self.lastPos.col = 0;
                self.lastPos.row += 1;
                if (self.lastPos.row == 8) return null; // Out of the board.
            }

            const piece = get(self.board, self.lastPos);
            if (piece == .empty) continue;
            if (board.colorOf(piece) != self.board.to_move) continue;

            // Get all the moves for this piece.
            self.unreturnedMoveCnt = switch (piece) {
                .empty => unreachable,
                .white_pawn => fillWhitePawnMoves(self.lastPos, self.board, &self.moveBuf),
                .white_knight => 0,
                .white_bishop => fillBishopMoves(self.lastPos, self.board, &self.moveBuf, piece),
                .white_rook => fillRookMoves(self.lastPos, self.board, &self.moveBuf, piece),
                .white_queen => fillQueenMoves(self.lastPos, self.board, &self.moveBuf, piece),
                .white_king => 0,
                .black_pawn => fillBlackPawnMoves(self.lastPos, self.board, &self.moveBuf),
                .black_knight => 0,
                .black_bishop => fillBishopMoves(self.lastPos, self.board, &self.moveBuf, piece),
                .black_rook => fillRookMoves(self.lastPos, self.board, &self.moveBuf, piece),
                .black_queen => fillQueenMoves(self.lastPos, self.board, &self.moveBuf, piece),
                .black_king => 0,
            };

            // TODO maybe check for legality here? Some of the moves might make a discover check for example.

            if (self.unreturnedMoveCnt > 0) return self.pop();
        }
    }
};

pub fn makeMove(brd: *board.Board, mv: MoveDescription) void {
    brd.pieces[@intCast(usize, mv.from.row)][@intCast(usize, mv.from.col)] = .empty;
    brd.pieces[@intCast(usize, mv.to.row)][@intCast(usize, mv.to.col)] = mv.becomes;
    brd.to_move = if (brd.to_move == .white) .black else .white;
}

test "MoveDescription: .toStr and .fromStr" {
    const m = MoveDescription{ .from = .{ .row = 0, .col = 0 }, .to = .{ .row = 7, .col = 7 }, .becomes = .white_queen };
    try expect(std.mem.eql(u8, &m.toStr(), "a1-h8(Q)"));

    const m2 = MoveDescription.fromStr("a1-h8(Q)".*);
    try expectEqual(m2, m);
}

// test "isMoveValid: correct opponent" {
//     const bw = Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
//     try expect(isMoveValid(Move.fromStr("h2-h3".*), bw)); // White can move
//     try expect(!isMoveValid(Move.fromStr("h7-h6".*), bw)); // Black can't
//
//     const bb = Board.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1");
//     try expect(!isMoveValid(Move.fromStr("h2-h3".*), bb)); // White can't move
//     try expect(isMoveValid(Move.fromStr("h7-h6".*), bb)); // Black can
// }

// test "isMoveValid: pawns" {
//     var b = Board.fromFEN("8/8/8/8/1p6/P7/7P/8 w KQkq - 0 1");
//     b.print(); // - use this to understand better
//
//     // Push the starting pawn 1 - yes
//     try expect(isMoveValid(Move.fromStr("h2-h3".*), b));
//     // Push the starting pawn 2 - yes
//     try expect(isMoveValid(Move.fromStr("h2-h4".*), b));
//     // Push the starting pawn 3 - no
//     try expect(!isMoveValid(Move.fromStr("h2-h5".*), b));
//
//     // Push rando pawn 1 - yes
//     try expect(isMoveValid(Move.fromStr("a3-a4".*), b));
//     // Push rando pawn 2 - no
//     try expect(!isMoveValid(Move.fromStr("a3-a5".*), b));
//     // Take rando pawn back - no
//     try expect(!isMoveValid(Move.fromStr("a3-a2".*), b));
//
//     // Attack with the white - yes
//     try expect(isMoveValid(Move.fromStr("a3-b4".*), b));
//
//     // Attack with the black - yes
//     b.white_to_move = false;
//     try expect(isMoveValid(Move.fromStr("b4-a3".*), b));
//     try expect(!isMoveValid(Move.fromStr("b4-c3".*), b));
// }
