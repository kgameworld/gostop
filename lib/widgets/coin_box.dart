import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CoinBox extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;
  final double size;
  const CoinBox({
    super.key,
    required this.coins,
    this.onTap,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withOpacity(0.7),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/icons/coin.png', width: size, height: size),
                Shimmer.fromColors(
                  baseColor: Colors.transparent,
                  highlightColor: Colors.white.withOpacity(0.7),
                  period: const Duration(seconds: 2),
                  child: Image.asset(
                    'assets/icons/coin.png',
                    width: size,
                    height: size,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Text('$coins', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
    );
  }
} 