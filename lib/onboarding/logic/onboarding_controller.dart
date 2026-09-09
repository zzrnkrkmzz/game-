import 'package:flutter_riverpod/flutter_riverpod.dart';

/// İlk 60 saniyelik akışın durumu (bkz. docs/GDD.md, Bölüm 8.1 -
/// "Doğrudan Oyuna Düş"): açılış ekranı yok, ilk birkaç hamle ipucuyla
/// yönlendirilir, ilk satır temizlenince Ada ekranına otomatik geçilir.
class OnboardingState {
  const OnboardingState({
    required this.movesPlaced,
    required this.hasClearedFirstLine,
    required this.navigateToIslandRequested,
  });

  factory OnboardingState.initial() => const OnboardingState(
    movesPlaced: 0,
    hasClearedFirstLine: false,
    navigateToIslandRequested: false,
  );

  final int movesPlaced;
  final bool hasClearedFirstLine;

  /// Bir kerelik "Ada'ya geç" isteği — tüketildiğinde tekrar false olur.
  final bool navigateToIslandRequested;

  /// İlk hamlelerde tahtanın üzerinde ok/ışık ipucu gösterilsin mi?
  bool get showMoveHint =>
      !hasClearedFirstLine && movesPlaced < OnboardingController.hintMoveCount;

  OnboardingState copyWith({
    int? movesPlaced,
    bool? hasClearedFirstLine,
    bool? navigateToIslandRequested,
  }) => OnboardingState(
    movesPlaced: movesPlaced ?? this.movesPlaced,
    hasClearedFirstLine: hasClearedFirstLine ?? this.hasClearedFirstLine,
    navigateToIslandRequested:
        navigateToIslandRequested ?? this.navigateToIslandRequested,
  );
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController({OnboardingState? initialState})
    : super(initialState ?? OnboardingState.initial());

  /// İlk kaç hamlede ipucu gösterileceği (bkz. docs/GDD.md: "ilk 2-3 hamle").
  static const int hintMoveCount = 2;

  void recordMove() {
    if (state.hasClearedFirstLine) return;
    state = state.copyWith(movesPlaced: state.movesPlaced + 1);
  }

  void recordLineCleared() {
    if (state.hasClearedFirstLine) return;
    state = state.copyWith(
      hasClearedFirstLine: true,
      navigateToIslandRequested: true,
    );
  }

  /// UI, otomatik Ada geçişini gerçekleştirdikten sonra bu bayrağı
  /// tüketmelidir — aksi halde her rebuild'de tekrar tetiklenir.
  void consumeNavigationRequest() {
    if (!state.navigateToIslandRequested) return;
    state = state.copyWith(navigateToIslandRequested: false);
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
      (ref) => OnboardingController(),
    );
