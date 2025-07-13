import 'package:flutter/material.dart';

class LobbyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double width;
  final double height;
  final double fontSize;
  final VoidCallback onPressed;
  final Color? color;

  const LobbyButton({
    super.key,
    required this.label,
    this.icon,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        icon: icon != null ? Icon(icon, size: fontSize * 1.2) : const SizedBox.shrink(),
        label: Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(height * 0.4)),
          elevation: 2,
        ),
        onPressed: onPressed,
      ),
    );
  }
} 