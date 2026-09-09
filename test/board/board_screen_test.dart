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
      const ProviderScope(
        child: MaterialApp(home: BoardScreen()),
      ),
    );

    expect(find.text('SKOR 0'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('onboarding ipucu ilk hamlelerde görünür', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: BoardScreen()),
      ),
    );

    expect(find.textContaining('sürükle'), findsOneWidget);
  });

  testWidgets('ilk satır temizlenince onboarding ipucu kaybolur', (tester) async {
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

  testWidgets('bir parça sürükleyip tahtaya bırakınca skor artar', (tester) async {
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

    final draggable = find.byType(Draggable<int>).first;
    final target = find.byType(DragTarget<int>).first;

    final gesture = await tester.startGesture(tester.getCenter(draggable));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(container.read(gameControllerProvider).score, greaterThan(0));
  });
}
