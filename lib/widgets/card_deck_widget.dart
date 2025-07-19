import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/sound_manager.dart';

class CardDeckController {
  VoidCallback? _flip;
  void flipCard() => _flip?.call();
}

class CardDeckWidget extends StatefulWidget {
  final int remainingCards;
  final int maxDeckView;
  final String cardBackImage;
  final String emptyDeckImage;
  final CardDeckController? controller;
  final VoidCallback? onFlipComplete;
  final bool showCountLabel;
  final double width; // 카드더미 가로 크기(반응형)
  final double height; // 카드더미 세로 크기(반응형)

  const CardDeckWidget({
    super.key,
    required this.remainingCards,
    this.maxDeckView = 10,
    required this.cardBackImage,
    required this.emptyDeckImage,
    this.controller,
    this.onFlipComplete,
    this.showCountLabel = true,
    this.width = 48,
    this.height = 72,
  });

  @override
  State<CardDeckWidget> createState() => _CardDeckWidgetState();
}

class _CardDeckWidgetState extends State<CardDeckWidget> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _drawController;
  bool isFlipping = false;
  bool showFront = false;
  bool isDrawing = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._flip = _startFlip;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isFlipping = false;
          showFront = false;
        });
        widget.onFlipComplete?.call();
      }
    });
    
    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isDrawing = false;
        });
      }
    });
  }

  void _startFlip() {
    if (isFlipping) return;
    SoundManager.instance.play(Sfx.cardFlip);
    setState(() {
      isFlipping = true;
      showFront = false;
    });
    _flipController.reset();
    _flipController.forward();
  }

  void _startDraw() {
    if (isDrawing) return;
    setState(() {
      isDrawing = true;
    });
    _drawController.reset();
    _drawController.forward();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = min(widget.maxDeckView, widget.remainingCards);
    if (widget.remainingCards == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 카드더미가 비었을 때도 반응형 크기 적용
          Image.asset(widget.emptyDeckImage, width: widget.width, height: widget.height, fit: BoxFit.contain),
          if (widget.showCountLabel)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('남은장: 0', style: TextStyle(color: Colors.white)),
            ),
        ],
      );
    }
    // 카드더미 전체 크기 계산 (겹침 포함)
    // 겹침 간격을 50% 더 촘촘하게 (0.125 → 0.0625, 0.042 → 0.021)
    final deckWidth = widget.width + (visibleCount - 1) * (widget.width * 0.0625);
    final deckHeight = widget.height + (visibleCount - 1) * (widget.height * 0.021);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: deckWidth,
          height: deckHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              for (int i = 0; i < visibleCount - (isFlipping ? 1 : 0); i++)
                // 겹침 간격을 50% 더 촘촘하게
                Positioned(
                  left: i * (widget.width * 0.0625),
                  top: i * (widget.height * 0.021),
                  child: AnimatedBuilder(
                    animation: _drawController,
                    builder: (context, child) {
                      final drawProgress = _drawController.value;
                      final isTopCard = i == visibleCount - 1;
                      final offset = isTopCard && isDrawing ? drawProgress * (widget.height * 0.28) : 0.0;
                      return Transform.translate(
                        offset: Offset(0, -offset),
                        child: Transform.rotate(
                          angle: (i % 2 == 0 ? -1 : 1) * 0.03,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
                            ),
                            child: Image.asset(widget.cardBackImage, width: widget.width, height: widget.height, fit: BoxFit.contain),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (isFlipping)
                AnimatedBuilder(
                  animation: _flipController,
                  builder: (context, child) {
                    final angle = _flipController.value * pi;
                    final isBack = angle < pi / 2 && !showFront;
                    return Positioned(
                      left: (visibleCount - 1) * (widget.width * 0.0625),
                      top: (visibleCount - 1) * (widget.height * 0.021),
                      child: Transform.translate(
                        offset: Offset(0, -(widget.height * 0.28) * sin(_flipController.value * pi)),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 2))],
                            ),
                            child: Image.asset(
                              isBack ? widget.cardBackImage : widget.emptyDeckImage,
                              width: widget.width,
                              height: widget.height,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        if (widget.showCountLabel)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('남은장: ${widget.remainingCards}', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
} 