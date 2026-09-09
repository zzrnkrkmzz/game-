import 'package:ada_blast/board/models/block_color.dart';
import 'package:ada_blast/board/models/board_state.dart';
import 'package:ada_blast/board/models/piece.dart';
import 'package:ada_blast/board/models/piece_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieceShapes', () {
    test('havuzda 21 farklı şekil var', () {
      expect(PieceShapes.all.length, 21);
    });

    test('artı (plus) pentomino 5 hücreden oluşur ve 3x3 alana sığar', () {
      const piece = Piece(
        shape: PieceShapes.pentominoPlus,
        color: BlockColor.coral,
      );

      expect(piece.cellCount, 5);
      expect(piece.width, 3);
      expect(piece.height, 3);
    });

    test('artı pentomino boş tahtaya yerleştirilebilir', () {
      final board = BoardState(size: 8);
      const piece = Piece(
        shape: PieceShapes.pentominoPlus,
        color: BlockColor.coral,
      );

      expect(board.canPlace(piece, 2, 2), isTrue);

      final result = board.place(piece, 2, 2);
      expect(result.cellsPlaced, 5);
      // Merkez + 4 kol dolu, köşeler boş.
      expect(board.cellAt(3, 3), isNotNull); // merkez
      expect(board.cellAt(2, 2), isNull); // sol-üst köşe boş kalmalı
    });

    test('çapraz (X) parça 5 hücreden oluşur ve 3x3 alana sığar', () {
      const piece = Piece(shape: PieceShapes.crossX, color: BlockColor.amber);

      expect(piece.cellCount, 5);
      expect(piece.width, 3);
      expect(piece.height, 3);
    });

    test('büyük kare (bigSquare) 9 hücreden oluşur ve boş tahtaya sığar', () {
      final board = BoardState(size: 8);
      const piece = Piece(
        shape: PieceShapes.bigSquare,
        color: BlockColor.seafoam,
      );

      expect(piece.cellCount, 9);
      expect(board.canPlace(piece, 0, 0), isTrue);
    });

    test('5 hücrelik düz çizgiler (I-pentomino) tahtaya sığar', () {
      final board = BoardState(size: 8);
      const horizontal = Piece(
        shape: PieceShapes.pentominoIH,
        color: BlockColor.coral,
      );
      const vertical = Piece(
        shape: PieceShapes.pentominoIV,
        color: BlockColor.coral,
      );

      expect(horizontal.cellCount, 5);
      expect(vertical.cellCount, 5);
      expect(board.canPlace(horizontal, 0, 0), isTrue);
      expect(board.canPlace(vertical, 0, 0), isTrue);
    });
  });
}
