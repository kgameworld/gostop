import 'package:go_stop_app/utils/deck_manager.dart';
import 'package:go_stop_app/utils/matgo_engine.dart';
import 'package:go_stop_app/models/card_model.dart';

void main() {
  print('🎮 고스톱 게임 시뮬레이션 시작');
  print('=' * 50);
  
  // 시뮬레이션 1: 보너스피 처리 규칙 검증
  testBonusPiRules();
  
  // 시뮬레이션 2: 뻑 발생 시 보너스피 손실 검증
  testPpeokBonusPiLoss();
  
  // 시뮬레이션 3: 2장 매치(따닥) 처리 검증
  testTtakRules();
  
  // 시뮬레이션 4: 피 강탈 우선순위 검증
  testPiStealPriority();
  
  // 시뮬레이션 5: 턴 종료 시 보너스피 처리 검증
  testTurnEndBonusPi();
  
  print('=' * 50);
  print('✅ 모든 시뮬레이션 완료');
}

void testBonusPiRules() {
  print('\n🔍 시뮬레이션 1: 보너스피 처리 규칙 검증');
  
  final deckManager = DeckManager(playerCount: 2);
  final engine = MatgoEngine(deckManager);
  
  // 초기 상태 설정
  resetEngine(engine);
  
  // 테스트 시나리오: 보너스피가 나와서 내가 낸 카드 위에 겹침
  final handCard = GoStopCard(id: 1, month: 3, type: '피', name: '손패 3월피', imageUrl: '3_pi1.png');
  final bonusCard = GoStopCard(id: 2, month: 0, type: '피', name: '보너스피', imageUrl: 'bonus_3pi.png', isBonus: true);
  final normalCard = GoStopCard(id: 3, month: 4, type: '피', name: '일반 4월피', imageUrl: '4_pi1.png');
  
  // 상태 설정
  engine.deckManager.playerHands[0] = [handCard];
  engine.deckManager.drawPile.clear();
  engine.deckManager.drawPile.addAll([bonusCard, normalCard]);
  
  print('📋 초기 상태:');
  printState(engine);
  
  // 1단계: 손패 카드 내기
  print('\n🎯 1단계: 손패 카드 내기');
  engine.playCard(handCard);
  printState(engine);
  
  // 2단계: 카드더미 뒤집기 (보너스피)
  print('\n🎯 2단계: 카드더미 뒤집기 (보너스피)');
  engine.flipFromDeck();
  printState(engine);
  
  // 검증: 보너스피가 필드에 추가되었는지 확인
  final fieldCards = engine.getField();
  final hasBonusInField = fieldCards.any((c) => c.isBonus);
  
  print('\n❌ 규칙 위반 발견:');
  if (hasBonusInField) {
    print('  - 보너스피가 필드에 추가됨 (규칙 위반)');
    print('  - engine.mdc: "보너스피는 내가 낸 손패카드 위에 겹치고 한 장 더 뒤집는다"');
    print('  - 필드에 추가하면 안 됨');
  }
  
  // 검증: pendingCaptured에 즉시 추가되었는지 확인
  final hasBonusInPending = engine.pendingCaptured.any((c) => c.isBonus);
  if (hasBonusInPending) {
    print('  - 보너스피가 pendingCaptured에 즉시 추가됨 (규칙 위반)');
    print('  - 뻑 발생 시 손실 가능성 무시됨');
  }
}

void testPpeokBonusPiLoss() {
  print('\n🔍 시뮬레이션 2: 뻑 발생 시 보너스피 손실 검증');
  
  final deckManager = DeckManager(playerCount: 2);
  final engine = MatgoEngine(deckManager);
  
  resetEngine(engine);
  
  // 테스트 시나리오: 보너스피 → 뻑 발생 → 보너스피 손실
  final handCard = GoStopCard(id: 1, month: 3, type: '피', name: '손패 3월피', imageUrl: '3_pi1.png');
  final fieldCard1 = GoStopCard(id: 2, month: 3, type: '피', name: '필드 3월피1', imageUrl: '3_pi2.png');
  final fieldCard2 = GoStopCard(id: 3, month: 3, type: '피', name: '필드 3월피2', imageUrl: '3_pi3.png');
  final bonusCard = GoStopCard(id: 4, month: 0, type: '피', name: '보너스피', imageUrl: 'bonus_3pi.png', isBonus: true);
  final ppeokCard = GoStopCard(id: 5, month: 3, type: '피', name: '뻑 3월피', imageUrl: '3_pi4.png');
  
  // 상태 설정: 뻑 발생 상황
  engine.deckManager.playerHands[0] = [handCard];
  engine.deckManager.fieldCards.clear();
  engine.deckManager.fieldCards.addAll([fieldCard1, fieldCard2]); // 필드에 3월 2장
  engine.deckManager.drawPile.clear();
  engine.deckManager.drawPile.addAll([bonusCard, ppeokCard]);
  
  print('📋 초기 상태 (뻑 발생 상황):');
  printState(engine);
  
  // 1단계: 손패 카드 내기
  engine.playCard(handCard);
  
  // 2단계: 보너스피 뒤집기
  engine.flipFromDeck();
  
  // 3단계: 뻑 발생 카드 뒤집기
  engine.flipFromDeck();
  
  print('\n📋 뻑 발생 후 상태:');
  printState(engine);
  
  // 검증: 뻑 발생 시 보너스피가 손실되었는지 확인
  final hasBonusInPending = engine.pendingCaptured.any((c) => c.isBonus);
  final hasPpeokMonth = engine.ppeokMonth != null;
  
  print('\n❌ 규칙 위반 발견:');
  if (hasPpeokMonth && hasBonusInPending) {
    print('  - 뻑 발생 시에도 보너스피가 pendingCaptured에 남아있음 (규칙 위반)');
    print('  - engine.mdc: "보너스피가 아닌 카드로 뻑이 발생하면, 보너스피까지 전부 뻑에 묶여서 가져오지 않는다"');
  }
}

void testTtakRules() {
  print('\n🔍 시뮬레이션 3: 2장 매치(따닥) 처리 검증');
  
  final deckManager = DeckManager(playerCount: 2);
  final engine = MatgoEngine(deckManager);
  
  resetEngine(engine);
  
  // 테스트 시나리오: 2장 매치 → 뒤집은 카드가 매치 없음
  final handCard = GoStopCard(id: 1, month: 3, type: '피', name: '손패 3월피', imageUrl: '3_pi1.png');
  final fieldCard1 = GoStopCard(id: 2, month: 3, type: '피', name: '필드 3월피1', imageUrl: '3_pi2.png');
  final fieldCard2 = GoStopCard(id: 3, month: 3, type: '피', name: '필드 3월피2', imageUrl: '3_pi3.png');
  final flipCard = GoStopCard(id: 4, month: 4, type: '피', name: '뒤집힌 4월피', imageUrl: '4_pi1.png');
  
  // 상태 설정: 2장 매치 상황
  engine.deckManager.playerHands[0] = [handCard];
  engine.deckManager.fieldCards.clear();
  engine.deckManager.fieldCards.addAll([fieldCard1, fieldCard2]); // 필드에 3월 2장
  engine.deckManager.drawPile.clear();
  engine.deckManager.drawPile.addAll([flipCard]);
  
  print('📋 초기 상태 (2장 매치 상황):');
  printState(engine);
  
  // 1단계: 손패 카드 내기 (2장 매치 발생)
  engine.playCard(handCard);
  
  // 2단계: 카드더미 뒤집기 (매치 없음)
  engine.flipFromDeck();
  
  print('\n📋 2장 매치 처리 후 상태:');
  printState(engine);
  
  // 검증: 뒤집은 카드가 필드에 남았는지 확인
  final fieldCards = engine.getField();
  final hasFlipCardInField = fieldCards.any((c) => c.id == flipCard.id);
  
  print('\n❌ 규칙 위반 발견:');
  if (!hasFlipCardInField) {
    print('  - 뒤집은 카드가 필드에 남지 않음 (규칙 위반)');
    print('  - engine.mdc: "뒤집은 카드가 2장 매치가 아니면, 뒤집은 카드는 필드에 남고 먹은 카드로 분류되지 않는다"');
  }
}

void testPiStealPriority() {
  print('\n🔍 시뮬레이션 4: 피 강탈 우선순위 검증');
  
  final deckManager = DeckManager(playerCount: 2);
  final engine = MatgoEngine(deckManager);
  
  resetEngine(engine);
  
  // 테스트 시나리오: 상대방이 일반피, 쌍피, 보너스피를 모두 가지고 있을 때 강탈
  final normalPi = GoStopCard(id: 1, month: 1, type: '피', name: '일반피', imageUrl: '1_pi1.png');
  final ssangPi = GoStopCard(id: 2, month: 2, type: '피', name: '쌍피', imageUrl: '2_ssangpi_double.png');
  final bonusPi = GoStopCard(id: 3, month: 0, type: '피', name: '보너스피', imageUrl: 'bonus_3pi.png', isBonus: true);
  
  // 상대방 획득 카드 설정
  engine.deckManager.capturedCards[1] = [normalPi, ssangPi, bonusPi];
  
  print('📋 초기 상태 (상대방 피 카드):');
  print('  상대방 획득: ${engine.getCaptured(2).map((c) => c.name).toList()}');
  
  // 피 강탈 시뮬레이션 (뻑 완성 등으로)
  // 실제로는 뻑 완성이나 쪽 등에서 피 강탈이 발생
  print('\n🎯 피 강탈 시뮬레이션');
  
  // 검증: 우선순위 로직이 구현되었는지 확인
  print('\n❌ 규칙 위반 발견:');
  print('  - 피 강탈 우선순위 로직이 구현되지 않음');
  print('  - engine.mdc: "우선순위: 일반피 → 쌍피 → 보너스피"');
  print('  - 각 종류별로 1장씩만 강탈하는 제한도 없음');
}

void testTurnEndBonusPi() {
  print('\n🔍 시뮬레이션 5: 턴 종료 시 보너스피 처리 검증');
  
  final deckManager = DeckManager(playerCount: 2);
  final engine = MatgoEngine(deckManager);
  
  resetEngine(engine);
  
  // 테스트 시나리오: 보너스피가 있는 상태에서 턴 종료
  final bonusCard = GoStopCard(id: 1, month: 0, type: '피', name: '보너스피', imageUrl: 'bonus_3pi.png', isBonus: true);
  
  // 보너스피를 pendingCaptured에 추가 (현재 구현 방식)
  engine.pendingCaptured.add(bonusCard);
  
  print('📋 턴 종료 전 상태:');
  print('  pendingCaptured: ${engine.pendingCaptured.map((c) => c.name).toList()}');
  
  // 턴 종료 시뮬레이션 (private 메서드이므로 직접 호출 불가)
  print('\n📋 턴 종료 후 상태 (시뮬레이션):');
  print('  - pendingCaptured의 카드들이 실제 획득 영역으로 이동해야 함');
  print('  - 뻑 상태가 아닌 경우에만 보너스피 획득');
  
  // 검증: 현재 구현 상태 확인
  final hasBonusInPending = engine.pendingCaptured.any((c) => c.isBonus);
  
  print('\n❌ 규칙 위반 발견:');
  if (hasBonusInPending) {
    print('  - 보너스피가 pendingCaptured에 남아있음 (규칙 위반)');
    print('  - engine.mdc: "턴 종료 시 pendingCaptured의 카드들을 실제 획득 영역으로 이동"');
    print('  - 뻑 상태가 아닌 경우에만 보너스피 획득해야 함');
  }
}

void resetEngine(MatgoEngine engine) {
  engine.deckManager.playerHands[0] = [];
  engine.deckManager.playerHands[1] = [];
  engine.deckManager.fieldCards.clear();
  engine.deckManager.drawPile.clear();
  engine.deckManager.capturedCards[0] = [];
  engine.deckManager.capturedCards[1] = [];
  engine.pendingCaptured.clear();
  engine.playedCard = null;
  engine.drawnCard = null;
  engine.bonusOverlayCards.clear();
  engine.currentPhase = TurnPhase.playingCard;
  engine.currentPlayer = 1;
  engine.ppeokMonth = null;
}

void printState(MatgoEngine engine) {
  print('  현재 플레이어: ${engine.currentPlayer}');
  print('  현재 단계: ${engine.currentPhase.name}');
  print('  손패: ${engine.getHand(1).map((c) => c.name).toList()}');
  print('  필드: ${engine.getField().map((c) => c.name).toList()}');
  print('  카드더미: ${engine.deckManager.drawPile.map((c) => c.name).toList()}');
  print('  획득: ${engine.getCaptured(1).map((c) => c.name).toList()}');
  print('  pendingCaptured: ${engine.pendingCaptured.map((c) => c.name).toList()}');
  print('  bonusOverlayCards: ${engine.bonusOverlayCards.map((c) => c.name).toList()}');
  if (engine.ppeokMonth != null) {
    print('  뻑 월: ${engine.ppeokMonth}');
  }
} 