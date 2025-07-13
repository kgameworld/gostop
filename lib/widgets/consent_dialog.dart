import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/legal/privacy_policy_page.dart';
import '../screens/legal/terms_of_service_page.dart';

class ConsentDialog extends StatefulWidget {
  const ConsentDialog({super.key});

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  bool _privacyConsent = false;
  bool _termsConsent = false;
  bool _marketingConsent = false;
  bool _analyticsConsent = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 방지
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text(
              '개인정보 및 이용약관 동의',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '고스톱 서비스를 이용하기 위해 다음 사항에 동의해주세요:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // 필수 동의 항목
              _buildConsentItem(
                title: '개인정보처리방침 (필수)',
                subtitle: '개인정보 수집 및 이용에 동의합니다',
                value: _privacyConsent,
                onChanged: (value) => setState(() => _privacyConsent = value ?? false),
                isRequired: true,
                onViewPolicy: () => _viewPrivacyPolicy(),
              ),

              const SizedBox(height: 12),

              _buildConsentItem(
                title: '이용약관 (필수)',
                subtitle: '서비스 이용약관에 동의합니다',
                value: _termsConsent,
                onChanged: (value) => setState(() => _termsConsent = value ?? false),
                isRequired: true,
                onViewPolicy: () => _viewTermsOfService(),
              ),

              const SizedBox(height: 20),

              // 선택 동의 항목
              const Text(
                '선택 동의 항목 (동의하지 않아도 서비스 이용 가능):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              _buildConsentItem(
                title: '마케팅 정보 수신 (선택)',
                subtitle: '이벤트, 업데이트 등 마케팅 정보를 받습니다',
                value: _marketingConsent,
                onChanged: (value) => setState(() => _marketingConsent = value ?? false),
                isRequired: false,
              ),

              const SizedBox(height: 12),

              _buildConsentItem(
                title: '서비스 개선 분석 (선택)',
                subtitle: '서비스 개선을 위한 사용 통계 수집에 동의합니다',
                value: _analyticsConsent,
                onChanged: (value) => setState(() => _analyticsConsent = value ?? false),
                isRequired: false,
              ),

              const SizedBox(height: 20),

              // 중요 안내사항
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '중요 안내사항',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• 필수 항목에 동의하지 않으면 서비스를 이용할 수 없습니다.\n• 선택 항목은 언제든지 설정에서 변경할 수 있습니다.\n• 개인정보 관련 권리는 설정 > 개인정보 관리에서 행사할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _handleDecline(),
            child: const Text('동의하지 않음'),
          ),
          ElevatedButton(
            onPressed: (_privacyConsent && _termsConsent && !_isLoading)
                ? () => _handleAccept()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('동의하고 시작하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required bool isRequired,
    VoidCallback? onViewPolicy,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isRequired ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isRequired ? Colors.red[700] : Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '(필수)',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (onViewPolicy != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onViewPolicy,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '자세히 보기',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  void _viewPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  void _viewTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServicePage()),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    try {
      // 동의 정보 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_consent', _privacyConsent);
      await prefs.setBool('terms_consent', _termsConsent);
      await prefs.setBool('marketing_consent', _marketingConsent);
      await prefs.setBool('analytics_consent', _analyticsConsent);
      await prefs.setString('consent_date', DateTime.now().toIso8601String());

      // 동의 로그 기록 (선택사항)
      _logConsent();

      if (mounted) {
        Navigator.of(context).pop({
          'privacy': _privacyConsent,
          'terms': _termsConsent,
          'marketing': _marketingConsent,
          'analytics': _analyticsConsent,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동의 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleDecline() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('서비스 이용 불가'),
        content: const Text(
          '필수 동의 항목에 동의하지 않으면 서비스를 이용할 수 없습니다.\n\n동의하지 않으시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('다시 생각해보기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(false); // 동의 거부
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('동의하지 않음', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _logConsent() {
    // 동의 로그 기록 (개발용)
    print('=== 사용자 동의 로그 ===');
    print('개인정보처리방침: $_privacyConsent');
    print('이용약관: $_termsConsent');
    print('마케팅 정보: $_marketingConsent');
    print('분석 데이터: $_analyticsConsent');
    print('동의 시간: ${DateTime.now()}');
    print('========================');
  }
} 