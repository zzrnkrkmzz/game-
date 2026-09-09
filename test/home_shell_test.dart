import 'package:ada_blast/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeShell Tahta ve Ada sekmelerini gösterir', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeShell())),
    );
    await tester.pumpAndSettle();

    expect(find.text('🧩 Tahta'), findsOneWidget);
    expect(find.text('🏝️ Ada'), findsOneWidget);
    // Board sayfası başlangıçta görünür olmalı.
    expect(find.text('SKOR 0'), findsOneWidget);
  });

  testWidgets('üst köşedeki görev ikonu görev panelini açar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeShell())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('📋'));
    await tester.pumpAndSettle();

    expect(find.text('📋 Günlük Görevler'), findsOneWidget);
  });

  testWidgets('üst köşedeki koleksiyon ikonu koleksiyon panelini açar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeShell())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('📖'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Koleksiyon'), findsOneWidget);
  });
}
