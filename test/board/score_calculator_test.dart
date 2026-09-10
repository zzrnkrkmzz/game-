import 'package:ada_blast/board/models/board_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScoreCalculator', () {
    test('temizlik olmadan sadece hücre başı puan verir', () {
      final score = ScoreCalculator.calculate(cellsPlaced: 4, linesCleared: 0);
      expect(score, 4);
    });

    test('tek satır temizliği hat bonusu ekler', () {
      final score = ScoreCalculator.calculate(cellsPlaced: 3, linesCleared: 1);
      expect(score, 3 + 100);
    });

    test('çoklu (kombo) temizlik ekstra bonus verir', () {
      final score = ScoreCalculator.calculate(cellsPlaced: 1, linesCleared: 2);
      // 1 hücre + 2 hat * 100 + 1 ekstra hat * 50 kombo bonusu
      expect(score, 1 + 200 + 50);
    });
  });
}
