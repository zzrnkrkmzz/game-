import 'quest.dart';

/// Günün tarihini yalnızca yıl/ay/gün olarak normalize eder — saat farkları
/// gün değişimi tespitini etkilemesin diye.
DateTime dayOf(DateTime time) => DateTime(time.year, time.month, time.day);

/// Bugünün görevleri, ilerlemesi ve seri (streak) sayacı
/// (bkz. docs/GDD.md, Bölüm 5 - Retention Mekanikleri).
class DailyQuestState {
  const DailyQuestState({
    required this.day,
    required this.quests,
    required this.streak,
    this.lastAllCompletedDay,
  });

  final DateTime day;
  final List<DailyQuest> quests;
  final int streak;
  final DateTime? lastAllCompletedDay;

  bool get allCompleted => quests.every((q) => q.isComplete);

  DailyQuestState copyWith({
    DateTime? day,
    List<DailyQuest>? quests,
    int? streak,
    DateTime? lastAllCompletedDay,
  }) => DailyQuestState(
    day: day ?? this.day,
    quests: quests ?? this.quests,
    streak: streak ?? this.streak,
    lastAllCompletedDay: lastAllCompletedDay ?? this.lastAllCompletedDay,
  );
}
