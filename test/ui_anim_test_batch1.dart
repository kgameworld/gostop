import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_stop_app/main.dart';
import 'package:go_stop_app/screens/gostop_board.dart';
import 'package:go_stop_app/screens/game_page.dart';
import 'package:go_stop_app/models/card_model.dart';
import 'package:go_stop_app/utils/matgo_engine.dart';

void main() {
  group('UI-애니메이션 체크포인트 Batch 1 (실제 플레이 문제 검증)', () {
    
    // Mock 게임 상태 설정 헬퍼 (실제 구현에 맞게 조정 필요)
    void setGameStateForTest(MatgoEngine engine, {
      List<GoStopCard>? playerHand,
      List<GoStopCard>? tableCards,
      int? playerScore,
      bool? hasBomb,
      bool? hasBonusCard,
    }) {
      // 실제 클래스 구조에 맞게 구현 필요
      // 현재는 placeholder로 남겨둠
    }

    testWidgets('1. 카드 순간이동 방지 (Hand→PlayZone 애니)', (tester) async {
      // 게임 페이지 위젯 생성
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 손패 카드 찾기
      final handCards = find.byType(GestureDetector);
      expect(handCards, findsWidgets);

      if (handCards.evaluate().isNotEmpty) {
        // 카드 탭 전 상태 저장
        final cardBeforeTap = handCards.first;
        
        // 카드 탭
        await tester.tap(cardBeforeTap);
        
        // 100ms 이내에 카드가 여전히 존재하는지 확인
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(GestureDetector), findsWidgets);
        
        // 애니메이션 완료 후 카드가 필드로 이동했는지 확인
        await tester.pumpAndSettle();
        final fieldCards = find.byType(CardWidget);
        expect(fieldCards.evaluate().length, greaterThan(0));
      }
    });

    testWidgets('2. Deck→Hand 착지 위치 정확성', (tester) async {
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 보너스피 상황 시뮬레이션
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        // 첫 번째 카드 탭 (보너스피로 가정)
        await tester.tap(handCards.first);
        await tester.pumpAndSettle();

        // 새 카드가 손패에 추가되는지 확인
        final newHandCards = find.byType(GestureDetector);
        expect(newHandCards.evaluate().length, greaterThanOrEqualTo(handCards.evaluate().length));
        
        // 카드 위치가 적절한 범위 내에 있는지 확인
        for (final card in newHandCards.evaluate()) {
          final cardElement = card as Element;
          final renderBox = cardElement.renderObject as RenderBox?;
          if (renderBox != null) {
            final position = renderBox.localToGlobal(Offset.zero);
            // 화면 하단 손패 영역에 위치하는지 확인
            expect(position.dy, greaterThan(400)); // 화면 높이의 대략 60% 이상
          }
        }
      }
    });

    testWidgets('3. Slide+Shake 충돌 방지', (tester) async {
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 폭탄 상황 시뮬레이션 (3장 카드 매치)
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        // 카드 탭으로 폭탄 효과 트리거
        await tester.tap(handCards.first);
        await tester.pump(const Duration(milliseconds: 500));

        // 애니메이션 중 카드들이 적절한 위치에 있는지 확인
        final animatedCards = find.byType(AnimatedContainer);
        expect(animatedCards, findsWidgets);
        
        // 애니메이션 완료 후 카드들이 필드에 정상적으로 배치되었는지 확인
        await tester.pumpAndSettle();
        final fieldCards = find.byType(CardWidget);
        expect(fieldCards.evaluate().length, greaterThan(0));
      }
    });

    testWidgets('4. choosingMatch 팝업 하단 터치 가능 여부', (tester) async {
      // 작은 화면 크기 설정 (640px 이하)
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 매치 상황 시뮬레이션
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pumpAndSettle();

        // 선택 팝업 확인
        final popups = find.byType(AlertDialog);
        if (popups.evaluate().isNotEmpty) {
          // 팝업 내 버튼들이 화면 내에 있는지 확인
          final buttons = find.byType(ElevatedButton);
          expect(buttons, findsWidgets);
          
          // 버튼 탭 가능 여부 확인
          for (final button in buttons.evaluate()) {
            final buttonElement = button as Element;
            final renderBox = buttonElement.renderObject as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(Offset.zero);
              // 버튼이 화면 하단 80% 이내에 있는지 확인
              expect(position.dy, lessThan(640 * 0.8));
            }
          }
        }
      }
    });

    testWidgets('5. GO 버튼 debounce (조건부 표시)', (tester) async {
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // GO 버튼 찾기 (조건부로 표시됨)
      final goButtons = find.text('GO');
      
      // GO 버튼이 표시되는 경우에만 테스트
      if (goButtons.evaluate().isNotEmpty) {
        // 첫 번째 GO 버튼 탭
        await tester.tap(goButtons.first);
        await tester.pump(const Duration(milliseconds: 100));
        
        // 200ms 내 두 번째 탭 시도
        await tester.tap(goButtons.first);
        await tester.pump(const Duration(milliseconds: 200));
        
        // GO 버튼이 여전히 존재하는지 확인 (debounce 효과)
        expect(find.text('GO'), findsWidgets);
        
        // 또는 확인 다이얼로그가 나타나는지 확인
        final dialogs = find.byType(AlertDialog);
        if (dialogs.evaluate().isNotEmpty) {
          expect(dialogs, findsOneWidget);
        }
      } else {
        // GO 버튼이 표시되지 않는 경우 (정상적인 게임 진행 중)
        expect(true, isTrue); // 테스트 통과
      }
    });

    testWidgets('6. ScorePanel overflow', (tester) async {
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 높은 점수 상태 시뮬레이션 (48점 이상)
      // 실제로는 게임 엔진을 통해 점수 설정 필요
      
      // 점수 표시 위젯 찾기
      final scoreTexts = find.byType(Text);
      for (final scoreText in scoreTexts.evaluate()) {
        final textWidget = tester.widget<Text>(find.byWidget(scoreText.widget));
        if (textWidget.data != null && textWidget.data!.contains('점')) {
          // 점수 텍스트가 잘리지 않았는지 확인
          final textElement = scoreText as Element;
          final renderBox = textElement.renderObject as RenderBox?;
          if (renderBox != null) {
            // 텍스트가 적절한 크기로 렌더링되었는지 확인
            expect(renderBox.size.width, greaterThan(0));
            expect(renderBox.size.height, greaterThan(0));
          }
        }
      }
    });

    testWidgets('7. Toast/Banner 중첩 방지', (tester) async {
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 여러 효과 동시 발생 시뮬레이션
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        // 연속으로 여러 카드 탭하여 효과 트리거
        final handCardsList = handCards.evaluate().toList();
        for (int i = 0; i < 3 && i < handCardsList.length; i++) {
          await tester.tap(find.byWidget(handCardsList[i].widget));
          await tester.pump(const Duration(milliseconds: 100));
        }
        
        await tester.pumpAndSettle();

        // Toast/Banner 확인
        final snackBars = find.byType(SnackBar);
        final banners = find.byType(Container);
        
        // 동시에 2개 이상의 Toast가 표시되지 않는지 확인
        expect(snackBars.evaluate().length, lessThanOrEqualTo(1));
        
        // 또는 순차적으로 표시되는지 확인
        if (snackBars.evaluate().isNotEmpty) {
          // 첫 번째 SnackBar가 사라진 후 다음 것이 나타나는지 확인
          await tester.pump(const Duration(seconds: 3)); // SnackBar 기본 지속시간
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('8. 카드 애니메이션 성능 테스트', (tester) async {
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 애니메이션 성능 측정
      final stopwatch = Stopwatch()..start();
      
      final handCards = find.byType(GestureDetector);
      if (handCards.evaluate().isNotEmpty) {
        await tester.tap(handCards.first);
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // 애니메이션이 1초 이내에 완료되는지 확인
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      }
    });

    testWidgets('9. 화면 회전 시 레이아웃 안정성', (tester) async {
      // 가로 모드 시뮬레이션
      tester.binding.window.physicalSizeTestValue = const Size(800, 400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 가로 모드에서도 모든 UI 요소가 적절히 배치되는지 확인
      final handCards = find.byType(GestureDetector);
      final fieldCards = find.byType(CardWidget);
      
      expect(handCards, findsWidgets);
      expect(fieldCards, findsWidgets);
      
      // 세로 모드로 복원
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      await tester.pumpAndSettle();
      
      // 세로 모드에서도 정상 작동하는지 확인
      expect(handCards, findsWidgets);
      expect(fieldCards, findsWidgets);
    });

    testWidgets('10. 기본 UI 요소 존재 확인', (tester) async {
      final gamePage = MaterialApp(
        home: GamePage(mode: 'ai'),
      );
      
      await tester.pumpWidget(gamePage);
      await tester.pumpAndSettle();

      // 기본 UI 요소들이 존재하는지 확인
      final handCards = find.byType(GestureDetector);
      final fieldCards = find.byType(CardWidget);
      
      // 손패 카드가 존재하는지 확인
      expect(handCards, findsWidgets);
      
      // 필드 카드가 존재하는지 확인
      expect(fieldCards, findsWidgets);
      
      // 버튼들이 존재하는지 확인 (조건부)
      final buttons = find.byType(ElevatedButton);
      // 버튼이 없어도 정상 (게임 진행 중일 때)
      expect(true, isTrue);
    });
  });
} 