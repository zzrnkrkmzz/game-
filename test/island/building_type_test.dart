import 'package:ada_blast/island/models/building_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildingType', () {
    test('her seviye bir öncekinden daha pahalıdır', () {
      for (final type in BuildingType.values) {
        var previousCost = 0;
        for (var level = 1; level <= BuildingTypeX.maxLevel; level++) {
          final cost = type.costForLevel(level);
          expect(
            cost,
            greaterThan(previousCost),
            reason: '$type seviye $level, öncekinden pahalı olmalı',
          );
          previousCost = cost;
        }
      }
    });

    test('seviye 0 açıklaması "henüz inşa edilmedi" der', () {
      expect(
        BuildingType.warehouse.effectDescriptionFor(0),
        contains('inşa edilmedi'),
      );
    });

    test('her bina türünün bir maliyet kaynağı vardır', () {
      for (final type in BuildingType.values) {
        expect(type.costResource, isNotNull);
      }
    });
  });
}
