import 'package:flutter/material.dart';
import '../widgets/ilosi_splash_painter.dart';
import '../utils/sound_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late Animation<double> _mainAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 메인 애니메이션 컨트롤러 (글자 등장)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // 글로우 애니메이션 컨트롤러 (빛나는 효과)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // 메인 애니메이션 (글자별 순차 등장)
    _mainAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));
    
    // 글로우 애니메이션 (빛나는 효과)
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _startSplashAnimation();
  }
  
  void _startSplashAnimation() async {
    try {
      // 배경음악 재생 (오류 방지)
      try {
        SoundManager.instance.playBgm('lobby', volume: 0.4);
      } catch (e) {
        // 사운드 오류는 무시하고 계속 진행
        print('Sound error: $e');
      }
      
      // 메인 애니메이션 시작
      await _mainController.forward();
      
      // 글로우 애니메이션 시작
      await _glowController.forward();
      
      // 잠시 대기
      await Future.delayed(const Duration(seconds: 1));
      
      // 로비 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/lobby');
      }
    } catch (e) {
      // 애니메이션 오류시 바로 로비로 이동
      print('Animation error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/lobby');
      }
    }
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e), // 이미지와 동일한 배경색
      body: GestureDetector(
        onTap: () {
          // 터치하면 바로 로비로 이동
          Navigator.of(context).pushReplacementNamed('/lobby');
        },
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_mainController, _glowController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: IlosiSplashPainter(
                    animation: _mainAnimation,
                    glowIntensity: _glowAnimation.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            // 터치 안내 텍스트
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _mainAnimation.value,
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Text(
                    '터치하여 시작',
                    style: TextStyle(
                      color: const Color(0xFF00FFFF).withOpacity(0.6),
                      fontSize: 18,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 