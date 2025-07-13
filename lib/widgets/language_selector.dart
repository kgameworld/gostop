import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  final List<Locale> supportedLocales;
  final Locale currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;
  final double? fontSize; // 반응형 폰트 크기 추가
  final double? iconSize; // 반응형 아이콘 크기 추가
  const LanguageSelector({
    super.key,
    required this.supportedLocales,
    required this.currentLocale,
    this.onLocaleChanged,
    this.fontSize,
    this.iconSize,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late Locale _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.currentLocale;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.fontSize ?? 14.0;
    final iconSize = widget.iconSize ?? 20.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (fontSize * 0.5).clamp(4.0, 8.0),
        vertical: (fontSize * 0.3).clamp(2.0, 6.0),
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: DropdownButton<Locale>(
        value: _selected,
        dropdownColor: Colors.white,
        iconEnabledColor: Colors.white,
        iconSize: iconSize,
        underline: const SizedBox(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
        items: widget.supportedLocales
            .map((locale) => DropdownMenuItem<Locale>(
                  value: locale,
                  child: Text(
                    _localeLabel(locale),
                    style: const TextStyle(color: Colors.black),
                  ),
                ))
            .toList(),
        onChanged: (locale) {
          if (locale == null) return;
          setState(() => _selected = locale);
          widget.onLocaleChanged?.call(locale);
        },
      ),
    );
  }

  String _localeLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      default:
        return locale.languageCode;
    }
  }
} 