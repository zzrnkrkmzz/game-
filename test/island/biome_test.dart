import 'package:ada_blast/island/models/biome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BiomeTypeX.forTotalLevel', () {
    test('0-4 toplam seviye Orman', () {
      expect(BiomeTypeX.forTotalLevel(0), BiomeType.forest);
      expect(BiomeTypeX.forTotalLevel(4), BiomeType.forest);
    });

    test('5-9 toplam seviye Çöl', () {
      expect(BiomeTypeX.forTotalLevel(5), BiomeType.desert);
      expect(BiomeTypeX.forTotalLevel(9), BiomeType.desert);
    });

    test('10-14 toplam seviye Kar', () {
      expect(BiomeTypeX.forTotalLevel(10), BiomeType.snow);
      expect(BiomeTypeX.forTotalLevel(14), BiomeType.snow);
    });

    test('15+ toplam seviye Uzay', () {
      expect(BiomeTypeX.forTotalLevel(15), BiomeType.space);
      expect(BiomeTypeX.forTotalLevel(20), BiomeType.space);
    });
  });

  group('BiomeTypeX.hasIceBlocks', () {
    test('Kar ve Uzay biyomunda buz bloğu aktif', () {
      expect(BiomeType.snow.hasIceBlocks, isTrue);
      expect(BiomeType.space.hasIceBlocks, isTrue);
    });

    test('Orman ve Çöl biyomunda buz bloğu kapalı', () {
      expect(BiomeType.forest.hasIceBlocks, isFalse);
      expect(BiomeType.desert.hasIceBlocks, isFalse);
    });
  });

  test('Uzay biyomunun bir sonraki eşiği yoktur', () {
    expect(BiomeType.space.nextThreshold, isNull);
  });
}
