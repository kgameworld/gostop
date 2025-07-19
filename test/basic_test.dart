import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('기본 테스트', () {
    
    testWidgets('간단한 위젯 렌더링 테스트', (tester) async {
      print('🧪 기본 테스트 시작');
      
      print('🎨 간단한 Text 위젯 생성');
      final testWidget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Hello, Test!'),
          ),
        ),
      );
      
      print('🔄 위젯 렌더링 시작');
      await tester.pumpWidget(testWidget);
      print('✅ 렌더링 완료');
      
      print('🔍 Text 위젯 찾기');
      expect(find.text('Hello, Test!'), findsOneWidget);
      print('✅ Text 위젯 발견');
      
      print('✅ 기본 테스트 완료');
    });
    
    testWidgets('버튼 탭 테스트', (tester) async {
      print('🧪 버튼 탭 테스트 시작');
      
      bool buttonPressed = false;
      
      print('🎨 버튼이 있는 위젯 생성');
      final testWidget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
                print('🖱️ 버튼이 탭되었습니다!');
              },
              child: Text('Tap Me'),
            ),
          ),
        ),
      );
      
      print('🔄 위젯 렌더링 시작');
      await tester.pumpWidget(testWidget);
      print('✅ 렌더링 완료');
      
      print('🔍 버튼 찾기');
      expect(find.text('Tap Me'), findsOneWidget);
      print('✅ 버튼 발견');
      
      print('🖱️ 버튼 탭 중...');
      await tester.tap(find.text('Tap Me'));
      print('⏳ 탭 이벤트 처리 대기 중...');
      await tester.pump();
      print('✅ 탭 완료');
      
      print('🔍 버튼 탭 결과 확인');
      expect(buttonPressed, isTrue);
      print('✅ 버튼 탭 확인됨');
      
      print('✅ 버튼 탭 테스트 완료');
    });
    
    testWidgets('화면 크기 테스트', (tester) async {
      print('🧪 화면 크기 테스트 시작');
      
      print('📱 작은 화면 크기 설정 (200x400)');
      tester.binding.window.physicalSizeTestValue = const Size(200, 400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      print('🎨 반응형 위젯 생성');
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              print('📏 현재 화면 크기: ${constraints.maxWidth} x ${constraints.maxHeight}');
              return Center(
                child: Text('화면 크기: ${constraints.maxWidth.toInt()} x ${constraints.maxHeight.toInt()}'),
              );
            },
          ),
        ),
      );
      
      print('🔄 위젯 렌더링 시작');
      await tester.pumpWidget(testWidget);
      print('✅ 렌더링 완료');
      
      print('🔍 화면 크기 확인');
      expect(find.text('화면 크기: 200 x 400'), findsOneWidget);
      print('✅ 화면 크기 정상 확인');
      
      print('🔄 화면 크기 복원 중...');
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
      print('✅ 화면 크기 복원 완료');
      
      print('✅ 화면 크기 테스트 완료');
    });
  });
} 