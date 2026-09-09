import 'block_color.dart';
import 'piece.dart';

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

/// 8x8 oyun tahtası. Her hücre boşsa `null`, doluysa o hücreyi dolduran
/// [BlockColor] değerini tutar (bkz. docs/GDD.md, Bölüm 2).
class BoardState {
  BoardState({int size = 8})
    : size = size,
      _cells = List.generate(size, (_) => List<BlockColor?>.filled(size, null));

  BoardState._fromCells(this._cells) : size = _cells.length;

  final int size;
  final List<List<BlockColor?>> _cells;

  BlockColor? cellAt(int row, int col) => _cells[row][col];

  int get filledCellCount =>
      _cells.expand((row) => row).where((c) => c != null).length;

  /// Tahtanın doluluk oranı (0.0 - 1.0). Anti-frustration eşiği için kullanılır.
  double get fillRatio => filledCellCount / (size * size);

  BoardState copy() =>
      BoardState._fromCells(_cells.map((row) => List<BlockColor?>.from(row)).toList());

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
  /// satır/sütunları temizler ve kazanılan skor + kaynakları döner.
  ///
  /// Çağırmadan önce [canPlace] ile doğrulanmalıdır.
  PlacementResult place(Piece piece, int anchorRow, int anchorCol) {
    assert(canPlace(piece, anchorRow, anchorCol), 'Geçersiz yerleştirme');

    for (final cell in piece.shape) {
      _cells[anchorRow + cell.row][anchorCol + cell.col] = piece.color;
    }

    final fullRows = <int>[
      for (var r = 0; r < size; r++)
        if (_cells[r].every((c) => c != null)) r,
    ];
    final fullCols = <int>[
      for (var c = 0; c < size; c++)
        if (_cells.every((row) => row[c] != null)) c,
    ];

    final resourcesGained = <ResourceType, int>{};
    final clearedCoords = <(int, int)>{};

    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        clearedCoords.add((r, c));
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        clearedCoords.add((r, c));
      }
    }

    for (final (r, c) in clearedCoords) {
      final color = _cells[r][c];
      if (color != null) {
        resourcesGained.update(
          color.resource,
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
    }

    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        _cells[r][c] = null;
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        _cells[r][c] = null;
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
