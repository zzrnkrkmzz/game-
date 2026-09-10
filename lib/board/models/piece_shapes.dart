import 'piece.dart';

/// Klasik "block blast" tarzı oyunlarda kullanılan standart parça şekilleri
/// havuzu (1 ila 5 hücre arası). Tepsiye gelecek parçalar bu havuzdan seçilir
/// (bkz. docs/GDD.md, Bölüm 2 - Zorluk eğrisi).
class PieceShapes {
  PieceShapes._();

  static const PieceShape single = [Point(0, 0)];

  static const PieceShape dominoH = [Point(0, 0), Point(0, 1)];
  static const PieceShape dominoV = [Point(0, 0), Point(1, 0)];

  static const PieceShape triominoIH = [Point(0, 0), Point(0, 1), Point(0, 2)];
  static const PieceShape triominoIV = [Point(0, 0), Point(1, 0), Point(2, 0)];

  static const PieceShape triominoL1 = [Point(0, 0), Point(1, 0), Point(1, 1)];
  static const PieceShape triominoL2 = [Point(0, 0), Point(0, 1), Point(1, 0)];
  static const PieceShape triominoL3 = [Point(0, 0), Point(0, 1), Point(1, 1)];
  static const PieceShape triominoL4 = [Point(0, 1), Point(1, 0), Point(1, 1)];

  static const PieceShape square = [
    Point(0, 0),
    Point(0, 1),
    Point(1, 0),
    Point(1, 1),
  ];

  static const PieceShape tetrominoIH = [
    Point(0, 0),
    Point(0, 1),
    Point(0, 2),
    Point(0, 3),
  ];
  static const PieceShape tetrominoIV = [
    Point(0, 0),
    Point(1, 0),
    Point(2, 0),
    Point(3, 0),
  ];

  static const PieceShape tetrominoT = [
    Point(0, 0),
    Point(0, 1),
    Point(0, 2),
    Point(1, 1),
  ];

  static const PieceShape tetrominoL = [
    Point(0, 0),
    Point(1, 0),
    Point(2, 0),
    Point(2, 1),
  ];
  static const PieceShape tetrominoJ = [
    Point(0, 1),
    Point(1, 1),
    Point(2, 0),
    Point(2, 1),
  ];

  static const PieceShape pentominoP = [
    Point(0, 0),
    Point(0, 1),
    Point(1, 0),
    Point(1, 1),
    Point(2, 0),
  ];

  /// "Artı" (plus) pentomino — klasik block-blast oyunlarında yaygın,
  /// tüm yönlerden komşu hücre isteyen, yerleştirmesi en zor şekillerden.
  static const PieceShape pentominoPlus = [
    Point(0, 1),
    Point(1, 0),
    Point(1, 1),
    Point(1, 2),
    Point(2, 1),
  ];

  /// 5 hücrelik düz çizgiler — mevcut en uzun parça 4 hücreydi, bunlar
  /// tahtada tam bir satır/sütunun daha büyük bir bölümünü tek hamlede
  /// kapatabilen "büyük" parçalar.
  static const PieceShape pentominoIH = [
    Point(0, 0),
    Point(0, 1),
    Point(0, 2),
    Point(0, 3),
    Point(0, 4),
  ];
  static const PieceShape pentominoIV = [
    Point(0, 0),
    Point(1, 0),
    Point(2, 0),
    Point(3, 0),
    Point(4, 0),
  ];

  /// "Çapraz" (X) parça — köşegen düzende, ortası ve dört köşesi dolu.
  /// Aralarında boşluk bıraktığı için yerleştirmesi en zor şekillerden.
  static const PieceShape crossX = [
    Point(0, 0),
    Point(0, 2),
    Point(1, 1),
    Point(2, 0),
    Point(2, 2),
  ];

  /// 3x3'lük büyük kare — havuzdaki en büyük (9 hücre) parça.
  static const PieceShape bigSquare = [
    Point(0, 0),
    Point(0, 1),
    Point(0, 2),
    Point(1, 0),
    Point(1, 1),
    Point(1, 2),
    Point(2, 0),
    Point(2, 1),
    Point(2, 2),
  ];

  /// Tepsi üretiminde ağırlıklı rastgele seçim için kullanılan tüm havuz.
  /// Küçük parçalar (1-3 hücre) daha sık, büyük parçalar (4+ hücre) daha
  /// seyrek gelir — bu, `PieceGenerator` tarafından ağırlıklandırılır.
  static const List<PieceShape> all = [
    single,
    dominoH,
    dominoV,
    triominoIH,
    triominoIV,
    triominoL1,
    triominoL2,
    triominoL3,
    triominoL4,
    square,
    tetrominoIH,
    tetrominoIV,
    tetrominoT,
    tetrominoL,
    tetrominoJ,
    pentominoP,
    pentominoPlus,
    pentominoIH,
    pentominoIV,
    crossX,
    bigSquare,
  ];
}
