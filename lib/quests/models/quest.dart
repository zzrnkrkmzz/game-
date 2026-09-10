/// Günlük görev türleri (bkz. docs/GDD.md, Bölüm 5 - Retention Mekanikleri).
enum QuestType {
  clearLines,
  placeCells,
  upgradeBuilding,
  scorePoints,
  finishRounds,
}

extension QuestTypeX on QuestType {
  String get icon => switch (this) {
    QuestType.clearLines => '🧹',
    QuestType.placeCells => '🧩',
    QuestType.upgradeBuilding => '🏗️',
    QuestType.scorePoints => '⭐',
    QuestType.finishRounds => '🔁',
  };

  /// Görevin hedef aralığı — günlük görev seçilirken bu aralıktan
  /// rastgele bir hedef belirlenir.
  (int min, int max) get targetRange => switch (this) {
    QuestType.clearLines => (3, 6),
    QuestType.placeCells => (12, 20),
    QuestType.upgradeBuilding => (1, 1),
    QuestType.scorePoints => (200, 400),
    QuestType.finishRounds => (1, 2),
  };

  String description(int target) => switch (this) {
    QuestType.clearLines => '$target satır/sütun temizle',
    QuestType.placeCells => '$target blok yerleştir',
    QuestType.upgradeBuilding => '$target bina yükselt',
    QuestType.scorePoints => '$target puan topla',
    QuestType.finishRounds => '$target tur bitir',
  };
}

/// Bir günlük görevin durumu.
class DailyQuest {
  const DailyQuest({
    required this.type,
    required this.target,
    this.progress = 0,
  });

  final QuestType type;
  final int target;
  final int progress;

  bool get isComplete => progress >= target;

  String get description => type.description(target);

  DailyQuest withProgress(int newProgress) => DailyQuest(
    type: type,
    target: target,
    progress: newProgress.clamp(0, target),
  );

  DailyQuest addProgress(int amount) => withProgress(progress + amount);
}
