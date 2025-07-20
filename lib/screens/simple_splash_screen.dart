import 'package:flutter/material.dart';

class SimpleSplashScreen extends StatefulWidget {
  const SimpleSplashScreen({super.key});

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _startAnimation();
  }
  
  void _startAnimation() async {
    await _controller.forward();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/lobby');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pushReplacementNamed('/lobby'),
        child: Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: Text(
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
              );
            },
          ),
        ),
      ),
    );
  }
} 