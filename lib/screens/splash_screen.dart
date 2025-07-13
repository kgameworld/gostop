import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import '../lobby_screen.dart';
import '../providers/auth_provider.dart';
import 'auth/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 애니메이션 컨트롤러/애니메이션 (1단계)
  late AnimationController _logoController;
  late Animation<double> _logoOpacityAnim; // 투명도 효과용 애니메이션
  // 나머지 단계 애니메이션 컨트롤러/변수
  late AnimationController _titleController;
  late AnimationController _themeController;
  late AnimationController _tapController;
  late Animation<double> _titleScale;
  late Animation<double> _titleGlow;
  late Animation<double> _cardFlip;
  late Animation<double> _cardRotation;
  late Animation<double> _cardScale;
  late Animation<double> _secondCardSlide;
  late Animation<double> _petalOpacity;
  late Animation<double> _tapOpacity;
  
  // 각 단계별 표시 여부
  bool showStage1 = true;
  // 2, 4단계 제거

  // 카드 뒤집기 상태(2~3단계에서 공유)
  double cardFlipValue = 0.0;
  // 10월 사슴 카드 위치(3단계)
  double deerCardOffset = 400.0;
  // 타이틀 페이드인(2단계)
  double titleOpacity = 0.0;
  // 광채 효과(2단계)
  double titleGlow = 0.0;

  // 현재 단계
  int _currentStage = 0;
  bool _canTap = false;
  
  @override
  void initState() {
    super.initState();
    _startStage1();
  }

  // 1단계: 전체 로고 부드럽게 페이드인
  void _startStage1() async {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 1.5초
      vsync: this,
    );
    _logoOpacityAnim = CurvedAnimation(parent: _logoController, curve: Curves.easeInOut);
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    // 1단계 끝나면 인증 상태에 따라 적절한 화면으로 이동
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _themeController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: showStage1 ? _navigateToNextScreen : null,
        child: Stack(
          children: [
            // 1단계: ILOSI 로고
            if (showStage1)
              AnimatedBuilder(
                animation: _logoOpacityAnim,
                builder: (context, child) {
                  return Center(
                    child: Opacity(
                      opacity: _logoOpacityAnim.value,
                      child: Text(
                        'I L O S I',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w300, // Light weight
                          fontSize: 54,
                          color: Colors.black,
                          letterSpacing: 6.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToNextScreen() {
    // 인증 상태 확인
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    Widget nextScreen;
    if (authProvider.isAuthenticated) {
      // 인증된 사용자: 로비 화면으로 이동
      nextScreen = const LobbyScreen();
    } else {
      // 인증되지 않은 사용자: 로그인 화면으로 이동
      nextScreen = const LoginPage();
    }
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
} 