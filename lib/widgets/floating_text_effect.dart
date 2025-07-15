import 'package:flutter/material.dart';

// 간단한 텍스트 이펙트: 지정 좌표에 텍스트를 표시하고 서서히 사라짐
class FloatingTextEffect extends StatefulWidget {
  final String text;
  final Offset position;
  final Duration duration;
  final VoidCallback? onComplete;
  final Color color;

  const FloatingTextEffect({
    super.key,
    required this.text,
    required this.position,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
    this.color = Colors.white,
  });

  @override
  State<FloatingTextEffect> createState() => _FloatingTextEffectState();
}

class _FloatingTextEffectState extends State<FloatingTextEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration)..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(_fade);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
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
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: ReverseAnimation(_fade), // 시작 1 → 0
        child: ScaleTransition(
          scale: _scale,
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 