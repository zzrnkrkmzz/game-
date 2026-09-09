import 'package:ada_blast/board/models/block_color.dart';
import 'package:ada_blast/shared/resource_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResourceWallet', () {
    test('başlangıçta tüm kaynaklar sıfırdır', () {
      final wallet = ResourceWallet();
      expect(wallet.amountOf(ResourceType.wood), 0);
      expect(wallet.amountOf(ResourceType.stone), 0);
      expect(wallet.amountOf(ResourceType.crystal), 0);
    });

    test('deposit bakiyeyi artırır', () {
      final wallet = ResourceWallet();
      wallet.deposit({ResourceType.wood: 5, ResourceType.crystal: 2});

      expect(wallet.amountOf(ResourceType.wood), 5);
      expect(wallet.amountOf(ResourceType.crystal), 2);
      expect(wallet.amountOf(ResourceType.stone), 0);
    });

    test('art arda yapılan depositler birikir', () {
      final wallet = ResourceWallet();
      wallet.deposit({ResourceType.wood: 3});
      wallet.deposit({ResourceType.wood: 4});

      expect(wallet.amountOf(ResourceType.wood), 7);
    });

    test('canAfford yeterli bakiyede true, yetersizde false döner', () {
      final wallet = ResourceWallet();
      wallet.deposit({ResourceType.wood: 10, ResourceType.stone: 2});

      expect(wallet.canAfford({ResourceType.wood: 10}), isTrue);
      expect(wallet.canAfford({ResourceType.wood: 11}), isFalse);
      expect(
        wallet.canAfford({ResourceType.wood: 5, ResourceType.stone: 2}),
        isTrue,
      );
      expect(
        wallet.canAfford({ResourceType.wood: 5, ResourceType.stone: 3}),
        isFalse,
      );
    });

    test('spend yeterli bakiyede düşer ve true döner', () {
      final wallet = ResourceWallet();
      wallet.deposit({ResourceType.wood: 10});

      final ok = wallet.spend({ResourceType.wood: 6});

      expect(ok, isTrue);
      expect(wallet.amountOf(ResourceType.wood), 4);
    });

    test('spend yetersiz bakiyede hiçbir şeyi değiştirmez ve false döner', () {
      final wallet = ResourceWallet();
      wallet.deposit({ResourceType.wood: 3, ResourceType.stone: 10});

      final ok = wallet.spend({ResourceType.wood: 5, ResourceType.stone: 1});

      expect(ok, isFalse);
      expect(wallet.amountOf(ResourceType.wood), 3);
      expect(wallet.amountOf(ResourceType.stone), 10);
    });
  });
}
