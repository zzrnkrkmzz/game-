import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/logic/onboarding_controller.dart';
import '../shared/haptics.dart';
import '../shared/resource_bar.dart';
import 'logic/game_controller.dart';
import 'models/block_color.dart';
import 'models/piece.dart';
import 'models/placed_block.dart';

/// Sürüklenen tepsi parçasının anlık global işaretçi konumu — parçanın
/// tahta üzerinde nereye oturacağını sürekli takip edebilmek için
/// [Draggable.onDragUpdate] burada güncellenir (bkz. [_TraySlot]) ve
/// [_BoardGrid] bunu izleyip hayalet önizlemeyi hesaplar. Önceden 64 ayrı
/// [DragTarget]'ın giriş/çıkış (onWillAccept/onLeave) olaylarına
/// dayanılıyordu; bunlar sürekli konum bildirmediği için önizleme bazen
/// tek hücrede takılı kalıyordu — bu yaklaşım her imleç hareketinde
/// gerçek global konumu paylaşarak daha güvenilir çalışır.
class DragHoverInfo {
  const DragHoverInfo({required this.trayIndex, required this.globalPosition});

  final int trayIndex;
  final Offset globalPosition;
}

final dragHoverProvider = StateProvider<DragHoverInfo?>((ref) => null);

/// Çekirdek oyun ekranı: 8x8 tahta + 3'lü parça tepsisi. Kaynak bakiyesi
/// [ResourceBar] üzerinden Island ekranıyla paylaşılır (bkz. docs/GDD.md,
/// Bölüm 14 — bu ekran kaynak/bina sisteminden bağımsız olarak tek başına
/// da test edilebilir kalır). Skor patlaması, haptik ve ilk-hamle ipucu
/// gibi Faz 5 cilalama öğelerini de barındırır (bkz. Bölüm 8.1).
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  static const _bgTop = Color(0xFF122A42);
  static const _bgBottom = Color(0xFF0A1B2C);
  static const _panel = Color(0xFF16304A);
  static const _panelLine = Color(0x1FFFFFFF);
  static const _ink = Color(0xFFEFE6D3);
  static const _amber = Color(0xFFFFC96B);

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

    final totalGained = result.scoreGained + next.lastStreakBonus;
    if (totalGained <= 0) return;
    final parts = <String>['+$totalGained'];
    if (result.linesCleared > 1) parts.add('KOMBO x${result.linesCleared}');
    if (next.lastStreakBonus > 0) parts.add('SERİ x${next.clearStreak}');
    final text = parts.length > 1 ? '${parts.join(' · ')}!' : parts.first;

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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BoardScreen._bgTop, BoardScreen._bgBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Column(
                  children: [
                    _ScoreHeader(score: state.score, streak: state.clearStreak),
                    _UndoBar(remaining: state.undosRemaining),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Center(
                        child: AspectRatio(aspectRatio: 1, child: _BoardGrid()),
                      ),
                    ),
                    const SizedBox(height: 18),
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
  const _ScoreHeader({required this.score, required this.streak});

  final int score;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BoardScreen._panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BoardScreen._panelLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'SKOR $score',
                style: const TextStyle(
                  color: BoardScreen._amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: 0.3,
                ),
              ),
              if (streak >= 2) ...[
                const SizedBox(width: 8),
                _StreakBadge(streak: streak),
              ],
            ],
          ),
          const ResourceBar(),
        ],
      ),
    );
  }
}

/// Peş peşe temizlik serisini gösteren küçük rozet
/// (bkz. [GameState.clearStreak] — "peşpeşe patlatmalarda bonus" isteği).
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(streak),
      tween: Tween(begin: 1.3, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B4A).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFF6B4A).withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          '🔥 SERİ x$streak',
          style: const TextStyle(
            color: Color(0xFFFF9B7A),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Depo binası seviyesine bağlı "geri al" hakkını gösterir ve kullandırır
/// (bkz. docs/GDD.md, Bölüm 3 — Depo binasının gerçek oyun içi etkisi).
class _UndoBar extends ConsumerWidget {
  const _UndoBar({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (remaining <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ref.read(gameControllerProvider.notifier).undo(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BoardScreen._panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BoardScreen._panelLine),
              ),
              child: Text(
                '↩️ Geri Al ($remaining)',
                style: const TextStyle(
                  color: BoardScreen._ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardGrid extends ConsumerStatefulWidget {
  const _BoardGrid();

  @override
  ConsumerState<_BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends ConsumerState<_BoardGrid> {
  static const _padding = 8.0;
  final GlobalKey _gridKey = GlobalKey();

  /// [globalPosition]'ı, dolgu ve hücre aralıklarını hesaba katarak
  /// tahtadaki (row, col) hücre koordinatına çevirir. Konum tahtanın
  /// dışındaysa null döner.
  (int row, int col)? _cellAt(Offset globalPosition, int size) {
    final box = _gridKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    final local = box.globalToLocal(globalPosition);
    final x = local.dx - _padding;
    final y = local.dy - _padding;
    final contentWidth = box.size.width - _padding * 2;
    final contentHeight = box.size.height - _padding * 2;
    if (x < 0 || y < 0 || x >= contentWidth || y >= contentHeight) return null;

    final cellWidth = contentWidth / size;
    final cellHeight = contentHeight / size;
    final col = (x / cellWidth).floor().clamp(0, size - 1);
    final row = (y / cellHeight).floor().clamp(0, size - 1);
    return (row, col);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(gameControllerProvider.notifier);
    final state = ref.watch(gameControllerProvider);
    final hover = ref.watch(dragHoverProvider);
    final size = state.board.size;

    // Sürüklenen parçanın tüm gövdesinin nereye oturacağını gösteren
    // "hayalet" önizleme — sadece imlecin altındaki tek hücre değil,
    // parçanın kaplayacağı bütün hücreler vurgulanır. Konum,
    // [dragHoverProvider] üzerinden gelen sürekli imleç takibiyle
    // hesaplanır (bkz. [DragHoverInfo]).
    Piece? hoveredPiece;
    int? anchorRow;
    int? anchorCol;
    final footprint = <int>{};
    var footprintValid = false;
    if (hover != null) {
      final cell = _cellAt(hover.globalPosition, size);
      final piece = state.tray[hover.trayIndex];
      if (cell != null && piece != null) {
        hoveredPiece = piece;
        anchorRow = cell.$1;
        anchorCol = cell.$2;
        footprintValid = controller.canPlace(
          hover.trayIndex,
          anchorRow,
          anchorCol,
        );
        for (final c in piece.shape) {
          final r = anchorRow + c.row;
          final cc = anchorCol + c.col;
          if (r >= 0 && r < size && cc >= 0 && cc < size) {
            footprint.add(r * size + cc);
          }
        }
      }
    }

    return Container(
      key: _gridKey,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2439),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BoardScreen._panelLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          // Bırakma hücresi olarak, önizlemede gösterilen aynı çapa
          // (anchorRow/anchorCol) kullanılır — böylece "gördüğün, aldığındır"
          // (WYSIWYG) ve details.offset'in (feedback boyutu tepsi
          // önizlemesinden farklı olduğu için) yanlış hücreye işaret etme
          // riski ortadan kalkar.
          if (anchorRow != null && anchorCol != null) {
            controller.placePiece(details.data, anchorRow, anchorCol);
          }
          ref.read(dragHoverProvider.notifier).state = null;
        },
        builder: (context, candidates, rejects) {
          return GridView.builder(
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

              return _BoardCell(
                block: block,
                isInFootprint: isInFootprint,
                footprintValid: footprintValid,
                footprintColor: hoveredPiece?.color.displayColor,
              );
            },
          );
        },
      ),
    );
  }
}

/// Tahtadaki tek bir hücrenin görünümü — dolu hücreler hafif "kabartma"
/// (gradyan + üst kenar parlaması) hissi verecek şekilde çiziliyor.
class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.block,
    required this.isInFootprint,
    required this.footprintValid,
    required this.footprintColor,
  });

  final PlacedBlock? block;
  final bool isInFootprint;
  final bool footprintValid;
  final Color? footprintColor;

  @override
  Widget build(BuildContext context) {
    if (isInFootprint) {
      final color = footprintValid
          ? (footprintColor ?? Colors.white).withValues(alpha: 0.55)
          : Colors.red.withValues(alpha: 0.4);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: (footprintValid ? Colors.white : Colors.red).withValues(
              alpha: 0.6,
            ),
            width: 1.5,
          ),
        ),
      );
    }

    if (block == null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
      );
    }

    final base = block!.color.displayColor;
    final isIce = block!.isIce;
    final isBonus = block!.isBonus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.22)!,
            base,
            Color.lerp(base, Colors.black, 0.12)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: isIce
            ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isBonus
          ? const Center(
              child: Text(
                '★',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            )
          : (isIce
                ? const Center(child: Text('❄', style: TextStyle(fontSize: 12)))
                : null),
    );
  }
}

class _PieceTray extends ConsumerWidget {
  const _PieceTray();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: BoardScreen._panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BoardScreen._panelLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < state.tray.length; i++)
              _TraySlot(trayIndex: i, piece: state.tray[i]),
          ],
        ),
      ),
    );
  }
}

class _TraySlot extends ConsumerWidget {
  const _TraySlot({required this.trayIndex, required this.piece});

  final int trayIndex;
  final Piece? piece;

  static const double _slotSize = 80;

  /// Sürüklerken parçayı parmağın üzerine değil, biraz yukarısına
  /// kaldırır — böylece elin tahtanın hedef hücrelerini kapatmaz
  /// ("parçaların hareket ettirilişi kolay olsun" isteği). Hem görsel
  /// geri bildirim (bkz. [_DragFeedback]) hem de hayalet önizleme/bırakma
  /// hesabı ([_BoardGridState._cellAt]) aynı kaldırma miktarını kullanır,
  /// böylece gördüğün yer ile bıraktığın yer birebir eşleşir.
  static const Offset dragLift = Offset(0, -72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (piece == null) {
      return const SizedBox(width: _slotSize, height: _slotSize);
    }

    final preview = _PiecePreview(piece: piece!, cellSize: 20);
    // Küçük parçaların (ör. tek hücreli) önizlemesi çok küçük olabiliyor;
    // tutma/sürükleme alanını her zaman tüm tepsi hücresi kadar (80x80)
    // büyütmek için görünmez ama isabet testine giren bir kutu içine
    // alıyoruz — parmakla tutması zorlaşmasın diye.
    final hitArea = Container(
      width: _slotSize,
      height: _slotSize,
      color: Colors.transparent,
      child: Center(child: preview),
    );

    void clearHover() {
      final current = ref.read(dragHoverProvider);
      if (current?.trayIndex == trayIndex) {
        ref.read(dragHoverProvider.notifier).state = null;
      }
    }

    return Draggable<int>(
      data: trayIndex,
      feedback: Transform.translate(
        offset: dragLift,
        child: _DragFeedback(piece: piece!),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: hitArea),
      onDragUpdate: (details) {
        ref.read(dragHoverProvider.notifier).state = DragHoverInfo(
          trayIndex: trayIndex,
          globalPosition: details.globalPosition + dragLift,
        );
      },
      onDragEnd: (_) => clearHover(),
      onDraggableCanceled: (_, _) => clearHover(),
      child: hitArea,
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
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(piece.color.displayColor, Colors.white, 0.22)!,
                      piece.color.displayColor,
                    ],
                  ),
                  border: piece.isIce
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 2,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: piece.isBonus
                    ? const Center(
                        child: Text(
                          '★',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
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
            onPressed: () =>
                ref.read(gameControllerProvider.notifier).newGame(),
            child: const Text('Yeniden Oyna'),
          ),
        ],
      ),
    );
  }
}
