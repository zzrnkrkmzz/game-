import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../island/logic/island_controller.dart';
import '../../island/models/biome.dart';
import '../../island/models/building_type.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../../quests/logic/daily_quest_controller.dart';
import '../../shared/resource_wallet.dart';
import '../models/block_color.dart';
import '../models/board_state.dart';
import '../models/piece.dart';
import 'piece_generator.dart';

/// Board modülünün Island/Quest modüllerine sıkı bağımlı olmaması için
/// [GameController], bu modüllerin somut sınıflarını değil yalnızca
/// ihtiyaç duyduğu fonksiyon imzalarını (callback) alır — bkz. sabit
/// [onResourcesGained] deseni. `IslandController`/`DailyQuestController`
/// importları yalnızca [gameControllerProvider]'ın bu callback'leri
/// bağlamak için ihtiyaç duyduğu provider referanslarını okumak içindir.

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
    this.clearStreak = 0,
    this.lastStreakBonus = 0,
    this.undosRemaining = 0,
  });

  factory GameState.initial(
    BoardState board,
    List<Piece> tray, {
    int undosRemaining = 0,
  }) => GameState(
    board: board,
    tray: tray,
    score: 0,
    isGameOver: false,
    undosRemaining: undosRemaining,
  );

  final BoardState board;
  final List<Piece?> tray;
  final int score;
  final bool isGameOver;

  /// En son yerleştirmenin sonucu (UI'da kombo/temizlik animasyonu için).
  final PlacementResult? lastResult;

  /// Peş peşe (art arda hamlelerde) satır/sütun temizleme sayacı — bir
  /// hamlede hiç temizlik olmazsa sıfırlanır (bkz. [GameController.placePiece]
  /// ve [GameController.streakBonusStep]).
  final int clearStreak;

  /// En son hamlede seri sayesinde kazanılan ekstra puan (UI'da göstermek için).
  final int lastStreakBonus;

  /// Depo binası seviyesine göre bu turda kalan "geri al" hakkı
  /// (bkz. docs/GDD.md, Bölüm 3 — Depo binası).
  final int undosRemaining;

  GameState copyWith({
    BoardState? board,
    List<Piece?>? tray,
    int? score,
    bool? isGameOver,
    PlacementResult? lastResult,
    int? clearStreak,
    int? lastStreakBonus,
    int? undosRemaining,
  }) => GameState(
    board: board ?? this.board,
    tray: tray ?? this.tray,
    score: score ?? this.score,
    isGameOver: isGameOver ?? this.isGameOver,
    lastResult: lastResult ?? this.lastResult,
    clearStreak: clearStreak ?? this.clearStreak,
    lastStreakBonus: lastStreakBonus ?? this.lastStreakBonus,
    undosRemaining: undosRemaining ?? this.undosRemaining,
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
    bool Function()? isIceBiomeEnabled,
    int Function()? maxUndos,
    int Function()? millBonusLevel,
    void Function(int linesCleared)? onLinesCleared,
    void Function(int cellsPlaced)? onCellsPlaced,
    void Function(int score)? onScoreGained,
    void Function()? onRoundFinished,
  }) : _generator = generator ?? PieceGenerator(),
       _onResourcesGained = onResourcesGained ?? ((_) {}),
       _isIceBiomeEnabled = isIceBiomeEnabled ?? (() => false),
       _maxUndos = maxUndos ?? (() => 0),
       _millBonusLevel = millBonusLevel ?? (() => 0),
       _onLinesCleared = onLinesCleared ?? ((_) {}),
       _onCellsPlaced = onCellsPlaced ?? ((_) {}),
       _onScoreGained = onScoreGained ?? ((_) {}),
       _onRoundFinished = onRoundFinished ?? (() {}),
       super(GameState.initial(BoardState(size: boardSize), const [])) {
    _startNewGame(boardSize);
  }

  /// Peş peşe (art arda) satır/sütun temizleyen hamlelerde, ikinci
  /// temizlikten itibaren her ek hamle için eklenen ekstra puan
  /// (bkz. [GameState.clearStreak] — "peşpeşe patlatmalarda bonus").
  static const int streakBonusStep = 25;

  /// [undo] için tutulan geçmiş — en fazla bu kadar hamle saklanır.
  static const int _maxHistory = 50;

  final PieceGenerator _generator;
  final void Function(Map<ResourceType, int> gained) _onResourcesGained;
  final bool Function() _isIceBiomeEnabled;
  final int Function() _maxUndos;
  final int Function() _millBonusLevel;
  final void Function(int linesCleared) _onLinesCleared;
  final void Function(int cellsPlaced) _onCellsPlaced;
  final void Function(int score) _onScoreGained;
  final void Function() _onRoundFinished;
  final List<GameState> _history = [];

  void _startNewGame(int boardSize) {
    _history.clear();
    final board = BoardState(size: boardSize);
    final tray = _generator.generateTray(
      board,
      iceEnabled: _isIceBiomeEnabled(),
    );
    state = GameState.initial(board, tray, undosRemaining: _maxUndos());
  }

  void newGame({int boardSize = 8}) => _startNewGame(boardSize);

  bool canPlace(int trayIndex, int row, int col) {
    final piece = state.tray[trayIndex];
    if (piece == null || state.isGameOver) return false;
    return state.board.canPlace(piece, row, col);
  }

  /// Depo binası seviyesi kadar hak varsa son hamleyi geri alır (tahta,
  /// tepsi ve skor bir önceki duruma döner) — bkz. docs/GDD.md, Bölüm 3.
  void undo() {
    if (state.undosRemaining <= 0 || _history.isEmpty) return;
    final previous = _history.removeLast();
    state = previous.copyWith(undosRemaining: state.undosRemaining - 1);
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

    // Peş peşe temizlik serisi: bir hamlede hiç satır/sütun temizlenmezse
    // seri sıfırlanır; art arda her temizlikte artan bir bonus verir.
    final newStreak = result.linesCleared > 0 ? state.clearStreak + 1 : 0;
    final streakBonus = newStreak >= 2 ? (newStreak - 1) * streakBonusStep : 0;
    final totalScoreGained = result.scoreGained + streakBonus;

    // Değirmen binasının gerçek etkisi: satır/sütun temizlenen her hamlede
    // seviyesi kadar ekstra taş verir (bkz. BuildingType.mill açıklaması).
    final resourcesGained = Map<ResourceType, int>.from(result.resourcesGained);
    if (result.linesCleared > 0) {
      final millLevel = _millBonusLevel();
      if (millLevel > 0) {
        final bonus = millLevel * result.linesCleared;
        resourcesGained.update(
          ResourceType.stone,
          (v) => v + bonus,
          ifAbsent: () => bonus,
        );
      }
    }

    _onResourcesGained(resourcesGained);
    _onCellsPlaced(result.cellsPlaced);
    _onScoreGained(totalScoreGained);
    if (result.linesCleared > 0) _onLinesCleared(result.linesCleared);

    final trayEmpty = newTray.every((p) => p == null);
    final refilledTray = trayEmpty
        ? _generator.generateTray(board, iceEnabled: _isIceBiomeEnabled())
        : newTray;

    final isGameOver = refilledTray.whereType<Piece>().every(
      (p) => !board.canPlaceAnywhere(p),
    );

    if (isGameOver && !state.isGameOver) _onRoundFinished();

    _history.add(state);
    if (_history.length > _maxHistory) _history.removeAt(0);

    state = state.copyWith(
      board: board,
      tray: refilledTray,
      score: state.score + totalScoreGained,
      isGameOver: isGameOver,
      lastResult: result,
      clearStreak: newStreak,
      lastStreakBonus: streakBonus,
    );
  }
}

final gameControllerProvider = StateNotifierProvider<GameController, GameState>(
  (ref) => GameController(
    onResourcesGained: ref.read(resourceWalletProvider.notifier).deposit,
    isIceBiomeEnabled: () =>
        ref.read(islandControllerProvider).biome.hasIceBlocks,
    maxUndos: () =>
        ref.read(islandControllerProvider).levelOf(BuildingType.warehouse),
    millBonusLevel: () =>
        ref.read(islandControllerProvider).levelOf(BuildingType.mill),
    onLinesCleared: (count) {
      ref.read(dailyQuestControllerProvider.notifier).recordLinesCleared(count);
      ref.read(onboardingControllerProvider.notifier).recordLineCleared();
    },
    onCellsPlaced: (count) {
      ref.read(dailyQuestControllerProvider.notifier).recordCellsPlaced(count);
      ref.read(onboardingControllerProvider.notifier).recordMove();
    },
    onScoreGained: ref.read(dailyQuestControllerProvider.notifier).recordScore,
    onRoundFinished: ref
        .read(dailyQuestControllerProvider.notifier)
        .recordRoundFinished,
  ),
);
