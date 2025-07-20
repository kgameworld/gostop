import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/sound_manager.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Apple 수준의 엘레강트 스플래시 스크린 - 미니멀리즘과 정교함
class AppleGradeSplashScreen extends StatefulWidget {
  const AppleGradeSplashScreen({super.key});

  @override
  State<AppleGradeSplashScreen> createState() => _AppleGradeSplashScreenState();
}

class _AppleGradeSplashScreenState extends State<AppleGradeSplashScreen>
    with TickerProviderStateMixin {
  
  // 상태 관리
  SplashState _state = SplashState.initial();
  
  // Apple 스타일 애니메이션 컨트롤러들
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _blurController;
  late final AnimationController _textController;
  late final AnimationController _progressController;
  
  // 정교한 애니메이션들
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _blurAnimation;
  late final Animation<double> _textAnimation;
  late final Animation<double> _progressAnimation;
  
  // Apple 스타일 색상 팔레트
  static const Color _primaryColor = Color(0xFF007AFF);
  static const Color _secondaryColor = Color(0xFF5856D6);
  static const Color _accentColor = Color(0xFFFF2D92);
  static const Color _backgroundStart = Color(0xFFF2F2F7);
  static const Color _backgroundEnd = Color(0xFFFFFFFF);
  static const Color _textColor = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  
  // 성능 최적화
  bool _isDisposed = false;
  bool _isInitialized = false;
  
  // 접근성
  final _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startElegantAnimationSequence();
  }
  
  void _initializeAnimations() {
    // 페이드 인 컨트롤러 (Apple의 부드러운 등장)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // 스케일 컨트롤러 (미묘한 확대 효과)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 블러 컨트롤러 (포커스 효과)
    _blurController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // 텍스트 컨트롤러 (타이포그래피 애니메이션)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    // 프로그레스 컨트롤러 (정교한 로딩)
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Apple 스타일 애니메이션 정의
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic, // Apple의 선호하는 커브
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutQuart, // 부드러운 확대
    ));
    
    _blurAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeOutCubic,
    ));
    
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));
    
    // 애니메이션 완료 리스너
    _fadeController.addStatusListener(_onAnimationStatusChanged);
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
        // 자동 이동 제거 - 터치해야만 이동
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
      default:
        break;
    }
  }
  
  void _startElegantAnimationSequence() async {
    if (_isDisposed) return;
    
    // Apple 스타일 순차 애니메이션
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isDisposed) return;
    
    // 블러 효과 시작
    _blurController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    if (_isDisposed) return;
    
    // 페이드 인 시작
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    if (_isDisposed) return;
    
    // 스케일 애니메이션 시작
    _scaleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isDisposed) return;
    
    // 텍스트 애니메이션 시작
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    if (_isDisposed) return;
    
    // 프로그레스 애니메이션 시작
    _progressController.forward();
  }
  
  // 자동 이동 기능 제거 - 터치해야만 이동
  
  void _navigateToNextScreen() {
    if (_isDisposed) return;
    
    try {
      // 터치시 로비 화면으로 이동
      Navigator.of(context).pushReplacementNamed('/lobby');
    } catch (e) {
      // 오류 발생시에도 로비로 이동
      Navigator.of(context).pushReplacementNamed('/lobby');
    }
  }
  
  void _onSkip() async {
    if (!_state.canSkip || _isDisposed || _state.isSkipping) return;
    
    if (mounted && !_isDisposed) {
      setState(() {
        _state = _state.copyWith(isSkipping: true);
      });
    }
    
    // Apple 스타일 미묘한 햅틱 피드백
    await _provideAppleHapticFeedback();
    
    // Apple 스타일 사운드
    await _playAppleSound();
    
    _navigateToNextScreen();
  }
  
  Future<void> _provideAppleHapticFeedback() async {
    try {
      // Apple의 미묘한 햅틱 피드백
      await HapticFeedback.selectionClick();
    } catch (e) {
      // 실패시 무시
    }
  }
  
  Future<void> _playAppleSound() async {
    try {
      // Apple 스타일 미묘한 사운드
      await SoundManager.instance.play(Sfx.buttonClick, volume: 0.2);
    } catch (e) {
      // 실패시 무시
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInitialized) {
      _initializeResponsiveSizes();
      _isInitialized = true;
    }
  }
  
  void _initializeResponsiveSizes() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    final sizes = ResponsiveSizes.calculate(screenWidth, screenHeight);
    
    if (mounted && !_isDisposed) {
      setState(() {
        _state = _state.copyWith(sizes: sizes);
      });
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _fadeController.dispose();
    _scaleController.dispose();
    _blurController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundStart,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _fadeController,
          _scaleController,
          _blurController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _backgroundStart,
                  _backgroundEnd,
                ],
              ),
            ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: _blurAnimation.value,
                sigmaY: _blurAnimation.value,
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
                          // Apple 스타일 로고 섹션
                          _buildAppleLogoSection(),
                          SizedBox(height: _state.sizes.logoSize * 0.8),
                          
                          // Apple 스타일 로딩 인디케이터
                          _buildAppleLoadingIndicator(),
                          SizedBox(height: _state.sizes.logoSize * 0.6),
                          
                          // Apple 스타일 스킵 안내
                          if (_state.canSkip) _buildAppleSkipGuide(),
                        ],
                      ),
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
  
  Widget _buildAppleLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeController,
        _scaleController,
        _textController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                // Apple 스타일 로고
                _buildAppleLogo(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAppleLogo() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildAppleLogoLetters(),
        );
      },
    );
  }
  
  List<Widget> _buildAppleLogoLetters() {
    const letters = 'ilosi';
    return List.generate(letters.length, (index) {
      return AnimatedBuilder(
        animation: _textController,
        builder: (context, child) {
          final letterProgress = _getAppleLetterProgress(index);
          final letterOffset = _getAppleLetterOffset(index);
          
          return Transform.translate(
            offset: letterOffset,
            child: Opacity(
              opacity: letterProgress,
              child: Text(
                letters[index],
                style: _getAppleLogoTextStyle(),
              ),
            ),
          );
        },
      );
    });
  }
  
  double _getAppleLetterProgress(int index) {
    final progress = _textController.value;
    final start = 0.2 + (index * 0.15);
    final end = start + 0.2;
    
    if (progress < start) return 0.0;
    if (progress > end) return 1.0;
    
    return (progress - start) / (end - start);
  }
  
  Offset _getAppleLetterOffset(int index) {
    final progress = _textController.value;
    final letterProgress = _getAppleLetterProgress(index);
    final baseOffset = 20.0;
    
    return Offset(
      0,
      baseOffset * (1 - letterProgress) * math.sin(progress * math.pi + index * 0.5),
    );
  }
  
  TextStyle _getAppleLogoTextStyle() {
    return TextStyle(
      fontSize: _state.sizes.logoSize,
      fontFamily: 'SF Pro Display', // Apple의 공식 폰트
      fontWeight: FontWeight.w300,
      color: _textColor,
      letterSpacing: _state.sizes.letterSpacing * 0.8,
      height: 1.0,
    );
  }
  

  
  Widget _buildAppleLoadingIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeController,
        _progressController,
      ]),
      builder: (context, child) {
        final progress = _progressController.value;
        final opacity = math.min(1.0, _fadeAnimation.value * 2);
        
        return Opacity(
          opacity: opacity,
          child: SizedBox(
            width: _state.sizes.logoSize * 0.6,
            height: _state.sizes.logoSize * 0.6,
            child: CustomPaint(
              painter: AppleLoadingPainter(
                progress: progress,
                primaryColor: _primaryColor,
                secondaryColor: _secondaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAppleSkipGuide() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final opacity = _fadeAnimation.value;
        
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _state.sizes.tapTextSize * 1.8,
              vertical: _state.sizes.tapTextSize * 0.8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: _primaryColor.withOpacity(0.1),
              border: Border.all(
                color: _primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Semantics(
              label: '터치하거나 스페이스바를 눌러 시작하세요',
              button: true,
              onTap: _onSkip,
              child: Text(
                'Continue',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: _state.sizes.tapTextSize,
                  fontFamily: 'SF Pro Text',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Apple 스타일 로딩 페인터
class AppleLoadingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  
  AppleLoadingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    
    // Apple 스타일 배경 원
    final backgroundPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Apple 스타일 진행 원호
    final progressPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, progress * 2 * math.pi, false, progressPaint);
    
    // Apple 스타일 점진적 투명도
    final fadePaint = Paint()
      ..color = secondaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final fadeRect = Rect.fromCircle(center: center, radius: radius - 2);
    canvas.drawArc(fadeRect, -math.pi / 2, progress * 2 * math.pi, false, fadePaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Apple 스타일 상태 관리
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
}

// Apple 스타일 반응형 크기
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
      logoSize: math.min(screenWidth * 0.15, screenHeight * 0.12),
      letterSpacing: math.min(screenWidth * 0.008, 12.0),
      tapTextSize: math.min(screenWidth * 0.018, screenHeight * 0.025),
    );
  }
}

enum SplashAnimationState {
  initial,
  animating,
  canSkip,
  completed,
} 