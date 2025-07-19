import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/guest_restrictions.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  final GuestRestrictions _guestRestrictions = GuestRestrictions();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 & 랭킹'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '친구'),
            Tab(text: '랭킹'),
          ],
        ),
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
            
            return Column(
              children: [
                // 게스트 모드 안내
                if (isGuest) _buildGuestNotice(),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFriendsTab(isGuest),
                      _buildRankingTab(isGuest),
                    ],
                  ),
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
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.people,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(height: 8),
          const Text(
            '게스트 모드 제한',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '친구 목록과 랭킹은 확인만 가능합니다.\n친구 초대, DM, 친구 추가는 계정이 필요합니다.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildFriendsTab(bool isGuest) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 친구 추가 버튼 (게스트는 비활성화)
        if (!isGuest)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () => _addFriend(),
              icon: const Icon(Icons.person_add),
              label: const Text('친구 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        // 친구 목록
        _buildFriendsList(isGuest),
      ],
    );
  }

  Widget _buildFriendsList(bool isGuest) {
    // 샘플 친구 데이터
    final friends = [
      {'name': '플레이어1', 'level': 15, 'status': '온라인', 'avatar': '👤'},
      {'name': '고스톱마스터', 'level': 25, 'status': '게임중', 'avatar': '👑'},
      {'name': '카드왕', 'level': 30, 'status': '오프라인', 'avatar': '🎴'},
      {'name': '승리자', 'level': 18, 'status': '온라인', 'avatar': '🏆'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '친구 목록 (${friends.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...friends.map((friend) => _buildFriendCard(friend, isGuest)).toList(),
      ],
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend, bool isGuest) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[700],
          child: Text(
            friend['avatar'],
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          friend['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '레벨 ${friend['level']}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              friend['status'],
              style: TextStyle(
                color: friend['status'] == '온라인' ? Colors.green : 
                       friend['status'] == '게임중' ? Colors.orange : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isGuest) ...[
              IconButton(
                onPressed: () => _sendMessage(friend['name']),
                icon: const Icon(Icons.message, color: Colors.blue),
                tooltip: '메시지 보내기',
              ),
              IconButton(
                onPressed: () => _inviteToGame(friend['name']),
                icon: const Icon(Icons.games, color: Colors.green),
                tooltip: '게임 초대',
              ),
            ],
            IconButton(
              onPressed: () => _viewProfile(friend['name']),
              icon: const Icon(Icons.person, color: Colors.white),
              tooltip: '프로필 보기',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingTab(bool isGuest) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 랭킹 필터 (게스트는 비활성화)
        if (!isGuest)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  '필터:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('전체'),
                  selected: true,
                  onSelected: (selected) {},
                  selectedColor: Colors.green,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('친구'),
                  selected: false,
                  onSelected: (selected) {},
                  selectedColor: Colors.green,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // 랭킹 목록
        _buildRankingList(isGuest),
      ],
    );
  }

  Widget _buildRankingList(bool isGuest) {
    // 샘플 랭킹 데이터
    final rankings = [
      {'rank': 1, 'name': '고스톱킹', 'level': 50, 'score': 12500, 'avatar': '👑'},
      {'rank': 2, 'name': '카드마스터', 'level': 45, 'score': 11800, 'avatar': '🎴'},
      {'rank': 3, 'name': '승리의신', 'level': 42, 'score': 11200, 'avatar': '🏆'},
      {'rank': 4, 'name': '플레이어1', 'level': 38, 'score': 10500, 'avatar': '👤'},
      {'rank': 5, 'name': '고스톱러버', 'level': 35, 'score': 9800, 'avatar': '❤️'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '전체 랭킹',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...rankings.map((ranking) => _buildRankingCard(ranking, isGuest)).toList(),
      ],
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> ranking, bool isGuest) {
    final isTop3 = ranking['rank'] <= 3;
    
    return Card(
      color: isTop3 ? Colors.yellow.withOpacity(0.2) : Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isTop3 ? Colors.yellow.withOpacity(0.5) : Colors.white.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isTop3 ? Colors.yellow : Colors.green[700],
              child: Text(
                ranking['avatar'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
            if (isTop3)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${ranking['rank']}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          ranking['name'],
          style: TextStyle(
            color: isTop3 ? Colors.yellow : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '레벨 ${ranking['level']} • ${ranking['score']}점',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isGuest) ...[
              IconButton(
                onPressed: () => _addFriendFromRanking(ranking['name']),
                icon: const Icon(Icons.person_add, color: Colors.blue),
                tooltip: '친구 추가',
              ),
            ],
            IconButton(
              onPressed: () => _viewProfile(ranking['name']),
              icon: const Icon(Icons.person, color: Colors.white),
              tooltip: '프로필 보기',
            ),
          ],
        ),
      ),
    );
  }

  // 친구 관련 액션들
  void _addFriend() {
    if (!_guestRestrictions.canUseFriendFeatures('add_friend', false)) {
      _showUpgradeDialog('friend_invite');
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: const Text(
            '친구 추가',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const TextField(
            decoration: InputDecoration(
              labelText: '플레이어 이름 또는 ID',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('친구 요청을 보냈습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage(String friendName) {
    if (!_guestRestrictions.canUseFriendFeatures('send_dm', false)) {
      _showUpgradeDialog('friend_invite');
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$friendName에게 메시지를 보냅니다.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _inviteToGame(String friendName) {
    if (!_guestRestrictions.canUseFriendFeatures('send_invite', false)) {
      _showUpgradeDialog('friend_invite');
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$friendName을 게임에 초대합니다.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewProfile(String playerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: Text(
            '$playerName의 프로필',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('레벨: 25', style: const TextStyle(color: Colors.white)),
              Text('승률: 68%', style: const TextStyle(color: Colors.white)),
              Text('총 게임: 150판', style: const TextStyle(color: Colors.white)),
              Text('랭킹: 15위', style: const TextStyle(color: Colors.white)),
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
          ],
        );
      },
    );
  }

  void _addFriendFromRanking(String playerName) {
    if (!_guestRestrictions.canUseFriendFeatures('add_friend', false)) {
      _showUpgradeDialog('friend_invite');
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$playerName에게 친구 요청을 보냈습니다.'),
        backgroundColor: Colors.blue,
      ),
    );
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