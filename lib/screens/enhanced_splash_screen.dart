import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EnhancedSplashScreen extends StatefulWidget {
  const EnhancedSplashScreen({super.key});

  @override
  State<EnhancedSplashScreen> createState() => _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends State<EnhancedSplashScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _showTapText = false;
  
  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _letterController;
  late AnimationController _tapTextController;
  
  // 애니메이션들
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _letterAnimation;
  late Animation<double> _tapTextAnimation;
  
  // 글자별 애니메이션 딜레이
  final List<double> _letterDelays = [0.0, 0.1, 0.2, 0.3, 0.4];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }
  
  void _initializeAnimations() {
    // 페이드인 애니메이션
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // 글자 애니메이션
    _letterController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _tapTextAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tapTextController,
      curve: Curves.easeInOut,
    ));
    
    // 애니메이션 시작
    _startAnimations();
  }
  
  void _startAnimations() async {
    // 페이드인 시작
    _fadeController.forward();
    
    // 500ms 후 글로우 효과 시작
    await Future.delayed(const Duration(milliseconds: 500));
    _glowController.repeat(reverse: true);
    
    // 800ms 후 글자 애니메이션 시작
    await Future.delayed(const Duration(milliseconds: 300));
    _letterController.forward();
    
    // 1.5초 후 터치 텍스트 표시
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _showTapText = true;
    });
    _tapTextController.forward();
  }
  
  void _initializeApp() async {
    try {
      // 3초 대기 (스플래시 효과)
      await Future.delayed(const Duration(seconds: 3));
      
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
  
  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _letterController.dispose();
    _tapTextController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a0a1a),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
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
            ]),
            builder: (context, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고 텍스트 (애니메이션 적용)
                    _buildAnimatedLogo(),
                    const SizedBox(height: 40),
                    // 로딩 인디케이터 (애니메이션 적용)
                    if (_isLoading) _buildAnimatedLoader(),
                    const SizedBox(height: 20),
                    // 안내 텍스트 (애니메이션 적용)
                    if (_showTapText) _buildAnimatedTapText(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _letterAnimation,
            builder: (context, child) {
              final letterDelay = _letterDelays[index];
              final letterProgress = (_letterAnimation.value - letterDelay).clamp(0.0, 1.0);
              
              return Transform.translate(
                offset: Offset(0, 20 * (1 - letterProgress)),
                child: Opacity(
                  opacity: letterProgress,
                  child: Text(
                    'ilosi'[index],
                    style: TextStyle(
                      fontSize: 80,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF00FFFF),
                      letterSpacing: 8.0,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 20 * _glowAnimation.value,
                        ),
                        Shadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.6 * _glowAnimation.value),
                          blurRadius: 10 * _glowAnimation.value,
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
    );
  }
  
  Widget _buildAnimatedLoader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            const Color(0xFF00FFFF).withOpacity(_glowAnimation.value),
          ),
          strokeWidth: 3,
        ),
      ),
    );
  }
  
  Widget _buildAnimatedTapText() {
    return FadeTransition(
      opacity: _tapTextAnimation,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - _tapTextAnimation.value)),
        child: Text(
          '터치하여 시작',
          style: TextStyle(
            color: const Color(0xFF00FFFF).withOpacity(0.6 * _tapTextAnimation.value),
            fontSize: 16,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w300,
            shadows: [
              Shadow(
                color: const Color(0xFF00FFFF).withOpacity(0.3 * _tapTextAnimation.value),
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 