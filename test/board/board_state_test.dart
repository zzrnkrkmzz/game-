import 'package:ada_blast/board/models/block_color.dart';
import 'package:ada_blast/board/models/board_state.dart';
import 'package:ada_blast/board/models/piece.dart';
import 'package:ada_blast/board/models/piece_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardState.canPlace', () {
    test('boş tahtaya sığan bir parça yerleştirilebilir', () {
      final board = BoardState(size: 8);
      const piece = Piece(shape: PieceShapes.square, color: BlockColor.coral);
      expect(board.canPlace(piece, 0, 0), isTrue);
    });

    test('tahta sınırlarının dışına taşan parça yerleştirilemez', () {
      final board = BoardState(size: 8);
      const piece = Piece(
        shape: PieceShapes.tetrominoIH,
        color: BlockColor.coral,
      );
      expect(board.canPlace(piece, 0, 6), isFalse);
      expect(board.canPlace(piece, 8, 0), isFalse);
    });

    test('dolu hücreyle çakışan parça yerleştirilemez', () {
      final board = BoardState(size: 8);
      const piece = Piece(shape: PieceShapes.square, color: BlockColor.coral);
      board.place(piece, 0, 0);
      expect(board.canPlace(piece, 0, 0), isFalse);
    });
  });

  group('BoardState.place — satır/sütun temizleme', () {
    test('tamamen dolan bir satır temizlenir', () {
      final board = BoardState(size: 8);
      // Satır 0'ı 8 tekli parçayla doldur, sonuncusu satırı tamamlar.
      for (var col = 0; col < 7; col++) {
        board.place(
          const Piece(shape: PieceShapes.single, color: BlockColor.coral),
          0,
          col,
        );
      }
      final result = board.place(
        const Piece(shape: PieceShapes.single, color: BlockColor.seafoam),
        0,
        7,
      );

      expect(result.linesCleared, 1);
      for (var col = 0; col < 8; col++) {
        expect(board.cellAt(0, col), isNull);
      }
    });

    test('aynı anda bir satır ve bir sütun temizlenirse ikisi de sayılır', () {
      final board = BoardState(size: 8);
      // Satır 0'ı (0,0) hariç doldur.
      for (var col = 1; col < 8; col++) {
        board.place(
          const Piece(shape: PieceShapes.single, color: BlockColor.coral),
          0,
          col,
        );
      }
      // Sütun 0'ı (0,0) hariç doldur.
      for (var row = 1; row < 8; row++) {
        board.place(
          const Piece(shape: PieceShapes.single, color: BlockColor.coral),
          row,
          0,
        );
      }

      final result = board.place(
        const Piece(shape: PieceShapes.single, color: BlockColor.amber),
        0,
        0,
      );

      expect(result.linesCleared, 2);
      expect(board.filledCellCount, 0);
    });

    test('temizlenen bloklar renklerine göre doğru kaynağı verir', () {
      final board = BoardState(size: 8);
      for (var col = 0; col < 7; col++) {
        board.place(
          const Piece(shape: PieceShapes.single, color: BlockColor.coral),
          0,
          col,
        );
      }
      final result = board.place(
        const Piece(shape: PieceShapes.single, color: BlockColor.coral),
        0,
        7,
      );

      expect(result.resourcesGained[ResourceType.wood], 8);
      expect(result.resourcesGained.containsKey(ResourceType.stone), isFalse);
    });

    test('hiçbir satır/sütun tamamlanmazsa temizlik olmaz', () {
      final board = BoardState(size: 8);
      const piece = Piece(shape: PieceShapes.square, color: BlockColor.coral);
      final result = board.place(piece, 3, 3);

      expect(result.linesCleared, 0);
      expect(board.filledCellCount, 4);
    });
  });

  group('BoardState.canPlaceAnywhere', () {
    test('köşegen hariç dolu bir tahtada domino hiçbir yere sığmaz', () {
      final board = BoardState(size: 3);
      // (i, i) köşegeni boş bırakılacak şekilde diğer tüm hücreleri doldur.
      // Not: bir satır/sütunu tamamen doldurmak place() içinde otomatik
      // temizliği tetikler; bu yüzden her satır/sütunda kasıtlı olarak tam
      // bir hücre boş bırakılır.
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          if (r == c) continue;
          board.place(
            const Piece(shape: PieceShapes.single, color: BlockColor.coral),
            r,
            c,
          );
        }
      }

      // Boş hücreler yalnızca (0,0), (1,1), (2,2) — hiçbiri komşu değil.
      const domino = Piece(shape: PieceShapes.dominoH, color: BlockColor.coral);
      const single = Piece(shape: PieceShapes.single, color: BlockColor.coral);

      expect(board.canPlaceAnywhere(domino), isFalse);
      expect(board.canPlaceAnywhere(single), isTrue);
    });

    test('boş tahtada her zaman en az bir yer vardır', () {
      final board = BoardState(size: 8);
      const piece = Piece(
        shape: PieceShapes.tetrominoL,
        color: BlockColor.coral,
      );

      expect(board.canPlaceAnywhere(piece), isTrue);
    });
  });

  group('BoardState.place — buz ve bonus blok mekaniği', () {
    test('buz bloğu ilk satır tamamlanışında kaybolmaz, ikincide kaybolur', () {
      final board = BoardState(size: 8);
      board.place(
        const Piece(
          shape: PieceShapes.single,
          color: BlockColor.coral,
          isIce: true,
        ),
        0,
        0,
      );
      for (var col = 1; col < 8; col++) {
        board.place(
          const Piece(shape: PieceShapes.single, color: BlockColor.coral),
          0,
          col,
        );
      }

      // Satır tamamlandı (skor/kombo için sayılır) ama buz hücre kalıyor.
      expect(board.cellAt(0, 0), isNotNull);
      expect(
        board.cellAt(0, 0)!.isIce,
        isFalse,
      ); // 1 vuruş kaldı, artık "buz" değil
      expect(board.cellAt(0, 1), isNull);

      // Satırı tekrar doldurunca (col0 zaten dolu, col1-7'yi yeniden
      // doldurmak satırı ikinci kez tamamlar) buz hücre de temizlenir.
      PlacementResult? lastResult;
      for (var col = 1; col < 8; col++) {
        lastResult = board.place(
          const Piece(shape: PieceShapes.single, color: BlockColor.coral),
          0,
          col,
        );
      }

      expect(board.cellAt(0, 0), isNull);
      expect(lastResult!.linesCleared, 1);
    });

    test('bonus blok tamamen temizlenince ekstra kaynak verir', () {
      final board = BoardState(size: 8);
      for (var col = 0; col < 7; col++) {
        board.place(
          const Piece(shape: PieceShapes.single, color: BlockColor.coral),
          0,
          col,
        );
      }
      final result = board.place(
        const Piece(
          shape: PieceShapes.single,
          color: BlockColor.coral,
          isBonus: true,
        ),
        0,
        7,
      );

      // 8 hücre * 1 (normal) + 3 (bonus ekstra) = 11.
      expect(result.resourcesGained[ResourceType.wood], 11);
    });
  });
}
