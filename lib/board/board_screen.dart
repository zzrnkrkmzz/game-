import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/logic/onboarding_controller.dart';
import '../shared/haptics.dart';
import '../shared/resource_bar.dart';
import 'logic/game_controller.dart';
import 'models/block_color.dart';
import 'models/piece.dart';

/// Çekirdek oyun ekranı: 8x8 tahta + 3'lü parça tepsisi. Kaynak bakiyesi
/// [ResourceBar] üzerinden Island ekranıyla paylaşılır (bkz. docs/GDD.md,
/// Bölüm 14 — bu ekran kaynak/bina sisteminden bağımsız olarak tek başına
/// da test edilebilir kalır). Skor patlaması, haptik ve ilk-hamle ipucu
/// gibi Faz 5 cilalama öğelerini de barındırır (bkz. Bölüm 8.1).
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  static const _background = Color(0xFF0E2033);
  static const _panel = Color(0xFF16304A);
  static const _ink = Color(0xFFEFE6D3);

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String? _popupText;
  int _popupSeq = 0;

  void _handlePlacement(GameState? previous, GameState next) {
    final result = next.lastResult;
    if (result == null || identical(result, previous?.lastResult)) return;

    Haptics.placePiece();
    if (result.linesCleared > 0) Haptics.lineCleared();
    if (next.isGameOver && previous?.isGameOver != true) Haptics.gameOver();

    if (result.scoreGained <= 0) return;
    final text = result.linesCleared > 1
        ? '+${result.scoreGained} · KOMBO x${result.linesCleared}!'
        : '+${result.scoreGained}';

    final seq = ++_popupSeq;
    setState(() => _popupText = text);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _popupSeq == seq) setState(() => _popupText = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameControllerProvider, _handlePlacement);
    final state = ref.watch(gameControllerProvider);
    final onboarding = ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: BoardScreen._background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                children: [
                  _ScoreHeader(score: state.score),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: AspectRatio(aspectRatio: 1, child: _BoardGrid()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PieceTray(),
                  if (onboarding.showMoveHint) const _MoveHint(),
                  const SizedBox(height: 8),
                  if (state.isGameOver) _GameOverBanner(score: state.score),
                ],
              ),
              Align(
                alignment: const Alignment(0, -0.55),
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _popupText == null
                        ? const SizedBox.shrink(key: ValueKey('empty'))
                        : _ScorePopup(
                            key: ValueKey(_popupSeq),
                            text: _popupText!,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePopup extends StatelessWidget {
  const _ScorePopup({required super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: (1 - t).clamp(0, 1),
        child: Transform.translate(offset: Offset(0, -24 * t), child: child),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFC96B),
          fontWeight: FontWeight.w800,
          fontSize: 22,
          shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
        ),
      ),
    );
  }
}

class _MoveHint extends StatelessWidget {
  const _MoveHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, -4 * (0.5 - (t - 0.5).abs()) * 2),
          child: child,
        ),
        child: const Text(
          '👆 Bir parçayı tahtaya sürükle',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9FB6C7), fontSize: 12),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.score});

  final int score;

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
        const ResourceBar(),
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

    // Sürüklenen parçanın tüm gövdesinin nereye oturacağını gösteren
    // "hayalet" önizleme — sadece imlecin altındaki tek hücre değil,
    // parçanın kaplayacağı bütün hücreler vurgulanır.
    Piece? hoveredPiece;
    final footprint = <int>{};
    var footprintValid = false;
    if (_hoveredTrayIndex != null && _hoveredRow != null && _hoveredCol != null) {
      hoveredPiece = state.tray[_hoveredTrayIndex!];
      if (hoveredPiece != null) {
        footprintValid = controller.canPlace(_hoveredTrayIndex!, _hoveredRow!, _hoveredCol!);
        for (final cell in hoveredPiece.shape) {
          final r = _hoveredRow! + cell.row;
          final c = _hoveredCol! + cell.col;
          if (r >= 0 && r < size && c >= 0 && c < size) {
            footprint.add(r * size + c);
          }
        }
      }
    }

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
          final block = state.board.cellAt(row, col);
          final isInFootprint = footprint.contains(index);

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
              if (block != null) cellColor = block.color.displayColor;
              if (isInFootprint) {
                cellColor = footprintValid
                    ? (hoveredPiece?.color.displayColor ?? Colors.white)
                          .withValues(alpha: 0.55)
                    : Colors.red.withValues(alpha: 0.4);
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(4),
                  border: block != null && block.isIce
                      ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2)
                      : null,
                ),
                child: block != null && block.isBonus
                    ? const Center(
                        child: Text('★', style: TextStyle(fontSize: 12, color: Colors.white)),
                      )
                    : (block != null && block.isIce
                          ? const Center(child: Text('❄', style: TextStyle(fontSize: 12)))
                          : null),
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
      feedback: _DragFeedback(piece: piece!),
      childWhenDragging: Opacity(opacity: 0.3, child: preview),
      child: preview,
    );
  }
}

/// Parça sürüklenmeye başlayınca elde büyüyüp hafifçe zıplayan (pop)
/// görünüm — "tutunca büyüsün" geri bildirimi.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.piece});

  final Piece piece;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _PiecePreview(piece: piece, cellSize: 30),
      ),
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
                  border: piece.isIce
                      ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2)
                      : null,
                ),
                child: piece.isBonus
                    ? const Center(
                        child: Text('★', style: TextStyle(fontSize: 10, color: Colors.white)),
                      )
                    : null,
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
