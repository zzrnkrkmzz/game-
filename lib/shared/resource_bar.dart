import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../board/models/block_color.dart';
import 'resource_wallet.dart';

const _ink = Color(0xFF9FB6C7);

/// Ahşap/Taş/Kristal bakiyesini gösteren, Board ve Island ekranları
/// arasında paylaşılan kaynak çubuğu.
class ResourceBar extends ConsumerWidget {
  const ResourceBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(resourceWalletProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final type in ResourceType.values) ...[
          _ResourceChip(icon: type.icon, amount: wallet[type] ?? 0),
          if (type != ResourceType.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({required this.icon, required this.amount});

  final String icon;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          '$amount',
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
