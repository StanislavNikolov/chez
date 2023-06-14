const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub const Color = enum { empty, white, black };
// pub const PieceType = enum { pawn, knight, bishop, rook, queen, king };

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
