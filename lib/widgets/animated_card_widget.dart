import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/card_model.dart';
import 'card_widget.dart';

class AnimatedCardWidget extends StatefulWidget {
  final GoStopCard card;
  final bool isFaceUp;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  final Duration duration;
  final bool withTrail;

  const AnimatedCardWidget({
    super.key,
    required this.card,
    required this.isFaceUp,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 800),
    this.withTrail = true,
  });

  @override
  State<AnimatedCardWidget> createState() => _AnimatedCardWidgetState();
}

class _AnimatedCardWidgetState extends State<AnimatedCardWidget>
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
                child: CardWidget(
                  imageUrl: widget.isFaceUp ? widget.card.imageUrl : 'assets/cards/back.png',
                  isFaceDown: !widget.isFaceUp,
                  width: 72,
                  height: 108,
                ),
              ),
            ),
          )),
        
        // 메인 카드 (카드더미의 실제 카드 이미지 사용)
        Transform.translate(
          offset: Offset(
            _moveAnimation.value.dx + _bounceAnimation.value.dx, 
            _moveAnimation.value.dy + _bounceAnimation.value.dy
          ),
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
                child: CardWidget(
                  imageUrl: widget.isFaceUp ? widget.card.imageUrl : 'assets/cards/back.png',
                  isFaceDown: !widget.isFaceUp,
                  width: 72,
                  height: 108,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 