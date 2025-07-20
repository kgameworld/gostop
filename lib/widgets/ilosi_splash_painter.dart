import 'package:flutter/material.dart';

class IlosiSplashPainter extends CustomPainter {
  final Animation<double> animation;
  final double glowIntensity;
  
  IlosiSplashPainter({
    required this.animation,
    this.glowIntensity = 1.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 어두운 파란색 배경 (이미지와 동일한 색상)
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1a1a2e);
    canvas.drawRect(Offset.zero & size, backgroundPaint);
    
    // 배경 그라데이션 효과 추가
    _drawBackgroundGradient(canvas, size);
    
    // "ilosi" 텍스트 위치 계산
    final text = 'ilosi';
    final fontSize = size.width * 0.15;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 각 글자별로 개별 렌더링 (복잡한 효과를 위해)
    _drawIlosText(canvas, text, centerX, centerY, fontSize);
  }
  
  void _drawBackgroundGradient(Canvas canvas, Size size) {
    // 미묘한 그라데이션 효과로 깊이감 추가
    try {
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            const Color(0xFF1a1a2e).withOpacity(0.0),
            const Color(0xFF2a2a3e).withOpacity(0.3),
            const Color(0xFF1a1a2e).withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
      canvas.drawRect(Offset.zero & size, gradientPaint);
    } catch (e) {
      // 그라데이션 실패시 단색 배경으로 대체
      final fallbackPaint = Paint()
        ..color = const Color(0xFF1a1a2e);
      canvas.drawRect(Offset.zero & size, fallbackPaint);
    }
  }
  
  void _drawIlosText(Canvas canvas, String text, double centerX, double centerY, double fontSize) {
    final letters = text.split('');
    final letterWidth = fontSize * 0.6;
    final totalWidth = letters.length * letterWidth;
    final startX = centerX - totalWidth / 2;
    
    for (int i = 0; i < letters.length; i++) {
      final letter = letters[i];
      final x = startX + i * letterWidth;
      final y = centerY;
      
      _drawLetter(canvas, letter, x, y, fontSize, i);
    }
  }
  
  void _drawLetter(Canvas canvas, String letter, double x, double y, double fontSize, int index) {
    try {
      // 애니메이션 지연 효과
      final delay = index * 0.1;
      final animValue = (animation.value - delay).clamp(0.0, 1.0);
      
      if (animValue <= 0) return;
    
    // 1. 그림자 효과 (이미지의 부드러운 그림자)
    final shadowTextPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w300,
          color: Colors.black.withOpacity(0.3 * animValue),
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    shadowTextPainter.layout();
    shadowTextPainter.paint(canvas, Offset(x + 2, y + 2));
    
    // 2. 외부 글로우 효과 (이미지의 청록색 글로우)
    final outerGlowTextPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w300,
          color: const Color(0xFF00FFFF).withOpacity(0.4 * glowIntensity * animValue),
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    outerGlowTextPainter.layout();
    outerGlowTextPainter.paint(canvas, Offset(x, y));
    
    // 3. 내부 글로우 효과 (이미지의 흰색 글로우)
    final innerGlowTextPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w300,
          color: Colors.white.withOpacity(0.6 * glowIntensity * animValue),
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    innerGlowTextPainter.layout();
    innerGlowTextPainter.paint(canvas, Offset(x, y));
    
    // 4. 메인 텍스트 (이미지의 반투명 청록색)
    final mainTextPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w300,
          color: const Color(0xFF00FFFF).withOpacity(0.8 * animValue),
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    mainTextPainter.layout();
    mainTextPainter.paint(canvas, Offset(x, y));
    
    // 5. 하이라이트 효과 (이미지의 내부 반사)
    _drawHighlights(canvas, letter, x, y, fontSize, animValue);
    } catch (e) {
      // 오류 발생시 기본 텍스트만 그리기
      final fallbackTextPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w300,
            color: const Color(0xFF00FFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      fallbackTextPainter.layout();
      fallbackTextPainter.paint(canvas, Offset(x, y));
    }
  }
  
  Shader _createCrystalShader(double x, double y, double fontSize) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF00FFFF).withOpacity(0.9),
        const Color(0xFFE0FFFF).withOpacity(0.7),
        const Color(0xFF00FFFF).withOpacity(0.8),
        const Color(0xFFB0E0E6).withOpacity(0.6),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(x, y, fontSize, fontSize));
  }
  
  void _drawHighlights(Canvas canvas, String letter, double x, double y, double fontSize, double animValue) {
    // 내부 하이라이트 (이미지의 결정 내부 반사)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4 * animValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    // 각 글자별 특별한 하이라이트 위치
    final highlightOffset = _getHighlightOffset(letter, fontSize);
    
    final highlightTextPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize * 0.3,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w300,
          color: Colors.white.withOpacity(0.4 * animValue),
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    highlightTextPainter.layout();
    highlightTextPainter.paint(canvas, Offset(x + highlightOffset.dx, y + highlightOffset.dy));
  }
  
  Offset _getHighlightOffset(String letter, double fontSize) {
    switch (letter) {
      case 'i':
        return Offset(fontSize * 0.1, -fontSize * 0.2);
      case 'l':
        return Offset(fontSize * 0.15, -fontSize * 0.15);
      case 'o':
        return Offset(fontSize * 0.2, -fontSize * 0.1);
      case 's':
        return Offset(fontSize * 0.1, fontSize * 0.1);
      default:
        return Offset.zero;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is IlosiSplashPainter &&
           (oldDelegate.animation != animation ||
            oldDelegate.glowIntensity != glowIntensity);
  }
} 