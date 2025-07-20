import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/sound_manager.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// 프로페셔널급 스플래시 스크린 - 고급 애니메이션, 입체 효과, 물리 시뮬레이션
class ProfessionalAnimationSplashScreen extends StatefulWidget {
  const ProfessionalAnimationSplashScreen({super.key});

  @override
  State<ProfessionalAnimationSplashScreen> createState() => _ProfessionalAnimationSplashScreenState();
}

class _ProfessionalAnimationSplashScreenState extends State<ProfessionalAnimationSplashScreen>
    with TickerProviderStateMixin {
  
  // 상태 관리
  SplashState _state = SplashState.initial();
  
  // 고급 애니메이션 컨트롤러들
  late final AnimationController _mainController;
  late final AnimationController _particleController;
  late final AnimationController _glowController;
  late final AnimationController _waveController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  
  // 고급 애니메이션들
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _waveAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _pulseAnimation;
  
  // 고급 파티클 시스템
  final List<AdvancedParticle> _particles = [];
  final List<SparkleParticle> _sparkles = [];
  final List<WaveParticle> _waves = [];
  
  // 물리 시뮬레이션
  final List<PhysicsObject> _physicsObjects = [];
  
  // 성능 최적화
  bool _isDisposed = false;
  bool _isInitialized = false;
  int _frameCount = 0;
  
  // 접근성
  final _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticleSystems();
    _initializePhysicsObjects();
    _startAnimationSequence();
  }
  
  void _initializeAnimations() {
    // 메인 애니메이션 컨트롤러
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    // 파티클 애니메이션
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // 글로우 효과
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // 웨이브 효과
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // 플로팅 효과
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // 펄스 효과
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 애니메이션 정의
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
    ));
    
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.4, curve: Curves.easeOutBack),
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    
    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // 애니메이션 리스너
    _mainController.addStatusListener(_onMainAnimationStatusChanged);
  }
  
  void _initializeParticleSystems() {
    final random = math.Random();
    
    // 고급 파티클 생성
    for (int i = 0; i < 50; i++) {
      _particles.add(AdvancedParticle(
        position: Offset(
          random.nextDouble() * 800 - 400,
          random.nextDouble() * 600 - 300,
        ),
        velocity: Offset(
          random.nextDouble() * 3 - 1.5,
          random.nextDouble() * 3 - 1.5,
        ),
        size: random.nextDouble() * 4 + 1,
        opacity: random.nextDouble() * 0.6 + 0.2,
        color: _getRandomParticleColor(),
        life: random.nextDouble() * 0.5 + 0.5,
        type: ParticleType.values[random.nextInt(ParticleType.values.length)],
      ));
    }
    
    // 스파클 파티클 생성
    for (int i = 0; i < 30; i++) {
      _sparkles.add(SparkleParticle(
        position: Offset(
          random.nextDouble() * 600 - 300,
          random.nextDouble() * 400 - 200,
        ),
        velocity: Offset(
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 2 - 1,
        ),
        size: random.nextDouble() * 3 + 1,
        opacity: random.nextDouble() * 0.8 + 0.2,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: random.nextDouble() * 0.1 - 0.05,
      ));
    }
    
    // 웨이브 파티클 생성
    for (int i = 0; i < 20; i++) {
      _waves.add(WaveParticle(
        position: Offset(
          random.nextDouble() * 1000 - 500,
          random.nextDouble() * 800 - 400,
        ),
        velocity: Offset(
          random.nextDouble() * 1 - 0.5,
          random.nextDouble() * 1 - 0.5,
        ),
        size: random.nextDouble() * 100 + 50,
        opacity: random.nextDouble() * 0.3 + 0.1,
        frequency: random.nextDouble() * 0.02 + 0.01,
        amplitude: random.nextDouble() * 20 + 10,
      ));
    }
  }
  
  void _initializePhysicsObjects() {
    final random = math.Random();
    
    // 물리 객체 생성
    for (int i = 0; i < 15; i++) {
      _physicsObjects.add(PhysicsObject(
        position: Offset(
          random.nextDouble() * 600 - 300,
          random.nextDouble() * 400 - 200,
        ),
        velocity: Offset(
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 2 - 1,
        ),
        size: random.nextDouble() * 8 + 4,
        mass: random.nextDouble() * 2 + 0.5,
        elasticity: random.nextDouble() * 0.5 + 0.3,
        friction: random.nextDouble() * 0.1 + 0.05,
      ));
    }
  }
  
  Color _getRandomParticleColor() {
    final colors = [
      const Color(0xFF00FFFF),
      const Color(0xFF0080FF),
      const Color(0xFF8000FF),
      const Color(0xFFFF0080),
      const Color(0xFFFF8000),
      const Color(0xFF80FF00),
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
  
  void _onMainAnimationStatusChanged(AnimationStatus status) {
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
  
  void _startAnimationSequence() {
    if (_isDisposed) return;
    
    // 메인 애니메이션 시작
    _mainController.forward();
    
    // 파티클 애니메이션 시작
    _particleController.repeat();
    
    // 글로우 효과 시작
    _glowController.repeat(reverse: true);
    
    // 웨이브 효과 시작
    _waveController.repeat();
    
    // 플로팅 효과 시작
    _floatController.repeat(reverse: true);
    
    // 펄스 효과 시작
    _pulseController.repeat(reverse: true);
    
    // 물리 시뮬레이션 시작
    _startPhysicsSimulation();
  }
  
  void _startPhysicsSimulation() {
    // 60fps 물리 시뮬레이션
    Future.doWhile(() async {
      if (_isDisposed) return false;
      
      _updatePhysics();
      await Future.delayed(const Duration(milliseconds: 16)); // ~60fps
      return true;
    });
  }
  
  void _updatePhysics() {
    if (_isDisposed) return;
    
    // 중력 적용
    const gravity = Offset(0, 0.1);
    const bounds = Rect.fromLTWH(-400, -300, 800, 600);
    
    for (final object in _physicsObjects) {
      // 중력 적용
      object.velocity += gravity;
      
      // 위치 업데이트
      object.position += object.velocity;
      
      // 경계 충돌 처리
      if (object.position.dx < bounds.left || object.position.dx > bounds.right) {
        object.velocity = Offset(-object.velocity.dx * object.elasticity, object.velocity.dy);
        object.position = Offset(
          object.position.dx.clamp(bounds.left, bounds.right),
          object.position.dy,
        );
      }
      
      if (object.position.dy < bounds.top || object.position.dy > bounds.bottom) {
        object.velocity = Offset(object.velocity.dx, -object.velocity.dy * object.elasticity);
        object.position = Offset(
          object.position.dx,
          object.position.dy.clamp(bounds.top, bounds.bottom),
        );
      }
      
      // 마찰력 적용
      object.velocity *= (1 - object.friction);
    }
    
    // 파티클 업데이트
    _updateParticles();
    
    // 프레임 카운트 증가
    _frameCount++;
    
    // 상태 업데이트 (60fps로 제한)
    if (_frameCount % 2 == 0 && mounted && !_isDisposed) {
      setState(() {});
    }
  }
  
  void _updateParticles() {
    // 고급 파티클 업데이트
    for (final particle in _particles) {
      particle.position += particle.velocity;
      particle.life -= 0.01;
      particle.opacity = particle.life;
      
      // 파티클 타입별 특수 효과
      switch (particle.type) {
        case ParticleType.normal:
          particle.size *= 0.99;
          break;
        case ParticleType.sparkle:
          particle.size *= 1.01;
          break;
        case ParticleType.wave:
          particle.velocity *= 0.98;
          break;
      }
    }
    
    // 스파클 파티클 업데이트
    for (final sparkle in _sparkles) {
      sparkle.position += sparkle.velocity;
      sparkle.rotation += sparkle.rotationSpeed;
      sparkle.opacity *= 0.995;
    }
    
    // 웨이브 파티클 업데이트
    for (final wave in _waves) {
      wave.position += wave.velocity;
      wave.opacity *= 0.998;
    }
  }
  
  void _scheduleNavigation() {
    if (_isDisposed) return;
    
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
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  void _onSkip() async {
    if (!_state.canSkip || _isDisposed || _state.isSkipping) return;
    
    if (mounted && !_isDisposed) {
      setState(() {
        _state = _state.copyWith(isSkipping: true);
      });
    }
    
    // 고급 햅틱 피드백
    await _provideAdvancedHapticFeedback();
    
    // 고급 사운드 효과
    await _playAdvancedSoundEffects();
    
    // 스킵 파티클 효과
    _createSkipParticleEffect();
    
    _navigateToNextScreen();
  }
  
  Future<void> _provideAdvancedHapticFeedback() async {
    try {
      // 연속 햅틱 피드백
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // 실패시 무시
    }
  }
  
  Future<void> _playAdvancedSoundEffects() async {
    try {
      // 멀티 레이어 사운드
      await Future.wait([
        SoundManager.instance.play(Sfx.buttonClick, volume: 0.4),
        SoundManager.instance.play(Sfx.cardPlay, volume: 0.2),
      ]);
    } catch (e) {
      // 실패시 무시
    }
  }
  
  void _createSkipParticleEffect() {
    final random = math.Random();
    
    // 스킵 파티클 폭발 효과
    for (int i = 0; i < 25; i++) {
      _particles.add(AdvancedParticle(
        position: Offset(
          random.nextDouble() * 200 - 100,
          random.nextDouble() * 200 - 100,
        ),
        velocity: Offset(
          random.nextDouble() * 10 - 5,
          random.nextDouble() * 10 - 5,
        ),
        size: random.nextDouble() * 6 + 2,
        opacity: 1.0,
        color: _getRandomParticleColor(),
        life: 1.0,
        type: ParticleType.sparkle,
      ));
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
    _mainController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                const Color(0xFF0a0a1a),
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e),
                const Color(0xFF0f3460),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 배경 파티클 레이어
              _buildBackgroundParticleLayer(),
              
              // 물리 객체 레이어
              _buildPhysicsObjectLayer(),
              
              // 메인 콘텐츠 레이어
              _buildMainContentLayer(),
              
              // 포그라운드 파티클 레이어
              _buildForegroundParticleLayer(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBackgroundParticleLayer() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundParticlePainter(
            particles: _particles,
            sparkles: _sparkles,
            waves: _waves,
            animation: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildPhysicsObjectLayer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: PhysicsObjectPainter(
            objects: _physicsObjects,
            pulseAnimation: _pulseAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildMainContentLayer() {
    return SafeArea(
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
                // 고급 로고 섹션
                _buildAdvancedLogoSection(),
                SizedBox(height: _state.sizes.logoSize * 0.8),
                
                // 고급 로딩 인디케이터
                _buildAdvancedLoadingIndicator(),
                SizedBox(height: _state.sizes.logoSize * 0.4),
                
                // 고급 스킵 안내
                if (_state.canSkip) _buildAdvancedSkipGuide(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildForegroundParticleLayer() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return CustomPaint(
          painter: ForegroundParticlePainter(
            glowAnimation: _glowAnimation.value,
            waveAnimation: _waveAnimation.value,
          ),
          size: Size.infinite,
        );
      },
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
  
  Widget _buildAdvancedLogoSection() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..scale(_scaleAnimation.value)
            ..rotateZ(_rotationAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildFloatingLogo(),
          ),
        );
      },
    );
  }
  
  Widget _buildFloatingLogo() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_floatAnimation.value * 2 * math.pi) * 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildAdvancedLogoLetters(),
          ),
        );
      },
    );
  }
  
  List<Widget> _buildAdvancedLogoLetters() {
    const letters = 'ilosi';
    return List.generate(letters.length, (index) {
      return AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          final letterProgress = _getAdvancedLetterProgress(index);
          final letterGlow = _getLetterGlowIntensity(index);
          
          return Transform.translate(
            offset: Offset(0, 30 * (1 - letterProgress)),
            child: Opacity(
              opacity: letterProgress,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  letters[index],
                  style: _getAdvancedLogoTextStyle(letterGlow),
                ),
              ),
            ),
          );
        },
      );
    });
  }
  
  double _getAdvancedLetterProgress(int index) {
    final progress = _mainController.value;
    final start = 0.3 + (index * 0.1);
    final end = start + 0.2;
    
    if (progress < start) return 0.0;
    if (progress > end) return 1.0;
    
    return (progress - start) / (end - start);
  }
  
  double _getLetterGlowIntensity(int index) {
    final progress = _mainController.value;
    final baseGlow = math.max(0.3, progress);
    final letterGlow = math.sin(progress * math.pi + index * 0.5) * 0.3 + baseGlow;
    return letterGlow.clamp(0.0, 1.0);
  }
  
  TextStyle _getAdvancedLogoTextStyle(double glowIntensity) {
    return TextStyle(
      fontSize: _state.sizes.logoSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w300,
      color: const Color(0xFF00FFFF),
      letterSpacing: _state.sizes.letterSpacing,
      shadows: [
        Shadow(
          color: const Color(0xFF00FFFF).withOpacity(0.8 * glowIntensity),
          blurRadius: 25 * glowIntensity,
        ),
        Shadow(
          color: Colors.white.withOpacity(0.5 * glowIntensity),
          blurRadius: 8 * glowIntensity,
        ),
        Shadow(
          color: const Color(0xFF0080FF).withOpacity(0.4 * glowIntensity),
          blurRadius: 15 * glowIntensity,
        ),
      ],
    );
  }
  
  Widget _buildAdvancedLoadingIndicator() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final progress = _mainController.value;
        final opacity = math.min(1.0, progress * 2);
        
        return Opacity(
          opacity: opacity,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: SizedBox(
                  width: _state.sizes.logoSize * 0.5,
                  height: _state.sizes.logoSize * 0.5,
                  child: CustomPaint(
                    painter: AdvancedLoadingPainter(
                      progress: progress,
                      pulseAnimation: _pulseAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildAdvancedSkipGuide() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final progress = _mainController.value;
        final opacity = math.max(0.0, (progress - 0.8) * 5);
        
        return Opacity(
          opacity: opacity,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _state.sizes.tapTextSize * 1.5,
                  vertical: _state.sizes.tapTextSize * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF00FFFF).withOpacity(0.6 * _glowAnimation.value),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFFF).withOpacity(0.3 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1 * _glowAnimation.value),
                      blurRadius: 10 * _glowAnimation.value,
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
                      color: const Color(0xFF00FFFF).withOpacity(0.9),
                      fontSize: _state.sizes.tapTextSize,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.6 * _glowAnimation.value),
                          blurRadius: 12 * _glowAnimation.value,
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
          ),
        );
      },
    );
  }
}

// 고급 파티클 클래스들
class AdvancedParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Color color;
  double life;
  ParticleType type;
  
  AdvancedParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.color,
    required this.life,
    required this.type,
  });
}

class SparkleParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  double rotation;
  double rotationSpeed;
  
  SparkleParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class WaveParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  double frequency;
  double amplitude;
  
  WaveParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.frequency,
    required this.amplitude,
  });
}

class PhysicsObject {
  Offset position;
  Offset velocity;
  double size;
  double mass;
  double elasticity;
  double friction;
  
  PhysicsObject({
    required this.position,
    required this.velocity,
    required this.size,
    required this.mass,
    required this.elasticity,
    required this.friction,
  });
}

enum ParticleType { normal, sparkle, wave }

// 고급 CustomPainter 클래스들
class BackgroundParticlePainter extends CustomPainter {
  final List<AdvancedParticle> particles;
  final List<SparkleParticle> sparkles;
  final List<WaveParticle> waves;
  final double animation;
  
  BackgroundParticlePainter({
    required this.particles,
    required this.sparkles,
    required this.waves,
    required this.animation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 고급 파티클 그리기
    for (final particle in particles) {
      if (particle.life > 0) {
        final paint = Paint()
          ..color = particle.color.withOpacity(particle.opacity)
          ..style = PaintingStyle.fill;
        
        final position = center + particle.position;
        
        switch (particle.type) {
          case ParticleType.normal:
            canvas.drawCircle(position, particle.size, paint);
            break;
          case ParticleType.sparkle:
            _drawSparkle(canvas, position, particle.size, paint);
            break;
          case ParticleType.wave:
            _drawWave(canvas, position, particle.size, paint);
            break;
        }
      }
    }
    
    // 스파클 파티클 그리기
    for (final sparkle in sparkles) {
      if (sparkle.opacity > 0.1) {
        final paint = Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(sparkle.opacity)
          ..style = PaintingStyle.fill;
        
        final position = center + sparkle.position;
        _drawSparkle(canvas, position, sparkle.size, paint, sparkle.rotation);
      }
    }
    
    // 웨이브 파티클 그리기
    for (final wave in waves) {
      if (wave.opacity > 0.05) {
        final paint = Paint()
          ..color = const Color(0xFF00FFFF).withOpacity(wave.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        final position = center + wave.position;
        _drawWaveRing(canvas, position, wave.size, paint, wave.frequency, wave.amplitude);
      }
    }
  }
  
  void _drawSparkle(Canvas canvas, Offset position, double size, Paint paint, [double rotation = 0]) {
    final path = Path();
    final radius = size;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + rotation;
      final start = position + Offset(
        math.cos(angle) * radius * 0.3,
        math.sin(angle) * radius * 0.3,
      );
      final end = position + Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      );
      
      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
    }
    
    canvas.drawPath(path, paint);
  }
  
  void _drawWave(Canvas canvas, Offset position, double size, Paint paint) {
    final path = Path();
    final radius = size;
    
    for (int i = 0; i < 360; i += 5) {
      final angle = i * math.pi / 180;
      final waveOffset = math.sin(angle * 3 + animation * 2 * math.pi) * 5;
      final x = position.dx + math.cos(angle) * (radius + waveOffset);
      final y = position.dy + math.sin(angle) * (radius + waveOffset);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawWaveRing(Canvas canvas, Offset position, double size, Paint paint, double frequency, double amplitude) {
    final path = Path();
    final radius = size;
    
    for (int i = 0; i < 360; i += 2) {
      final angle = i * math.pi / 180;
      final waveOffset = math.sin(angle * frequency + animation * 2 * math.pi) * amplitude;
      final x = position.dx + math.cos(angle) * (radius + waveOffset);
      final y = position.dy + math.sin(angle) * (radius + waveOffset);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PhysicsObjectPainter extends CustomPainter {
  final List<PhysicsObject> objects;
  final double pulseAnimation;
  
  PhysicsObjectPainter({
    required this.objects,
    required this.pulseAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (final object in objects) {
      final position = center + object.position;
      final scaledSize = object.size * (0.8 + 0.2 * pulseAnimation);
      
      // 물리 객체 그라데이션
      final gradient = RadialGradient(
        colors: [
          const Color(0xFF00FFFF).withOpacity(0.3),
          const Color(0xFF0080FF).withOpacity(0.1),
          Colors.transparent,
        ],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(
          center: position,
          radius: scaledSize,
        ));
      
      canvas.drawCircle(position, scaledSize, paint);
      
      // 물리 객체 테두리
      final borderPaint = Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawCircle(position, scaledSize, borderPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ForegroundParticlePainter extends CustomPainter {
  final double glowAnimation;
  final double waveAnimation;
  
  ForegroundParticlePainter({
    required this.glowAnimation,
    required this.waveAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 글로우 효과
    final glowGradient = RadialGradient(
      colors: [
        const Color(0xFF00FFFF).withOpacity(0.1 * glowAnimation),
        const Color(0xFF0080FF).withOpacity(0.05 * glowAnimation),
        Colors.transparent,
      ],
    );
    
    final glowPaint = Paint()
      ..shader = glowGradient.createShader(Rect.fromCircle(
        center: center,
        radius: 300,
      ));
    
    canvas.drawCircle(center, 300, glowPaint);
    
    // 웨이브 효과
    final wavePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (int i = 0; i < 3; i++) {
      final radius = 200 + i * 50 + math.sin(waveAnimation + i) * 20;
      canvas.drawCircle(center, radius, wavePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AdvancedLoadingPainter extends CustomPainter {
  final double progress;
  final double pulseAnimation;
  
  AdvancedLoadingPainter({
    required this.progress,
    required this.pulseAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // 배경 원
    final backgroundPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // 진행 원호
    final progressPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final rect = Rect.fromCircle(center: center, radius: radius - 2);
    canvas.drawArc(rect, -math.pi / 2, progress * 2 * math.pi, false, progressPaint);
    
    // 펄스 효과
    final pulsePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3 * pulseAnimation)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final pulseRadius = radius * (0.8 + 0.2 * pulseAnimation);
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 기존 클래스들 (상태 관리용)
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
}

enum SplashAnimationState {
  initial,
  animating,
  canSkip,
  completed,
} 