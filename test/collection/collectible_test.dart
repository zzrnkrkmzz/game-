import 'package:ada_blast/collection/models/collectible.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Collectible.isUnlockedFor', () {
    test('ada seviyesi koşulu sağlanınca açılır', () {
      const item = Collectible(
        id: 'x',
        name: 'X',
        icon: '🐚',
        unlockKind: UnlockKind.islandLevel,
        unlockValue: 5,
      );

      expect(item.isUnlockedFor(islandTotalLevel: 4, streak: 0), isFalse);
      expect(item.isUnlockedFor(islandTotalLevel: 5, streak: 0), isTrue);
    });

    test('seri koşulu sağlanınca açılır', () {
      const item = Collectible(
        id: 'y',
        name: 'Y',
        icon: '🔥',
        unlockKind: UnlockKind.streak,
        unlockValue: 3,
      );

      expect(item.isUnlockedFor(islandTotalLevel: 100, streak: 2), isFalse);
      expect(item.isUnlockedFor(islandTotalLevel: 0, streak: 3), isTrue);
    });
  });

  group('CollectibleCatalog', () {
    test('seviye 0 ögesi başlangıçta açık gelir', () {
      final unlocked = CollectibleCatalog.unlockedIds(
        islandTotalLevel: 0,
        streak: 0,
      );

      expect(unlocked, contains('shell'));
    });

    test('yüksek seviye ve seri ile tüm ögeler açılabilir', () {
      final unlocked = CollectibleCatalog.unlockedIds(
        islandTotalLevel: 100,
        streak: 100,
      );

      expect(unlocked.length, CollectibleCatalog.all.length);
    });

    test('katalogdaki her id benzersizdir', () {
      final ids = CollectibleCatalog.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
