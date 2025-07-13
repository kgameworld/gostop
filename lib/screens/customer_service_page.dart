import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/guest_restrictions.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final GuestRestrictions _guestRestrictions = GuestRestrictions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터'),
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

                // FAQ 섹션
                _buildFAQSection(isGuest),
                const SizedBox(height: 24),

                // 문의하기 섹션 (게스트는 비활성화)
                if (!isGuest) _buildContactSection(),
                if (!isGuest) const SizedBox(height: 24),

                // 채팅 상담 섹션 (게스트는 비활성화)
                if (!isGuest) _buildChatSupportSection(),
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
            Icons.support_agent,
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
            'FAQ는 자유롭게 확인할 수 있습니다.\n문의하기와 채팅 상담은 계정이 필요합니다.',
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

  Widget _buildFAQSection(bool isGuest) {
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
                const Icon(Icons.question_answer, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '자주 묻는 질문 (FAQ)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildFAQItem(
            question: '고스톱 게임의 기본 규칙은 무엇인가요?',
            answer: '고스톱은 3명이 플레이하는 카드 게임입니다. 광, 열, 쌍피, 끗의 조합으로 점수를 계산하며, 3점 이상이면 고, 7점 이상이면 스톱을 외칠 수 있습니다.',
            isGuest: isGuest,
          ),
          _buildFAQItem(
            question: '게임에서 승리하는 방법은?',
            answer: '카드를 조합하여 높은 점수를 얻거나, 상대방보다 먼저 고/스톱을 외쳐야 합니다. 전략적으로 카드를 선택하고 타이밍을 잘 맞추는 것이 중요합니다.',
            isGuest: isGuest,
          ),
          _buildFAQItem(
            question: '레벨업은 어떻게 하나요?',
            answer: '게임에서 승리하면 경험치를 획득할 수 있습니다. 경험치가 일정량 쌓이면 레벨업하며, 레벨이 올라갈수록 더 많은 보상을 받을 수 있습니다.',
            isGuest: isGuest,
          ),
          _buildFAQItem(
            question: '코인은 어떻게 얻나요?',
            answer: '게임 승리, 일일 보상, 광고 시청, 이벤트 참여 등을 통해 코인을 획득할 수 있습니다. 정식 계정으로 업그레이드하면 더 많은 방법으로 코인을 얻을 수 있습니다.',
            isGuest: isGuest,
          ),
          _buildFAQItem(
            question: '친구와 함께 플레이하려면?',
            answer: '정식 계정을 만들어야 친구 추가, 초대, 함께 플레이가 가능합니다. 게스트 모드에서는 AI와의 매치만 가능합니다.',
            isGuest: isGuest,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required bool isGuest,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            answer,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildContactSection() {
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
                const Icon(Icons.email, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '문의하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildContactItem(
                  title: '이메일 문의',
                  description: '이메일로 문의사항을 보내주세요',
                  icon: Icons.email,
                  color: Colors.blue,
                  onTap: () => _sendEmail(),
                ),
                _buildContactItem(
                  title: '버그 신고',
                  description: '게임 버그나 오류를 신고해주세요',
                  icon: Icons.bug_report,
                  color: Colors.red,
                  onTap: () => _reportBug(),
                ),
                _buildContactItem(
                  title: '기능 제안',
                  description: '새로운 기능이나 개선사항을 제안해주세요',
                  icon: Icons.lightbulb,
                  color: Colors.yellow,
                  onTap: () => _suggestFeature(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChatSupportSection() {
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
                const Icon(Icons.chat, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '실시간 채팅 상담',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildContactItem(
              title: '상담원과 채팅',
              description: '실시간으로 상담원과 대화하세요',
              icon: Icons.chat_bubble,
              color: Colors.purple,
              onTap: () => _startChatSupport(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  // 문의하기 액션들
  void _sendEmail() {
    if (!_guestRestrictions.canUseCustomerService('create_ticket', false)) {
      _showUpgradeDialog('customer_service');
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: const Text(
            '이메일 문의',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: '제목',
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
              const SizedBox(height: 16),
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '문의 내용',
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
            ],
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
                    content: Text('문의가 접수되었습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('전송'),
            ),
          ],
        );
      },
    );
  }

  void _reportBug() {
    if (!_guestRestrictions.canUseCustomerService('create_ticket', false)) {
      _showUpgradeDialog('customer_service');
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: const Text(
            '버그 신고',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: '버그 내용을 자세히 설명해주세요',
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
                    content: Text('버그 신고가 접수되었습니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('신고'),
            ),
          ],
        );
      },
    );
  }

  void _suggestFeature() {
    if (!_guestRestrictions.canUseCustomerService('create_ticket', false)) {
      _showUpgradeDialog('customer_service');
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: const Text(
            '기능 제안',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: '제안하고 싶은 기능을 설명해주세요',
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
                    content: Text('기능 제안이 접수되었습니다.'),
                    backgroundColor: Colors.yellow,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('제안'),
            ),
          ],
        );
      },
    );
  }

  void _startChatSupport() {
    if (!_guestRestrictions.canUseCustomerService('chat_support', false)) {
      _showUpgradeDialog('customer_service');
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('채팅 상담을 시작합니다.'),
        backgroundColor: Colors.purple,
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