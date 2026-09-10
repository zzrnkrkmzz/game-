import 'package:ada_blast/quests/quest_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showQuestPanel 3 görev ve seri sayacını gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showQuestPanel(context),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    expect(find.text('📋 Günlük Görevler'), findsOneWidget);
    expect(find.textContaining('gün'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });
}
