import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/card_model.dart';

class CardWidget extends StatefulWidget {
  final String imageUrl;
  final bool isFaceDown;
  final VoidCallback? onTap;
  final bool highlight;
  final double width;
  final double height;
  final bool dimmed; // 추가: 어둡게 처리 여부
  final bool bombHighlight; // 폭탄 이글거림
  final bool ppeokHighlight; // 뻑 이글거림
  final bool bonusHighlight; // 보너스 이글거림
  const CardWidget({super.key, required this.imageUrl, this.isFaceDown = false, this.onTap, this.highlight = false, this.width = 48, this.height = 72, this.dimmed = false, this.bombHighlight = false, this.ppeokHighlight = false, this.bonusHighlight = false});

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    // 이글거림 애니메이션: 1초 반복, 0.5~1.0 사이로 밝기 변화
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    if (_shouldAnimate()) {
      _glowCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // highlight 상태가 바뀌면 애니메이션 on/off
    if (_shouldAnimate()) {
      _glowCtrl.repeat(reverse: true);
    } else {
      _glowCtrl.stop();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  bool _shouldAnimate() => widget.bombHighlight || widget.ppeokHighlight || widget.bonusHighlight;

  List<BoxShadow>? _buildGlowShadow() {
    final glow = _glowAnim.value;
    if (widget.bombHighlight) {
      // 폭탄: 더 진한 주황/빨강 이글거림 (넓고 강하게)
      return [
        BoxShadow(
          color: Colors.deepOrange.withOpacity(0.75 + 0.2 * glow),
          blurRadius: 8.0 + 8.0 * glow,
          spreadRadius: 1.5 + 1.5 * glow,
        ),
        BoxShadow(
          color: Colors.redAccent.withOpacity(0.45 + 0.25 * glow),
          blurRadius: 14.0 + 6.0 * glow,
          spreadRadius: 0.8 + 1.2 * glow,
        ),
      ]; 
    } else if (widget.ppeokHighlight) {
      // 뻑: 파랑/시안 이글거림 (기존과 동일)
      return [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.4 + 0.3 * glow),
          blurRadius: 6.0 + 5.0 * glow,
          spreadRadius: 1.0 + 0.7 * glow,
        ),
        BoxShadow(
          color: Colors.cyan.withOpacity(0.2 + 0.3 * glow),
          blurRadius: 10.0 + 5.0 * glow,
          spreadRadius: 0.5 + 0.7 * glow,
        ),
      ]; 
    } else if (widget.bonusHighlight) {
      // 보너스: 더 밝고 넓은 노란색 이글거림 (폭탄과 동일 범위)
      return [
        BoxShadow(
          color: Colors.yellowAccent.withOpacity(0.55 + 0.25 * glow),
          blurRadius: 8.0 + 8.0 * glow,
          spreadRadius: 1.5 + 1.5 * glow,
        ),
        BoxShadow(
          color: Colors.yellow.withOpacity(0.35 + 0.25 * glow),
          blurRadius: 14.0 + 6.0 * glow,
          spreadRadius: 0.8 + 1.2 * glow,
        ),
      ]; 
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.highlight ? 1.63 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowCtrl,
          builder: (context, child) {
            return Container(
              width: widget.width,
              height: widget.height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: _buildGlowShadow(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1/1.63,
                      child: Image.asset(
                        widget.imageUrl,
                        width: widget.width,
                        height: widget.height,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (widget.dimmed)
                      AspectRatio(
                        aspectRatio: 1/1.63,
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
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
