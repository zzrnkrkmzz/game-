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
class Piece {
  const Piece({required this.shape, required this.color});

  final PieceShape shape;
  final BlockColor color;

  int get cellCount => shape.length;

  int get height => shape.map((p) => p.row).reduce((a, b) => a > b ? a : b) + 1;

  int get width => shape.map((p) => p.col).reduce((a, b) => a > b ? a : b) + 1;
}
