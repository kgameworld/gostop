import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SafeSplashScreen extends StatefulWidget {
  const SafeSplashScreen({super.key});

  @override
  State<SafeSplashScreen> createState() => _SafeSplashScreenState();
}

class _SafeSplashScreenState extends State<SafeSplashScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  void _initializeApp() async {
    try {
      // 2초 대기 (스플래시 효과)
      await Future.delayed(const Duration(seconds: 2));
      
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: GestureDetector(
        onTap: () {
          // 터치하면 인증 상태에 따라 적절한 화면으로 이동
          _navigateToNextScreen();
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 텍스트
              Text(
                'ilosi',
                style: TextStyle(
                  fontSize: 80,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF00FFFF),
                  letterSpacing: 8.0,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00FFFF).withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // 로딩 인디케이터
              if (_isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFFF)),
                ),
              const SizedBox(height: 20),
              // 안내 텍스트
              Text(
                '터치하여 시작',
                style: TextStyle(
                  color: const Color(0xFF00FFFF).withOpacity(0.6),
                  fontSize: 16,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 