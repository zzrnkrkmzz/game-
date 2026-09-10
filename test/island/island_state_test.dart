import 'package:ada_blast/island/models/biome.dart';
import 'package:ada_blast/island/models/building_type.dart';
import 'package:ada_blast/island/models/island_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IslandState.totalLevel', () {
    test('başlangıçta 0dır', () {
      expect(IslandState.initial().totalLevel, 0);
    });

    test('bina seviyelerinin toplamıdır', () {
      final state = IslandState.initial().copyWith(
        levels: {
          BuildingType.warehouse: 2,
          BuildingType.mill: 3,
          BuildingType.market: 0,
          BuildingType.lighthouse: 1,
        },
      );

      expect(state.totalLevel, 6);
    });
  });

  test('IslandState.biome toplam seviyeye göre değişir', () {
    final forest = IslandState.initial();
    expect(forest.biome, BiomeType.forest);

    final desert = forest.copyWith(
      levels: {
        BuildingType.warehouse: 5,
        BuildingType.mill: 0,
        BuildingType.market: 0,
        BuildingType.lighthouse: 0,
      },
    );
    expect(desert.biome, BiomeType.desert);
  });
}
