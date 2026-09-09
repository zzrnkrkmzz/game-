import 'dart:math';

import 'package:ada_blast/quests/logic/daily_quest_controller.dart';
import 'package:ada_blast/quests/models/quest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day1 = DateTime(2026, 1, 1);
  final day2 = DateTime(2026, 1, 2);
  final day3 = DateTime(2026, 1, 3);

  group('DailyQuestController', () {
    test('başlangıçta 3 görev üretir ve seri 0dır', () {
      final controller = DailyQuestController(random: Random(1), now: day1);

      expect(controller.state.quests.length, DailyQuestController.questsPerDay);
      expect(controller.state.streak, 0);
      expect(controller.state.allCompleted, isFalse);
    });

    test('bir görev türüne ilerleme yalnızca o türü etkiler', () {
      final controller = DailyQuestController(random: Random(1), now: day1);
      final targetType = controller.state.quests.first.type;
      final otherQuests = controller.state.quests.skip(1).toList();

      switch (targetType) {
        case QuestType.clearLines:
          controller.recordLinesCleared(1);
        case QuestType.placeCells:
          controller.recordCellsPlaced(1);
        case QuestType.upgradeBuilding:
          controller.recordBuildingUpgraded();
        case QuestType.scorePoints:
          controller.recordScore(1);
        case QuestType.finishRounds:
          controller.recordRoundFinished();
      }

      expect(controller.state.quests.first.progress, 1);
      for (var i = 0; i < otherQuests.length; i++) {
        expect(controller.state.quests[i + 1].progress, otherQuests[i].progress);
      }
    });

    test('tüm görevler tamamlanınca streak 1 artar', () {
      final controller = DailyQuestController(random: Random(2), now: day1);

      for (final quest in controller.state.quests) {
        _completeQuest(controller, quest.type, quest.target);
      }

      expect(controller.state.allCompleted, isTrue);
      expect(controller.state.streak, 1);
    });

    test('aynı gün tekrar tamamlanma streak\'i tekrar artırmaz', () {
      final controller = DailyQuestController(random: Random(2), now: day1);
      for (final quest in controller.state.quests) {
        _completeQuest(controller, quest.type, quest.target);
      }
      expect(controller.state.streak, 1);

      // Zaten tamamlanmış bir göreve fazladan ilerleme eklemek streak'i
      // tekrar artırmamalı.
      controller.recordScore(9999);
      expect(controller.state.streak, 1);
    });

    test('gün değişince yeni görevler üretilir, ilerleme sıfırlanır', () {
      final controller = DailyQuestController(random: Random(4), now: day1);
      controller.recordScore(50);

      controller.checkNewDay(day2);

      expect(controller.state.day, DateTime(2026, 1, 2));
      expect(controller.state.quests.every((q) => q.progress == 0), isTrue);
    });

    test('önceki gün tamamlanmışsa streak korunur', () {
      final controller = DailyQuestController(random: Random(6), now: day1);
      for (final quest in controller.state.quests) {
        _completeQuest(controller, quest.type, quest.target);
      }
      expect(controller.state.streak, 1);

      controller.checkNewDay(day2);

      expect(controller.state.streak, 1);
    });

    test('bir gün atlanırsa (tamamlanmadan) streak sıfırlanır', () {
      final controller = DailyQuestController(random: Random(6), now: day1);
      for (final quest in controller.state.quests) {
        _completeQuest(controller, quest.type, quest.target);
      }
      expect(controller.state.streak, 1);

      // day2'de hiçbir görev tamamlanmadan day3'e geç.
      controller.checkNewDay(day2);
      controller.checkNewDay(day3);

      expect(controller.state.streak, 0);
    });

    test('aynı gün içinde checkNewDay hiçbir şeyi değiştirmez', () {
      final controller = DailyQuestController(random: Random(1), now: day1);
      final before = controller.state;

      controller.checkNewDay(day1);

      expect(controller.state, same(before));
    });
  });
}

void _completeQuest(DailyQuestController controller, QuestType type, int target) {
  switch (type) {
    case QuestType.clearLines:
      controller.recordLinesCleared(target);
    case QuestType.placeCells:
      controller.recordCellsPlaced(target);
    case QuestType.upgradeBuilding:
      for (var i = 0; i < target; i++) {
        controller.recordBuildingUpgraded();
      }
    case QuestType.scorePoints:
      controller.recordScore(target);
    case QuestType.finishRounds:
      for (var i = 0; i < target; i++) {
        controller.recordRoundFinished();
      }
  }
}
