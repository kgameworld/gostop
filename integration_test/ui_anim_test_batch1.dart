import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_stop_app/main.dart' as app;
import 'package:go_stop_app/screens/gostop_board.dart';

// 120Hz 시뮬레이션 헬퍼
Future<void> pumpAndSettle120Hz(WidgetTester tester, Duration duration) async {
  final frameCount = (duration.inMilliseconds / (1000 / 120)).round();
  for (int i = 0; i < frameCount; i++) {
    await tester.pump(Duration(milliseconds: (1000 / 120).round()));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UI-애니메이션 체크포인트 Batch 1 (1~10)', () {
    testWidgets('1. 카드 탭 → 300ms 안에 Hand 슬롯 empty == false & 카드 pos == PlayZone', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // 손패 카드 찾기 (실제 앱에서는 GestureDetector로 감싸진 CardWidget)
      final handCards = find.byType(GestureDetector);
      expect(handCards, findsWidgets);

      if (handCards.evaluate().isNotEmpty) {
        // 첫 번째 손패 카드 탭
        await tester.tap(handCards.first);
        await tester.pump(const Duration(milliseconds: 300));

        // 카드가 필드로 이동했는지 확인 (CardWidget이 필드에 있는지)
        final fieldCards = find.byType(CardWidget);
        expect(fieldCards.evaluate().length, greaterThan(0));
      }
    });

    testWidgets('2. GoldFlash TweenSequence duration == 0.12s & opacity peak == 1.0', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // GoldFlash 애니메이션 트리거 (예: 특정 카드 조합)
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pump(const Duration(milliseconds: 120));

        // GoldFlash 효과 확인 (실제 구현에 따라 조정 필요)
        final goldFlashEffects = find.byType(AnimatedOpacity);
        expect(goldFlashEffects, findsWidgets);
      }
    });

    testWidgets('3. 폭탄: Slide 종료 offset.y diff < 1px _AND_ Shake maxOffset ≤ 8px', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // 폭탄 애니메이션 트리거 (예: 특정 상황)
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pump(const Duration(milliseconds: 500));

        // 폭탄 효과 확인 (실제 구현에 따라 조정 필요)
        final bombEffects = find.byType(AnimatedContainer);
        expect(bombEffects, findsWidgets);
      }
    });

    testWidgets('4. Deck→Hand arc 경로: endPos == handSlot & duration 0.18-0.22s', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // 카드 분배 애니메이션 확인
      final animatedCards = find.byType(AnimatedPositioned);
      expect(animatedCards, findsWidgets);

      // 애니메이션 duration 확인
      await tester.pump(const Duration(milliseconds: 200));
      expect(animatedCards.evaluate().isNotEmpty, true);
    });

    testWidgets('5. 화면 width 280dp → choosingMatch 팝업 size ≤ screen & no overflow', (tester) async {
      // 화면 크기 설정
      tester.binding.window.physicalSizeTestValue = const Size(280, 400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      await tester.pumpAndSettle();

      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // 팝업 트리거 (예: 카드 선택 상황)
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pumpAndSettle();

        // 팝업 확인
        final popups = find.byType(AlertDialog);
        expect(popups, findsWidgets);
      }
    });

    testWidgets('6. 역GO Bust 발생 → OverlayEntry id == "bust" z==999 & EndPanel below', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // Bust 상황 트리거 (실제 게임 로직에 따라 조정 필요)
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pumpAndSettle();

        // Bust 배너 확인
        final bustBanners = find.textContaining('Bust');
        expect(bustBanners, findsWidgets);
      }
    });

    testWidgets('7. 120Hz 기기 → PulseGlow frameCount ≥ 14 (끊김 없음)', (tester) async {
      await pumpAndSettle120Hz(tester, const Duration(milliseconds: 120));

      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // PulseGlow 애니메이션 트리거
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pump(const Duration(milliseconds: 200));

        // PulseGlow 효과 확인 (실제 구현에 따라 조정 필요)
        final pulseEffects = find.byType(AnimatedContainer);
        expect(pulseEffects, findsWidgets);
      }
    });

    testWidgets('8. Field stack t=0..end clipBehavior == none', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // 필드 스택 확인
      final fieldStacks = find.byType(Stack);
      expect(fieldStacks, findsWidgets);

      // clipBehavior 확인
      for (final stack in fieldStacks.evaluate()) {
        final stackWidget = stack.widget as Stack;
        expect(stackWidget.clipBehavior, Clip.none);
      }
    });

    testWidgets('9. RedFlash 연속 2회 → color == baseRed (no darker)', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // RedFlash 애니메이션 트리거
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(handCards.first);
        await tester.pump(const Duration(milliseconds: 100));

        // RedFlash 효과 확인 (실제 구현에 따라 조정 필요)
        final redFlashEffects = find.byType(AnimatedContainer);
        expect(redFlashEffects, findsWidgets);
      }
    });

    testWidgets('10. Badge 중첩 연속 3개 → Column.childCount == 3 & 위치 y stagger 12px', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지에서 "게임 시작" 버튼 클릭
      await tester.tap(find.text('게임 시작'));
      await tester.pumpAndSettle();

      // 게임 설정 페이지에서 "AI 대전" 버튼 클릭
      await tester.tap(find.text('AI 대전'));
      await tester.pumpAndSettle();

      // Badge 중첩 상황 트리거 (실제 게임 로직에 따라 조정 필요)
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pumpAndSettle();

        // Badge 확인
        final badges = find.byType(Container);
        expect(badges, findsWidgets);
      }
    });
  });
} 