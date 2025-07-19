import 'package:flutter/material.dart';
import '../services/privacy_manager.dart';

class ConsentSettingsDialog extends StatefulWidget {
  const ConsentSettingsDialog({super.key});

  @override
  State<ConsentSettingsDialog> createState() => _ConsentSettingsDialogState();
}

class _ConsentSettingsDialogState extends State<ConsentSettingsDialog> {
  final PrivacyManager _privacyManager = PrivacyManager();
  Map<String, bool> _consentStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  Future<void> _loadConsentStatus() async {
    final status = await _privacyManager.getConsentStatus();
    setState(() {
      _consentStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _updateConsent(String type, bool value) async {
    setState(() => _isLoading = true);
    
    try {
      await _privacyManager.updateConsentStatus(
        privacy: type == 'privacy' ? value : null,
        terms: type == 'terms' ? value : null,
        marketing: type == 'marketing' ? value : null,
        analytics: type == 'analytics' ? value : null,
      );
      
      await _loadConsentStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동의 설정이 업데이트되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 업데이트 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.privacy_tip, color: Colors.green[700]),
          const SizedBox(width: 8),
          const Text('동의 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '개인정보 수집 및 이용에 대한 동의를 관리할 수 있습니다.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // 필수 동의 항목
                  const Text(
                    '필수 동의 항목',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  _buildConsentItem(
                    title: '개인정보처리방침',
                    subtitle: '개인정보 수집 및 이용에 동의합니다',
                    value: _consentStatus['privacy'] ?? false,
                    onChanged: (value) => _updateConsent('privacy', value ?? false),
                    isRequired: true,
                  ),

                  const SizedBox(height: 8),

                  _buildConsentItem(
                    title: '이용약관',
                    subtitle: '서비스 이용약관에 동의합니다',
                    value: _consentStatus['terms'] ?? false,
                    onChanged: (value) => _updateConsent('terms', value ?? false),
                    isRequired: true,
                  ),

                  const SizedBox(height: 20),

                  // 선택 동의 항목
                  const Text(
                    '선택 동의 항목',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  _buildConsentItem(
                    title: '마케팅 정보 수신',
                    subtitle: '이벤트, 업데이트 등 마케팅 정보를 받습니다',
                    value: _consentStatus['marketing'] ?? false,
                    onChanged: (value) => _updateConsent('marketing', value ?? false),
                    isRequired: false,
                  ),

                  const SizedBox(height: 8),

                  _buildConsentItem(
                    title: '서비스 개선 분석',
                    subtitle: '서비스 개선을 위한 사용 통계 수집에 동의합니다',
                    value: _consentStatus['analytics'] ?? false,
                    onChanged: (value) => _updateConsent('analytics', value ?? false),
                    isRequired: false,
                  ),

                  const SizedBox(height: 20),

                  // 안내사항
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '안내사항',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• 필수 항목에 동의하지 않으면 서비스를 이용할 수 없습니다.\n• 선택 항목은 언제든지 변경할 수 있습니다.\n• 동의 철회 시 관련 기능이 제한될 수 있습니다.',
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _buildConsentItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required bool isRequired,
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
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
} 