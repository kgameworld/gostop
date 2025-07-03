import 'dart:math';
import '../data/card_data.dart';
import '../models/card_model.dart';
import 'card_location.dart';

class DeckManager {
  final int playerCount;
  final bool isMatgo;
  List<GoStopCard> fullDeck = [];
  final Map<int, List<GoStopCard>> playerHands = {};
  final List<GoStopCard> fieldCards = [];
  final List<GoStopCard> drawPile = [];
  final Random random = Random();
  final Map<int, List<GoStopCard>> capturedCards = {};
  final Map<int, CardLocation> locator = {};

  DeckManager({required this.playerCount, this.isMatgo = false}) {
    if (playerCount < 2 || playerCount > 3) {
      throw Exception('GoStop supports only 2 or 3 players.');
    }
    reset();
  }

  void reset() {
    // 모든 상태 초기화
    playerHands.clear();
    fieldCards.clear();
    drawPile.clear();
    capturedCards.clear();
    for (int i = 0; i < playerCount; i++) {
      capturedCards[i] = [];
    }
    fullDeck = List.from(goStopCards.where((card) => card.type != 'back'));
    _setupGame();
  }

  void _setupGame() {
    shuffle();
    deal();
  }

  void shuffle() {
    fullDeck.shuffle(random);
  }

  void deal() {
    // 모든 카드 리스트 초기화
    for (var p = 0; p < playerCount; p++) {
      playerHands[p] = [];
    }
    fieldCards.clear();
    drawPile.clear();

    // 맞고(2인) 기준 분배
    // 바닥 4장 -> 플레이어1 5장 -> 플레이어2 5장
    fieldCards.addAll(fullDeck.sublist(0, 4));
    playerHands[0]!.addAll(fullDeck.sublist(4, 9));
    playerHands[1]!.addAll(fullDeck.sublist(9, 14));
    fullDeck.removeRange(0, 14);

    // 바닥 4장 -> 플레이어1 5장 -> 플레이어2 5장
    fieldCards.addAll(fullDeck.sublist(0, 4));
    playerHands[0]!.addAll(fullDeck.sublist(4, 9));
    playerHands[1]!.addAll(fullDeck.sublist(9, 14));
    fullDeck.removeRange(0, 14);

    _handleInitialBonusCards();

    // 나머지는 더미
    drawPile.addAll(fullDeck);
    fullDeck.clear();

    // 중복 검증: 전체 카드가 정확히 한 번씩만 존재해야 함
    final allIds = <int>{};
    for (var h in playerHands.values) {
      for (var c in h) allIds.add(c.id);
    }
    for (var c in fieldCards) allIds.add(c.id);
    for (var c in drawPile) allIds.add(c.id);
    for (var p in capturedCards.values) {
      for (var c in p) allIds.add(c.id);
    }
    assert(allIds.length == goStopCards.where((card) => card.type != 'back').length, '카드 중복 또는 누락 발생!');

    // 로그 추가
    print('[DEAL] 분배 직후 fieldCards: \x1b[33m${fieldCards.length}\x1b[0m');
    for (var c in fieldCards) {
      print('[DEAL] 필드카드: id=${c.id}, month=${c.month}, type=${c.type}, name=${c.name}');
    }
    print('[DEBUG] playerHands[0] length: \x1b[32m${playerHands[0]?.length}\x1b[0m');
    print('[DEBUG] playerHands[1] length: \x1b[32m${playerHands[1]?.length}\x1b[0m');
  }

  List<GoStopCard> getPlayerHand(int playerIndex) {
    return playerHands[playerIndex] ?? [];
  }

  List<GoStopCard> getFieldCards() {
    print('[getFieldCards] fieldCards: ${fieldCards.length}');
    for (var c in fieldCards) {
      print('[getFieldCards] 필드카드: id=${c.id}, month=${c.month}, type=${c.type}, name=${c.name}');
    }
    return fieldCards;
  }

  List<GoStopCard> getDrawPile() => drawPile;

  void _handleInitialBonusCards() {
    var bonusCards = fieldCards.where((c) => c.isBonus).toList();
    while (bonusCards.isNotEmpty) {
      fieldCards.removeWhere((c) => c.isBonus);
      capturedCards[0]?.addAll(bonusCards);
      for (var i = 0; i < bonusCards.length; i++) {
        if (fullDeck.isNotEmpty) {
          fieldCards.add(fullDeck.removeAt(0));
        }
      }
      bonusCards = fieldCards.where((c) => c.isBonus).toList();
    }
  }

  // 카드 이동 관련 메서드
  void moveCardToField(GoStopCard card) {
    fieldCards.add(card);
  }

  void removeCardFromField(GoStopCard card) {
    fieldCards.removeWhere((c) => c.id == card.id);
  }

  void moveCardToCaptured(GoStopCard card, int playerIndex) {
    playerHands[playerIndex]?.removeWhere((c) => c.id == card.id);
    capturedCards[playerIndex]?.add(card);
  }

  GoStopCard? drawCard() {
    if (drawPile.isEmpty) return null;
    return drawPile.removeAt(0);
  }

  // 카드 이동 시 locator 업데이트 함수
  void moveCard(int cardId, CardLocation to) {
    locator[cardId] = to;
    assert(_validState());
  }

  bool _validState() {
    // 카드 개수(48+보너스) 및 중복 없음 검증
    final allIds = <int>{};
    for (var hand in playerHands.values) {
      for (var c in hand) allIds.add(c.id);
    }
    for (var c in fieldCards) allIds.add(c.id);
    for (var c in drawPile) allIds.add(c.id);
    for (var p in capturedCards.values) {
      for (var c in p) allIds.add(c.id);
    }
    // 카드 개수(51장) 및 중복 없음
    return allIds.length == 51 && !locator.values.any((v) => v == null);
  }
}