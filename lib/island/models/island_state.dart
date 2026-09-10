import 'biome.dart';
import 'building_type.dart';

/// Ada'daki tüm binaların seviyesi. Seviye 0 = henüz inşa edilmedi.
class IslandState {
  const IslandState({required this.levels});

  factory IslandState.initial() =>
      IslandState(levels: {for (final type in BuildingType.values) type: 0});

  final Map<BuildingType, int> levels;

  int levelOf(BuildingType type) => levels[type] ?? 0;

  /// Tüm bina seviyelerinin toplamı — biyom eşiklerini belirler
  /// (bkz. docs/GDD.md, Bölüm 4).
  int get totalLevel => levels.values.fold(0, (sum, level) => sum + level);

  BiomeType get biome => BiomeTypeX.forTotalLevel(totalLevel);

  IslandState copyWith({Map<BuildingType, int>? levels}) =>
      IslandState(levels: levels ?? this.levels);
}
