import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardWidget extends StatelessWidget {
  final GoStopCard card;
  final bool showBack;
  final double width;
  final bool overlap;
  final bool highlight;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.card,
    this.showBack = false,
    this.width = 60,
    this.overlap = false,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      showBack ? 'assets/cards/back.png' : card.imageUrl,
      width: width,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: highlight ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: overlap
            ? Transform.translate(
                offset: const Offset(0, 0), // 겹치기
                child: image,
              )
            : Container(
                margin: const EdgeInsets.only(left: 4),
                child: image,
              ),
      ),
    );
  }
}
