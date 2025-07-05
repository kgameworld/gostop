import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/game_setup_page.dart';

void main() {
  // GlobalKey 중복 오류 로그 숨기기
  FlutterError.onError = (FlutterErrorDetails details) {
    // GlobalKey 중복 오류는 무시
    if (details.exception.toString().contains('Multiple widgets used the same GlobalKey')) {
      return;
    }
    // 다른 오류는 정상적으로 처리
    FlutterError.presentError(details);
  };
  
  // 디버그 모드에서만 특정 로그 숨기기
  if (kDebugMode) {
    // GlobalKey 관련 로그 숨기기
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.contains('Multiple widgets used the same GlobalKey')) {
        return;
      }
      // 다른 로그는 정상 출력
      print(message);
    };
    

  }
  
  runApp(const GoStopApp());
}

class GoStopApp extends StatelessWidget {
  const GoStopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '고스톱 MVP',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const GameSetupPage(),
    );
  }
}

