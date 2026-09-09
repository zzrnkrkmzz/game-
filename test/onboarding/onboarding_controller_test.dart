import 'package:ada_blast/onboarding/logic/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingController', () {
    test('başlangıçta ipucu gösterilir', () {
      final controller = OnboardingController();
      expect(controller.state.showMoveHint, isTrue);
      expect(controller.state.movesPlaced, 0);
    });

    test('hintMoveCount kadar hamleden sonra ipucu gizlenir', () {
      final controller = OnboardingController();

      for (var i = 0; i < OnboardingController.hintMoveCount; i++) {
        expect(controller.state.showMoveHint, isTrue);
        controller.recordMove();
      }

      expect(controller.state.showMoveHint, isFalse);
    });

    test('ilk satır temizlenince navigateToIslandRequested true olur', () {
      final controller = OnboardingController();

      controller.recordLineCleared();

      expect(controller.state.hasClearedFirstLine, isTrue);
      expect(controller.state.navigateToIslandRequested, isTrue);
      expect(controller.state.showMoveHint, isFalse);
    });

    test('consumeNavigationRequest bayrağı sıfırlar', () {
      final controller = OnboardingController();
      controller.recordLineCleared();

      controller.consumeNavigationRequest();

      expect(controller.state.navigateToIslandRequested, isFalse);
      expect(controller.state.hasClearedFirstLine, isTrue);
    });

    test(
      'ilk satır temizlendikten sonra recordMove hiçbir şeyi değiştirmez',
      () {
        final controller = OnboardingController();
        controller.recordLineCleared();
        controller.consumeNavigationRequest();
        final before = controller.state;

        controller.recordMove();

        expect(controller.state, same(before));
      },
    );
  });
}
