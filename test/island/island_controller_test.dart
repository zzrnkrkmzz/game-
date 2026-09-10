import 'package:ada_blast/board/models/block_color.dart';
import 'package:ada_blast/island/logic/island_controller.dart';
import 'package:ada_blast/island/models/building_type.dart';
import 'package:ada_blast/shared/resource_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IslandController', () {
    test('başlangıçta tüm binalar seviye 0dır', () {
      final controller = IslandController(wallet: ResourceWallet());

      for (final type in BuildingType.values) {
        expect(controller.state.levelOf(type), 0);
      }
    });

    test('yetersiz kaynakla yükseltme başarısız olur ve seviye değişmez', () {
      final wallet = ResourceWallet();
      final controller = IslandController(wallet: wallet);

      final ok = controller.upgrade(BuildingType.warehouse);

      expect(ok, isFalse);
      expect(controller.state.levelOf(BuildingType.warehouse), 0);
    });

    test('yeterli kaynakla yükseltme başarılı olur ve kaynak düşer', () {
      final wallet = ResourceWallet();
      wallet.deposit({BuildingType.warehouse.costResource: 100});
      final controller = IslandController(wallet: wallet);
      final cost = BuildingType.warehouse.costForLevel(1);

      final ok = controller.upgrade(BuildingType.warehouse);

      expect(ok, isTrue);
      expect(controller.state.levelOf(BuildingType.warehouse), 1);
      expect(wallet.amountOf(BuildingType.warehouse.costResource), 100 - cost);
    });

    test('maksimum seviyeye ulaşınca daha fazla yükseltilemez', () {
      final wallet = ResourceWallet();
      wallet.deposit({BuildingType.warehouse.costResource: 100000});
      final controller = IslandController(wallet: wallet);

      for (var i = 0; i < BuildingTypeX.maxLevel; i++) {
        expect(controller.upgrade(BuildingType.warehouse), isTrue);
      }

      expect(controller.isMaxLevel(BuildingType.warehouse), isTrue);
      expect(controller.upgrade(BuildingType.warehouse), isFalse);
      expect(
        controller.state.levelOf(BuildingType.warehouse),
        BuildingTypeX.maxLevel,
      );
    });

    test('canUpgrade kaynak yetersizken false, yeterliyken true döner', () {
      final wallet = ResourceWallet();
      final controller = IslandController(wallet: wallet);

      expect(controller.canUpgrade(BuildingType.mill), isFalse);

      wallet.deposit({
        BuildingType.mill.costResource: BuildingType.mill.costForLevel(1),
      });

      expect(controller.canUpgrade(BuildingType.mill), isTrue);
    });

    test('bir binanın yükseltilmesi diğerinin bakiyesini etkilemez', () {
      final wallet = ResourceWallet();
      wallet.deposit({
        ResourceType.wood: 1000,
        ResourceType.stone: 1000,
        ResourceType.crystal: 1000,
      });
      final controller = IslandController(wallet: wallet);

      controller.upgrade(BuildingType.warehouse);

      expect(controller.state.levelOf(BuildingType.mill), 0);
    });
  });
}
