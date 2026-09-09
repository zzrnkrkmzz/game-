import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/game_controller.dart';
import 'models/block_color.dart';
import 'models/piece.dart';

/// Faz 1 çekirdek prototip ekranı: 8x8 tahta + 3'lü parça tepsisi.
/// Ada/üs kurma ekranı henüz yok (Faz 2) — bu ekran kaynak/bina sisteminden
/// bağımsız olarak tek başına test edilebilir (bkz. docs/GDD.md, Bölüm 14).
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  static const _background = Color(0xFF0E2033);
  static const _panel = Color(0xFF16304A);
  static const _ink = Color(0xFFEFE6D3);
  static const _inkDim = Color(0xFF9FB6C7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ScoreHeader(score: state.score, resources: state.resources),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _BoardGrid(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _PieceTray(),
              const SizedBox(height: 8),
              if (state.isGameOver) _GameOverBanner(score: state.score),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.score, required this.resources});

  final int score;
  final Map<ResourceType, int> resources;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SKOR $score',
          style: const TextStyle(
            color: Color(0xFFFFC96B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Row(
          children: [
            _ResourceChip(icon: '🪵', amount: resources[ResourceType.wood] ?? 0),
            const SizedBox(width: 10),
            _ResourceChip(icon: '🪨', amount: resources[ResourceType.stone] ?? 0),
            const SizedBox(width: 10),
            _ResourceChip(
              icon: '💎',
              amount: resources[ResourceType.crystal] ?? 0,
            ),
          ],
        ),
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
          style: const TextStyle(
            color: BoardScreen._inkDim,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BoardGrid extends ConsumerStatefulWidget {
  const _BoardGrid();

  @override
  ConsumerState<_BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends ConsumerState<_BoardGrid> {
  int? _hoveredTrayIndex;
  int? _hoveredRow;
  int? _hoveredCol;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(gameControllerProvider.notifier);
    final state = ref.watch(gameControllerProvider);
    final size = state.board.size;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF12293F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemCount: size * size,
        itemBuilder: (context, index) {
          final row = index ~/ size;
          final col = index % size;
          final color = state.board.cellAt(row, col);
          final isHovered =
              _hoveredRow == row && _hoveredCol == col && _hoveredTrayIndex != null;
          final isValidHover = isHovered &&
              controller.canPlace(_hoveredTrayIndex!, row, col);

          return DragTarget<int>(
            onWillAcceptWithDetails: (details) {
              setState(() {
                _hoveredTrayIndex = details.data;
                _hoveredRow = row;
                _hoveredCol = col;
              });
              return true;
            },
            onLeave: (_) {
              setState(() {
                _hoveredRow = null;
                _hoveredCol = null;
              });
            },
            onAcceptWithDetails: (details) {
              controller.placePiece(details.data, row, col);
              setState(() {
                _hoveredTrayIndex = null;
                _hoveredRow = null;
                _hoveredCol = null;
              });
            },
            builder: (context, candidates, rejects) {
              Color cellColor = Colors.white.withValues(alpha: 0.05);
              if (color != null) cellColor = color.displayColor;
              if (isHovered) {
                cellColor = isValidHover
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.red.withValues(alpha: 0.35);
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PieceTray extends ConsumerWidget {
  const _PieceTray();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);

    return SizedBox(
      height: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < state.tray.length; i++)
            _TraySlot(trayIndex: i, piece: state.tray[i]),
        ],
      ),
    );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({required this.trayIndex, required this.piece});

  final int trayIndex;
  final Piece? piece;

  @override
  Widget build(BuildContext context) {
    if (piece == null) return const SizedBox(width: 80, height: 80);

    final preview = _PiecePreview(piece: piece!, cellSize: 20);

    return Draggable<int>(
      data: trayIndex,
      feedback: _PiecePreview(piece: piece!, cellSize: 28),
      childWhenDragging: Opacity(opacity: 0.3, child: preview),
      child: preview,
    );
  }
}

class _PiecePreview extends StatelessWidget {
  const _PiecePreview({required this.piece, required this.cellSize});

  final Piece piece;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: piece.width * cellSize,
      height: piece.height * cellSize,
      child: Stack(
        children: [
          for (final cell in piece.shape)
            Positioned(
              left: cell.col * cellSize,
              top: cell.row * cellSize,
              width: cellSize - 2,
              height: cellSize - 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: piece.color.displayColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameOverBanner extends ConsumerWidget {
  const _GameOverBanner({required this.score});

  final int score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: BoardScreen._panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tur bitti — skor: $score',
            style: const TextStyle(
              color: BoardScreen._ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => ref.read(gameControllerProvider.notifier).newGame(),
            child: const Text('Yeniden Oyna'),
          ),
        ],
      ),
    );
  }
}
