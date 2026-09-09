import 'package:flutter/material.dart';

/// Ada'nın toplam bina seviyesine göre değişen görsel/mekanik tema
/// (bkz. docs/GDD.md, Bölüm 4 - Tema/Biyom İlerlemesi ve Koleksiyon).
enum BiomeType { forest, desert, snow, space }

extension BiomeTypeX on BiomeType {
  String get displayName => switch (this) {
    BiomeType.forest => 'Orman',
    BiomeType.desert => 'Çöl',
    BiomeType.snow => 'Kar',
    BiomeType.space => 'Uzay',
  };

  String get icon => switch (this) {
    BiomeType.forest => '🌲',
    BiomeType.desert => '🏜️',
    BiomeType.snow => '❄️',
    BiomeType.space => '🪐',
  };

  Color get accentColor => switch (this) {
    BiomeType.forest => const Color(0xFF6FD9C4),
    BiomeType.desert => const Color(0xFFFFC96B),
    BiomeType.snow => const Color(0xFF9FD8FF),
    BiomeType.space => const Color(0xFFB695D9),
  };

  /// Kar biyomundan itibaren tahtaya buz bloğu (2 vuruşta temizlenen)
  /// karışabilir (bkz. docs/GDD.md, Bölüm 4).
  bool get hasIceBlocks => index >= BiomeType.snow.index;

  /// [totalBuildingLevel] (adadaki tüm bina seviyelerinin toplamı, 0-20
  /// arası) hangi biyoma denk geliyor.
  static BiomeType forTotalLevel(int totalBuildingLevel) {
    if (totalBuildingLevel >= 15) return BiomeType.space;
    if (totalBuildingLevel >= 10) return BiomeType.snow;
    if (totalBuildingLevel >= 5) return BiomeType.desert;
    return BiomeType.forest;
  }

  /// Bir sonraki biyoma geçmek için gereken toplam bina seviyesi.
  /// Zaten son biyomdaysa `null` döner.
  int? get nextThreshold => switch (this) {
    BiomeType.forest => 5,
    BiomeType.desert => 10,
    BiomeType.snow => 15,
    BiomeType.space => null,
  };
}
