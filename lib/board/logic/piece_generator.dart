import 'dart:math';

import '../models/block_color.dart';
import '../models/board_state.dart';
import '../models/piece.dart';
import '../models/piece_shapes.dart';

/// Tepsiye gelecek parçaları üretir.
///
/// bkz. docs/GDD.md, Bölüm 2 - "Zorluk eğrisi: Yumuşak Anti-Frustration":
/// parçalar hücre sayısına göre ağırlıklı rastgele seçilir (küçük parçalar
/// daha sık gelir). Tahta doluluk oranı [antiFrustrationThreshold] değerini
/// geçtiğinde, üretilen tepside tahtaya sığan en az bir parça olması garanti
/// edilir — oyuncu bunu fark etmez, ama ani/haksız oyun bitişleri azalır.
class PieceGenerator {
  PieceGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const double antiFrustrationThreshold = 0.75;
  static const int traySize = 3;

  /// Kar biyomundan itibaren bir parçanın buz bloğu olma olasılığı
  /// (bkz. docs/GDD.md, Bölüm 4).
  static const double iceChance = 0.15;

  /// Herhangi bir biyomda bir parçanın bonus blok olma olasılığı.
  static const double bonusChance = 0.08;

  /// Küçük parçalara (1-3 hücre) daha yüksek, büyük parçalara (4-5 hücre)
  /// daha düşük ağırlık verir.
  int _weightOf(PieceShape shape) => switch (shape.length) {
    <= 2 => 5,
    3 => 4,
    4 => 3,
    _ => 2,
  };

  PieceShape _pickWeightedShape() {
    final weights = PieceShapes.all.map(_weightOf).toList();
    final total = weights.reduce((a, b) => a + b);
    var roll = _random.nextInt(total);
    for (var i = 0; i < PieceShapes.all.length; i++) {
      if (roll < weights[i]) return PieceShapes.all[i];
      roll -= weights[i];
    }
    return PieceShapes.all.last;
  }

  BlockColor _pickRandomColor() =>
      BlockColor.values[_random.nextInt(BlockColor.values.length)];

  Piece _randomPiece({bool iceEnabled = false}) {
    final roll = _random.nextDouble();
    final isIce = iceEnabled && roll < iceChance;
    final isBonus = !isIce && roll < iceChance + bonusChance;
    return Piece(
      shape: _pickWeightedShape(),
      color: _pickRandomColor(),
      isIce: isIce,
      isBonus: isBonus,
    );
  }

  /// [board]'un mevcut durumuna göre yeni bir tepsi (3 parça) üretir.
  /// [iceEnabled] `true` ise (Kar biyomu ve sonrası) parçalar arasına
  /// düşük olasılıkla buz bloğu karışabilir.
  List<Piece> generateTray(BoardState board, {bool iceEnabled = false}) {
    final tray = List.generate(
      traySize,
      (_) => _randomPiece(iceEnabled: iceEnabled),
    );

    final needsSafetyNet = board.fillRatio >= antiFrustrationThreshold &&
        !tray.any(board.canPlaceAnywhere);

    if (needsSafetyNet) {
      final guaranteed = _findAnyFittingPiece(board);
      if (guaranteed != null) {
        tray[_random.nextInt(traySize)] = guaranteed;
      }
    }

    return tray;
  }

  /// Tahtaya sığan en küçük parçadan başlayarak ilk uygun parçayı döner.
  /// Hiçbir parça sığmıyorsa (tahta neredeyse tamamen doluysa) `null` döner.
  Piece? _findAnyFittingPiece(BoardState board) {
    final shapesBySize = [...PieceShapes.all]
      ..sort((a, b) => a.length.compareTo(b.length));
    for (final shape in shapesBySize) {
      final piece = Piece(shape: shape, color: _pickRandomColor());
      if (board.canPlaceAnywhere(piece)) return piece;
    }
    return null;
  }
}
