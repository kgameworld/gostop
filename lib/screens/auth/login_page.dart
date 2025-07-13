import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/consent_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고/타이틀
                  const Icon(
                    Icons.casino,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '고스톱',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '소셜 계정으로 로그인하여\n게임을 시작하세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 소셜 로그인 버튼들
                  Column(
                    children: [
                      // 중앙 정렬을 위한 Center 위젯 추가
                      Center(
                        child: Column(
                          children: [
                      // Google 로그인 버튼
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return SizedBox(
                            width: 400, // 적절한 너비로 조정
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: authProvider.isLoading ? null : _handleGoogleLogin,
                              icon: const Icon(Icons.g_mobiledata, size: 24),
                              label: const Text(
                                'Google로 로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Apple 로그인 버튼
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return SizedBox(
                            width: 400, // 적절한 너비로 조정
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: authProvider.isLoading ? null : _handleAppleLogin,
                              icon: const Icon(Icons.apple, size: 24),
                              label: const Text(
                                'Apple로 로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Facebook 로그인 버튼
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return SizedBox(
                            width: 400, // 적절한 너비로 조정
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: authProvider.isLoading ? null : _handleFacebookLogin,
                              icon: const Icon(Icons.facebook, size: 24),
                              label: const Text(
                                'Facebook으로 로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1877F2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // 구분선
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white30)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '또는',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white30)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 게스트 로그인 버튼
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return SizedBox(
                            width: 400, // 적절한 너비로 조정
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: authProvider.isLoading ? null : _handleGuestLogin,
                              icon: const Icon(Icons.person_outline, size: 24),
                              label: const Text(
                                '게스트로 시작하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),

                  // 로딩 인디케이터
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isLoading) {
                        return const Column(
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              '로그인 중...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // 에러 메시지
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.error != null) {
                        return Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 32),

                  // 게스트 로그인 안내
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                          size: 24,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '게스트로 시작하면 게임 기록이 저장되지 않습니다.\n계정을 만들어서 진행하시는 것을 권장합니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 약관 및 개인정보 처리방침
                  const Text(
                    '로그인 시 서비스 이용약관 및\n개인정보 처리방침에 동의하는 것으로 간주됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    // 동의 상태 확인
    final hasConsent = await _checkConsentStatus();
    if (!hasConsent) {
      final consentResult = await _showConsentDialog();
      if (consentResult == null || consentResult == false) {
        return; // 동의하지 않음
      }
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      // 로그인 성공 시 메인 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleAppleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithApple();

    if (success && mounted) {
      // 로그인 성공 시 메인 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleFacebookLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithFacebook();

    if (success && mounted) {
      // 로그인 성공 시 메인 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleGuestLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInAsGuest();

    if (success && mounted) {
      // 로그인 성공 시 메인 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // 동의 상태 확인
  Future<bool> _checkConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final privacyConsent = prefs.getBool('privacy_consent') ?? false;
    final termsConsent = prefs.getBool('terms_consent') ?? false;
    return privacyConsent && termsConsent;
  }

  // 동의 다이얼로그 표시
  Future<bool?> _showConsentDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConsentDialog(),
    );
  }
} 