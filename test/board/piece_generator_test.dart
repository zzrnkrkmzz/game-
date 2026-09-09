import 'dart:math';

import 'package:ada_blast/board/logic/piece_generator.dart';
import 'package:ada_blast/board/models/block_color.dart';
import 'package:ada_blast/board/models/board_state.dart';
import 'package:ada_blast/board/models/piece.dart';
import 'package:ada_blast/board/models/piece_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieceGenerator', () {
    test('her zaman istenen sayıda parça üretir', () {
      final generator = PieceGenerator(random: Random(1));
      final board = BoardState(size: 8);

      final tray = generator.generateTray(board);

      expect(tray.length, PieceGenerator.traySize);
    });

    test(
      'tahta doluluk eşiğinin (%75) üzerindeyken üretilen tepside her zaman '
      'sığan en az bir parça vardır (anti-frustration)',
      () {
        final generator = PieceGenerator(random: Random(42));
        final board = _diagonalGapsBoard();

        // %87.5 dolu (64 hücrenin 56'sı) ve boş kalan 8 hücre (köşegen)
        // birbirine komşu değil — yalnızca "single" (1 hücrelik) parça
        // sığabiliyor. Bu, anti-frustration güvenlik ağını gerçekten test
        // eden dar bir senaryo.
        expect(board.fillRatio, greaterThanOrEqualTo(0.75));

        for (var i = 0; i < 200; i++) {
          final tray = generator.generateTray(board);
          final anyFits = tray.any(board.canPlaceAnywhere);
          expect(
            anyFits,
            isTrue,
            reason: 'Doluluk %75 üzerindeyken tepside sığan parça olmalı',
          );
        }
      },
    );

    test('yalnızca köşegenin sığdığı bir tahtada güvenlik ağı "single" parça bulur', () {
      final generator = PieceGenerator(random: Random(7));
      final board = _diagonalGapsBoard();

      final piece = generator.generateTray(board).firstWhere(
        board.canPlaceAnywhere,
        orElse: () => throw StateError('sığan parça bulunamadı'),
      );

      expect(piece.cellCount, 1);
    });

    test('iceEnabled false iken hiçbir parça buz olmaz', () {
      final generator = PieceGenerator(random: Random(3));
      final board = BoardState(size: 8);

      for (var i = 0; i < 300; i++) {
        final tray = generator.generateTray(board, iceEnabled: false);
        expect(tray.any((p) => p.isIce), isFalse);
      }
    });

    test('iceEnabled true iken zaman içinde buzlu parça üretilir', () {
      final generator = PieceGenerator(random: Random(3));
      final board = BoardState(size: 8);

      final anyIce = List.generate(
        100,
        (_) => generator.generateTray(board, iceEnabled: true),
      ).any((tray) => tray.any((p) => p.isIce));

      expect(anyIce, isTrue);
    });

    test('bir parça aynı anda hem buz hem bonus olamaz', () {
      final generator = PieceGenerator(random: Random(5));
      final board = BoardState(size: 8);

      for (var i = 0; i < 300; i++) {
        final tray = generator.generateTray(board, iceEnabled: true);
        for (final piece in tray) {
          expect(piece.isIce && piece.isBonus, isFalse);
        }
      }
    });
  });
}

/// 8x8'lik, yalnızca köşegeni ((i,i)) boş bırakılmış bir tahta üretir.
/// %87.5 dolu olsa da hiçbir satır/sütun tam olmadığından `place()`
/// içindeki otomatik temizlik tetiklenmez. Boş 8 hücre birbirine komşu
/// olmadığından yalnızca tek hücrelik ("single") parçalar sığabilir —
/// bu da anti-frustration güvenlik ağını test etmek için dar bir senaryo
/// oluşturur.
BoardState _diagonalGapsBoard() {
  final board = BoardState(size: 8);
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      if (r == c) continue;
      board.place(
        const Piece(shape: PieceShapes.single, color: BlockColor.coral),
        r,
        c,
      );
    }
  }
  return board;
}
