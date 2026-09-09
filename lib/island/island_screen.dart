import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../board/models/block_color.dart';
import '../shared/haptics.dart';
import '../shared/resource_bar.dart';
import '../shared/resource_wallet.dart';
import 'logic/island_controller.dart';
import 'models/biome.dart';
import 'models/building_type.dart';

/// Faz 2-3 Ada ekranı: kazanılan kaynaklarla bina inşa/yükseltme ve
/// toplam bina seviyesine göre değişen biyom göstergesi
/// (bkz. docs/GDD.md, Bölüm 3 - Meta Katman: Üs/Ada Kurma, Bölüm 4 -
/// Tema/Biyom İlerlemesi).
class IslandScreen extends ConsumerWidget {
  const IslandScreen({super.key});

  static const _background = Color(0xFF0E2033);
  static const _inkDim = Color(0xFF9FB6C7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final island = ref.watch(islandControllerProvider);
    final biome = island.biome;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${biome.icon} ${biome.displayName.toUpperCase()}',
                    style: TextStyle(
                      color: biome.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const ResourceBar(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  biome.nextThreshold == null
                      ? 'En üst biyoma ulaştın'
                      : 'Sonraki biyom: ${island.totalLevel}/${biome.nextThreshold} toplam seviye',
                  style: const TextStyle(color: _inkDim, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: BuildingType.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _BuildingCard(type: BuildingType.values[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildingCard extends ConsumerWidget {
  const _BuildingCard({required this.type});

  final BuildingType type;

  static const _panel = Color(0xFF16304A);
  static const _ink = Color(0xFFEFE6D3);
  static const _inkDim = Color(0xFF9FB6C7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final island = ref.watch(islandControllerProvider);
    final controller = ref.read(islandControllerProvider.notifier);
    // Cüzdanı doğrudan izle: bakiye değiştikçe "yükselt" butonunun
    // etkin/pasif durumu güncellensin.
    ref.watch(resourceWalletProvider);

    final level = island.levelOf(type);
    final maxed = controller.isMaxLevel(type);
    final canUpgrade = !maxed && controller.canUpgrade(type);
    final nextLevel = level + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(level),
            tween: Tween(begin: level == 0 ? 1.0 : 1.4, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(type.icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type.displayName,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      level == 0 ? 'Kurulmadı' : 'Seviye $level',
                      style: const TextStyle(color: _inkDim, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  type.effectDescriptionFor(level),
                  style: const TextStyle(color: _inkDim, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _UpgradeButton(
            maxed: maxed,
            enabled: canUpgrade,
            costLabel: maxed
                ? null
                : '${type.costForLevel(nextLevel)} ${type.costResource.icon}',
            onPressed: () {
              if (controller.upgrade(type)) Haptics.buildingUpgraded();
            },
          ),
        ],
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({
    required this.maxed,
    required this.enabled,
    required this.costLabel,
    required this.onPressed,
  });

  final bool maxed;
  final bool enabled;
  final String? costLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (maxed) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('Maks.', style: TextStyle(color: Color(0xFFFFC96B))),
      );
    }

    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8B5E),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(costLabel ?? ''),
    );
  }
}
