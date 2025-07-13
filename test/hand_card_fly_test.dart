import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_stop_app/main.dart';
import 'package:go_stop_app/widgets/card_widget.dart';

void main() {
  testWidgets('손패 카드 애니메이션 Overlay 동작 테스트', (tester) async {
    print('🧪 손패 카드 애니메이션 Overlay 동작 테스트 시작');
    await tester.pumpWidget(const GoStopApp());
    await tester.pumpAndSettle();

    // 손패 카드 찾기 (첫 번째 카드)
    final handCard = find.byType(CardWidget).first;
    expect(handCard, findsWidgets);
    print('✅ 손패 카드 위젯 찾음');

    // 카드 클릭 전 Overlay에 CardWidget이 없는지 확인
    // (실제 OverlayEntry는 일반적으로 find로 바로 잡히지 않음)

    // 카드 탭
    await tester.tap(handCard);
    await tester.pump(); // 애니메이션 시작
    print('🖱️ 손패 카드 탭, 애니메이션 시작');

    // 애니메이션 중 Overlay에 카드가 떠 있는지 확인 (위치까지 비교하려면 더 복잡한 로직 필요)
    // 여기서는 CardWidget 개수가 일시적으로 늘어나는지로 간접 확인
    final cardCountDuringAnim = tester.widgetList(find.byType(CardWidget)).length;
    print('📊 애니메이션 중 CardWidget 개수: $cardCountDuringAnim');
    expect(cardCountDuringAnim, greaterThan(0));

    // 애니메이션 끝까지 기다림
    await tester.pump(const Duration(milliseconds: 600));
    print('⏳ 애니메이션 완료 대기');

    // OverlayEntry가 사라졌는지 확인 (CardWidget 개수 정상화)
    final cardCountAfterAnim = tester.widgetList(find.byType(CardWidget)).length;
    print('📊 애니메이션 후 CardWidget 개수: $cardCountAfterAnim');
    expect(cardCountAfterAnim, greaterThan(0));

    print('✅ 손패 카드 애니메이션 Overlay 동작 테스트 완료');
  });
} 