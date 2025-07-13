import 'package:flutter/material.dart';
import '../screens/settings_page.dart';
import '../utils/sound_manager.dart';
import '../l10n/app_localizations.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// 공통 설정 다이얼로그 위젯
class SettingsDialog extends StatefulWidget {
  final String selectedLang;
  final ValueChanged<String> onLangChanged;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;
  final VoidCallback onLogout;
  const SettingsDialog({
    super.key,
    required this.selectedLang,
    required this.onLangChanged,
    required this.isMuted,
    required this.onMuteChanged,
    required this.onLogout,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _selectedLang;
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.selectedLang;
    _isMuted = widget.isMuted;
  }

  @override
  Widget build(BuildContext context) {
    final supportedLocales = const [Locale('en'), Locale('ko'), Locale('ja')];
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 다이얼로그 타이틀
              Row(
                children: [
                  const Icon(Icons.settings, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.settings, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 24),
              // 언어/음악을 2행 2열 테이블 구조로 정렬 (각 열 수직 정렬, ON/Mute 텍스트 제거)
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      // 언어 라벨(아이콘+텍스트)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.language, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            AutoSizeText(
                              AppLocalizations.of(context)!.language,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // 음악 라벨(아이콘+텍스트)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_note, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            AutoSizeText(
                              AppLocalizations.of(context)!.music,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      // 언어 드롭다운
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: DropdownButton<String>(
                            value: _selectedLang,
                            items: supportedLocales.map((locale) {
                              return DropdownMenuItem<String>(
                                value: locale.languageCode,
                                child: AutoSizeText(
                                  locale.languageCode == 'en' ? 'English' :
                                  locale.languageCode == 'ko' ? '한국어' :
                                  locale.languageCode == 'ja' ? '日本語' : locale.languageCode,
                                  maxLines: 1,
                                  minFontSize: 10,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) { 
                              if (val != null) {
                                setState(() => _selectedLang = val);
                                widget.onLangChanged(val);
                              }
                            },
                          ),
                        ),
                      ),
                      // 음악 스위치
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Switch(
                            value: !_isMuted,
                            onChanged: (val) {
                              setState(() => _isMuted = !val);
                              widget.onMuteChanged(!val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // 개인정보 관리 버튼 (너비 유동, overflow 방지)
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 120, maxWidth: 240), // 최소/최대 너비 지정
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.privacy_tip, color: Colors.white),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppLocalizations.of(context)!.privacyManagement,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // 좌우 패딩 추가
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 로그아웃 버튼 (너비 유동, overflow 방지)
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 120, maxWidth: 240),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppLocalizations.of(context)!.logout,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    ),
                    onPressed: widget.onLogout,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 공통 설정 다이얼로그를 띄우는 함수
Future<void> showCustomSettingsDialog(BuildContext context, {
  required String selectedLang,
  required ValueChanged<String> onLangChanged,
  required bool isMuted,
  required ValueChanged<bool> onMuteChanged,
  required VoidCallback onLogout,
}) {
  return showDialog(
    context: context,
    builder: (context) => SettingsDialog(
      selectedLang: selectedLang,
      onLangChanged: onLangChanged,
      isMuted: isMuted,
      onMuteChanged: onMuteChanged,
      onLogout: onLogout,
    ),
  );
} 