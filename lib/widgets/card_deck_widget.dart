import 'package:flutter/material.dart';
import 'dart:math';

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

  const CardDeckWidget({
    super.key,
    required this.remainingCards,
    this.maxDeckView = 10,
    required this.cardBackImage,
    required this.emptyDeckImage,
    this.controller,
    this.onFlipComplete,
    this.showCountLabel = true,
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
          Image.asset(widget.emptyDeckImage, width: 72, height: 108, fit: BoxFit.contain),
          if (widget.showCountLabel)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('남은장: 0', style: TextStyle(color: Colors.white)),
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48 + (visibleCount - 1) * 6.0,
          height: 72 + (visibleCount - 1) * 3.0,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              for (int i = 0; i < visibleCount - (isFlipping ? 1 : 0); i++)
                Positioned(
                  left: i * 6.0,
                  top: i * 3.0,
                  child: AnimatedBuilder(
                    animation: _drawController,
                    builder: (context, child) {
                      final drawProgress = _drawController.value;
                      final isTopCard = i == visibleCount - 1;
                      final offset = isTopCard && isDrawing ? drawProgress * 20 : 0.0;
                      return Transform.translate(
                        offset: Offset(0, -offset),
                        child: Transform.rotate(
                          angle: (i % 2 == 0 ? -1 : 1) * 0.03,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
                            ),
                            child: Image.asset(widget.cardBackImage, width: 48, height: 72, fit: BoxFit.contain),
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
                      left: (visibleCount - 1) * 6.0,
                      top: (visibleCount - 1) * 3.0,
                      child: Transform.translate(
                        offset: Offset(0, -20 * sin(_flipController.value * pi)),
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
                              width: 48,
                              height: 72,
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