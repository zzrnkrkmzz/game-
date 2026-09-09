import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quests/logic/daily_quest_controller.dart';
import '../../shared/resource_wallet.dart';
import '../models/building_type.dart';
import '../models/island_state.dart';

/// Ada ekranındaki bina inşa/yükseltme akışını yönetir. Kaynak harcaması
/// [ResourceWallet] üzerinden yapılır — bkz. docs/GDD.md, Bölüm 3.
class IslandController extends StateNotifier<IslandState> {
  IslandController({
    required ResourceWallet wallet,
    void Function()? onUpgraded,
  }) : _wallet = wallet,
       _onUpgraded = onUpgraded ?? (() {}),
       super(IslandState.initial());

  final ResourceWallet _wallet;
  final void Function() _onUpgraded;

  bool canUpgrade(BuildingType type) {
    final nextLevel = state.levelOf(type) + 1;
    if (nextLevel > BuildingTypeX.maxLevel) return false;
    return _wallet.canAfford({type.costResource: type.costForLevel(nextLevel)});
  }

  bool isMaxLevel(BuildingType type) =>
      state.levelOf(type) >= BuildingTypeX.maxLevel;

  /// [type] binasını bir sonraki seviyeye yükseltmeyi dener. Kaynak
  /// yetersizse veya zaten maksimum seviyedeyse hiçbir şey değişmez.
  bool upgrade(BuildingType type) {
    final nextLevel = state.levelOf(type) + 1;
    if (nextLevel > BuildingTypeX.maxLevel) return false;

    final cost = {type.costResource: type.costForLevel(nextLevel)};
    if (!_wallet.spend(cost)) return false;

    final levels = Map<BuildingType, int>.from(state.levels);
    levels[type] = nextLevel;
    state = state.copyWith(levels: levels);
    _onUpgraded();
    return true;
  }
}

final islandControllerProvider =
    StateNotifierProvider<IslandController, IslandState>(
      (ref) => IslandController(
        wallet: ref.read(resourceWalletProvider.notifier),
        onUpgraded: ref
            .read(dailyQuestControllerProvider.notifier)
            .recordBuildingUpgraded,
      ),
    );
