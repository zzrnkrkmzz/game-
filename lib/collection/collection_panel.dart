import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/collection_provider.dart';
import 'models/collectible.dart';

const _panel = Color(0xFF16304A);
const _ink = Color(0xFFEFE6D3);
const _inkDim = Color(0xFF9FB6C7);

/// Koleksiyon albümünü modal olarak gösterir
/// (bkz. docs/GDD.md, Bölüm 8.2 - Navigasyon: modal/popup deseni).
void showCollectionPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF12293F),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CollectionSheet(),
  );
}

class _CollectionSheet extends ConsumerWidget {
  const _CollectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedCollectiblesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📖 Koleksiyon (${unlocked.length}/${CollectibleCatalog.all.length})',
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: CollectibleCatalog.all.length,
                itemBuilder: (context, index) {
                  final item = CollectibleCatalog.all[index];
                  return _CollectibleTile(
                    item: item,
                    isUnlocked: unlocked.contains(item.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectibleTile extends StatelessWidget {
  const _CollectibleTile({required this.item, required this.isUnlocked});

  final Collectible item;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: isUnlocked ? 1 : 0.25,
            child: Text(item.icon, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 6),
          Text(
            isUnlocked ? item.name : '???',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUnlocked ? _ink : _inkDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 2),
            Text(
              item.unlockHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _inkDim, fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}
