import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../board/models/block_color.dart';

/// Tahtada kazanılan ve adada harcanan kaynakların tek doğruluk kaynağı.
/// Board ve Island ekranları aynı cüzdanı paylaşır (bkz. docs/GDD.md,
/// Bölüm 3 - "kazanılan kaynaklarla bina inşa et").
class ResourceWallet extends StateNotifier<Map<ResourceType, int>> {
  ResourceWallet()
    : super(const {
        ResourceType.wood: 0,
        ResourceType.stone: 0,
        ResourceType.crystal: 0,
      });

  int amountOf(ResourceType type) => state[type] ?? 0;

  void deposit(Map<ResourceType, int> gained) {
    if (gained.isEmpty) return;
    final next = Map<ResourceType, int>.from(state);
    gained.forEach((type, amount) {
      next.update(type, (v) => v + amount, ifAbsent: () => amount);
    });
    state = next;
  }

  bool canAfford(Map<ResourceType, int> cost) =>
      cost.entries.every((e) => amountOf(e.key) >= e.value);

  /// [cost] karşılanabiliyorsa hepsini tek seferde düşer ve `true` döner.
  /// Karşılanamıyorsa hiçbir şeyi değiştirmeden `false` döner (kısmi
  /// harcama yapılmaz).
  bool spend(Map<ResourceType, int> cost) {
    if (!canAfford(cost)) return false;
    final next = Map<ResourceType, int>.from(state);
    cost.forEach((type, amount) {
      next.update(type, (v) => v - amount, ifAbsent: () => -amount);
    });
    state = next;
    return true;
  }
}

final resourceWalletProvider =
    StateNotifierProvider<ResourceWallet, Map<ResourceType, int>>(
      (ref) => ResourceWallet(),
    );
