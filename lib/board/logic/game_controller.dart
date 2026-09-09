import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/resource_wallet.dart';
import '../models/block_color.dart';
import '../models/board_state.dart';
import '../models/piece.dart';
import 'piece_generator.dart';

/// Bir turun tüm durumu: tahta, tepsideki parçalar, skor ve oyun sonu
/// bilgisi. Kaynak bakiyesi burada değil, [ResourceWallet]'ta tutulur —
/// Board ve Island ekranları aynı cüzdanı paylaşır (bkz. docs/GDD.md,
/// Bölüm 2 - Çekirdek Döngü, Bölüm 3 - Üs/Ada Kurma).
class GameState {
  const GameState({
    required this.board,
    required this.tray,
    required this.score,
    required this.isGameOver,
    this.lastResult,
  });

  factory GameState.initial(BoardState board, List<Piece> tray) =>
      GameState(board: board, tray: tray, score: 0, isGameOver: false);

  final BoardState board;
  final List<Piece?> tray;
  final int score;
  final bool isGameOver;

  /// En son yerleştirmenin sonucu (UI'da kombo/temizlik animasyonu için).
  final PlacementResult? lastResult;

  GameState copyWith({
    BoardState? board,
    List<Piece?>? tray,
    int? score,
    bool? isGameOver,
    PlacementResult? lastResult,
  }) => GameState(
    board: board ?? this.board,
    tray: tray ?? this.tray,
    score: score ?? this.score,
    isGameOver: isGameOver ?? this.isGameOver,
    lastResult: lastResult ?? this.lastResult,
  );
}

/// Tur akışını yöneten controller: parça yerleştirme, tepsi yenileme,
/// skor güncelleme, oyun sonu tespiti ve kazanılan kaynakları
/// [onResourcesGained] aracılığıyla cüzdana aktarma.
class GameController extends StateNotifier<GameState> {
  GameController({
    PieceGenerator? generator,
    int boardSize = 8,
    void Function(Map<ResourceType, int> gained)? onResourcesGained,
  }) : _generator = generator ?? PieceGenerator(),
       _onResourcesGained = onResourcesGained ?? ((_) {}),
       super(GameState.initial(BoardState(size: boardSize), const [])) {
    _startNewGame(boardSize);
  }

  final PieceGenerator _generator;
  final void Function(Map<ResourceType, int> gained) _onResourcesGained;

  void _startNewGame(int boardSize) {
    final board = BoardState(size: boardSize);
    final tray = _generator.generateTray(board);
    state = GameState.initial(board, tray);
  }

  void newGame({int boardSize = 8}) => _startNewGame(boardSize);

  bool canPlace(int trayIndex, int row, int col) {
    final piece = state.tray[trayIndex];
    if (piece == null || state.isGameOver) return false;
    return state.board.canPlace(piece, row, col);
  }

  /// Tepsideki [trayIndex] konumundaki parçayı (row, col) hücresine
  /// yerleştirmeyi dener. Geçersizse hiçbir şey yapmaz.
  void placePiece(int trayIndex, int row, int col) {
    final piece = state.tray[trayIndex];
    if (piece == null || state.isGameOver) return;
    if (!state.board.canPlace(piece, row, col)) return;

    final board = state.board.copy();
    final result = board.place(piece, row, col);

    final newTray = List<Piece?>.from(state.tray);
    newTray[trayIndex] = null;

    _onResourcesGained(result.resourcesGained);

    final trayEmpty = newTray.every((p) => p == null);
    final refilledTray = trayEmpty ? _generator.generateTray(board) : newTray;

    final isGameOver = refilledTray
        .whereType<Piece>()
        .every((p) => !board.canPlaceAnywhere(p));

    state = state.copyWith(
      board: board,
      tray: refilledTray,
      score: state.score + result.scoreGained,
      isGameOver: isGameOver,
      lastResult: result,
    );
  }
}

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>(
      (ref) => GameController(
        onResourcesGained: ref.read(resourceWalletProvider.notifier).deposit,
      ),
    );
