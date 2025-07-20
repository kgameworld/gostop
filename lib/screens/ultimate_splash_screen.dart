import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/sound_manager.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class UltimateSplashScreen extends StatefulWidget {
  const UltimateSplashScreen({super.key});

  @override
  State<UltimateSplashScreen> createState() => _UltimateSplashScreenState();
}

class _UltimateSplashScreenState extends State<UltimateSplashScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _showTapText = false;
  bool _isHovered = false;
  bool _isTapped = false;
  
  // 반응형 크기 변수들
  late double _screenWidth;
  late double _screenHeight;
  late double _logoSize;
  late double _letterSpacing;
  late double _tapTextSize;
  
  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _letterController;
  late AnimationController _tapTextController;
  late AnimationController _hoverController;
  late AnimationController _particleController;
  late AnimationController _rotationController;
  late AnimationController _tapEffectController;
  late AnimationController _soundController;
  
  // 애니메이션들
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _letterAnimation;
  late Animation<double> _tapTextAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _tapEffectAnimation;
  late Animation<double> _soundAnimation;
  
  // 글자별 애니메이션 딜레이
  late List<double> _letterDelays;
  
  // 파티클 시스템
  final List<Particle> _particles = [];
  final List<TapParticle> _tapParticles = [];
  
  // 성능 최적화
  bool _isDisposed = false;
  int _frameCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeResponsiveSizes();
    _initializeParticles();
    _initializeAnimations();
    _initializeApp();
    _playStartSound();
  }
  
  void _initializeResponsiveSizes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final mediaQuery = MediaQuery.of(context);
        _screenWidth = mediaQuery.size.width;
        _screenHeight = mediaQuery.size.height;
        
        // 반응형 크기 계산
        _logoSize = math.min(_screenWidth * 0.15, _screenHeight * 0.12);
        _letterSpacing = _logoSize * 0.12;
        _tapTextSize = math.min(_screenWidth * 0.02, _screenHeight * 0.025);
        
        // 글자 딜레이도 화면 크기에 따라 조정
        _letterDelays = [
          0.0, 
          0.15 * (_screenWidth / 1920), 
          0.3 * (_screenWidth / 1920), 
          0.45 * (_screenWidth / 1920), 
          0.6 * (_screenWidth / 1920)
        ];
        
        setState(() {});
      }
    });
  }
  
  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        position: Offset(
          random.nextDouble() * 600 - 300,
          random.nextDouble() * 600 - 300,
        ),
        velocity: Offset(
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 2 - 1,
        ),
        size: random.nextDouble() * 3 + 1,
        opacity: random.nextDouble() * 0.3 + 0.1,
      ));
    }
  }
  
  void _initializeAnimations() {
    // 페이드인 애니메이션
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // 글로우 효과 애니메이션
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // 글자 애니메이션
    _letterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _letterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _letterController,
      curve: Curves.elasticOut,
    ));
    
    // 터치 텍스트 애니메이션
    _tapTextController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _tapTextAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tapTextController,
      curve: Curves.easeInOut,
    ));
    
    // 호버 애니메이션
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    // 파티클 애니메이션
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));
    
    // 회전 애니메이션
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 15000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // 터치 효과 애니메이션
    _tapEffectController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _tapEffectAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tapEffectController,
      curve: Curves.elasticOut,
    ));
    
    // 사운드 애니메이션
    _soundController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _soundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _soundController,
      curve: Curves.easeInOut,
    ));
    
    // 애니메이션 시작
    _startAnimations();
  }
  
  void _startAnimations() async {
    if (_isDisposed) return;
    
    // 페이드인 시작
    _fadeController.forward();
    
    // 800ms 후 글로우 효과 시작
    await Future.delayed(const Duration(milliseconds: 800));
    if (_isDisposed) return;
    _glowController.repeat(reverse: true);
    
    // 1.2초 후 글자 애니메이션 시작
    await Future.delayed(const Duration(milliseconds: 400));
    if (_isDisposed) return;
    _letterController.forward();
    
    // 2.2초 후 터치 텍스트 표시
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_isDisposed) return;
    setState(() {
      _showTapText = true;
    });
    _tapTextController.forward();
    
    // 파티클 애니메이션 시작
    _particleController.repeat();
    
    // 회전 애니메이션 시작
    _rotationController.repeat();
  }
  
  void _playStartSound() async {
    try {
      await SoundManager.instance.playBgm('lobby', volume: 0.3);
    } catch (e) {
      // 사운드 재생 실패시 무시
    }
  }
  
  void _playTapSound() async {
    try {
      await SoundManager.instance.play(Sfx.buttonClick, volume: 0.5);
    } catch (e) {
      // 사운드 재생 실패시 무시
    }
  }
  
  void _initializeApp() async {
    try {
      // 5초 대기 (스플래시 효과)
      await Future.delayed(const Duration(seconds: 5));
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
        
        // 인증 상태에 따라 적절한 화면으로 이동
        _navigateToNextScreen();
      }
    } catch (e) {
      // 오류 발생시 인증 상태에 따라 이동
      if (mounted && !_isDisposed) {
        _navigateToNextScreen();
      }
    }
  }
  
  void _navigateToNextScreen() {
    if (_isDisposed) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      // 인증된 사용자: 로비로 이동
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // 인증되지 않은 사용자: 로그인 화면으로 이동
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  void _onHover(bool isHovered) {
    if (_isDisposed) return;
    
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
  
  void _onTap() {
    if (_isDisposed) return;
    
    setState(() {
      _isTapped = true;
    });
    
    // 터치 효과 애니메이션 시작
    _tapEffectController.forward().then((_) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isTapped = false;
        });
        _tapEffectController.reset();
      }
    });
    
    // 터치 파티클 생성
    _createTapParticles();
    
    // 사운드 재생
    _playTapSound();
    
    // 사운드 애니메이션
    _soundController.forward().then((_) {
      if (mounted && !_isDisposed) {
        _soundController.reset();
      }
    });
    
    // 인증 상태에 따라 적절한 화면으로 이동
    _navigateToNextScreen();
  }
  
  void _createTapParticles() {
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      _tapParticles.add(TapParticle(
        position: Offset(
          random.nextDouble() * 200 - 100,
          random.nextDouble() * 200 - 100,
        ),
        velocity: Offset(
          random.nextDouble() * 8 - 4,
          random.nextDouble() * 8 - 4,
        ),
        size: random.nextDouble() * 4 + 2,
        opacity: random.nextDouble() * 0.8 + 0.2,
        life: 1.0,
      ));
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _fadeController.dispose();
    _glowController.dispose();
    _letterController.dispose();
    _tapTextController.dispose();
    _hoverController.dispose();
    _particleController.dispose();
    _rotationController.dispose();
    _tapEffectController.dispose();
    _soundController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 2.0,
            colors: [
              Color(0xFF050510),
              Color(0xFF0a0a1a),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 배경 파티클들
            _buildBackgroundParticles(),
            
            // 메인 콘텐츠
            Center(
              child: MouseRegion(
                onEnter: (_) => _onHover(true),
                onExit: (_) => _onHover(false),
                child: GestureDetector(
                  onTap: _onTap,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _fadeController,
                      _glowController,
                      _letterController,
                      _tapTextController,
                      _hoverController,
                      _tapEffectController,
                      _soundController,
                    ]),
                    builder: (context, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 로고 텍스트 (애니메이션 적용)
                          _buildUltimateLogo(),
                          SizedBox(height: _screenHeight * 0.06),
                          // 로딩 인디케이터 (애니메이션 적용)
                          if (_isLoading) _buildUltimateLoader(),
                          SizedBox(height: _screenHeight * 0.04),
                          // 안내 텍스트 (애니메이션 적용)
                          if (_showTapText) _buildUltimateTapText(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // 터치 파티클 효과
            _buildTapParticles(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: UltimateParticlePainter(
            particles: _particles,
            animation: _particleAnimation.value,
            rotation: _rotationAnimation.value,
            screenWidth: _screenWidth,
            screenHeight: _screenHeight,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildTapParticles() {
    return AnimatedBuilder(
      animation: _tapEffectAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: TapParticlePainter(
            particles: _tapParticles,
            animation: _tapEffectAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildUltimateLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.scale(
        scale: 1.0 + (_hoverAnimation.value * 0.08) + (_tapEffectAnimation.value * 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _letterAnimation,
              builder: (context, child) {
                final letterDelay = _letterDelays.isNotEmpty ? _letterDelays[index] : 0.0;
                final letterProgress = (_letterAnimation.value - letterDelay).clamp(0.0, 1.0);
                
                return Transform.translate(
                  offset: Offset(0, 40 * (1 - letterProgress)),
                  child: Transform.rotate(
                    angle: (1 - letterProgress) * 0.15,
                    child: Opacity(
                      opacity: letterProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withOpacity(0.3 * _glowAnimation.value),
                              blurRadius: 40 * _glowAnimation.value,
                              spreadRadius: 8 * _glowAnimation.value,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withOpacity(0.5 * _glowAnimation.value),
                              blurRadius: 20 * _glowAnimation.value,
                              spreadRadius: 3 * _glowAnimation.value,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2 * _glowAnimation.value),
                              blurRadius: 5 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: Text(
                          'ilosi'[index],
                          style: TextStyle(
                            fontSize: _logoSize,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w100,
                            color: const Color(0xFF00FFFF),
                            letterSpacing: _letterSpacing,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00FFFF).withOpacity(0.9 * _glowAnimation.value),
                                blurRadius: 30 * _glowAnimation.value,
                              ),
                              Shadow(
                                color: Colors.white.withOpacity(0.4 * _glowAnimation.value),
                                blurRadius: 8 * _glowAnimation.value,
                              ),
                            ],
                          ),
                        ),
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
  
  Widget _buildUltimateLoader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: _screenWidth * 0.04,
        height: _screenWidth * 0.04,
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF00FFFF).withOpacity(_glowAnimation.value),
                ),
                strokeWidth: _screenWidth * 0.003,
                backgroundColor: const Color(0xFF00FFFF).withOpacity(0.2),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildUltimateTapText() {
    return FadeTransition(
      opacity: _tapTextAnimation,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - _tapTextAnimation.value)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _screenWidth * 0.02,
            vertical: _screenHeight * 0.01,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFF00FFFF).withOpacity(0.4 * _tapTextAnimation.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFFF).withOpacity(0.2 * _tapTextAnimation.value),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '터치하여 시작',
            style: TextStyle(
              color: const Color(0xFF00FFFF).withOpacity(0.8 * _tapTextAnimation.value),
              fontSize: _tapTextSize,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: const Color(0xFF00FFFF).withOpacity(0.5 * _tapTextAnimation.value),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 파티클 클래스들
class Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
  });
  
  void update(double deltaTime) {
    position += velocity * deltaTime;
    
    // 화면 경계에서 반사
    if (position.dx.abs() > 300) velocity = Offset(-velocity.dx, velocity.dy);
    if (position.dy.abs() > 300) velocity = Offset(velocity.dx, -velocity.dy);
  }
}

class TapParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  double life;
  
  TapParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.life,
  });
  
  void update(double deltaTime) {
    position += velocity * deltaTime;
    velocity *= 0.95; // 저항
    life -= deltaTime * 2;
    opacity *= 0.98;
  }
  
  bool isDead() => life <= 0;
}

// 고급 파티클 파인터
class UltimateParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final double rotation;
  final double screenWidth;
  final double screenHeight;
  
  UltimateParticlePainter({
    required this.particles,
    required this.animation,
    required this.rotation,
    required this.screenWidth,
    required this.screenHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final x = size.width / 2 + particle.position.dx * math.cos(rotation + i * 0.3);
      final y = size.height / 2 + particle.position.dy * math.sin(rotation + i * 0.2);
      
      // 그라데이션 효과
      final gradient = RadialGradient(
        colors: [
          const Color(0xFF00FFFF).withOpacity(particle.opacity),
          const Color(0xFF00FFFF).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(x, y),
        radius: particle.size * 2,
      ));
      
      paint.shader = gradient;
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size + math.sin(animation * 2 * math.pi + i) * 1.5,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 터치 파티클 파인터
class TapParticlePainter extends CustomPainter {
  final List<TapParticle> particles;
  final double animation;
  
  TapParticlePainter({
    required this.particles,
    required this.animation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    for (final particle in particles) {
      if (particle.isDead()) continue;
      
      final x = size.width / 2 + particle.position.dx;
      final y = size.height / 2 + particle.position.dy;
      
      paint.color = const Color(0xFF00FFFF).withOpacity(particle.opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1 - animation),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 