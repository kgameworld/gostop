import 'package:flutter/material.dart';
import 'dart:math';

class DealAnimationWidget extends StatefulWidget {
  final int playerCount;
  final int handCardCount;
  final int fieldCardCount;
  final String backImage;
  final VoidCallback? onDealEnd;
  const DealAnimationWidget({
    super.key,
    required this.playerCount,
    required this.handCardCount,
    required this.fieldCardCount,
    required this.backImage,
    this.onDealEnd,
  });

  @override
  State<DealAnimationWidget> createState() => _DealAnimationWidgetState();
}

class _DealAnimationWidgetState extends State<DealAnimationWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDealEnd?.call();
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
    final size = MediaQuery.of(context).size;
    final deckPos = Offset(size.width / 2, size.height / 2);
    final handY = size.height * 0.85;
    final aiHandY = size.height * 0.15;
    final fieldY = size.height * 0.5;
    final cardW = 72.0;
    final cardH = 108.0;
    final handGap = 32.0;
    final fieldGap = 24.0;
    final aiGap = 32.0;
    final handCount = widget.handCardCount;
    final fieldCount = widget.fieldCardCount;
    final aiCount = widget.playerCount == 2 ? handCount : handCount;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 카드가 덱에서 손/필드로 날아가는 연출
        List<Widget> flyingCards = [];
        // 플레이어 손패
        for (int i = 0; i < handCount; i++) {
          final t = (_animation.value - i * 0.05).clamp(0.0, 1.0);
          final x = size.width / 2 + (i - handCount / 2) * handGap;
          final y = deckPos.dy + (handY - deckPos.dy) * t;
          flyingCards.add(
            Positioned(
              left: x - cardW / 2,
              top: y - cardH / 2,
              child: Opacity(
                opacity: t,
                child: Image.asset(widget.backImage, width: cardW, height: cardH),
              ),
            ),
          );
        }
        // AI 손패
        for (int i = 0; i < aiCount; i++) {
          final t = (_animation.value - i * 0.05).clamp(0.0, 1.0);
          final x = size.width / 2 + (i - aiCount / 2) * aiGap;
          final y = deckPos.dy + (aiHandY - deckPos.dy) * t;
          flyingCards.add(
            Positioned(
              left: x - cardW / 2,
              top: y - cardH / 2,
              child: Opacity(
                opacity: t,
                child: Image.asset(widget.backImage, width: cardW, height: cardH),
              ),
            ),
          );
        }
        // 필드 카드
        for (int i = 0; i < fieldCount; i++) {
          final t = (_animation.value - i * 0.03).clamp(0.0, 1.0);
          final x = size.width / 2 + (i - fieldCount / 2) * fieldGap;
          final y = deckPos.dy + (fieldY - deckPos.dy) * t;
          flyingCards.add(
            Positioned(
              left: x - cardW / 2,
              top: y - cardH / 2,
              child: Opacity(
                opacity: t,
                child: Image.asset(widget.backImage, width: cardW, height: cardH),
              ),
            ),
          );
        }
        return Stack(children: flyingCards);
      },
    );
  }
}
