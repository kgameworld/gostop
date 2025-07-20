import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/sound_manager.dart';
import 'dart:math' as math;

/// 전문가급 스플래시 스크린 - 고성능, 모듈화, 접근성
class ProfessionalSplashScreen extends StatefulWidget {
  const ProfessionalSplashScreen({super.key});

  @override
  State<ProfessionalSplashScreen> createState() => _ProfessionalSplashScreenState();
}

class _ProfessionalSplashScreenState extends State<ProfessionalSplashScreen>
    with TickerProviderStateMixin {
  // 상태 관리
  bool _isInitialized = false;
  bool _isAnimating = false;
  bool _canSkip = false;
  
  // 반응형 크기 (초기값으로 시작, 나중에 업데이트)
  late ResponsiveSizes _sizes;
  
  // 통합 애니메이션 컨트롤러 (성능 최적화)
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  // 글자별 애니메이션
  late List<Animation<double>> _letterAnimations;
  
  // 성능 최적화
  bool _isDisposed = false;
  final _animationQueue = <VoidCallback>[];
  
  // 접근성
  final _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _initializeSizes();
    _initializeAnimations();
    _startAnimationSequence();
  }
  
  void _initializeSizes() {
    // 초기 크기 설정 (나중에 MediaQuery로 업데이트)
    _sizes = ResponsiveSizes(
      logoSize: 80.0,
      letterSpacing: 8.0,
      tapTextSize: 16.0,
    );
  }
  
  void _initializeAnimations() {
    // 통합 메인 컨트롤러 (성능 최적화)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // 메인 애니메이션들
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.5, curve: Curves.elasticOut),
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
    
    // 글자별 애니메이션 (성능 최적화)
    _letterAnimations = List.generate(5, (index) {
      final start = 0.3 + (index * 0.1);
      final end = start + 0.15;
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _mainController,
        curve: Interval(start, end, curve: Curves.elasticOut),
      ));
    });
  }
  
  void _startAnimationSequence() async {
    if (_isDisposed) return;
    
    // 애니메이션 시작
    _mainController.forward();
    
    // 2초 후 스킵 가능
    await Future.delayed(const Duration(seconds: 2));
    if (_isDisposed) return;
    
    setState(() {
      _canSkip = true;
    });
    
    // 3초 후 자동 이동
    await Future.delayed(const Duration(seconds: 1));
    if (_isDisposed) return;
    
    _navigateToNextScreen();
  }
  
  void _navigateToNextScreen() {
    if (_isDisposed) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final route = authProvider.isAuthenticated ? '/home' : '/login';
    
    Navigator.of(context).pushReplacementNamed(route);
  }
  
  void _onSkip() async {
    if (!_canSkip || _isDisposed) return;
    
    // 터치 피드백
    HapticFeedback.lightImpact();
    
    // 사운드 재생 (비동기, 실패해도 계속 진행)
    _playTapSound();
    
    // 즉시 이동
    _navigateToNextScreen();
  }
  
  Future<void> _playTapSound() async {
    try {
      await SoundManager.instance.play(Sfx.buttonClick, volume: 0.3);
    } catch (e) {
      // 사운드 실패시 무시 (사용자 경험에 영향 없음)
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 반응형 크기 업데이트 (한 번만)
    if (!_isInitialized) {
      final mediaQuery = MediaQuery.of(context);
      final screenWidth = mediaQuery.size.width;
      final screenHeight = mediaQuery.size.height;
      
      _sizes = ResponsiveSizes(
        logoSize: math.min(screenWidth * 0.12, screenHeight * 0.1),
        letterSpacing: math.min(screenWidth * 0.006, 10.0),
        tapTextSize: math.min(screenWidth * 0.015, screenHeight * 0.02),
      );
      
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _mainController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  const Color(0xFF0a0a1a),
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                ],
              ),
            ),
            child: SafeArea(
              child: GestureDetector(
                onTap: _onSkip,
                child: Focus(
                  focusNode: _focusNode,
                  autofocus: true,
                  onKey: (node, event) {
                    if (event is RawKeyDownEvent && 
                        (event.logicalKey == LogicalKeyboardKey.space || 
                         event.logicalKey == LogicalKeyboardKey.enter)) {
                      _onSkip();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 로고 섹션
                        _buildLogoSection(),
                        SizedBox(height: _sizes.logoSize * 0.6),
                        
                        // 로딩 인디케이터
                        _buildLoadingIndicator(),
                        SizedBox(height: _sizes.logoSize * 0.3),
                        
                        // 스킵 안내
                        if (_canSkip) _buildSkipGuide(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLogoSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _letterAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _letterAnimations[index].value)),
                  child: Opacity(
                    opacity: _letterAnimations[index].value,
                    child: Text(
                      'ilosi'[index],
                      style: TextStyle(
                        fontSize: _sizes.logoSize,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF00FFFF),
                        letterSpacing: _sizes.letterSpacing,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF00FFFF).withOpacity(0.6 * _glowAnimation.value),
                            blurRadius: 20 * _glowAnimation.value,
                          ),
                          Shadow(
                            color: Colors.white.withOpacity(0.3 * _glowAnimation.value),
                            blurRadius: 5 * _glowAnimation.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: _sizes.logoSize * 0.4,
        height: _sizes.logoSize * 0.4,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            const Color(0xFF00FFFF).withOpacity(_glowAnimation.value),
          ),
          strokeWidth: 3,
          backgroundColor: const Color(0xFF00FFFF).withOpacity(0.2),
        ),
      ),
    );
  }
  
  Widget _buildSkipGuide() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _sizes.tapTextSize * 1.2,
          vertical: _sizes.tapTextSize * 0.6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00FFFF).withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FFFF).withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Semantics(
          label: '터치하거나 스페이스바를 눌러 시작하세요',
          child: Text(
            '터치하여 시작',
            style: TextStyle(
              color: const Color(0xFF00FFFF).withOpacity(0.8),
              fontSize: _sizes.tapTextSize,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w300,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: const Color(0xFF00FFFF).withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 반응형 크기 데이터 클래스
class ResponsiveSizes {
  final double logoSize;
  final double letterSpacing;
  final double tapTextSize;
  
  const ResponsiveSizes({
    required this.logoSize,
    required this.letterSpacing,
    required this.tapTextSize,
  });
}

/// 스플래시 스크린 설정 (설정 가능)
class SplashScreenConfig {
  final Duration animationDuration;
  final Duration skipDelay;
  final Duration autoNavigateDelay;
  final bool enableSound;
  final bool enableHapticFeedback;
  
  const SplashScreenConfig({
    this.animationDuration = const Duration(milliseconds: 3000),
    this.skipDelay = const Duration(seconds: 2),
    this.autoNavigateDelay = const Duration(seconds: 3),
    this.enableSound = true,
    this.enableHapticFeedback = true,
  });
}

/// 스플래시 스크린 애니메이션 상태
enum SplashAnimationState {
  initial,
  animating,
  canSkip,
  completed,
}

/// 스플래시 스크린 이벤트
abstract class SplashScreenEvent {}

class SplashScreenStarted extends SplashScreenEvent {}
class SplashScreenSkipped extends SplashScreenEvent {}
class SplashScreenCompleted extends SplashScreenEvent {} 