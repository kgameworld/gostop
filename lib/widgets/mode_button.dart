import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/sound_manager.dart';

class ModeButton extends StatefulWidget {
  final String label;
  final Color color;
  final String emojiIcon;
  final VoidCallback? onPressed;
  final double? fontSize; // 추가: 반응형 폰트 크기
  final double? height;
  final double? iconSize;
  const ModeButton({
    super.key,
    required this.label,
    required this.color,
    required this.emojiIcon,
    this.onPressed,
    this.fontSize,
    this.height,
    this.iconSize,
  });

  @override
  State<ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<ModeButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        SoundManager.instance.play(Sfx.buttonClick);
        widget.onPressed?.call();
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 120),
        tween: Tween(begin: 1.0, end: _pressed ? 0.96 : 1.0),
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((widget.height ?? 60) * 0.4),
          child: Stack(
            children: [
              // Glassmorphism blur layer
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  height: widget.height ?? 60,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular((widget.height ?? 60) * 0.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: (widget.height ?? 60) * 0.18,
                    horizontal: (widget.height ?? 60) * 0.22,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(widget.emojiIcon, style: TextStyle(fontSize: widget.iconSize ?? widget.fontSize ?? 28)),
                        SizedBox(height: (widget.height ?? 60) * 0.09),
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center, // 텍스트 중앙 정렬 추가
                          style: TextStyle(
                            fontSize: widget.fontSize ?? 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: (widget.height ?? 60) * 0.09),
                        Icon(Icons.chevron_right, size: widget.iconSize ?? 22, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 