import 'package:flutter/material.dart';
import 'dart:math';
import 'l10n/app_localizations.dart';

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
  final bool _isFlipped = false;

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
        final isBack = angle < pi / 2;  // 수정: π/2 미만일 때 뒷면, 이상일 때 앞면 (카드더미에서 뒤집어서 나오는 경우)
        
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
                  child: Transform.scale(
                    scaleX: isBack ? 1.0 : -1.0,  // 앞면일 때 좌우 반전
                    child: Image.asset(
                      isBack ? widget.backImage : widget.frontImage,
                      fit: BoxFit.contain,
                    ),
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
  late Animation<Offset> _bounceAnimation;

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

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);

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
        final isBack = angle < pi / 2;  // 수정: π/2 미만일 때 뒷면, 이상일 때 앞면 (카드더미에서 뒤집어서 나오는 경우)
        
        return Transform.translate(
          offset: Offset(_moveAnimation.value.dx + _bounceAnimation.value.dx, _moveAnimation.value.dy + _bounceAnimation.value.dy),
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
  late Animation<Offset> _bounceAnimation;
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

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);

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
          ..._trailPositions.map((position) => Transform.translate(
            offset: Offset(position.dx, position.dy),
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
        Transform.translate(
          offset: Offset(_moveAnimation.value.dx + _bounceAnimation.value.dx, _moveAnimation.value.dy + _bounceAnimation.value.dy),
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
        // 뻑!: 네모 박스 없이 텍스트만 강조 효과로 표시
        return Text(
          '${AppLocalizations.of(context)!.ppeok}!',
          style: const TextStyle(
            color: Colors.red, // 강조 색상
            fontSize: 36, // 크기 키움
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black38,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'sseul':
        // 쓸: 파란색, 아래에서 위로 슬라이드, 그림자 강조
        return Text(
          '${AppLocalizations.of(context)!.sweep}!',
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.black26,
                offset: Offset(0, 4),
              ),
            ],
          ),
        );
      case 'bomb':
        // 폭탄: 보라/노랑, scale+shake 느낌, 그림자 강조
        return Text(
          AppLocalizations.of(context)!.bombStatus,
          style: const TextStyle(
            color: Colors.deepPurple,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 12,
                color: Colors.amber,
                offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 8,
                color: Colors.black38,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'ttak':
        // 따닥: 오렌지/노랑, 좌우로 튕기는 느낌, 그림자 강조
        return Text(
          '${AppLocalizations.of(context)!.doubleMatch}!',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.yellow,
                offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'chok':
        // 쪽: 네모 박스 없이 텍스트만 강조
        return Text(
          '${AppLocalizations.of(context)!.snap}!',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.white70,
                offset: Offset(0, 4),
              ),
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'godori':
        // 고도리: 네모 박스 없이 텍스트만 강조
        return Text(
          '${AppLocalizations.of(context)!.godori}!',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.amber,
                offset: Offset(0, -2),
              ),
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'piSteal':
        // 피 강탈: 네모 박스 없이 텍스트만 강조
        return Text(
          '피 강탈!',
          style: const TextStyle(
            color: Colors.pink,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.white70,
                offset: Offset(0, 4),
              ),
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'hongdan':
        // 홍단: 빨강+금색, 위에서 아래로 drop 느낌
        return Text(
          '홍단!',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.amber,
                offset: Offset(0, 4),
              ),
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'cheongdan':
        // 청단: 파랑+은색, 좌우 흔들림 느낌
        return Text(
          '청단!',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.white70,
                offset: Offset(-2, 2),
              ),
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'chodan':
        // 초단: 초록+금색, 아래에서 위로 튀는 느낌
        return Text(
          '초단!',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.amber,
                offset: Offset(0, -2),
              ),
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'ppeok_complete':
        // 뻑 완성: 빨강+노랑, scale+flash 느낌
        return Text(
          '뻑 완성!',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 14,
                color: Colors.yellow,
                offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 8,
                color: Colors.black38,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );
      case 'heundal':
        // 흔들: 주황+금색, 좌우 크게 흔들리는 느낌
        return Text(
          '${AppLocalizations.of(context)!.shake}!',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 12,
                color: Colors.amber,
                offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 8,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
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
  late Animation<Offset> _bounceAnimation;

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

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
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
    final stackChild = SizedBox.expand(
      child: Stack(
        children: widget.cardImages.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;
          return Transform.translate(
            offset: Offset(index * 20.0, 0),
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _moveAnimation.value + _bounceAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: stackChild,
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
  late Animation<Offset> _bounceAnimation;

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
        final isBack = angle < pi / 2;  // 수정: π/2 미만일 때 뒷면, 이상일 때 앞면 (카드더미에서 뒤집어서 나오는 경우)
        
        // 고도 계산: 이동 중에 약간 위로 올라갔다가 내려옴 (더 자연스러운 곡선)
        final elevation = sin(_elevationAnimation.value * pi) * 15.0;
        
        return Transform.translate(
          offset: Offset(_moveAnimation.value.dx + _bounceAnimation.value.dx, _moveAnimation.value.dy + _bounceAnimation.value.dy - elevation),
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
                  child: Transform.scale(
                    scaleX: isBack ? 1.0 : -1.0,  // 앞면일 때 좌우 반전
                    child: Image.asset(
                      isBack ? widget.backImage : widget.frontImage,
                      fit: BoxFit.contain,
                    ),
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
  late Animation<Offset> _bounceAnimation;

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

    // 확대 애니메이션: 40~60% 구간에서 1.0 -> 1.5, 이후 원래 크기로 복귀
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 2.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 2.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    // 고도 애니메이션: 시작할 때 위로 올라갔다가 내려옴
    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
        // 고도 계산: 시작할 때 위로 올라갔다가 내려옴 (더 자연스러운 높이)
        final elevation = _elevationAnimation.value * 25.0;
        
        return Transform.translate(
          offset: Offset(_moveAnimation.value.dx + _bounceAnimation.value.dx, _moveAnimation.value.dy + _bounceAnimation.value.dy - elevation),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 48,
              height: 72,
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

// AI 손패 카드 뒤집기 애니메이션
class AiHandCardAnimation extends StatefulWidget {
  final String backImage; // 뒷면 이미지
  final String frontImage; // 앞면 이미지
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  final Duration duration;
  final double cardWidth;
  final double cardHeight;

  const AiHandCardAnimation({
    super.key,
    required this.backImage,
    required this.frontImage,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 600),
    this.cardWidth = 48,
    this.cardHeight = 72,
  });

  @override
  State<AiHandCardAnimation> createState() => _AiHandCardAnimationState();
}

class _AiHandCardAnimationState extends State<AiHandCardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

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

    // 확대 애니메이션: 시작할 때 약간 확대
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 회전 애니메이션: 카드가 앞면으로 뒤집히는 효과
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180도 회전 (0.5 = 180도)
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
        // 회전 애니메이션 중간에 카드 이미지 변경 (0.25 = 90도 회전 시점)
        final isFlipped = _rotationAnimation.value >= 0.25;
        final cardImage = isFlipped ? widget.frontImage : widget.backImage;
        
        return Transform.translate(
          offset: _moveAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // 원근감
                ..rotateY(_rotationAnimation.value * 3.14159), // Y축 회전
              alignment: Alignment.center,
              child: Container(
                width: widget.cardWidth,
                height: widget.cardHeight,
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
                    cardImage,
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

// 간단한 카드 이동 애니메이션 (직선 이동, 크기 변화 없음, 바운스 없음)
class SimpleCardMoveAnimation extends StatefulWidget {
  final String cardImage;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  final Duration duration;
  // 카드 크기(획득 영역과 동일 크기로 맞춤)
  final double cardWidth;
  final double cardHeight;

  const SimpleCardMoveAnimation({
    super.key,
    required this.cardImage,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 500),
    this.cardWidth = 48,
    this.cardHeight = 72,
  });

  @override
  State<SimpleCardMoveAnimation> createState() => _SimpleCardMoveAnimationState();
}

class _SimpleCardMoveAnimationState extends State<SimpleCardMoveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // 직선 이동 애니메이션
    _moveAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // 자연스러운 직선 이동
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
        return Transform.translate(
          offset: _moveAnimation.value,
          child: Image.asset(
            widget.cardImage,
            width: widget.cardWidth,
            height: widget.cardHeight,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
} 