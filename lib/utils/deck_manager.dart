import 'dart:math';
import '../data/card_data.dart';
import '../models/card_model.dart';

class DeckManager {
  final int playerCount;
  final bool isMatgo;
  List<GoStopCard> fullDeck = [];
  List<GoStopCard> animationDeck = []; // 애니메이션용 덱 추가
  final Map<int, List<GoStopCard>> playerHands = {};
  final List<GoStopCard> fieldCards = [];
  final List<GoStopCard> drawPile = [];
  final Random random = Random();
  final Map<int, List<GoStopCard>> capturedCards = {};

  DeckManager({required this.playerCount, this.isMatgo = false}) {
    if (playerCount < 2 || playerCount > 3) {
      throw Exception('GoStop supports only 2 or 3 players.');
    }
    // 애니메이션을 위해 자동 분배하지 않음
    _initializeDeck();
  }

  // 덱 초기화 (분배하지 않음)
  void _initializeDeck() {
    // 모든 상태 초기화
    playerHands.clear();
    fieldCards.clear();
    drawPile.clear();
    capturedCards.clear();
    
    // 손패 초기화 (중요!)
    for (int i = 0; i < playerCount; i++) {
      playerHands[i] = [];
      capturedCards[i] = [];
    }
    
    fullDeck = List.from(goStopCards.where((card) => card.type != 'back'));
    animationDeck = List.from(fullDeck); // 애니메이션용 덱도 초기화
    
    // 실제 게임 덱에 모든 카드 추가 (중요!)
    drawPile.addAll(fullDeck);
    
    // 덱 셔플 (중요!)
    shuffle();
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

  // 카드 분배 애니메이션을 위한 public 메서드
  void setupGameAfterAnimation() {
    // 애니메이션에서 사용된 카드들을 실제로 분배
    deal();
  }

  void _setupGame() {
    shuffle();
    deal();
  }

  void shuffle() {
    fullDeck.shuffle(random);
    animationDeck = List.from(fullDeck); // 애니메이션용 덱도 함께 셔플
    drawPile.shuffle(random); // 실제 게임 덱도 셔플
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
      for (var c in h) {
        allIds.add(c.id);
      }
    }
    for (var c in fieldCards) {
      allIds.add(c.id);
    }
    for (var c in drawPile) {
      allIds.add(c.id);
    }
    for (var p in capturedCards.values) {
      for (var c in p) {
        allIds.add(c.id);
      }
    }
    assert(allIds.length == goStopCards.where((card) => card.type != 'back').length, '카드 중복 또는 누락 발생!');


  }

  List<GoStopCard> getPlayerHand(int playerIndex) {
    return playerHands[playerIndex] ?? [];
  }

  List<GoStopCard> getFieldCards() {
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
}