import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedCardDeck extends StatefulWidget {
  final int cardCount;
  final String backImage;
  final VoidCallback? onTap;
  final bool isInteractive;
  final double width;
  final double height;

  const AnimatedCardDeck({
    super.key,
    required this.cardCount,
    required this.backImage,
    this.onTap,
    this.isInteractive = true,
    this.width = 72,
    this.height = 108,
  });

  @override
  State<AnimatedCardDeck> createState() => _AnimatedCardDeckState();
}

class _AnimatedCardDeckState extends State<AnimatedCardDeck>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _hoverController;
  late AnimationController _tensionController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _tensionAnimation;
  
  bool _isHovered = false;
  bool _isTensionMode = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _tensionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _tensionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tensionController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _hoverController.dispose();
    _tensionController.dispose();
    super.dispose();
  }

  void _startShake() {
    _shakeController.reset();
    _shakeController.forward();
  }

  void _startTension() {
    _isTensionMode = true;
    _tensionController.repeat(reverse: true);
  }

  void _stopTension() {
    _isTensionMode = false;
    _tensionController.stop();
    _tensionController.reset();
  }

  @override
  Widget build(BuildContext context) {
    // 10장 이상이면 10장만, 10장 미만이면 남은 카드 수만큼만 시각적으로 표현
    final visibleCount = widget.cardCount >= 10 ? 10 : widget.cardCount;
    final deckHeight = widget.height + (visibleCount - 1) * 3.0;
    final deckWidth = widget.width + (visibleCount - 1) * 2.0;
    
    return MouseRegion(
      onEnter: (_) {
        if (widget.isInteractive) {
          setState(() => _isHovered = true);
          _hoverController.forward();
        }
      },
      onExit: (_) {
        if (widget.isInteractive) {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _shakeAnimation,
            _hoverAnimation,
            _tensionAnimation,
          ]),
          builder: (context, child) {
            final shakeOffset = _shakeAnimation.value * 2 * sin(_shakeAnimation.value * 10 * pi);
            final hoverOffset = _hoverAnimation.value * -5;
            final tensionOffset = _tensionAnimation.value * 3 * sin(_tensionAnimation.value * 4 * pi);
            
            return Transform.translate(
              offset: Offset(
                shakeOffset + tensionOffset,
                hoverOffset,
              ),
              child: Container(
                width: deckWidth,
                height: deckHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < visibleCount; i++)
                      Positioned(
                        left: i * 2.0, // x축으로도 이동 (사선 효과)
                        top: i * 3.0,  // y축 이동
                        child: Transform.rotate(
                          angle: (_random.nextDouble() - 0.5) * 0.02,
                          child: Container(
                            width: widget.width,
                            height: widget.height,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                widget.backImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.cardCount > 0)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.cardCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// 긴장감 조성 효과
class TensionBuilder extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;

  const TensionBuilder({
    super.key,
    required this.child,
    this.isActive = false,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<TensionBuilder> createState() => _TensionBuilderState();
}

class _TensionBuilderState extends State<TensionBuilder>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(TensionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
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
        final shakeOffset = _shakeAnimation.value * 2 * sin(_shakeAnimation.value * 8 * pi);
        
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
} 