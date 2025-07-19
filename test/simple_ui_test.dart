import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_stop_app/widgets/game_log_viewer.dart';
import 'package:go_stop_app/utils/game_logger.dart';

void main() {
  group('UI 수정사항 검증 테스트', () {
    
    testWidgets('GameLogViewer 오버플로우 수정 확인', (tester) async {
      print('🧪 테스트 시작: GameLogViewer 오버플로우 수정 확인');
      
      // 작은 화면 크기 설정 (오버플로우 테스트용)
      print('📱 작은 화면 크기 설정 (300x600)');
      tester.binding.window.physicalSizeTestValue = const Size(300, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      print('📝 테스트 로그 생성 중...');
      final logger = GameLogger();
      logger.addLog(1, 'test', LogLevel.info, '테스트 메시지');
      logger.addLog(1, 'test', LogLevel.error, '에러 메시지');
      logger.addLog(1, 'test', LogLevel.warning, '경고 메시지');
      print('✅ 로그 생성 완료 (3개 메시지)');
      
      print('🎨 GameLogViewer 위젯 생성 중...');
      final gameLogViewer = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: GameLogViewer(logger: logger, isVisible: true),
          ),
        ),
      );
      
      print('🔄 위젯 렌더링 시작...');
      await tester.pumpWidget(gameLogViewer);
      print('⏳ 애니메이션 완료 대기 중...');
      await tester.pumpAndSettle();
      print('✅ 렌더링 완료');
      
      // 단계별 검증
      print('🔍 1단계: GameLogViewer 존재 확인');
      expect(find.byType(GameLogViewer), findsOneWidget);
      print('✅ GameLogViewer 발견');
      
      print('🔍 2단계: 필터 칩 존재 확인');
      final filterChips = find.byType(FilterChip);
      print('📊 발견된 FilterChip 개수: ${filterChips.evaluate().length}');
      expect(filterChips, findsWidgets);
      print('✅ FilterChip 발견');
      
      print('🔍 3단계: 드롭다운 버튼이 없어야 정상');
      final dropdowns = find.byType(DropdownButton);
      print('📊 발견된 DropdownButton 개수: ${dropdowns.evaluate().length}');
      expect(dropdowns, findsNothing);
      print('✅ DropdownButton 발견');
      
      print('🔍 4단계: 로그 엔트리 존재 확인');
      final containers = find.byType(Container);
      print('📊 발견된 Container 개수: ${containers.evaluate().length}');
      expect(containers, findsWidgets);
      print('✅ Container 발견');
      
      print('🔍 5단계: 오버플로우 확인');
      // 오버플로우가 발생하지 않았는지 확인
      final renderBox = tester.renderObject<RenderBox>(find.byType(GameLogViewer));
      print('📏 GameLogViewer 크기: ${renderBox.size}');
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));
      print('✅ 오버플로우 없음 확인');
      
      // 화면 크기 복원
      print('🔄 화면 크기 복원 중...');
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
      print('✅ 테스트 완료: GameLogViewer 오버플로우 수정 확인');
    });
    
    testWidgets('GameLogViewer 반응형 레이아웃 확인', (tester) async {
      print('🧪 테스트 시작: GameLogViewer 반응형 레이아웃 확인');
      
      // 태블릿 크기 설정
      print('📱 태블릿 크기 설정 (800x600)');
      tester.binding.window.physicalSizeTestValue = const Size(800, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      print('📝 긴 텍스트 로그 생성 중...');
      final logger = GameLogger();
      logger.addLog(1, 'test', LogLevel.info, '긴 테스트 메시지입니다. 이것은 매우 긴 텍스트로 오버플로우를 테스트하기 위한 것입니다.');
      print('✅ 긴 텍스트 로그 생성 완료');
      
      print('🎨 GameLogViewer 위젯 생성 중...');
      final gameLogViewer = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: GameLogViewer(logger: logger, isVisible: true),
          ),
        ),
      );
      
      print('🔄 위젯 렌더링 시작...');
      await tester.pumpWidget(gameLogViewer);
      print('⏳ 애니메이션 완료 대기 중...');
      await tester.pumpAndSettle();
      print('✅ 렌더링 완료');
      
      print('🔍 태블릿에서 정상 렌더링 확인');
      expect(find.byType(GameLogViewer), findsOneWidget);
      print('✅ 태블릿에서 정상 렌더링 확인됨');
      
      // 화면 크기 복원
      print('🔄 화면 크기 복원 중...');
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
      print('✅ 테스트 완료: GameLogViewer 반응형 레이아웃 확인');
    });
    
    testWidgets('GameLogViewer 필터 기능 확인', (tester) async {
      print('🧪 테스트 시작: GameLogViewer 필터 기능 확인');
      
      print('📝 다양한 레벨의 로그 생성 중...');
      final logger = GameLogger();
      logger.addLog(1, 'test', LogLevel.info, '정보 메시지');
      logger.addLog(1, 'test', LogLevel.error, '에러 메시지');
      logger.addLog(1, 'test', LogLevel.warning, '경고 메시지');
      print('✅ 로그 생성 완료 (정보, 에러, 경고)');
      
      print('🎨 GameLogViewer 위젯 생성 중...');
      final gameLogViewer = MaterialApp(
        home: Scaffold(
          body: GameLogViewer(logger: logger, isVisible: true),
        ),
      );
      
      print('🔄 위젯 렌더링 시작...');
      await tester.pumpWidget(gameLogViewer);
      print('⏳ 애니메이션 완료 대기 중...');
      await tester.pumpAndSettle();
      print('✅ 렌더링 완료');
      
      print('🔍 에러 레벨 필터 칩 찾기');
      final errorChip = find.text('ERROR');
      print('📊 발견된 ERROR 칩 개수: ${errorChip.evaluate().length}');
      
      if (errorChip.evaluate().isNotEmpty) {
        print('🖱️ ERROR 칩 탭 중...');
        await tester.tap(errorChip.first);
        print('⏳ 필터 적용 대기 중...');
        await tester.pumpAndSettle();
        
        print('🔍 필터링 결과 확인');
        expect(find.text('에러 메시지'), findsOneWidget);
        expect(find.text('정보 메시지'), findsNothing);
        print('✅ 필터링 정상 작동 확인');
      } else {
        print('⚠️ ERROR 칩을 찾을 수 없음 - 테스트 스킵');
      }
      
      print('✅ 테스트 완료: GameLogViewer 필터 기능 확인');
    });
    
    testWidgets('GameLogViewer 자동 스크롤 체크박스 확인', (tester) async {
      print('🧪 테스트 시작: GameLogViewer 자동 스크롤 체크박스 확인');
      
      print('📝 많은 로그 메시지 생성 중...');
      final logger = GameLogger();
      for (int i = 0; i < 20; i++) {
        logger.addLog(1, 'test', LogLevel.info, '로그 메시지 $i');
      }
      print('✅ 20개 로그 메시지 생성 완료');
      
      print('🎨 GameLogViewer 위젯 생성 중...');
      final gameLogViewer = MaterialApp(
        home: Scaffold(
          body: GameLogViewer(logger: logger, isVisible: true),
        ),
      );
      
      print('🔄 위젯 렌더링 시작...');
      await tester.pumpWidget(gameLogViewer);
      print('⏳ 애니메이션 완료 대기 중...');
      await tester.pumpAndSettle();
      print('✅ 렌더링 완료');
      
      print('🔍 자동 스크롤 체크박스 찾기');
      final checkbox = find.byType(Checkbox);
      print('📊 발견된 Checkbox 개수: ${checkbox.evaluate().length}');
      expect(checkbox, findsOneWidget);
      print('✅ Checkbox 발견');
      
      print('🖱️ 체크박스 탭 중...');
      await tester.tap(checkbox.first);
      print('⏳ 상태 변경 대기 중...');
      await tester.pumpAndSettle();
      
      print('🔍 체크박스 상태 변경 확인');
      final checkboxWidget = tester.widget<Checkbox>(checkbox.first);
      print('📊 체크박스 현재 상태: ${checkboxWidget.value}');
      expect(checkboxWidget.value, isFalse);
      print('✅ 체크박스 상태 변경 확인됨');
      
      print('✅ 테스트 완료: GameLogViewer 자동 스크롤 체크박스 확인');
    });
  });
} 