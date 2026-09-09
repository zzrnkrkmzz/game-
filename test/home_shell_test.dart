import 'package:ada_blast/main.dart';
import 'package:ada_blast/onboarding/logic/onboarding_controller.dart';
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

  testWidgets(
    'onboarding ilk satırı temizleyince Ada sayfasına otomatik geçilir',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeShell()),
        ),
      );
      await tester.pumpAndSettle();

      // Board sayfasındayken ilk satır temizlenmiş gibi bildir.
      container.read(onboardingControllerProvider.notifier).recordLineCleared();
      await tester.pumpAndSettle();

      // Ada sayfasına geçildi: biyom başlığı görünür olmalı.
      expect(find.textContaining('ORMAN'), findsOneWidget);
      expect(
        container.read(onboardingControllerProvider).navigateToIslandRequested,
        isFalse,
      );
    },
  );
}
