import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../island/logic/island_controller.dart';
import '../../quests/logic/daily_quest_controller.dart';
import '../models/collectible.dart';

/// Açık koleksiyon ögelerinin id kümesi — Ada seviyesi ve görev serisinden
/// türetilir, ayrı bir durum tutmaz (bkz. docs/GDD.md, Bölüm 4).
final unlockedCollectiblesProvider = Provider<Set<String>>((ref) {
  final island = ref.watch(islandControllerProvider);
  final quests = ref.watch(dailyQuestControllerProvider);
  return CollectibleCatalog.unlockedIds(
    islandTotalLevel: island.totalLevel,
    streak: quests.streak,
  );
});
