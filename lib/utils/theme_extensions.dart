import 'package:flutter/material.dart';

extension ThemeExtensions on ThemeData {
  // 하이 컨트라스트 & 다크 테마 대응 색상들
  Color get accentRed {
    return brightness == Brightness.dark
        ? Colors.redAccent.shade200
        : Colors.red;
  }

  Color get accentOrange {
    return brightness == Brightness.dark
        ? Colors.orangeAccent.shade200
        : Colors.orange;
  }

  Color get accentYellow {
    return brightness == Brightness.dark
        ? Colors.yellowAccent.shade200
        : Colors.yellow;
  }

  Color get accentGreen {
    return brightness == Brightness.dark
        ? Colors.greenAccent.shade200
        : Colors.green;
  }

  Color get accentBlue {
    return brightness == Brightness.dark
        ? Colors.blueAccent.shade200
        : Colors.blue;
  }

  Color get accentPurple {
    return brightness == Brightness.dark
        ? Colors.purpleAccent.shade200
        : Colors.purple;
  }

  // 카드 관련 색상
  Color get cardBorderColor {
    return brightness == Brightness.dark
        ? Colors.grey.shade600
        : Colors.black;
  }

  Color get cardHighlightColor {
    return brightness == Brightness.dark
        ? Colors.amber.shade300
        : Colors.orange;
  }

  Color get cardBackgroundColor {
    return brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;
  }

  // 게임 보드 색상
  Color get gameBoardBackground {
    return brightness == Brightness.dark
        ? const Color(0xFF1a2f1a) // 어두운 녹색
        : const Color(0xFF2f4f2f); // 기존 녹색
  }

  Color get fieldCardBackground {
    return brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.white;
  }

  // 텍스트 색상
  Color get primaryTextColor {
    return brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color get secondaryTextColor {
    return brightness == Brightness.dark
        ? Colors.grey.shade300
        : Colors.grey.shade700;
  }

  // 효과 색상
  Color get glowColor {
    return brightness == Brightness.dark
        ? const Color(0xFFFF8A8A) // redAccent200
        : Colors.red;
  }

  Color get successColor {
    return brightness == Brightness.dark
        ? Colors.greenAccent.shade200
        : Colors.green;
  }

  Color get warningColor {
    return brightness == Brightness.dark
        ? Colors.orangeAccent.shade200
        : Colors.orange;
  }

  Color get errorColor {
    return brightness == Brightness.dark
        ? Colors.redAccent.shade200
        : Colors.red;
  }

  // 그림자 색상
  Color get shadowColor {
    return brightness == Brightness.dark
        ? Colors.black.withOpacity(0.6)
        : Colors.black.withOpacity(0.3);
  }

  // 오버레이 색상
  Color get overlayBackground {
    return brightness == Brightness.dark
        ? Colors.black.withOpacity(0.8)
        : Colors.black.withOpacity(0.5);
  }

  // 배지 색상
  Color get badgeBackground {
    return brightness == Brightness.dark
        ? Colors.blue.shade700
        : Colors.blue;
  }

  Color get badgeTextColor {
    return brightness == Brightness.dark
        ? Colors.white
        : Colors.white;
  }

  // 토스트 색상
  Color get toastBackground {
    return brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.black87;
  }

  Color get toastTextColor {
    return brightness == Brightness.dark
        ? Colors.white
        : Colors.white;
  }

  // 다이얼로그 색상
  Color get dialogBackground {
    return brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;
  }

  Color get dialogTextColor {
    return brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  // 버튼 색상
  Color get primaryButtonColor {
    return brightness == Brightness.dark
        ? Colors.blue.shade600
        : Colors.blue;
  }

  Color get secondaryButtonColor {
    return brightness == Brightness.dark
        ? Colors.grey.shade600
        : Colors.grey;
  }

  Color get dangerButtonColor {
    return brightness == Brightness.dark
        ? Colors.red.shade600
        : Colors.red;
  }

  Color get successButtonColor {
    return brightness == Brightness.dark
        ? Colors.green.shade600
        : Colors.green;
  }

  // 카드 타입별 색상
  Color getCardTypeColor(String cardType) {
    switch (cardType) {
      case '광':
        return brightness == Brightness.dark
            ? Colors.yellowAccent.shade200
            : Colors.yellow;
      case '띠':
        return brightness == Brightness.dark
            ? Colors.blueAccent.shade200
            : Colors.blue;
      case '동물':
        return brightness == Brightness.dark
            ? Colors.greenAccent.shade200
            : Colors.green;
      case '피':
        return brightness == Brightness.dark
            ? Colors.redAccent.shade200
            : Colors.red;
      default:
        return brightness == Brightness.dark
            ? Colors.grey.shade300
            : Colors.grey;
    }
  }

  // 점수별 색상
  Color getScoreColor(int score) {
    if (score >= 7) {
      return brightness == Brightness.dark
          ? Colors.greenAccent.shade200
          : Colors.green;
    } else if (score >= 3) {
      return brightness == Brightness.dark
          ? Colors.orangeAccent.shade200
          : Colors.orange;
    } else {
      return brightness == Brightness.dark
          ? Colors.grey.shade300
          : Colors.grey;
    }
  }

  // 상태별 색상
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'go':
        return brightness == Brightness.dark
            ? Colors.orangeAccent.shade200
            : Colors.orange;
      case 'stop':
        return brightness == Brightness.dark
            ? Colors.redAccent.shade200
            : Colors.red;
      case 'bust':
        return brightness == Brightness.dark
            ? Colors.redAccent.shade200
            : Colors.red;
      case 'victory':
        return brightness == Brightness.dark
            ? Colors.greenAccent.shade200
            : Colors.green;
      default:
        return brightness == Brightness.dark
            ? Colors.grey.shade300
            : Colors.grey;
    }
  }
} 