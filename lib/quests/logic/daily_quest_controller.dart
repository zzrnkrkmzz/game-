import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_quest_state.dart';
import '../models/quest.dart';

/// Günlük görevleri ve seriyi (streak) yönetir. Board ve Island
/// controller'ları ilerlemeyi `record*` metotlarıyla bildirir
/// (bkz. docs/GDD.md, Bölüm 5 - Retention Mekanikleri).
///
/// Not: Bu prototipte gün değişimi yalnızca controller her oluşturulduğunda
/// (uygulama açılışında) kontrol edilir — kalıcı depolama henüz
/// eklenmedi (bkz. docs/GDD.md, Bölüm 9 - Teknik Mimari, ileri faz).
class DailyQuestController extends StateNotifier<DailyQuestState> {
  DailyQuestController({Random? random, DateTime? now})
    : _random = random ?? Random(),
      super(_freshState(now ?? DateTime.now(), random ?? Random(), null, 0));

  final Random _random;

  static const int questsPerDay = 3;

  static DailyQuestState _freshState(
    DateTime now,
    Random random,
    DateTime? lastAllCompletedDay,
    int streak,
  ) {
    final today = dayOf(now);
    final wasYesterdayCompleted =
        lastAllCompletedDay != null &&
        lastAllCompletedDay == dayOf(today.subtract(const Duration(days: 1)));
    return DailyQuestState(
      day: today,
      quests: _pickQuests(random),
      streak: wasYesterdayCompleted ? streak : 0,
      lastAllCompletedDay: lastAllCompletedDay,
    );
  }

  static List<DailyQuest> _pickQuests(Random random) {
    final types = [...QuestType.values]..shuffle(random);
    return types.take(questsPerDay).map((type) {
      final (min, max) = type.targetRange;
      final target = min + random.nextInt(max - min + 1);
      return DailyQuest(type: type, target: target);
    }).toList();
  }

  /// Gün değiştiyse görevleri ve gerekirse seriyi sıfırlar. UI, ekran
  /// açıldığında bunu çağırabilir; günün ortasında hiçbir şey yapmaz.
  void checkNewDay([DateTime? now]) {
    final today = dayOf(now ?? DateTime.now());
    if (today == state.day) return;
    state = _freshState(
      today,
      _random,
      state.lastAllCompletedDay,
      state.streak,
    );
  }

  void _addProgress(QuestType type, int amount) {
    if (amount <= 0) return;
    final wasAllComplete = state.allCompleted;
    final quests = state.quests
        .map((q) => q.type == type ? q.addProgress(amount) : q)
        .toList();
    final nowAllComplete = quests.every((q) => q.isComplete);

    state = state.copyWith(
      quests: quests,
      lastAllCompletedDay: (!wasAllComplete && nowAllComplete)
          ? state.day
          : state.lastAllCompletedDay,
      streak: (!wasAllComplete && nowAllComplete)
          ? state.streak + 1
          : state.streak,
    );
  }

  void recordLinesCleared(int count) =>
      _addProgress(QuestType.clearLines, count);

  void recordCellsPlaced(int count) =>
      _addProgress(QuestType.placeCells, count);

  void recordBuildingUpgraded() => _addProgress(QuestType.upgradeBuilding, 1);

  void recordScore(int amount) => _addProgress(QuestType.scorePoints, amount);

  void recordRoundFinished() => _addProgress(QuestType.finishRounds, 1);
}

final dailyQuestControllerProvider =
    StateNotifierProvider<DailyQuestController, DailyQuestState>(
      (ref) => DailyQuestController(),
    );
