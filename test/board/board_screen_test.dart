import 'dart:math';

import 'package:ada_blast/board/board_screen.dart';
import 'package:ada_blast/board/logic/game_controller.dart';
import 'package:ada_blast/board/logic/piece_generator.dart';
import 'package:ada_blast/onboarding/logic/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BoardScreen skor ve tahtayı gösterir', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BoardScreen())),
    );

    expect(find.text('SKOR 0'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('onboarding ipucu ilk hamlelerde görünür', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BoardScreen())),
    );

    expect(find.textContaining('sürükle'), findsOneWidget);
  });

  testWidgets('ilk satır temizlenince onboarding ipucu kaybolur', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        onboardingControllerProvider.overrideWith(
          (ref) => OnboardingController(
            initialState: OnboardingState.initial().copyWith(
              hasClearedFirstLine: true,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BoardScreen()),
      ),
    );

    expect(find.textContaining('sürükle'), findsNothing);
  });

  testWidgets('bir parça sürükleyip tahtaya bırakınca skor artar', (
    tester,
  ) async {
    // Üretim provider'ı tohumsuz (Random()) bir PieceGenerator kullanıyor;
    // testte kararlılık için burada sabit tohumlu bir generator'a geçiliyor.
    final container = ProviderContainer(
      overrides: [
        gameControllerProvider.overrideWith(
          (ref) => GameController(generator: PieceGenerator(random: Random(1))),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BoardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final draggable = find.byType(Draggable<int>).first;
    final target = find.byType(DragTarget<int>).first;

    // Piece önizlemesindeki hücreler arasında 2px boşluk bırakılıyor
    // (bkz. _PiecePreview); parçanın geometrik merkezi tam bu boşlukların
    // kesiştiği noktaya denk gelebiliyor ve isabet testi orada başarısız
    // olabiliyor. Merkezden küçük bir ofsetle başlamak bunu güvenilir
    // şekilde önlüyor.
    final start = tester.getCenter(draggable) + const Offset(3, 3);
    final end = tester.getCenter(target);

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 20));
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      await gesture.moveTo(Offset.lerp(start, end, t)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    // Skor patlaması (_ScorePopup) 900ms sonra kendini temizleyen bir
    // Future.delayed zamanlayıcısı kullanıyor; pumpAndSettle bunu
    // beklemeyebiliyor, test bitişinde "pending timer" hatası vermemesi
    // için süresini dolduruyoruz.
    await tester.pump(const Duration(milliseconds: 950));

    expect(container.read(gameControllerProvider).score, greaterThan(0));
  });

  testWidgets(
    'sürüklerken parçanın tüm gövdesi hayalet önizleme olarak vurgulanır',
    (tester) async {
      // seed=1 ile tepsideki ilk parça 3 hücreli (coral, (0,0)(1,0)(1,1)) —
      // bkz. test/board/piece_generator_test.dart benzeri sabitleme.
      final container = ProviderContainer(
        overrides: [
          gameControllerProvider.overrideWith(
            (ref) =>
                GameController(generator: PieceGenerator(random: Random(1))),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BoardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final draggedPiece = container.read(gameControllerProvider).tray[0]!;
      final draggable = find.byType(Draggable<int>).first;
      final target = find.byType(DragTarget<int>).first;
      final start = tester.getCenter(draggable) + const Offset(3, 3);
      final end = tester.getCenter(target);

      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 20));
      const steps = 6;
      for (var i = 1; i <= steps; i++) {
        await gesture.moveTo(Offset.lerp(start, end, i / steps)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      // Henüz bırakılmadı — sadece hover halindeyiz.
      await tester.pump();

      final decorations = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((w) => (w.decoration! as BoxDecoration).color!)
          .toList();
      final highlightedCount = decorations.where((c) => c.a > 0.1).length;

      expect(highlightedCount, draggedPiece.cellCount);
      expect(draggedPiece.cellCount, greaterThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 950));
    },
  );
}
