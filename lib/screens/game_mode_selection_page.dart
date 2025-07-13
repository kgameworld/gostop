import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/guest_restrictions.dart';

class GameModeSelectionPage extends StatefulWidget {
  const GameModeSelectionPage({super.key});

  @override
  State<GameModeSelectionPage> createState() => _GameModeSelectionPageState();
}

class _GameModeSelectionPageState extends State<GameModeSelectionPage> {
  final GuestRestrictions _guestRestrictions = GuestRestrictions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 모드 선택'),
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
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isGuest = authProvider.isGuest;
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 게스트 모드 안내
                if (isGuest) _buildGuestNotice(),
                const SizedBox(height: 24),

                // AI 매치
                FutureBuilder<bool>(
                  future: _guestRestrictions.canPlayAIMatch(isGuest),
                  builder: (context, snapshot) {
                    final canPlay = snapshot.data ?? false;
                    final remainingMatches = isGuest ? 
                      FutureBuilder<int>(
                        future: _guestRestrictions.getRemainingAIMatches(isGuest),
                        builder: (context, remainingSnapshot) {
                          final remaining = remainingSnapshot.data ?? 0;
                          return Text(
                            '남은 횟수: $remaining/3',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          );
                        },
                      ) : const Text(
                        '무제한',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      );

                    return _buildGameModeCard(
                      title: 'AI 매치',
                      subtitle: 'AI와 1:1 대결',
                      icon: Icons.computer,
                      color: Colors.blue,
                      isAvailable: canPlay,
                      subtitleWidget: remainingMatches,
                      onTap: canPlay ? () => _startAIMatch(isGuest) : null,
                      showComingSoonRibbon: false, // AI 매치는 리본 없음
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 랜덤 매칭 (게스트는 잠금)
                _buildGameModeCard(
                  title: '랜덤 매칭',
                  subtitle: '실시간 플레이어와 대결',
                  icon: Icons.people,
                  color: Colors.orange,
                  isAvailable: !isGuest, // 게스트는 불가
                  onTap: !isGuest ? () => _startGame('random_match') : null,
                  showComingSoonRibbon: true, // 리본 표시
                ),
                const SizedBox(height: 16),

                // 친구 매치 (게스트는 잠금)
                _buildGameModeCard(
                  title: '친구 매치',
                  subtitle: '친구와 1:1 대결',
                  icon: Icons.person_add,
                  color: Colors.purple,
                  isAvailable: !isGuest, // 게스트는 불가
                  onTap: !isGuest ? () => _startGame('friend_match') : null,
                  showComingSoonRibbon: true, // 리본 표시
                ),
                const SizedBox(height: 16),

                // 토너먼트 (게스트는 잠금)
                _buildGameModeCard(
                  title: '토너먼트',
                  subtitle: '다중 플레이어 토너먼트',
                  icon: Icons.emoji_events,
                  color: Colors.yellow,
                  isAvailable: !isGuest, // 게스트는 불가
                  onTap: !isGuest ? () => _startGame('tournament') : null,
                  showComingSoonRibbon: true, // 리본 표시
                ),
                const SizedBox(height: 16),

                // 연습 모드 (게스트는 잠금)
                _buildGameModeCard(
                  title: '연습 모드',
                  subtitle: '규칙 학습 및 연습',
                  icon: Icons.school,
                  color: Colors.teal,
                  isAvailable: !isGuest, // 게스트는 불가
                  onTap: !isGuest ? () => _startGame('practice') : null,
                  showComingSoonRibbon: true, // 리본 표시
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuestNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(height: 8),
          const Text(
            '게스트 모드 제한사항',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• AI 매치만 이용 가능 (1일 3판 제한)\n• 다른 게임 모드는 계정 필요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 로그아웃 후 로그인 화면으로 이동
                context.read<AuthProvider>().signOut().then((_) {
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

  Widget _buildGameModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    Widget? subtitleWidget,
    VoidCallback? onTap,
    bool showComingSoonRibbon = false, // "Coming Soon" 리본 표시 여부
  }) {
    // Stack으로 카드와 리본을 겹쳐서 배치
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          color: isAvailable ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isAvailable ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAvailable ? color : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isAvailable ? Colors.white : Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (subtitleWidget != null)
                          subtitleWidget
                        else
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: isAvailable ? Colors.white70 : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isAvailable)
                    const Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
        // "Coming Soon" 리본 배너 (showComingSoonRibbon이 true일 때만 표시)
        if (showComingSoonRibbon)
          Positioned(
            top: -8, // 카드 우상단에 살짝 겹치게
            right: -24,
            child: Transform.rotate(
              angle: -0.45, // 대각선 각도 (라디안)
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent, // 강조 색상
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Coming Soon',
                  style: const TextStyle(
                    fontFamily: 'SUIT', // 프리미엄 폰트
                    fontWeight: FontWeight.w600, // 세미볼드
                    color: Colors.white,
                    letterSpacing: 0.7, // 자간
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _startGame(String gameMode) {
    // 게임 시작 로직
    Navigator.pushNamed(context, '/game', arguments: {
      'mode': gameMode,
      'isGuest': context.read<AuthProvider>().isGuest,
    });
  }

  Future<void> _startAIMatch(bool isGuest) async {
    // AI 매치 시작 전 제한 확인
    final canPlay = await _guestRestrictions.canPlayAIMatch(isGuest);
    
    if (!canPlay) {
      _showUpgradeDialog('ai_match');
      return;
    }

    // AI 매치 기록
    await _guestRestrictions.recordAIMatch(isGuest);
    
    // 게임 시작
    _startGame('ai_match');
  }

  void _showUpgradeDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: const Text(
            '기능 제한',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _guestRestrictions.getUpgradeMessage(feature),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '나중에',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 로그아웃 후 로그인 화면으로 이동
                context.read<AuthProvider>().signOut().then((_) {
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
} 