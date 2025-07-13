import 'package:flutter_test/flutter_test.dart';
import 'package:go_stop_app/utils/matgo_engine.dart';
import 'package:go_stop_app/utils/deck_manager.dart';
import 'package:go_stop_app/models/card_model.dart';

void main() {
  group('보너스피(손패) 처리 테스트', () {
    late MatgoEngine engine;
    late DeckManager deckManager;

    setUp(() {
      deckManager = DeckManager(playerCount: 2);
      engine = MatgoEngine(deckManager);
      // 손패: 보너스피 + 일반카드
      deckManager.playerHands[0] = [
        GoStopCard(id: 1, name: '보너스피', month: 1, type: '피', imageUrl: 'bonus_3pi.png', isBonus: true),
        GoStopCard(id: 2, name: '일반피', month: 2, type: '피', imageUrl: '2_pi1.png'),
      ];
      // 카드더미: 교체용 카드 1장
      deckManager.drawPile.clear();
      deckManager.drawPile.add(
        GoStopCard(id: 3, name: '교체카드', month: 3, type: '피', imageUrl: '3_pi1.png'),
      );
      // 캡처 초기화
      deckManager.capturedCards[0] = [];
      engine.tapLock = true; // 입력락 활성화 상태에서 시작
    });

    test('보너스피 playCard 처리', () {
      final bonusPi = deckManager.playerHands[0]!.firstWhere((c) => c.isBonus);
      engine.playCard(bonusPi);
      // 캡처에 보너스피만 존재
      expect(deckManager.capturedCards[0]!.length, 1);
      expect(deckManager.capturedCards[0]!.first, bonusPi);
      // 손패는 교체로 2장 유지
      expect(deckManager.playerHands[0]!.length, 2);
      // 교체카드가 손패에 포함되어야 함
      expect(deckManager.playerHands[0]!.any((c) => c.name == '교체카드'), true);
      // Phase는 playingCard 유지
      expect(engine.currentPhase, TurnPhase.playingCard);
      // tapLock 해제
      expect(engine.tapLock, false);
    });
  });
} 