import 'package:flutter/material.dart';
import 'dart:math';

class CustomAnimatedScale extends StatelessWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const CustomAnimatedScale({
    super.key,
    required this.child,
    required this.scale,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: scale),
      duration: duration,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

class CustomAnimatedOpacity extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Duration duration;

  const CustomAnimatedOpacity({
    super.key,
    required this.child,
    required this.opacity,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: opacity),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

class CustomAnimatedPosition extends StatelessWidget {
  final Widget child;
  final Offset begin;
  final Offset end;
  final Duration duration;
  final Curve curve;

  const CustomAnimatedPosition({
    super.key,
    required this.child,
    required this.begin,
    required this.end,
    required this.duration,
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

// 카드 뒤집기 애니메이션 효과
class CardFlipAnimation extends StatefulWidget {
  final String backImage;
  final String frontImage;
  final VoidCallback? onComplete;
  final Duration duration;
  final bool withSound;

  const CardFlipAnimation({
    super.key,
    required this.backImage,
    required this.frontImage,
    this.onComplete,
    this.duration = const Duration(milliseconds: 800),
    this.withSound = true,
  });

  @override
  State<CardFlipAnimation> createState() => _CardFlipAnimationState();
}

class _CardFlipAnimationState extends State<CardFlipAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _bounceAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
    ));

    _bounceAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -10),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _flipAnimation.value * pi;
        final isBack = angle < pi / 2;
        
        return Transform.translate(
          offset: _bounceAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Container(
                width: 72,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    isBack ? widget.backImage : widget.frontImage,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 카드 뒤집기 + 이동 애니메이션 (AI 카드용)
class CardFlipMoveAnimation extends StatefulWidget {
  final String backImage;
  final String frontImage;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  final Duration duration;

  const CardFlipMoveAnimation({
    super.key,
    required this.backImage,
    required this.frontImage,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<CardFlipMoveAnimation> createState() => _CardFlipMoveAnimationState();
}

class _CardFlipMoveAnimationState extends State<CardFlipMoveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _moveAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _flipAnimation.value * pi;
        final isBack = angle < pi / 2;
        
        return Positioned(
          left: _moveAnimation.value.dx,
          top: _moveAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Container(
                width: 72,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(4, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    isBack ? widget.backImage : widget.frontImage,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 카드 이동 애니메이션 (더미에서 필드로)
class CardMoveAnimation extends StatefulWidget {
  final String cardImage;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  final Duration duration;
  final bool withTrail;

  const CardMoveAnimation({
    super.key,
    required this.cardImage,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 600),
    this.withTrail = true,
  });

  @override
  State<CardMoveAnimation> createState() => _CardMoveAnimationState();
}

class _CardMoveAnimationState extends State<CardMoveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  final List<Offset> _trailPositions = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _moveAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });

    // 트레일 효과를 위한 포지션 기록
    _controller.addListener(() {
      if (widget.withTrail && _controller.value % 0.1 < 0.05) {
        _trailPositions.add(_moveAnimation.value);
        if (_trailPositions.length > 5) {
          _trailPositions.removeAt(0);
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 트레일 효과
        if (widget.withTrail)
          ..._trailPositions.map((position) => Positioned(
            left: position.dx,
            top: position.dy,
            child: Opacity(
              opacity: 0.3,
              child: Transform.scale(
                scale: 0.8,
                child: Image.asset(
                  widget.cardImage,
                  width: 72,
                  height: 108,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          )),
        
        // 메인 카드
        Positioned(
          left: _moveAnimation.value.dx,
          top: _moveAnimation.value.dy,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 72,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(4, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    widget.cardImage,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 특수 효과 애니메이션 (뻑, 따닥 등)
class SpecialEffectAnimation extends StatefulWidget {
  final String effectType; // 'ppeok', 'ttak', 'bomb', 'chok'
  final VoidCallback? onComplete;
  final Duration duration;

  const SpecialEffectAnimation({
    super.key,
    required this.effectType,
    this.onComplete,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<SpecialEffectAnimation> createState() => _SpecialEffectAnimationState();
}

class _SpecialEffectAnimationState extends State<SpecialEffectAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildEffectWidget() {
    switch (widget.effectType) {
      case 'ppeok':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Text(
            '뻑!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'ttak':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Text(
            '따닥!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'bomb':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Text(
            '폭탄!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'chok':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Text(
            '쪽!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: _buildEffectWidget(),
            ),
          ),
        );
      },
    );
  }
}

// 카드 획득 애니메이션
class CardCaptureAnimation extends StatefulWidget {
  final List<String> cardImages;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  final Duration duration;

  const CardCaptureAnimation({
    super.key,
    required this.cardImages,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<CardCaptureAnimation> createState() => _CardCaptureAnimationState();
}

class _CardCaptureAnimationState extends State<CardCaptureAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _moveAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: widget.cardImages.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;
          return Positioned(
            left: index * 20.0,
            child: Image.asset(
              image,
              width: 72,
              height: 108,
              fit: BoxFit.contain,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 카드더미에서 필드로 이동하면서 뒤집는 애니메이션 (자연스러운 연출)
class CardDeckToFieldAnimation extends StatefulWidget {
  final String backImage;
  final String frontImage;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  final Duration duration;

  const CardDeckToFieldAnimation({
    super.key,
    required this.backImage,
    required this.frontImage,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<CardDeckToFieldAnimation> createState() => _CardDeckToFieldAnimationState();
}

class _CardDeckToFieldAnimationState extends State<CardDeckToFieldAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // 이동 애니메이션: 시작점에서 끝점으로
    _moveAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // 뒤집기 애니메이션: 이동 중간 지점에서 뒤집기 시작 (더 자연스러운 타이밍)
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
    ));

    // 크기 애니메이션: 시작할 때 약간 작게, 끝날 때 정상 크기
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 고도 애니메이션: 이동 중에 약간 위로 올라갔다가 내려옴
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _flipAnimation.value * pi;
        final isBack = angle < pi / 2;
        
        // 고도 계산: 이동 중에 약간 위로 올라갔다가 내려옴 (더 자연스러운 곡선)
        final elevation = sin(_elevationAnimation.value * pi) * 15.0;
        
        return Positioned(
          left: _moveAnimation.value.dx,
          top: _moveAnimation.value.dy - elevation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Container(
                width: 72,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(4, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    isBack ? widget.backImage : widget.frontImage,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 카드 내기 시 확대+들어올림 효과
class CardPlayAnimation extends StatefulWidget {
  final String cardImage;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  final Duration duration;

  const CardPlayAnimation({
    super.key,
    required this.cardImage,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<CardPlayAnimation> createState() => _CardPlayAnimationState();
}

class _CardPlayAnimationState extends State<CardPlayAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // 이동 애니메이션
    _moveAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // 확대 애니메이션: 시작할 때 확대, 끝날 때 정상 크기
    _scaleAnimation = Tween<double>(
      begin: 1.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // 고도 애니메이션: 시작할 때 위로 올라갔다가 내려옴
    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 고도 계산: 시작할 때 위로 올라갔다가 내려옴 (더 자연스러운 높이)
        final elevation = _elevationAnimation.value * 25.0;
        
        return Positioned(
          left: _moveAnimation.value.dx,
          top: _moveAnimation.value.dy - elevation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 72,
              height: 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.cardImage,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 