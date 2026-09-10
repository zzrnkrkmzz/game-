import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/daily_quest_controller.dart';
import 'models/quest.dart';

const _panel = Color(0xFF16304A);
const _ink = Color(0xFFEFE6D3);
const _inkDim = Color(0xFF9FB6C7);
const _amber = Color(0xFFFFC96B);
const _seafoam = Color(0xFF6FD9C4);

/// Günlük görevleri ve seriyi modal olarak gösterir
/// (bkz. docs/GDD.md, Bölüm 5 - Retention Mekanikleri).
void showQuestPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF12293F),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _QuestSheet(),
  );
}

class _QuestSheet extends ConsumerWidget {
  const _QuestSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(dailyQuestControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📋 Günlük Görevler',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${quests.streak} gün',
                      style: const TextStyle(
                        color: _amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final quest in quests.quests) ...[
              _QuestRow(quest: quest),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest});

  final DailyQuest quest;

  @override
  Widget build(BuildContext context) {
    final progressRatio = (quest.progress / quest.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(quest.type.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.description,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(
                      quest.isComplete ? _seafoam : _amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            quest.isComplete ? '✓' : '${quest.progress}/${quest.target}',
            style: TextStyle(
              color: quest.isComplete ? _seafoam : _inkDim,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
