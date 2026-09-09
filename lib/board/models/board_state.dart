import 'block_color.dart';
import 'piece.dart';
import 'placed_block.dart';

/// Bir parça yerleştirmenin sonucu: kaç hücre doldu, kaç satır/sütun
/// temizlendi ve bu temizlik sonucu hangi kaynaklardan ne kadar kazanıldı.
class PlacementResult {
  const PlacementResult({
    required this.cellsPlaced,
    required this.linesCleared,
    required this.scoreGained,
    required this.resourcesGained,
  });

  final int cellsPlaced;
  final int linesCleared;
  final int scoreGained;
  final Map<ResourceType, int> resourcesGained;
}

/// 8x8 oyun tahtası. Her hücre boşsa `null`, doluysa o hücredeki
/// [PlacedBlock]'u tutar (bkz. docs/GDD.md, Bölüm 2 ve Bölüm 4 - buz/bonus
/// blok mekaniği).
class BoardState {
  BoardState({int size = 8})
    : size = size,
      _cells = List.generate(size, (_) => List<PlacedBlock?>.filled(size, null));

  BoardState._fromCells(this._cells) : size = _cells.length;

  /// Bir bonus hücre tamamen temizlendiğinde normal 1 kaynağa ek olarak
  /// verilen ekstra miktar (bkz. docs/GDD.md, Bölüm 4 - "bonus blok").
  static const int bonusExtraResource = 3;

  final int size;
  final List<List<PlacedBlock?>> _cells;

  PlacedBlock? cellAt(int row, int col) => _cells[row][col];

  int get filledCellCount =>
      _cells.expand((row) => row).where((c) => c != null).length;

  /// Tahtanın doluluk oranı (0.0 - 1.0). Anti-frustration eşiği için kullanılır.
  double get fillRatio => filledCellCount / (size * size);

  BoardState copy() =>
      BoardState._fromCells(_cells.map((row) => List<PlacedBlock?>.from(row)).toList());

  /// [piece], (anchorRow, anchorCol) konumuna tahtanın sınırları içinde ve
  /// dolu hücreyle çakışmadan yerleştirilebiliyorsa `true` döner.
  bool canPlace(Piece piece, int anchorRow, int anchorCol) {
    for (final cell in piece.shape) {
      final r = anchorRow + cell.row;
      final c = anchorCol + cell.col;
      if (r < 0 || r >= size || c < 0 || c >= size) return false;
      if (_cells[r][c] != null) return false;
    }
    return true;
  }

  /// Tahtanın herhangi bir yerine [piece] sığıyor mu?
  bool canPlaceAnywhere(Piece piece) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (canPlace(piece, r, c)) return true;
      }
    }
    return false;
  }

  /// [piece]'i (anchorRow, anchorCol) konumuna yerleştirir, tamamlanan
  /// satır/sütunları işler ve kazanılan skor + kaynakları döner.
  ///
  /// Buz bloklarının (bkz. [PlacedBlock.isIce]) bulunduğu bir satır/sütun
  /// tamamlansa bile o hücre hemen kaybolmaz — yalnızca bir vuruş alır;
  /// tamamen temizlenmesi (ve kaynak vermesi) ikinci tamamlanışta olur.
  /// Skor açısından ise satır/sütun her tamamlanışında sayılır (buz hücre
  /// tam temizlenmemiş olsa bile).
  ///
  /// Çağırmadan önce [canPlace] ile doğrulanmalıdır.
  PlacementResult place(Piece piece, int anchorRow, int anchorCol) {
    assert(canPlace(piece, anchorRow, anchorCol), 'Geçersiz yerleştirme');

    final placedBlock = piece.isIce
        ? PlacedBlock.ice(piece.color)
        : PlacedBlock.normal(piece.color, isBonus: piece.isBonus);
    for (final cell in piece.shape) {
      _cells[anchorRow + cell.row][anchorCol + cell.col] = placedBlock;
    }

    final fullRows = <int>[
      for (var r = 0; r < size; r++)
        if (_cells[r].every((c) => c != null)) r,
    ];
    final fullCols = <int>[
      for (var c = 0; c < size; c++)
        if (_cells.every((row) => row[c] != null)) c,
    ];

    final completedCoords = <(int, int)>{};
    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        completedCoords.add((r, c));
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        completedCoords.add((r, c));
      }
    }

    final resourcesGained = <ResourceType, int>{};
    void addResource(ResourceType type, int amount) {
      resourcesGained.update(type, (v) => v + amount, ifAbsent: () => amount);
    }

    for (final (r, c) in completedCoords) {
      final block = _cells[r][c];
      if (block == null) continue;

      final afterHit = block.hit();
      _cells[r][c] = afterHit;

      if (afterHit == null) {
        // Hücre tamamen temizlendi — kaynağını ver.
        addResource(block.color.resource, 1);
        if (block.isBonus) {
          addResource(block.color.resource, bonusExtraResource);
        }
      }
    }

    final linesCleared = fullRows.length + fullCols.length;
    final score = ScoreCalculator.calculate(
      cellsPlaced: piece.cellCount,
      linesCleared: linesCleared,
    );

    return PlacementResult(
      cellsPlaced: piece.cellCount,
      linesCleared: linesCleared,
      scoreGained: score,
      resourcesGained: resourcesGained,
    );
  }
}

/// Skor hesaplama kuralları (bkz. docs/GDD.md, Bölüm 2 - Çekirdek Döngü):
/// her yerleştirilen hücre 1 puan, temizlenen her satır/sütun 100 puan,
/// aynı hamlede birden fazla satır/sütun temizlenirse ek kombo bonusu verir.
class ScoreCalculator {
  ScoreCalculator._();

  static const int pointsPerCell = 1;
  static const int pointsPerLine = 100;
  static const int comboBonusPerExtraLine = 50;

  static int calculate({required int cellsPlaced, required int linesCleared}) {
    var score = cellsPlaced * pointsPerCell;
    if (linesCleared > 0) {
      score += linesCleared * pointsPerLine;
      if (linesCleared > 1) {
        score += (linesCleared - 1) * comboBonusPerExtraLine;
      }
    }
    return score;
  }
}
