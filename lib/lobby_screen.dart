import 'dart:math';
import 'package:flutter/material.dart';
import 'adaptive_scaffold.dart';
import 'widgets/profile_card.dart';
import 'utils/coin_service.dart';
import 'utils/sound_manager.dart';
import 'screens/game_page.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/settings_dialog.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _coins = 0;
  final String nickname = 'User';
  final String avatarAsset = 'assets/avatars/default.png';
  final String countryCode = 'us';
  final int level = 1;
  final supportedLocales = const [Locale('en'), Locale('ko'), Locale('ja')];

  @override
  void initState() {
    super.initState();
    SoundManager.instance.playBgm('lobby', volume: 0.6);
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final c = await CoinService.instance.getCoins();
    if (mounted) setState(() => _coins = c);
  }

  @override
  void dispose() {
    SoundManager.instance.stopBgm();
    super.dispose();
  }

  void _ensureBgm() {
    if (!SoundManager.instance.isBgmPlaying && !SoundManager.instance.isBgmMuted) {
      SoundManager.instance.playBgm('lobby2', volume: 0.6);
    }
  }

  Future<void> _enterMatch(String mode) async {
    // 코인 차감 없이 바로 입장 (게스트/정식 계정 모두)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GamePage(mode: mode)),
    ).then((_) => _loadCoins());
  }

  void _openShop() {
    // 코인샵 화면으로 이동
    Navigator.pushNamed(context, '/shop');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final maxButtonWidth = 420.0;
    final buttonWidth = min(screenWidth * 0.7, maxButtonWidth);
    final buttonHeight = max(screenHeight * 0.08, 60.0);
    final buttonFontSize = max(min(screenWidth * 0.045, 28.0), 18.0);
    final moneyFontSize = max(min(screenWidth * 0.05, 32.0), 22.0);
    final iconSize = buttonHeight * 0.55;
    final goldColor = const Color(0xFFFFD700);
    final navyColor = const Color(0xFF2E3650);
    final profileCardScale = screenWidth < 900 ? 1.0 : 1.15;

    final localeProvider = Provider.of<LocaleProvider>(context);
    final selectedLang = localeProvider.locale.languageCode;

    // 배경 컨테이너가 화면 전체를 덮도록 최상위에 위치
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _ensureBgm,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/pink_glass_cards.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: AdaptiveScaffold(
          backgroundColor: Colors.transparent, // Scaffold가 배경 이미지를 덮지 않도록 투명 처리
          builder: (context, screenSize) {
            // SafeArea는 내부 내용만 감싸도록 위치 조정
            return SafeArea(
              child: Stack(
                children: [
                  // 메인 내용(ListView)
                  ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // 상단바: ProfileCard(머니 포함) + 설정 버튼
                      Padding(
                        padding: EdgeInsets.only(left: 0, right: 16, top: 16, bottom: 0), // 좌측 여백 제거, 우측/상단만 최소 유지
                        child: Row(
                          children: [
                            ProfileCard(
                              avatarUrl: avatarAsset,
                              nickname: nickname,
                              countryCode: countryCode,
                              level: level,
                              coins: _coins,
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.6),
                                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0,2))],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.settings, color: Colors.amberAccent, size: 30),
                                onPressed: () {
                                  bool isMuted = SoundManager.instance.isBgmMuted;
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  showCustomSettingsDialog(
                                    context,
                                    selectedLang: selectedLang,
                                    onLangChanged: (val) {
                                      // 언어 변경 시 LocaleProvider를 통해 앱 전체 언어 변경
                                      Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(val));
                                    },
                                    isMuted: isMuted,
                                    onMuteChanged: (val) async {
                                      isMuted = val;
                                      await SoundManager.instance.setBgmMuted(val);
                                      setState(() {});
                                    },
                                    onLogout: () async {
                                      Navigator.of(context).pop();
                                      await authProvider.signOut();
                                      if (mounted) {
                                        Navigator.of(context).pushReplacementNamed('/login');
                                      }
                                    },
                                  );
                                },
                                tooltip: AppLocalizations.of(context)!.settings,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      // 중앙 메뉴 (가로 스크롤 카드형 버튼, 중앙 정렬, 1.8배 확장)
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _cardButton(
                                label: AppLocalizations.of(context)!.aiMatch,
                                emoji: '🤖',
                                onTap: () => _enterMatch('ai'),
                                enabled: true,
                                width: 84 * 1.8,
                                height: 63 * 1.8,
                                fontSize: 11 * 1.8,
                                emojiSize: 22 * 1.8,
                              ),
                              SizedBox(width: 18),
                              _cardButton(
                                label: AppLocalizations.of(context)!.twoPlayerMatch,
                                emoji: '🧍🧍',
                                onTap: null,
                                enabled: false,
                                width: 84 * 1.8,
                                height: 63 * 1.8,
                                fontSize: 11 * 1.8,
                                emojiSize: 22 * 1.8,
                              ),
                              SizedBox(width: 18),
                              _cardButton(
                                label: AppLocalizations.of(context)!.onlinePvp,
                                emoji: '🌐',
                                onTap: null,
                                enabled: false,
                                width: 84 * 1.8,
                                height: 63 * 1.8,
                                fontSize: 11 * 1.8,
                                emojiSize: 22 * 1.8,
                              ),
                              SizedBox(width: 18),
                              _cardButton(
                                label: AppLocalizations.of(context)!.friendMatch,
                                emoji: '🎲',
                                onTap: null,
                                enabled: false,
                                width: 84 * 1.8,
                                height: 63 * 1.8,
                                fontSize: 11 * 1.8,
                                emojiSize: 22 * 1.8,
                              ),
                              SizedBox(width: 18),
                              _cardButton(
                                label: AppLocalizations.of(context)!.shop,
                                emoji: '🛒',
                                onTap: () => _openShop(),
                                enabled: true,
                                width: 84 * 1.8,
                                height: 63 * 1.8,
                                fontSize: 11 * 1.8,
                                emojiSize: 22 * 1.8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 100), // 하단 버튼과 겹치지 않게 충분한 여백
                    ],
                  ),
                  // How to Play 버튼 (화면 하단 중앙 고정, 크기 절반 축소)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: FractionallySizedBox(
                        widthFactor: 0.25,
                        child: SizedBox(
                          height: buttonHeight * 0.75,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.info_outline, color: Colors.white, size: iconSize * 0.75),
                            label: Text(AppLocalizations.of(context)!.howToPlay, style: TextStyle(fontSize: buttonFontSize * 0.6, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonHeight * 0.3)),
                              elevation: 0,
                              side: BorderSide(color: Colors.white.withOpacity(0.18)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(AppLocalizations.of(context)!.howToPlay),
                                  content: Text('${AppLocalizations.of(context)!.howToPlay}...'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(AppLocalizations.of(context)!.close),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _mainButton(String label, String emoji, VoidCallback? onPressed, double width, double height, double fontSize, Color color, double iconSize) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(height * 0.4)),
          elevation: 0,
          side: BorderSide(color: Colors.white.withOpacity(0.18)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(emoji, style: TextStyle(fontSize: iconSize)),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardButton({
    required String label,
    required String emoji,
    VoidCallback? onTap,
    bool enabled = true,
    double width = 120,
    double height = 90,
    double fontSize = 16,
    double emojiSize = 32,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          // 배경 이미지가 보이도록 투명 또는 반투명 색상 적용
          color: enabled ? const Color(0xFF2E3650).withOpacity(0.82) : Colors.grey[400]!.withOpacity(0.65),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: enabled ? Colors.amberAccent.withOpacity(0.7) : Colors.grey.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: emojiSize),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.white : Colors.white70,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 