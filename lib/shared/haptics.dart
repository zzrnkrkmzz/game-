import 'package:flutter/services.dart';

/// İnce dokunsal geri bildirim sarmalayıcısı. Web/desteklenmeyen
/// platformlarda `HapticFeedback` sessizce başarısız olabilir; bu yüzden
/// her çağrı yutuluyor — cilalama amaçlı, hataya sebep olmamalı.
class Haptics {
  Haptics._();

  static void placePiece() => _run(HapticFeedback.lightImpact);

  static void lineCleared() => _run(HapticFeedback.mediumImpact);

  static void gameOver() => _run(HapticFeedback.heavyImpact);

  static void buildingUpgraded() => _run(HapticFeedback.lightImpact);

  static void tap() => _run(HapticFeedback.selectionClick);

  static void _run(Future<void> Function() feedback) {
    // ignore: discarded_futures
    feedback().catchError((_) {});
  }
}
