import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/sound_manager.dart';
import 'dart:math' as math;

/// 천재 전문가급 스플래시 스크린 - 완벽한 아키텍처, 성능, 안정성
class GeniusSplashScreen extends StatefulWidget {
  const GeniusSplashScreen({super.key});

  @override
  State<GeniusSplashScreen> createState() => _GeniusSplashScreenState();
}

class _GeniusSplashScreenState extends State<GeniusSplashScreen>
    with TickerProviderStateMixin {
  
  // 상태 관리 (불변성 보장)
  SplashState _state = SplashState.initial();
  
  // 애니메이션 컨트롤러 (단일 책임)
  late final AnimationController _animationController;
  
  // 성능 최적화
  bool _isDisposed = false;
  bool _isInitialized = false;
  
  // 접근성
  final _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _initializeState();
    _initializeAnimation();
    _startAnimationSequence();
  }
  
  void _initializeState() {
    // 초기 상태는 이미 설정됨 (변수 선언시)
  }
  
  void _initializeAnimation() {
    // 단일 애니메이션 컨트롤러 (성능 최적화)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // 애니메이션 완료 리스너
    _animationController.addStatusListener(_onAnimationStatusChanged);
  }
  
  void _onAnimationStatusChanged(AnimationStatus status) {
    if (_isDisposed) return;
    
    switch (status) {
      case AnimationStatus.completed:
        if (mounted && !_isDisposed) {
          setState(() {
            _state = _state.copyWith(
              animationState: SplashAnimationState.completed,
              canSkip: true,
            );
          });
        }
        _scheduleNavigation();
        break;
      case AnimationStatus.dismissed:
        break;
      case AnimationStatus.forward:
        if (mounted && !_isDisposed) {
          setState(() {
            _state = _state.copyWith(
              animationState: SplashAnimationState.animating,
            );
          });
        }
        break;
      case AnimationStatus.reverse:
        break;
    }
  }
  
  void _startAnimationSequence() {
    if (_isDisposed) return;
    
    // 애니메이션 시작
    _animationController.forward();
    
    // 접근성 업데이트
    _updateAccessibility();
  }
  
  void _updateState(SplashState newState) {
    if (_isDisposed || !mounted) return;
    
    setState(() {
      _state = newState;
    });
    
    // 접근성 업데이트
    _updateAccessibility();
  }
  
  void _updateAccessibility() {
    if (_isDisposed) return;
    
    // 접근성 업데이트는 Semantics 위젯에서 처리
  }
  
  String _getAccessibilityLabel() {
    switch (_state.animationState) {
      case SplashAnimationState.initial:
        return '앱 로딩 중';
      case SplashAnimationState.animating:
        return '로고 애니메이션 재생 중';
      case SplashAnimationState.canSkip:
        return '터치하거나 스페이스바를 눌러 시작하세요';
      case SplashAnimationState.completed:
        return '준비 완료';
    }
  }
  
  String _getAccessibilityHint() {
    if (_state.canSkip) {
      return '터치하거나 스페이스바를 눌러 앱을 시작합니다';
    }
    return '잠시만 기다려주세요';
  }
  
  void _scheduleNavigation() {
    if (_isDisposed) return;
    
    // 1초 후 자동 이동
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isDisposed && mounted) {
        _navigateToNextScreen();
      }
    });
  }
  
  void _navigateToNextScreen() {
    if (_isDisposed) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final route = authProvider.isAuthenticated ? '/home' : '/login';
      
      Navigator.of(context).pushReplacementNamed(route);
    } catch (e) {
      // 오류 발생시 기본 경로로 이동
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  void _onSkip() async {
    if (!_state.canSkip || _isDisposed || _state.isSkipping) return;
    
    // 상태 업데이트 (중복 실행 방지)
    if (mounted && !_isDisposed) {
      setState(() {
        _state = _state.copyWith(isSkipping: true);
      });
    }
    
    // 햅틱 피드백
    await _provideHapticFeedback();
    
    // 사운드 재생 (사용자 상호작용 후)
    await _playInteractionSound();
    
    // 즉시 이동
    _navigateToNextScreen();
  }
  
  Future<void> _provideHapticFeedback() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // 햅틱 피드백 실패시 무시
    }
  }
  
  Future<void> _playInteractionSound() async {
    try {
      // 사용자 상호작용 후 사운드 재생 (브라우저 정책 준수)
      await SoundManager.instance.play(Sfx.buttonClick, volume: 0.3);
    } catch (e) {
      // 사운드 실패시 무시 (사용자 경험에 영향 없음)
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 반응형 크기 업데이트 (한 번만, 무한 루프 방지)
    if (!_isInitialized) {
      _initializeResponsiveSizes();
      _isInitialized = true;
    }
  }
  
  void _initializeResponsiveSizes() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // 반응형 크기 계산
    final sizes = ResponsiveSizes.calculate(screenWidth, screenHeight);
    
    // setState 직접 호출로 변경 (무한 루프 방지)
    if (mounted && !_isDisposed) {
      setState(() {
        _state = _state.copyWith(sizes: sizes);
      });
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: RepaintBoundary( // 성능 최적화: 리페인트 경계
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Color(0xFF0a0a1a),
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
              ],
            ),
          ),
          child: SafeArea(
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKey: _handleKeyEvent,
              child: GestureDetector(
                onTap: _onSkip,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로고 섹션
                      _buildLogoSection(),
                      SizedBox(height: _state.sizes.logoSize * 0.6),
                      
                      // 로딩 인디케이터
                      _buildLoadingIndicator(),
                      SizedBox(height: _state.sizes.logoSize * 0.3),
                      
                      // 스킵 안내
                      if (_state.canSkip) _buildSkipGuide(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent && _state.canSkip) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          _onSkip();
          return KeyEventResult.handled;
        default:
          break;
      }
    }
    return KeyEventResult.ignored;
  }
  
  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _getScaleValue(),
          child: Opacity(
            opacity: _getOpacityValue(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildLogoLetters(),
            ),
          ),
        );
      },
    );
  }
  
  List<Widget> _buildLogoLetters() {
    const letters = 'ilosi';
    return List.generate(letters.length, (index) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final letterProgress = _getLetterProgress(index);
          return Transform.translate(
            offset: Offset(0, 20 * (1 - letterProgress)),
            child: Opacity(
              opacity: letterProgress,
              child: Text(
                letters[index],
                style: _getLogoTextStyle(),
              ),
            ),
          );
        },
      );
    });
  }
  
  double _getScaleValue() {
    final progress = _animationController.value;
    if (progress < 0.3) {
      return 0.8 + (0.2 * (progress / 0.3));
    }
    return 1.0;
  }
  
  double _getOpacityValue() {
    final progress = _animationController.value;
    if (progress < 0.3) {
      return progress / 0.3;
    }
    return 1.0;
  }
  
  double _getLetterProgress(int index) {
    final progress = _animationController.value;
    final start = 0.3 + (index * 0.12);
    final end = start + 0.15;
    
    if (progress < start) return 0.0;
    if (progress > end) return 1.0;
    
    return (progress - start) / (end - start);
  }
  
  TextStyle _getLogoTextStyle() {
    final progress = _animationController.value;
    final glowIntensity = math.max(0.3, progress);
    
    return TextStyle(
      fontSize: _state.sizes.logoSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w300,
      color: const Color(0xFF00FFFF),
      letterSpacing: _state.sizes.letterSpacing,
      shadows: [
        Shadow(
          color: const Color(0xFF00FFFF).withOpacity(0.6 * glowIntensity),
          blurRadius: 20 * glowIntensity,
        ),
        Shadow(
          color: Colors.white.withOpacity(0.3 * glowIntensity),
          blurRadius: 5 * glowIntensity,
        ),
      ],
    );
  }
  
  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final progress = _animationController.value;
        final opacity = math.min(1.0, progress * 2);
        
        return Opacity(
          opacity: opacity,
          child: SizedBox(
            width: _state.sizes.logoSize * 0.4,
            height: _state.sizes.logoSize * 0.4,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF00FFFF).withOpacity(progress),
              ),
              strokeWidth: 3,
              backgroundColor: const Color(0xFF00FFFF).withOpacity(0.2),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSkipGuide() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final progress = _animationController.value;
        final opacity = math.max(0.0, (progress - 0.8) * 5);
        
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _state.sizes.tapTextSize * 1.2,
              vertical: _state.sizes.tapTextSize * 0.6,
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
              button: true,
              onTap: _onSkip,
              child: Text(
                '터치하여 시작',
                style: TextStyle(
                  color: const Color(0xFF00FFFF).withOpacity(0.8),
                  fontSize: _state.sizes.tapTextSize,
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
      },
    );
  }
}

/// 불변 상태 클래스 (타입 안전성 보장)
class SplashState {
  final SplashAnimationState animationState;
  final ResponsiveSizes sizes;
  final bool canSkip;
  final bool isSkipping;
  
  const SplashState({
    required this.animationState,
    required this.sizes,
    required this.canSkip,
    required this.isSkipping,
  });
  
  factory SplashState.initial() {
    return const SplashState(
      animationState: SplashAnimationState.initial,
      sizes: ResponsiveSizes(),
      canSkip: false,
      isSkipping: false,
    );
  }
  
  SplashState copyWith({
    SplashAnimationState? animationState,
    ResponsiveSizes? sizes,
    bool? canSkip,
    bool? isSkipping,
  }) {
    return SplashState(
      animationState: animationState ?? this.animationState,
      sizes: sizes ?? this.sizes,
      canSkip: canSkip ?? this.canSkip,
      isSkipping: isSkipping ?? this.isSkipping,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SplashState &&
        other.animationState == animationState &&
        other.sizes == sizes &&
        other.canSkip == canSkip &&
        other.isSkipping == isSkipping;
  }
  
  @override
  int get hashCode {
    return Object.hash(animationState, sizes, canSkip, isSkipping);
  }
}

/// 반응형 크기 계산 클래스 (불변성 보장)
class ResponsiveSizes {
  final double logoSize;
  final double letterSpacing;
  final double tapTextSize;
  
  const ResponsiveSizes({
    this.logoSize = 80.0,
    this.letterSpacing = 8.0,
    this.tapTextSize = 16.0,
  });
  
  factory ResponsiveSizes.calculate(double screenWidth, double screenHeight) {
    return ResponsiveSizes(
      logoSize: math.min(screenWidth * 0.12, screenHeight * 0.1),
      letterSpacing: math.min(screenWidth * 0.006, 10.0),
      tapTextSize: math.min(screenWidth * 0.015, screenHeight * 0.02),
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResponsiveSizes &&
        other.logoSize == logoSize &&
        other.letterSpacing == letterSpacing &&
        other.tapTextSize == tapTextSize;
  }
  
  @override
  int get hashCode {
    return Object.hash(logoSize, letterSpacing, tapTextSize);
  }
}

/// 애니메이션 상태 enum
enum SplashAnimationState {
  initial,
  animating,
  canSkip,
  completed,
}

/// 스플래시 스크린 설정 (설정 가능)
class SplashScreenConfig {
  final Duration animationDuration;
  final Duration skipDelay;
  final Duration autoNavigateDelay;
  final bool enableSound;
  final bool enableHapticFeedback;
  final bool enableAccessibility;
  
  const SplashScreenConfig({
    this.animationDuration = const Duration(milliseconds: 2500),
    this.skipDelay = const Duration(seconds: 2),
    this.autoNavigateDelay = const Duration(seconds: 1),
    this.enableSound = true,
    this.enableHapticFeedback = true,
    this.enableAccessibility = true,
  });
}

/// 스플래시 스크린 이벤트 (타입 안전성)
abstract class SplashScreenEvent {
  const SplashScreenEvent();
}

class SplashScreenStarted extends SplashScreenEvent {
  const SplashScreenStarted();
}

class SplashScreenSkipped extends SplashScreenEvent {
  const SplashScreenSkipped();
}

class SplashScreenCompleted extends SplashScreenEvent {
  const SplashScreenCompleted();
}

/// 스플래시 스크린 에러 (타입 안전성)
abstract class SplashScreenError {
  const SplashScreenError();
}

class SplashScreenNavigationError extends SplashScreenError {
  final String message;
  const SplashScreenNavigationError(this.message);
}

class SplashScreenAnimationError extends SplashScreenError {
  final String message;
  const SplashScreenAnimationError(this.message);
} 