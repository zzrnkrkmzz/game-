import 'dart:math';

import 'package:ada_blast/board/logic/game_controller.dart';
import 'package:ada_blast/board/logic/piece_generator.dart';
import 'package:ada_blast/board/models/block_color.dart';
import 'package:ada_blast/board/models/board_state.dart';
import 'package:ada_blast/board/models/piece.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testlerde tepsiye gelecek parçaları tamamen belirlemek için kullanılan
/// sahte üretici — gerçek [PieceGenerator]'ın ağırlıklı rastgele seçimini
/// (ve dolayısıyla PieceShapes havuzundaki değişikliklere kırılganlığı)
/// devre dışı bırakır.
class _FixedPieceGenerator extends PieceGenerator {
  _FixedPieceGenerator(this._trayBuilder);

  final List<Piece> Function() _trayBuilder;

  @override
  List<Piece> generateTray(BoardState board, {bool iceEnabled = false}) =>
      _trayBuilder();
}

/// 8 hücrelik yatay tam satır parçası — tek başına bir satırı tamamlar.
Piece _fullRow({BlockColor color = BlockColor.coral}) =>
    Piece(shape: [for (var c = 0; c < 8; c++) Point(0, c)], color: color);

Piece _singleCell({BlockColor color = BlockColor.amber}) =>
    Piece(shape: const [Point(0, 0)], color: color);

void main() {
  group('GameController', () {
    test('yeni oyun 0 skorla ve 3 parçalık dolu bir tepsiyle başlar', () {
      final controller = GameController(
        generator: PieceGenerator(random: Random(1)),
      );

      expect(controller.state.score, 0);
      expect(controller.state.tray.length, 3);
      expect(controller.state.tray.every((p) => p != null), isTrue);
      expect(controller.state.isGameOver, isFalse);
    });

    test('geçerli bir yerleştirme skoru ve kaynakları artırır', () {
      final controller = GameController(
        generator: PieceGenerator(random: Random(1)),
      );
      final piece = controller.state.tray[0]!;

      controller.placePiece(0, 0, 0);

      expect(controller.state.score, greaterThanOrEqualTo(piece.cellCount));
      expect(controller.state.tray[0], isNot(equals(piece)));
    });

    test('geçersiz yerleştirme durumu değiştirmez', () {
      final controller = GameController(
        generator: PieceGenerator(random: Random(1)),
      );
      final before = controller.state;

      // Tahta dışına yerleştirme denemesi.
      controller.placePiece(0, 100, 100);

      expect(controller.state, same(before));
    });

    test('tepsideki tüm parçalar bitince otomatik olarak yenilenir', () {
      final controller = GameController(
        generator: PieceGenerator(random: Random(3)),
      );

      // Aynı hücrelere denk gelmeyecek şekilde 3 parçayı da farklı
      // bölgelere yerleştir.
      controller.placePiece(0, 0, 0);
      controller.placePiece(1, 3, 0);
      controller.placePiece(2, 6, 0);

      expect(controller.state.tray.every((p) => p != null), isTrue);
    });

    test('newGame skoru ve tahtayı sıfırlar', () {
      final controller = GameController(
        generator: PieceGenerator(random: Random(1)),
      );
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

  group('GameController - peş peşe temizlik serisi (streak)', () {
    test('art arda satır temizleyen hamlelerde bonus artarak eklenir, temizliksiz hamlede sıfırlanır', () {
      final controller = GameController(
        generator: _FixedPieceGenerator(
          () => [_fullRow(), _fullRow(), _singleCell()],
        ),
      );

      controller.placePiece(0, 0, 0); // satır 0 temizlenir — ilk temizlik
      expect(controller.state.clearStreak, 1);
      expect(controller.state.lastStreakBonus, 0);

      controller.placePiece(1, 1, 0); // satır 1 temizlenir — 2. ardışık
      expect(controller.state.clearStreak, 2);
      expect(controller.state.lastStreakBonus, GameController.streakBonusStep);

      controller.placePiece(2, 2, 0); // tek hücre, hiçbir satırı tamamlamaz
      expect(controller.state.clearStreak, 0);
      expect(controller.state.lastStreakBonus, 0);

      // Tepsi burada yenilendi (aynı sabit üç parça) — yeni bir seri
      // başladığını doğrula (öncekinden devam etmiyor).
      controller.placePiece(0, 3, 0); // satır 3 temizlenir
      expect(controller.state.clearStreak, 1);
      expect(controller.state.lastStreakBonus, 0);
    });
  });

  group('GameController - Değirmen (mill) kaynak bonusu', () {
    test('satır temizlenince mill seviyesi kadar ekstra taş verilir', () {
      final gains = <Map<ResourceType, int>>[];
      final controller = GameController(
        generator: _FixedPieceGenerator(
          () => [_fullRow(), _fullRow(), _fullRow()],
        ),
        millBonusLevel: () => 3,
        onResourcesGained: gains.add,
      );

      controller.placePiece(0, 0, 0); // 8 mercan hücre temizlenir → 8 odun

      expect(gains, hasLength(1));
      expect(gains.single[ResourceType.wood], 8);
      // Mill bonusu, temizlenen satırdaki renkten bağımsız olarak taş verir.
      expect(gains.single[ResourceType.stone], 3);
    });

    test('mill seviyesi 0 iken bonus verilmez', () {
      final gains = <Map<ResourceType, int>>[];
      final controller = GameController(
        generator: _FixedPieceGenerator(
          () => [_fullRow(), _fullRow(), _fullRow()],
        ),
        onResourcesGained: gains.add,
      );

      controller.placePiece(0, 0, 0);

      expect(gains.single.containsKey(ResourceType.stone), isFalse);
    });
  });

  group('GameController - Depo (undo) hakkı', () {
    test('undo hakkı varsa son hamleyi geri alır ve hakkı bir azaltır', () {
      final controller = GameController(
        generator: _FixedPieceGenerator(
          () => [_fullRow(), _fullRow(), _fullRow()],
        ),
        maxUndos: () => 1,
      );

      controller.placePiece(0, 0, 0);
      expect(controller.state.score, greaterThan(0));
      expect(controller.state.undosRemaining, 1);

      controller.undo();

      expect(controller.state.score, 0);
      expect(controller.state.board.filledCellCount, 0);
      expect(controller.state.undosRemaining, 0);
    });

    test('undo hakkı tükenince tekrar geri alma yapılmaz', () {
      final controller = GameController(
        generator: _FixedPieceGenerator(
          () => [_fullRow(), _fullRow(), _fullRow()],
        ),
        maxUndos: () => 1,
      );

      controller.placePiece(0, 0, 0);
      controller.undo();
      final afterFirstUndo = controller.state;

      controller.undo();

      expect(controller.state, same(afterFirstUndo));
    });

    test('Depo inşa edilmemişse (maxUndos 0) undo hiçbir şey yapmaz', () {
      final controller = GameController(
        generator: _FixedPieceGenerator(
          () => [_fullRow(), _fullRow(), _fullRow()],
        ),
      );

      controller.placePiece(0, 0, 0);
      final before = controller.state;

      controller.undo();

      expect(controller.state, same(before));
    });
  });
}
