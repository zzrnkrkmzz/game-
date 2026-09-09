import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../board/models/block_color.dart';
import '../shared/haptics.dart';
import '../shared/resource_bar.dart';
import '../shared/resource_wallet.dart';
import 'logic/island_controller.dart';
import 'models/biome.dart';
import 'models/building_type.dart';
import 'models/island_state.dart';

/// Faz 2-3 Ada ekranı: kazanılan kaynaklarla bina inşa/yükseltme ve
/// toplam bina seviyesine göre değişen biyom göstergesi
/// (bkz. docs/GDD.md, Bölüm 3 - Meta Katman: Üs/Ada Kurma, Bölüm 4 -
/// Tema/Biyom İlerlemesi).
class IslandScreen extends ConsumerWidget {
  const IslandScreen({super.key});

  static const _bgBottom = Color(0xFF0A1B2C);
  static const _panel = Color(0xFF16304A);
  static const _panelLine = Color(0x1FFFFFFF);
  static const _inkDim = Color(0xFF9FB6C7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final island = ref.watch(islandControllerProvider);
    final biome = island.biome;
    final progress = biome.nextThreshold == null
        ? 1.0
        : (island.totalLevel / biome.nextThreshold!).clamp(0.0, 1.0);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(biome.accentColor, _bgBottom, 0.82)!,
              _bgBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BiomeHeader(biome: biome, island: island, progress: progress),
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
      ),
    );
  }
}

class _BiomeHeader extends StatelessWidget {
  const _BiomeHeader({
    required this.biome,
    required this.island,
    required this.progress,
  });

  final BiomeType biome;
  final IslandState island;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IslandScreen._panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IslandScreen._panelLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      biome.accentColor.withValues(alpha: 0.35),
                      biome.accentColor.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(color: biome.accentColor.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(biome.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${biome.icon} ${biome.displayName.toUpperCase()}',
                  style: TextStyle(
                    color: biome.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const ResourceBar(),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(biome.accentColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            biome.nextThreshold == null
                ? 'En üst biyoma ulaştın'
                : 'Sonraki biyom: ${island.totalLevel}/${biome.nextThreshold} toplam seviye',
            style: const TextStyle(color: IslandScreen._inkDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BuildingCard extends ConsumerWidget {
  const _BuildingCard({required this.type});

  final BuildingType type;

  static const _panel = Color(0xFF16304A);
  static const _panelLine = Color(0x1FFFFFFF);
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
    final resourceColor = type.costResource.displayColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _panelLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  resourceColor.withValues(alpha: 0.3),
                  resourceColor.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: resourceColor.withValues(alpha: 0.45)),
            ),
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(level),
                tween: Tween(begin: level == 0 ? 1.0 : 1.4, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(type.icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
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
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: level / BuildingTypeX.maxLevel,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(resourceColor),
                  ),
                ),
                const SizedBox(height: 6),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      child: Text(costLabel ?? ''),
    );
  }
}
