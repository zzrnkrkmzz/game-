import 'package:ada_blast/board/models/block_color.dart';
import 'package:ada_blast/board/models/placed_block.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlacedBlock', () {
    test('normal blok 1 vuruşta temizlenir', () {
      final block = PlacedBlock.normal(BlockColor.coral);

      expect(block.isIce, isFalse);
      expect(block.hit(), isNull);
    });

    test('buz bloğu 2 vuruş gerektirir', () {
      final block = PlacedBlock.ice(BlockColor.coral);

      expect(block.isIce, isTrue);
      final afterFirstHit = block.hit();
      expect(afterFirstHit, isNotNull);
      expect(afterFirstHit!.remainingHits, 1);
      expect(afterFirstHit.color, BlockColor.coral);

      expect(afterFirstHit.hit(), isNull);
    });

    test('bonus özelliği vuruş sonrası korunur', () {
      final block = PlacedBlock.ice(BlockColor.coral);
      expect(block.isBonus, isFalse);

      final normalBonus = PlacedBlock.normal(BlockColor.coral, isBonus: true);
      expect(normalBonus.isBonus, isTrue);
      expect(normalBonus.hit(), isNull);
    });
  });
}
