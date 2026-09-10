import 'package:ada_blast/board/models/block_color.dart';
import 'package:ada_blast/island/island_screen.dart';
import 'package:ada_blast/shared/resource_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IslandScreen 4 bina kartı ve kaynak barını gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: IslandScreen())),
    );

    expect(find.text('Depo'), findsOneWidget);
    expect(find.text('Değirmen'), findsOneWidget);
    expect(find.text('Pazar'), findsOneWidget);
    expect(find.text('Fener'), findsOneWidget);
    expect(find.text('Kurulmadı'), findsNWidgets(4));
  });

  testWidgets('kaynak yeterliyse yükselt butonuna basınca seviye artar', (
    tester,
  ) async {
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(home: IslandScreen());
          },
        ),
      ),
    );

    container.read(resourceWalletProvider.notifier).deposit({
      for (final type in ResourceType.values) type: 1000,
    });
    await tester.pump();

    await tester.tap(find.text('10 🪵'));
    await tester.pump();

    expect(find.text('Seviye 1'), findsOneWidget);
  });
}
