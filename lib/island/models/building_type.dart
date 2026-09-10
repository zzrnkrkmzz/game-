import '../../board/models/block_color.dart';

/// Ada'da inşa edilebilen bina türleri (bkz. docs/GDD.md, Bölüm 3 -
/// "Meta Katman: Üs/Ada Kurma"). Her bina tahtaya dokunmadan pasif bir
/// bonus verir; bu bonusun oyun mekaniğine bağlanması ileri fazlara aittir
/// (bkz. docs/GDD.md, Bölüm 14).
enum BuildingType { warehouse, mill, market, lighthouse }

extension BuildingTypeX on BuildingType {
  String get displayName => switch (this) {
    BuildingType.warehouse => 'Depo',
    BuildingType.mill => 'Değirmen',
    BuildingType.market => 'Pazar',
    BuildingType.lighthouse => 'Fener',
  };

  String get icon => switch (this) {
    BuildingType.warehouse => '🏚️',
    BuildingType.mill => '⚙️',
    BuildingType.market => '🏪',
    BuildingType.lighthouse => '🗼',
  };

  /// Binanın hangi kaynakla inşa edilip yükseltildiği.
  ResourceType get costResource => switch (this) {
    BuildingType.warehouse => ResourceType.wood,
    BuildingType.mill => ResourceType.stone,
    BuildingType.market => ResourceType.wood,
    BuildingType.lighthouse => ResourceType.crystal,
  };

  static const int maxLevel = 5;

  /// Bina seviye 0'dan (henüz inşa edilmemiş) [level]'e (1..maxLevel)
  /// çıkarmanın maliyeti. Her seviye bir öncekinden %60 daha pahalıdır.
  int costForLevel(int level) {
    final base = switch (this) {
      BuildingType.warehouse => 10,
      BuildingType.mill => 10,
      BuildingType.market => 12,
      BuildingType.lighthouse => 15,
    };
    return (base * _growth(level)).round();
  }

  double _growth(int level) {
    var multiplier = 1.0;
    for (var i = 1; i < level; i++) {
      multiplier *= 1.6;
    }
    return multiplier;
  }

  /// Binanın [level] seviyesindeki etkisinin kısa açıklaması.
  /// bkz. docs/GDD.md, Bölüm 3 tablosu.
  String effectDescriptionFor(int level) {
    if (level <= 0) return 'Henüz inşa edilmedi';
    return switch (this) {
      BuildingType.warehouse => 'Tahtada +$level ekstra geri al hakkı',
      BuildingType.mill => 'Satır temizlemede +$level ekstra 🪨',
      BuildingType.market => 'Kaynağı gem\'e çevirme oranı +%${level * 5}',
      BuildingType.lighthouse => 'Günlük ödül çarpanı +%${level * 10}',
    };
  }
}
