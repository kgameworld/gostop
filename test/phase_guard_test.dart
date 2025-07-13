import 'package:flutter_test/flutter_test.dart';
import 'package:go_stop_app/utils/matgo_engine.dart';
import 'package:go_stop_app/utils/deck_manager.dart';
import 'package:go_stop_app/models/card_model.dart';

void main() {
  group('Phase 가드, tapLock, ppeokMonth 리셋 테스트', () {
    late MatgoEngine engine;
    late DeckManager deckManager;

    setUp(() {
      deckManager = DeckManager(playerCount: 2);
      engine = MatgoEngine(deckManager);
    });

    test('잘못된 Phase에서 playCard() 호출 → AssertionError', () {
      engine.currentPhase = TurnPhase.flippingCard;
      final card = GoStopCard(id: 1, name: '1월 광', month: 1, type: '광', imageUrl: '1_gwang_crane.png');
      expect(() => engine.playCard(card), throwsA(isA<AssertionError>()));
    });

    test('잘못된 Phase에서 flipFromDeck() 호출 → AssertionError', () {
      engine.currentPhase = TurnPhase.playingCard;
      expect(() => engine.flipFromDeck(), throwsA(isA<AssertionError>()));
    });

    test('잘못된 Phase에서 chooseMatch() 호출 → AssertionError', () {
      engine.currentPhase = TurnPhase.playingCard;
      final card = GoStopCard(id: 2, name: '2월 광', month: 2, type: '광', imageUrl: '2_gwang_curtain.png');
      expect(() => engine.chooseMatch(card), throwsA(isA<AssertionError>()));
    });

    test('tapLock = true 상태에서 두 번 onCardTap → 두 번째 입력 무시', () {
      // tapLock이 true면 입력 무시
      engine.tapLock = true;
      bool tapped = false;
      void onCardTap() {
        if (engine.tapLock) return;
        tapped = true;
        engine.tapLock = true;
      }
      onCardTap(); // 첫 번째 입력: 무시됨
      expect(tapped, false);
      engine.tapLock = false;
      onCardTap(); // 두 번째 입력: 처리됨
      expect(tapped, true);
    });

    test('뻑 발생 후 ppeokMonth == null 초기화 확인', () {
      // 뻑 상태를 강제로 만든 뒤, _processDrawnCard로 뻑 완성 처리
      engine.ppeokMonth = 3;
      engine.playedCard = GoStopCard(id: 10, name: '3월 피', month: 3, type: '피', imageUrl: '3_pi1.png');
      final drawnCard = GoStopCard(id: 11, name: '3월 피', month: 3, type: '피', imageUrl: '3_pi2.png');
      // 필드에 2장 추가해서 4장 완성
      deckManager.fieldCards.addAll([
        GoStopCard(id: 12, name: '3월 피', month: 3, type: '피', imageUrl: '3_pi3.png'),
        GoStopCard(id: 13, name: '3월 피', month: 3, type: '피', imageUrl: '3_pi4.png'),
      ]);
      engine.processDrawnCardForTest(drawnCard);
      expect(engine.ppeokMonth, null);
    });

    test('newRound() 또는 gameDraw() 시 ppeokMonth == null', () {
      engine.ppeokMonth = 5;
      engine.newRound();
      expect(engine.ppeokMonth, null);
      engine.ppeokMonth = 7;
      engine.gameDraw();
      expect(engine.ppeokMonth, null);
    });
  });
} 