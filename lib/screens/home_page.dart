import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'game_setup_page.dart';
import 'settings_page.dart';
import 'game_mode_selection_page.dart';
import 'shop_page.dart';
import 'social_page.dart';
import 'customer_service_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoStop 게임'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          // 프로필 아이콘
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return IconButton(
                onPressed: () => _showProfileInfo(context, authProvider),
                icon: Icon(
                  authProvider.isGuest ? Icons.person_outline : Icons.person,
                  color: Colors.white,
                ),
                tooltip: '프로필 정보',
              );
            },
          ),
          // 설정(톱니바퀴) 버튼 추가
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: '설정',
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
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
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              children: [
                // 프로필 섹션
                _buildProfileSection(context, authProvider),
                
                // 메뉴 섹션
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                '고스톱에 오신 걸 환영합니다!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                          textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
                        
                        // 게임 관련 버튼들
                        _buildMenuSection(
                          title: '게임',
                          children: [
                            _buildMenuButton(
                              context,
                              '게임 모드 선택',
                              Icons.games,
                              Colors.blue,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GameModeSelectionPage()),
                              ),
                            ),
                            _buildMenuButton(
                              context,
                              '빠른 게임',
                              Icons.play_arrow,
                              Colors.green,
                              () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GameSetupPage()),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 소셜 관련 버튼들
                        _buildMenuSection(
                          title: '소셜',
                          children: [
                            _buildMenuButton(
                              context,
                              '친구 & 랭킹',
                              Icons.people,
                              Colors.purple,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SocialPage()),
                    ),
                  ),
                            _buildMenuButton(
                              context,
                              '상점',
                              Icons.shopping_cart,
                              Colors.orange,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ShopPage()),
                  ),
                ),
                          ],
              ),
                        
              const SizedBox(height: 20),
                        
                        // 기타 버튼들
                        _buildMenuSection(
                          title: '기타',
                          children: [
                            _buildMenuButton(
                              context,
                              '통계',
                              Icons.bar_chart,
                              Colors.cyan,
                              () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('통계 기능은 준비 중입니다'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                            ),
                            _buildMenuButton(
                              context,
                              '고객센터',
                              Icons.support_agent,
                              Colors.red,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CustomerServicePage()),
                              ),
                            ),
                            _buildMenuButton(
                              context,
                              '설정',
                              Icons.settings,
                              Colors.grey,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsPage()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // 아바타
          CircleAvatar(
            radius: 30,
            backgroundColor: authProvider.isGuest ? Colors.orange : Colors.green[700],
            child: Icon(
              authProvider.isGuest ? Icons.person_outline : Icons.person,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      authProvider.isGuest ? '게스트' : authProvider.userProfile?['nickname'] ?? authProvider.currentUser?.email ?? '사용자',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (authProvider.isGuest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Text(
                          '게스트',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                  ),
                ),
                      ),
                    ],
                  ],
              ),
                const SizedBox(height: 4),
                Text(
                  authProvider.isGuest 
                    ? '게스트 모드 - 제한된 기능으로 플레이'
                    : authProvider.currentUser?.email ?? '정식 계정',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (authProvider.isGuest) ...[
                  const SizedBox(height: 8),
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        '계정 만들기',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileInfo(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: Row(
            children: [
              Icon(
                authProvider.isGuest ? Icons.person_outline : Icons.person,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                '프로필 정보',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이름: ${authProvider.isGuest ? '게스트' : authProvider.userProfile?['nickname'] ?? authProvider.currentUser?.email ?? '사용자'}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '계정 타입: ${authProvider.isGuest ? '게스트' : '정식 계정'}',
                style: const TextStyle(color: Colors.white),
              ),
              if (!authProvider.isGuest) ...[
                const SizedBox(height: 8),
                Text(
                  '이메일: ${authProvider.currentUser?.email ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              if (authProvider.isGuest) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '게스트 모드 제한사항:',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                      SizedBox(height: 4),
                      Text(
                        '• AI 매치만 가능 (1일 3판 제한)\n• 구매 불가\n• 친구 기능 제한\n• 게임 기록 저장 안됨',
                        style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '닫기',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            if (authProvider.isGuest)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 로그아웃 후 로그인 화면으로 이동
                  authProvider.signOut().then((_) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('계정 만들기'),
              ),
          ],
        );
      },
    );
  }

  // 설정 다이얼로그 (로그아웃 포함)
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return AlertDialog(
              backgroundColor: Colors.green[800],
              title: Row(
                children: const [
                  Icon(Icons.settings, color: Colors.white),
                  SizedBox(width: 8),
                  Text('설정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('설정 및 계정 관리', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('로그아웃', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      authProvider.signOut().then((_) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기', style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}