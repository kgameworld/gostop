import 'package:go_stop_app/utils/deck_manager.dart';
import 'package:go_stop_app/utils/matgo_engine.dart';
import 'package:go_stop_app/models/card_model.dart';

void main() {
  final deckManager = DeckManager(playerCount: 2);
  final engine = MatgoEngine(deckManager);

  // 초기 상태 클린업
  deckManager.playerHands[0] = [];
  deckManager.playerHands[1] = [];
  deckManager.fieldCards.clear();
  deckManager.drawPile.clear();

  // 테스트용 카드 생성
  final handCard = GoStopCard(id: 1, month: 3, type: '피', name: '손패 3월피', imageUrl: '3_pi1.png');
  final fieldCard = GoStopCard(id: 2, month: 3, type: '피', name: '필드 3월피', imageUrl: '3_pi2.png');
  final bonusCard = GoStopCard(id: 3, month: 0, type: '피', name: '보너스피', imageUrl: 'bonus_3pi.png', isBonus: true);
  final flipCard = GoStopCard(id: 4, month: 3, type: '피', name: '뒤집힌 3월피', imageUrl: '3_pi3.png');

  // 상태 세팅: 손패/필드/더미
  deckManager.playerHands[0]!.add(handCard);
  deckManager.fieldCards.add(fieldCard);
  deckManager.drawPile.addAll([bonusCard, flipCard]);

  // 엔진 턴 진행
  engine.playCard(handCard); // 손패 카드 내기 (3월-1장 매치)
  engine.flipFromDeck();     // 보너스 → 추가 드로우(3월) → 캡처

  // 결과 출력
  final captured = deckManager.capturedCards[0] ?? [];
  print('획득 카드 (${captured.length}장):');
  for (var c in captured) {
    print(' - ${c.name} (id:${c.id})');
  }
} 