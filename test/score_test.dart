import 'package:flutter_test/flutter_test.dart';
import 'package:go_stop_app/utils/matgo_engine.dart';
import 'package:go_stop_app/utils/deck_manager.dart';
import 'package:go_stop_app/models/card_model.dart';

GoStopCard c(int month, String type, {String name = ''}) =>
    GoStopCard(id: month, month: month, type: type, name: name, imageUrl: '');

void main() {
  test('기본 점수 계산 테스트', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    deckManager.capturedCards[0] = [c(1, '광'), c(2, '광'), c(3, '광')];
    expect(engine.calculateScore(1), 3);
  });

  test('pi over 10 scores correctly', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    deckManager.capturedCards[0] = [for (var i = 0; i < 11; i++) c(i, '피')];
    expect(engine.calculateScore(1), 2);
  });

  test('고도리 점수 테스트', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    deckManager.capturedCards[0] = [c(1, '띠'), c(3, '띠'), c(8, '띠')];
    expect(engine.calculateScore(1), 0); // 5띠 미만이므로 0점
  });

  test('animal count seven doubles score', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    deckManager.capturedCards[0] = [for (var i = 0; i < 7; i++) c(i, '오')];
    expect(engine.calculateScore(1), 6); // 7오 = 6점 (7-1)
  });

  test('멍따 점수 테스트', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    // 10피 이상이면 (피수-9)점
    deckManager.capturedCards[0] = [for (var i = 0; i < 12; i++) c(i, '피')];
    expect(engine.calculateScore(1), 3); // 12피 = 3점 (12-9)
  });

  test('승수 적용 테스트', () {
    final deckManager = DeckManager(playerCount: 2, isMatgo: true);
    final engine = MatgoEngine(deckManager);
    // 3광 = 3점
    deckManager.capturedCards[0] = [c(1, '광'), c(3, '광'), c(8, '광')];
    // 1GO = +1점
    engine.goCount = 1;
    expect(engine.calculateScore(1), 4); // 3점 + 1점 = 4점
  });
}
