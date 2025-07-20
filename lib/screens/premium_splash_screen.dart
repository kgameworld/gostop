import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:math' as math;

class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({super.key});

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _showTapText = false;
  bool _isHovered = false;
  
  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _letterController;
  late AnimationController _tapTextController;
  late AnimationController _hoverController;
  late AnimationController _particleController;
  late AnimationController _rotationController;
  
  // 애니메이션들
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _letterAnimation;
  late Animation<double> _tapTextAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _rotationAnimation;
  
  // 글자별 애니메이션 딜레이
  final List<double> _letterDelays = [0.0, 0.15, 0.3, 0.45, 0.6];
  
  // 파티클 위치들
  final List<Offset> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeParticles();
    _initializeAnimations();
    _initializeApp();
  }
  
  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(Offset(
        random.nextDouble() * 400 - 200,
        random.nextDouble() * 400 - 200,
      ));
    }
  }
  
  void _initializeAnimations() {
    // 페이드인 애니메이션
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // 글자 애니메이션
    _letterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      duration: const Duration(milliseconds: 1200),
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
      duration: const Duration(milliseconds: 300),
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
      duration: const Duration(milliseconds: 3000),
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
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // 애니메이션 시작
    _startAnimations();
  }
  
  void _startAnimations() async {
    // 페이드인 시작
    _fadeController.forward();
    
    // 600ms 후 글로우 효과 시작
    await Future.delayed(const Duration(milliseconds: 600));
    _glowController.repeat(reverse: true);
    
    // 900ms 후 글자 애니메이션 시작
    await Future.delayed(const Duration(milliseconds: 300));
    _letterController.forward();
    
    // 1.8초 후 터치 텍스트 표시
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _showTapText = true;
    });
    _tapTextController.forward();
    
    // 파티클 애니메이션 시작
    _particleController.repeat();
    
    // 회전 애니메이션 시작
    _rotationController.repeat();
  }
  
  void _initializeApp() async {
    try {
      // 4초 대기 (스플래시 효과)
      await Future.delayed(const Duration(seconds: 4));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // 인증 상태에 따라 적절한 화면으로 이동
        _navigateToNextScreen();
      }
    } catch (e) {
      // 오류 발생시 인증 상태에 따라 이동
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }
  
  void _navigateToNextScreen() {
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
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _letterController.dispose();
    _tapTextController.dispose();
    _hoverController.dispose();
    _particleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
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
                  onTap: () {
                    // 터치하면 인증 상태에 따라 적절한 화면으로 이동
                    _navigateToNextScreen();
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _fadeController,
                      _glowController,
                      _letterController,
                      _tapTextController,
                      _hoverController,
                    ]),
                    builder: (context, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 로고 텍스트 (애니메이션 적용)
                          _buildPremiumLogo(),
                          const SizedBox(height: 50),
                          // 로딩 인디케이터 (애니메이션 적용)
                          if (_isLoading) _buildPremiumLoader(),
                          const SizedBox(height: 30),
                          // 안내 텍스트 (애니메이션 적용)
                          if (_showTapText) _buildPremiumTapText(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
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
          painter: ParticlePainter(
            particles: _particles,
            animation: _particleAnimation.value,
            rotation: _rotationAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildPremiumLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.scale(
        scale: 1.0 + (_hoverAnimation.value * 0.05),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _letterAnimation,
              builder: (context, child) {
                final letterDelay = _letterDelays[index];
                final letterProgress = (_letterAnimation.value - letterDelay).clamp(0.0, 1.0);
                
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - letterProgress)),
                  child: Transform.rotate(
                    angle: (1 - letterProgress) * 0.1,
                    child: Opacity(
                      opacity: letterProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withOpacity(0.2 * _glowAnimation.value),
                              blurRadius: 30 * _glowAnimation.value,
                              spreadRadius: 5 * _glowAnimation.value,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withOpacity(0.4 * _glowAnimation.value),
                              blurRadius: 15 * _glowAnimation.value,
                              spreadRadius: 2 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: Text(
                          'ilosi'[index],
                          style: TextStyle(
                            fontSize: 85,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w200,
                            color: const Color(0xFF00FFFF),
                            letterSpacing: 10.0,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00FFFF).withOpacity(0.8 * _glowAnimation.value),
                                blurRadius: 25 * _glowAnimation.value,
                              ),
                              Shadow(
                                color: Colors.white.withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 5 * _glowAnimation.value,
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
  
  Widget _buildPremiumLoader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: 50,
        height: 50,
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF00FFFF).withOpacity(_glowAnimation.value),
                ),
                strokeWidth: 4,
                backgroundColor: const Color(0xFF00FFFF).withOpacity(0.2),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildPremiumTapText() {
    return FadeTransition(
      opacity: _tapTextAnimation,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - _tapTextAnimation.value)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00FFFF).withOpacity(0.3 * _tapTextAnimation.value),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFFF).withOpacity(0.1 * _tapTextAnimation.value),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            '터치하여 시작',
            style: TextStyle(
              color: const Color(0xFF00FFFF).withOpacity(0.7 * _tapTextAnimation.value),
              fontSize: 18,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w300,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: const Color(0xFF00FFFF).withOpacity(0.4 * _tapTextAnimation.value),
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

class ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double animation;
  final double rotation;
  
  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.rotation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final x = size.width / 2 + particle.dx * math.cos(rotation + i * 0.5);
      final y = size.height / 2 + particle.dy * math.sin(rotation + i * 0.3);
      
      canvas.drawCircle(
        Offset(x, y),
        2 + math.sin(animation * 2 * math.pi + i) * 1,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 