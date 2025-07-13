import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/legal/privacy_policy_page.dart';
import '../screens/legal/terms_of_service_page.dart';
import '../services/privacy_manager.dart';
import '../widgets/consent_settings_dialog.dart';

enum AnimationSpeed {
  slow, normal, fast, instant
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AnimationSpeed _animationSpeed = AnimationSpeed.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 설정'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[900]!,
              Colors.green[700]!,
              Colors.green[500]!,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 게스트 계정 안내
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isGuest) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '게스트 계정',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '게스트로 로그인되어 있습니다.\n게임 기록이 저장되지 않으며, 앱을 삭제하면 모든 데이터가 사라집니다.\n계정을 만들어서 진행하시는 것을 권장합니다.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // 로그아웃 후 로그인 화면으로 이동
                              authProvider.signOut().then((_) {
                                Navigator.of(context).pushReplacementNamed('/login');
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '계정 만들기',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // 사용자 프로필 섹션
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isAuthenticated && authProvider.userProfile != null) {
                  return _buildSection(
                    title: '사용자 정보',
                    icon: Icons.person,
                    children: [
                      ListTile(
                        title: Text(
                          authProvider.userProfile!['nickname'] ?? '사용자',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          authProvider.userProfile!['email'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            (authProvider.userProfile!['nickname'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      ListTile(
                        title: const Text('레벨', style: TextStyle(color: Colors.white, fontSize: 16)),
                        subtitle: Text(
                          'Level ${authProvider.userProfile!['level'] ?? 1}',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                        leading: const Icon(Icons.star, color: Colors.yellow),
                      ),
                      ListTile(
                        title: const Text('총 게임 수', style: TextStyle(color: Colors.white, fontSize: 16)),
                        subtitle: Text(
                          '${authProvider.userProfile!['total_games'] ?? 0}게임',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        leading: const Icon(Icons.games, color: Colors.white),
                      ),
                      ListTile(
                        title: const Text('승리', style: TextStyle(color: Colors.white, fontSize: 16)),
                        subtitle: Text(
                          '${authProvider.userProfile!['wins'] ?? 0}승',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        leading: const Icon(Icons.emoji_events, color: Colors.yellow),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              title: '애니메이션 설정',
              icon: Icons.animation,
              children: [
                const Text(
                  '애니메이션 속도',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...AnimationSpeed.values.map((speed) => RadioListTile<AnimationSpeed>(
                  title: Text(_getAnimationSpeedText(speed), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: Text(_getAnimationSpeedDescription(speed), style: const TextStyle(color: Colors.white70)),
                  value: speed,
                  groupValue: _animationSpeed,
                  onChanged: (value) {
                    setState(() { _animationSpeed = value!; });
                  },
                  activeColor: Colors.yellow,
                )),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              title: '계정 관리',
              icon: Icons.account_circle,
              children: [
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ListTile(
                      title: const Text('로그아웃', style: TextStyle(color: Colors.white, fontSize: 16)),
                      subtitle: const Text('현재 계정에서 로그아웃합니다', style: TextStyle(color: Colors.white70)),
                      leading: const Icon(Icons.logout, color: Colors.red),
                      onTap: () => _showLogoutDialog(context, authProvider),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 개인정보 관리 섹션 - 테스트용으로 색상 변경
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: _buildSection(
                title: '개인정보 관리',
                icon: Icons.privacy_tip,
                children: [
                  ListTile(
                    title: const Text('개인정보처리방침', style: TextStyle(color: Colors.white, fontSize: 16)),
                    subtitle: const Text('개인정보 수집 및 이용에 대한 안내', style: TextStyle(color: Colors.white70)),
                    leading: const Icon(Icons.privacy_tip, color: Colors.white),
                    onTap: () => _navigateToPrivacyPolicy(),
                  ),
                  ListTile(
                    title: const Text('이용약관', style: TextStyle(color: Colors.white, fontSize: 16)),
                    subtitle: const Text('서비스 이용에 대한 약관', style: TextStyle(color: Colors.white70)),
                    leading: const Icon(Icons.description, color: Colors.white),
                    onTap: () => _navigateToTermsOfService(),
                  ),
                  ListTile(
                    title: const Text('동의 설정', style: TextStyle(color: Colors.white, fontSize: 16)),
                    subtitle: const Text('개인정보 수집 동의 관리', style: TextStyle(color: Colors.white70)),
                    leading: const Icon(Icons.settings, color: Colors.white),
                    onTap: () => _showConsentSettings(),
                  ),
                  ListTile(
                    title: const Text('개인정보 다운로드', style: TextStyle(color: Colors.white, fontSize: 16)),
                    subtitle: const Text('내 데이터 내보내기', style: TextStyle(color: Colors.white70)),
                    leading: const Icon(Icons.download, color: Colors.white),
                    onTap: () => _downloadUserData(),
                  ),
                  ListTile(
                    title: const Text('계정 삭제', style: TextStyle(color: Colors.white, fontSize: 16)),
                    subtitle: const Text('개인정보 완전 삭제 요청', style: TextStyle(color: Colors.white70)),
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    onTap: () => _requestAccountDeletion(),
                  ),
                ],
              ),
            ),
            _buildSection(
              title: '게임 정보',
              icon: Icons.info,
              children: [
                ListTile(
                  title: const Text('버전', style: TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: const Text('1.0.0', style: TextStyle(color: Colors.white70)),
                  leading: const Icon(Icons.app_settings_alt, color: Colors.white),
                ),
                ListTile(
                  title: const Text('개발자', style: TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: const Text('고스톱 게임 개발팀', style: TextStyle(color: Colors.white70)),
                  leading: const Icon(Icons.person, color: Colors.white),
                ),
                ListTile(
                  title: const Text('라이선스', style: TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: const Text('MIT License', style: TextStyle(color: Colors.white70)),
                  leading: const Icon(Icons.description, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.yellow, size: 24),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getAnimationSpeedText(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return '느리게';
      case AnimationSpeed.normal:
        return '보통';
      case AnimationSpeed.fast:
        return '빠르게';
      case AnimationSpeed.instant:
        return '즉시';
    }
  }

  String _getAnimationSpeedDescription(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return '애니메이션이 1.5배 느리게 재생됩니다';
      case AnimationSpeed.normal:
        return '기본 애니메이션 속도입니다';
      case AnimationSpeed.fast:
        return '애니메이션이 0.7배 빠르게 재생됩니다';
      case AnimationSpeed.instant:
        return '애니메이션 없이 즉시 결과를 표시합니다';
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: const Text(
            '로그아웃',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '정말로 로그아웃하시겠습니까?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // 개인정보 관리 메서드들
  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  void _navigateToTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServicePage()),
    );
  }

  void _showConsentSettings() {
    showDialog(
      context: context,
      builder: (context) => const ConsentSettingsDialog(),
    );
  }

  Future<void> _downloadUserData() async {
    try {
      final privacyManager = PrivacyManager();
      final userData = await privacyManager.requestDataPortability();
      
      if (userData != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('데이터 다운로드'),
            content: const Text('개인정보 다운로드가 완료되었습니다. 이메일로 전송됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 다운로드 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _requestAccountDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제 요청'),
        content: const Text(
          '계정을 삭제하면 모든 개인정보가 영구적으로 삭제되며 복구할 수 없습니다.\n\n정말 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final privacyManager = PrivacyManager();
              final success = await privacyManager.requestDataDeletion();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? '삭제 요청이 접수되었습니다. 이메일을 확인해주세요.'
                        : '삭제 요청 중 오류가 발생했습니다.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제 요청', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 