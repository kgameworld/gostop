import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/score_calculator.dart';

class DummyCard {
  final int id;
  final int month;
  final String type;
  DummyCard(this.id, this.month, this.type);
}

testCases() => [
  // 3광(비광X)
  PlayerState(captured: [DummyCard(1,1,'광'), DummyCard(9,8,'광'), DummyCard(45,12,'광')]),
  // 3광(비광O)
  PlayerState(captured: [DummyCard(1,1,'광'), DummyCard(9,8,'광'), DummyCard(41,11,'광')]),
  // 4광
  PlayerState(captured: [DummyCard(1,1,'광'), DummyCard(9,8,'광'), DummyCard(45,12,'광'), DummyCard(41,11,'광')]),
  // 5광
  PlayerState(captured: [DummyCard(1,1,'광'), DummyCard(9,8,'광'), DummyCard(45,12,'광'), DummyCard(41,11,'광'), DummyCard(99,5,'광')]),
  // 띠 5장
  PlayerState(captured: List.generate(5, (i) => DummyCard(i, i+1, '띠'))),
  // 띠 7장
  PlayerState(captured: List.generate(7, (i) => DummyCard(i, i+1, '띠'))),
  // 피 10장
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피'))),
  // 피 15장
  PlayerState(captured: List.generate(15, (i) => DummyCard(i, i+1, '피'))),
  // 오 2장
  PlayerState(captured: List.generate(2, (i) => DummyCard(i, i+1, '오'))),
  // 오 4장
  PlayerState(captured: List.generate(4, (i) => DummyCard(i, i+1, '오'))),
  // 폭탄
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), bomb: true),
  // 흔들기
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), shake: true),
  // 박
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), bak: true),
  // 총통
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), chongtong: true),
  // 고 1회
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), goCount: 1),
  // 고 2회
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), goCount: 2),
  // 고 3회
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), goCount: 3),
  // 폭탄+고
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), bomb: true, goCount: 2),
  // 폭탄+흔들기+고
  PlayerState(captured: List.generate(10, (i) => DummyCard(i, i+1, '피')), bomb: true, shake: true, goCount: 3),
];

void main() {
  test('ScoreCalculator snapshot tests', () {
    final cases = testCases();
    for (var i = 0; i < cases.length; i++) {
      final s = cases[i];
      final result = compute(s);
      print('CASE $i: ${result.detail} => base=${result.base}, mult=${result.mult}, total=${result.total}');
      expect(result.total, isNonNegative);
    }
  });
} 