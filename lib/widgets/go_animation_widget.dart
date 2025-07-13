import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../utils/sound_manager.dart';

class GoAnimationWidget extends StatefulWidget {
  final int goCount;
  final VoidCallback? onComplete;

  const GoAnimationWidget({
    Key? key,
    required this.goCount,
    this.onComplete,
  }) : super(key: key);

  @override
  State<GoAnimationWidget> createState() => _GoAnimationWidgetState();
}

class _GoAnimationWidgetState extends State<GoAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _scaleController;
  AnimationController? _shakeController;
  AnimationController? _particleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  Animation<double>? _shakeAnimation;
  Animation<double>? _particleAnimation;

  List<Particle> _particles = [];
  bool _showParticles = false;
  bool _showFlash = false;
  bool _showRipple = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    // 메인 애니메이션 컨트롤러
    _mainController = AnimationController(
      duration: _getAnimationDuration(),
      vsync: this,
    );

    // 스케일 애니메이션
    _scaleController = AnimationController(
      duration: Duration(milliseconds: _getScaleDuration()),
      vsync: this,
    );

    // 흔들림 애니메이션 (3GO 이상)
    if (widget.goCount >= 3) {
      _shakeController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
    }

    // 파티클 애니메이션 (4GO 이상)
    if (widget.goCount >= 4) {
      _particleController = AnimationController(
        duration: Duration(milliseconds: widget.goCount >= 5 ? 3000 : 2000),
        vsync: this,
      );
      _generateParticles();
    }

    _setupAnimations();
  }

  void _setupAnimations() {
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      reverseCurve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    if (widget.goCount >= 3) {
      _shakeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _shakeController!,
        curve: Curves.elasticInOut,
      ));
    }

    if (widget.goCount >= 4) {
      _particleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(_particleController!);
    }
  }

  void _startAnimation() {
    // GO 사운드 재생
    _playGoSound();
    
    // 진동 피드백
    if (widget.goCount == 1) {
      HapticFeedback.lightImpact();
    } else if (widget.goCount >= 6) {
      HapticFeedback.heavyImpact();
    }
    
    _mainController.forward();
    _scaleController.forward();
    
    // 2GO: ripple 효과
    if (widget.goCount >= 2) {
      setState(() => _showRipple = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() => _showRipple = false);
      });
    }
    
    // 3GO: 강한 플래시 효과
    if (widget.goCount >= 3) {
      setState(() => _showFlash = true);
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => _showFlash = false);
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        _shakeController?.forward();
      });
    }
    
    if (widget.goCount >= 4) {
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() => _showParticles = true);
        _particleController?.forward();
      });
    }

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete?.call();
        });
      }
    });
  }

  void _playGoSound() {
    switch (widget.goCount) {
      case 1:
        SoundManager.instance.play(Sfx.buttonClick);
        break;
      case 2:
        SoundManager.instance.play(Sfx.cardPlay);
        break;
      case 3:
        SoundManager.instance.play(Sfx.cardOverlap);
        break;
      case 4:
        SoundManager.instance.play(Sfx.bonusCard);
        break;
      case 5:
        SoundManager.instance.play(Sfx.goStop);
        break;
      case 6:
        SoundManager.instance.play(Sfx.winFanfare);
        break;
      default:
        SoundManager.instance.play(Sfx.buttonClick);
    }
  }

  void _generateParticles() {
    _particles.clear();
    final random = math.Random();
    final particleCount = widget.goCount >= 5 ? 40 : 20; // 5GO 이상에서는 더 많은 파티클
    
    for (int i = 0; i < particleCount; i++) {
      _particles.add(Particle(
        x: random.nextDouble() * 400 - 200,
        y: random.nextDouble() * 400 - 200,
        vx: (random.nextDouble() - 0.5) * (widget.goCount >= 5 ? 8 : 4), // 5GO 이상에서는 더 빠른 파티클
        vy: (random.nextDouble() - 0.5) * (widget.goCount >= 5 ? 8 : 4),
        color: _getParticleColor(),
        size: random.nextDouble() * (widget.goCount >= 5 ? 8 : 4) + 2,
      ));
    }
  }

  Color _getParticleColor() {
    switch (widget.goCount) {
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      case 6:
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  Duration _getAnimationDuration() {
    switch (widget.goCount) {
      case 1:
        return const Duration(milliseconds: 800);
      case 2:
        return const Duration(milliseconds: 1000);
      case 3:
        return const Duration(milliseconds: 1200);
      case 4:
        return const Duration(milliseconds: 1500);
      case 5:
        return const Duration(milliseconds: 1800);
      case 6:
        return const Duration(milliseconds: 3500); // 6GO는 슬로우모션으로 더 길게
      default:
        return const Duration(milliseconds: 1000);
    }
  }

  int _getScaleDuration() {
    switch (widget.goCount) {
      case 1:
        return 400;
      case 2:
        return 500;
      case 3:
        return 600;
      case 4:
        return 700;
      case 5:
        return 800;
      case 6:
        return 1000;
      default:
        return 500;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scaleController.dispose();
    _shakeController?.dispose();
    _particleController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Stack(
          children: [
            // 배경 오버레이 (5GO 이상)
            if (widget.goCount >= 5)
              AnimatedOpacity(
                opacity: _opacityAnimation.value * 0.3,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black,
                ),
              ),
            
            // 2GO ripple 효과
            if (_showRipple && widget.goCount >= 2)
              Center(
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Container(
                      width: 200 + _mainController.value * 100,
                      height: 200 + _mainController.value * 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3 - _mainController.value * 0.3),
                          width: 3,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // 파티클 효과 (4GO 이상, 텍스트 뒤에 배치)
            if (_showParticles && widget.goCount >= 4)
              ..._particles.map((particle) => _buildParticle(particle)),
            
            // 3GO 플래시 효과 (텍스트 뒤에 배치)
            if (_showFlash && widget.goCount >= 3)
              Center(
                child: AnimatedOpacity(
                  opacity: _showFlash ? 0.6 : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            
            // 메인 GO 텍스트 (3D 방향성 추가)
            Center(
              child: Transform.translate(
                offset: Offset(
                  widget.goCount >= 3 ? math.sin((_shakeAnimation?.value ?? 0) * 10) * 5 : 0,
                  _slideAnimation.value.dy * 100,
                ),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _get3DRotationAngle(),
                    child: AnimatedOpacity(
                      opacity: _opacityAnimation.value,
                      duration: const Duration(milliseconds: 300),
                      child: _buildGoText(),
                    ),
                  ),
                ),
              ),
            ),
            
            // 6GO 중심 폭발 효과
            if (widget.goCount >= 6)
              Center(
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Container(
                      width: 50 + _mainController.value * 200,
                      height: 50 + _mainController.value * 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.yellow.withOpacity(0.8 - _mainController.value * 0.8),
                            Colors.orange.withOpacity(0.6 - _mainController.value * 0.6),
                            Colors.red.withOpacity(0.4 - _mainController.value * 0.4),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGoText() {
    final text = _getGoText();
    final style = _getTextStyle();
    
    Widget textWidget = Text(
      text,
      style: style,
      textAlign: TextAlign.center,
    );

    // 3GO 이상: 글로우 효과 (5GO 이상에서만 적용)
    if (widget.goCount >= 5) {
      textWidget = ShaderMask(
        shaderCallback: (bounds) => RadialGradient(
          colors: _getGlowColors(),
          stops: _getGlowStops(),
        ).createShader(bounds),
        child: textWidget,
      );
    }

    // 3D 효과 적용
    textWidget = _build3DText(text, style);

    return textWidget;
  }

  Widget _build3DText(String text, TextStyle style) {
    return Stack(
      children: [
        // 뒤쪽 그림자 (진한 검정, 큰 오프셋)
        Transform.translate(
          offset: const Offset(4, 4),
          child: Text(
            text,
            style: style.copyWith(
              color: Colors.black.withOpacity(0.8),
              fontSize: style.fontSize! - 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // 중간 그림자 (회색톤, 작은 오프셋)
        Transform.translate(
          offset: const Offset(2, 2),
          child: Text(
            text,
            style: style.copyWith(
              color: Colors.grey.shade700.withOpacity(0.6),
              fontSize: style.fontSize! - 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // 메인 텍스트 (그라데이션 + 하이라이트)
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getTextGradientColors(),
            stops: const [0.0, 0.7, 1.0],
          ).createShader(bounds),
          child: Text(
            text,
            style: style.copyWith(
              color: Colors.white, // ShaderMask 때문에 흰색으로 설정
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // 하얀색 하이라이트 stroke
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Color> _getTextGradientColors() {
    switch (widget.goCount) {
      case 1:
        return [Colors.yellow.shade300, Colors.yellow.shade600, Colors.yellow.shade800];
      case 2:
        return [Colors.orange.shade300, Colors.orange.shade600, Colors.orange.shade800];
      case 3:
        return [Colors.red.shade300, Colors.red.shade600, Colors.red.shade800];
      case 4:
        return [Colors.deepOrange.shade300, Colors.deepOrange.shade600, Colors.deepOrange.shade800];
      case 5:
        return [Colors.amber.shade300, Colors.amber.shade600, Colors.amber.shade800];
      case 6:
        return [Colors.yellow.shade200, Colors.orange.shade400, Colors.red.shade600];
      default:
        return [Colors.white, Colors.grey.shade300, Colors.grey.shade600];
    }
  }

  double _get3DRotationAngle() {
    // GO 단계별로 다른 3D 회전 각도 적용
    switch (widget.goCount) {
      case 1:
        return 0.02; // 살짝 기울어짐
      case 2:
        return 0.03;
      case 3:
        return 0.04;
      case 4:
        return 0.05;
      case 5:
        return 0.06;
      case 6:
        return 0.08; // 가장 강한 기울어짐
      default:
        return 0.02;
    }
  }

  String _getGoText() {
    // goCount가 0 이하인 경우 처리하지 않음
    if (widget.goCount <= 0) {
      return "GO!";
    }
    
    switch (widget.goCount) {
      case 1:
        return "1 GO!";
      case 2:
        return "2 GO!";
      case 3:
        return "3 GO!";
      case 4:
        return "4 GO!!";
      case 5:
        return "5 GO!!!";
      case 6:
        return "ULTIMATE\n6 GO!!!";
      default:
        return "${widget.goCount} GO!";
    }
  }

  TextStyle _getTextStyle() {
    final baseStyle = TextStyle(
      fontSize: _getFontSize(),
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
      decoration: TextDecoration.none, // 밑줄 명시적 제거
    );

    switch (widget.goCount) {
      case 1:
        return baseStyle.copyWith(
          color: Colors.yellow.shade600,
          fontSize: 48,
          shadows: [
            Shadow(
              offset: const Offset(2, 2),
              blurRadius: 4,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        );
      case 2:
        return baseStyle.copyWith(
          color: Colors.orange.shade600,
          fontSize: 52,
          shadows: [
            Shadow(
              offset: const Offset(2, 2),
              blurRadius: 4,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        );
      case 3:
        return baseStyle.copyWith(
          color: Colors.red.shade900,
          fontSize: 56,
          shadows: [
            Shadow(
              offset: const Offset(3, 3),
              blurRadius: 6,
              color: Colors.black.withOpacity(0.9),
            ),
          ],
        );
      case 4:
        return baseStyle.copyWith(
          color: Colors.deepOrange.shade800,
          fontSize: 60,
          shadows: [
            Shadow(
              offset: const Offset(3, 3),
              blurRadius: 6,
              color: Colors.black.withOpacity(0.9),
            ),
          ],
        );
      case 5:
        return baseStyle.copyWith(
          color: Colors.amber.shade600,
          fontSize: 64,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              offset: const Offset(2, 2),
              blurRadius: 4,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        );
      case 6:
        return baseStyle.copyWith(
          color: Colors.yellow.shade600,
          fontSize: 72,
          fontWeight: FontWeight.w900,
          height: 1.2,
          shadows: [
            Shadow(
              offset: const Offset(2, 2),
              blurRadius: 4,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        );
      default:
        return baseStyle.copyWith(
          color: Colors.white,
          fontSize: 48,
        );
    }
  }

  double _getFontSize() {
    switch (widget.goCount) {
      case 1:
        return 48;
      case 2:
        return 52;
      case 3:
        return 56;
      case 4:
        return 60;
      case 5:
        return 64;
      case 6:
        return 72;
      default:
        return 48;
    }
  }

  List<Color> _getGlowColors() {
    switch (widget.goCount) {
      case 3:
        return [Colors.red, Colors.orange, Colors.yellow, Colors.red];
      case 4:
        return [Colors.deepOrange, Colors.red, Colors.pink, Colors.deepOrange];
      case 5:
        return [Colors.amber, Colors.yellow, Colors.orange, Colors.amber];
      case 6:
        return [Colors.yellow, Colors.orange, Colors.red, Colors.pink, Colors.purple, Colors.yellow];
      default:
        return [Colors.white, Colors.grey, Colors.white];
    }
  }

  List<double> _getGlowStops() {
    switch (widget.goCount) {
      case 3:
        return [0.0, 0.33, 0.66, 1.0]; // 4개 색상에 맞는 정지점
      case 4:
        return [0.0, 0.33, 0.66, 1.0]; // 4개 색상에 맞는 정지점
      case 5:
        return [0.0, 0.33, 0.66, 1.0]; // 4개 색상에 맞는 정지점
      case 6:
        return [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]; // 6개 색상에 맞는 정지점
      default:
        return [0.0, 0.5, 1.0]; // 3개 색상에 맞는 정지점
    }
  }

  Widget _buildParticle(Particle particle) {
    return AnimatedBuilder(
      animation: _particleAnimation ?? const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        final progress = _particleAnimation?.value ?? 0;
        final x = particle.x + particle.vx * progress * 100;
        final y = particle.y + particle.vy * progress * 100;
        final opacity = 1.0 - progress;
        
        return Positioned(
          left: MediaQuery.of(context).size.width / 2 + x,
          top: MediaQuery.of(context).size.height / 2 + y,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: particle.size,
              height: particle.size,
              decoration: BoxDecoration(
                color: particle.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: particle.color.withOpacity(0.8),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
} 