import 'package:ada_blast/board/board_screen.dart';
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

  testWidgets('bir parça sürükleyip tahtaya bırakınca skor artar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: BoardScreen()),
      ),
    );

    final draggable = find.byType(Draggable<int>).first;
    final target = find.byType(DragTarget<int>).first;

    await tester.drag(draggable, tester.getCenter(target) - tester.getCenter(draggable));
    await tester.pumpAndSettle();

    expect(find.text('SKOR 0'), findsNothing);
  });
}
