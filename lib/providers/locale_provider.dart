import 'package:flutter/material.dart';

/// 앱 전체 언어(로케일) 상태를 관리하는 Provider
class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('ko'); // 기본값: 한국어
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
} 