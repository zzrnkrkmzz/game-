import 'dart:math';

import 'package:ada_blast/board/logic/game_controller.dart';
import 'package:ada_blast/board/logic/piece_generator.dart';
import 'package:ada_blast/board/models/block_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameController', () {
    test('yeni oyun 0 skorla ve 3 parçalık dolu bir tepsiyle başlar', () {
      final controller = GameController(generator: PieceGenerator(random: Random(1)));

      expect(controller.state.score, 0);
      expect(controller.state.tray.length, 3);
      expect(controller.state.tray.every((p) => p != null), isTrue);
      expect(controller.state.isGameOver, isFalse);
    });

    test('geçerli bir yerleştirme skoru ve kaynakları artırır', () {
      final controller = GameController(generator: PieceGenerator(random: Random(1)));
      final piece = controller.state.tray[0]!;

      controller.placePiece(0, 0, 0);

      expect(controller.state.score, greaterThanOrEqualTo(piece.cellCount));
      expect(controller.state.tray[0], isNot(equals(piece)));
    });

    test('geçersiz yerleştirme durumu değiştirmez', () {
      final controller = GameController(generator: PieceGenerator(random: Random(1)));
      final before = controller.state;

      // Tahta dışına yerleştirme denemesi.
      controller.placePiece(0, 100, 100);

      expect(controller.state, same(before));
    });

    test('tepsideki tüm parçalar bitince otomatik olarak yenilenir', () {
      final controller = GameController(generator: PieceGenerator(random: Random(3)));

      // Aynı hücrelere denk gelmeyecek şekilde 3 parçayı da farklı
      // bölgelere yerleştir.
      controller.placePiece(0, 0, 0);
      controller.placePiece(1, 3, 0);
      controller.placePiece(2, 6, 0);

      expect(controller.state.tray.every((p) => p != null), isTrue);
    });

    test('newGame skoru ve tahtayı sıfırlar', () {
      final controller = GameController(generator: PieceGenerator(random: Random(1)));
      controller.placePiece(0, 0, 0);

      controller.newGame();

      expect(controller.state.score, 0);
      expect(controller.state.board.filledCellCount, 0);
    });

    test('her geçerli yerleştirmede onResourcesGained çağrılır', () {
      final gains = <Map<ResourceType, int>>[];
      final controller = GameController(
        generator: PieceGenerator(random: Random(1)),
        onResourcesGained: gains.add,
      );

      controller.placePiece(0, 0, 0);

      // Tek bir yerleştirme satır/sütun temizlemese bile (kaynak kazancı
      // sıfır olabilir), cüzdana bildirim tam olarak bir kez yapılmalı.
      // Kaynakların doğru miktar/renk eşleşmesi BoardState.place testlerinde
      // (board_state_test.dart) ve ResourceWallet testlerinde ayrıca
      // doğrulanıyor.
      expect(gains.length, 1);
    });
  });
}
