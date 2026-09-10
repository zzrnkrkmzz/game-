import 'package:ada_blast/collection/collection_panel.dart';
import 'package:ada_blast/collection/models/collectible.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showCollectionPanel tüm ögeleri ve açık sayısını gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showCollectionPanel(context),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('/${CollectibleCatalog.all.length}'),
      findsOneWidget,
    );
    // Başlangıçta yalnızca seviye 0 ögesi (shell) açık; kilitli ögeler
    // isim yerine "???" gösterir.
    expect(find.text('Deniz Kabuğu'), findsOneWidget);
    expect(find.text('???'), findsWidgets);
  });
}
