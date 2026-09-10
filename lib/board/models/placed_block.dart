import 'block_color.dart';

/// Tahtaya yerleştirilmiş tek bir hücrenin durumu. Normal bloklar tek
/// vuruşta (satırı/sütunu tamamlayan ilk temizlikte) kaybolur; buz bloğu
/// 2 vuruş gerektirir (bkz. docs/GDD.md, Bölüm 4 - "Buz bloğu: 2 vuruş").
/// Bonus bloklar temizlendiğinde ekstra kaynak ödülü verir.
class PlacedBlock {
  const PlacedBlock({
    required this.color,
    required this.remainingHits,
    this.isBonus = false,
  });

  factory PlacedBlock.normal(BlockColor color, {bool isBonus = false}) =>
      PlacedBlock(color: color, remainingHits: 1, isBonus: isBonus);

  factory PlacedBlock.ice(BlockColor color) =>
      PlacedBlock(color: color, remainingHits: 2);

  final BlockColor color;
  final int remainingHits;
  final bool isBonus;

  bool get isIce => remainingHits > 1;

  /// Bir vuruş daha alır. Kalan vuruş 0'a inerse `null` döner (hücre
  /// tamamen temizlenir); aksi halde aynı renkte, bir eksik vuruşlu yeni
  /// bir blok döner.
  PlacedBlock? hit() {
    final next = remainingHits - 1;
    if (next <= 0) return null;
    return PlacedBlock(color: color, remainingHits: next, isBonus: isBonus);
  }
}
