import 'block_color.dart';

/// Bir parçanın (0,0) çapasına göre kapladığı hücreler.
typedef PieceShape = List<Point<int>>;

/// Basit tamsayı koordinat çifti (satır, sütun).
class Point<T extends num> {
  const Point(this.row, this.col);

  final T row;
  final T col;

  @override
  bool operator ==(Object other) =>
      other is Point && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// Tepside oynanabilir bir parça: bir şekil + bir renk.
///
/// [isIce] ve [isBonus] tüm parçayı etkiler (parça içindeki her hücre aynı
/// özel türde olur) — bu, gerçek oyunlardaki hücre bazlı buz/bonus
/// bloklarının basitleştirilmiş bir versiyonudur (bkz. docs/GDD.md,
/// Bölüm 4). Bir parça aynı anda hem buz hem bonus olamaz.
class Piece {
  const Piece({
    required this.shape,
    required this.color,
    this.isIce = false,
    this.isBonus = false,
  }) : assert(!(isIce && isBonus), 'Bir parça aynı anda buz ve bonus olamaz');

  final PieceShape shape;
  final BlockColor color;
  final bool isIce;
  final bool isBonus;

  int get cellCount => shape.length;

  int get height => shape.map((p) => p.row).reduce((a, b) => a > b ? a : b) + 1;

  int get width => shape.map((p) => p.col).reduce((a, b) => a > b ? a : b) + 1;
}
