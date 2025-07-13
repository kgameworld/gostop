import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              const Text(
                '이용약관',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '이 이용약관은 전 세계 모든 사용자에게 적용됩니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),

              // 1. 서비스 개요
              _buildSection(
                '1. 서비스 개요',
                [
                  '당사는 "고스톱" 모바일 게임 서비스를 제공합니다.',
                  '이 서비스는 전통 고스톱 카드 게임을 모바일 환경에서 즐길 수 있도록 합니다.',
                  '서비스는 AI 대전, 멀티플레이어, 랭킹 시스템 등을 포함합니다.',
                ],
              ),

              // 2. 서비스 이용 조건
              _buildSection(
                '2. 서비스 이용 조건',
                [
                  '• 만 13세 이상의 사용자만 이용 가능합니다.',
                  '• 계정은 1인당 1개만 생성할 수 있습니다.',
                  '• 소셜 로그인(Google, Apple)을 통한 가입이 필요합니다.',
                  '• 게스트 모드도 제공되지만 제한된 기능만 이용 가능합니다.',
                ],
              ),

              // 3. 사용자 의무
              _buildSection(
                '3. 사용자 의무',
                [
                  '사용자는 다음 사항을 준수해야 합니다:',
                  '• 타인의 계정을 도용하거나 무단 사용하지 않기',
                  '• 부정한 방법으로 게임을 조작하거나 치팅하지 않기',
                  '• 다른 사용자에게 불쾌감을 주는 행위 금지',
                  '• 서비스의 안정성을 저해하는 행위 금지',
                  '• 저작권 및 지적재산권 침해 금지',
                  '• 불법적인 목적으로 서비스 이용 금지',
                ],
              ),

              // 4. 서비스 제공자의 의무
              _buildSection(
                '4. 서비스 제공자의 의무',
                [
                  '당사는 다음 의무를 수행합니다:',
                  '• 안정적이고 지속적인 서비스 제공',
                  '• 사용자 개인정보 보호',
                  '• 적절한 고객 지원 제공',
                  '• 서비스 개선 및 새로운 기능 개발',
                  '• 보안 및 사기 방지 조치',
                ],
              ),

              // 5. 지적재산권
              _buildSection(
                '5. 지적재산권',
                [
                  '• 서비스의 모든 콘텐츠는 당사의 지적재산권입니다.',
                  '• 사용자는 서비스 이용 목적으로만 콘텐츠를 사용할 수 있습니다.',
                  '• 무단 복제, 배포, 수정은 금지됩니다.',
                  '• 사용자가 생성한 콘텐츠의 권리는 사용자에게 있습니다.',
                ],
              ),

              // 6. 결제 및 환불
              _buildSection(
                '6. 결제 및 환불',
                [
                  '• 게임 내 결제는 앱스토어 정책을 따릅니다.',
                  '• 환불은 앱스토어 정책에 따라 처리됩니다.',
                  '• 당사는 결제 관련 분쟁 시 적극적으로 협력합니다.',
                  '• 게임 내 코인은 환불 대상이 아닙니다.',
                ],
              ),

              // 7. 서비스 중단 및 변경
              _buildSection(
                '7. 서비스 중단 및 변경',
                [
                  '• 정기 점검, 시스템 업데이트 등으로 서비스가 일시 중단될 수 있습니다.',
                  '• 중요한 변경사항은 사전 공지 후 적용됩니다.',
                  '• 서비스 종료 시 30일 전 공지합니다.',
                  '• 긴급한 보안 문제로 즉시 중단될 수 있습니다.',
                ],
              ),

              // 8. 책임 제한
              _buildSection(
                '8. 책임 제한',
                [
                  '• 서비스 중단으로 인한 손해에 대해 책임을 지지 않습니다.',
                  '• 사용자의 과실로 인한 손해는 사용자가 부담합니다.',
                  '• 간접적 손해, 영업 손실 등은 배상하지 않습니다.',
                  '• 법적 요구사항에 따른 최소한의 책임만 부담합니다.',
                ],
              ),

              // 9. 분쟁 해결
              _buildSection(
                '9. 분쟁 해결',
                [
                  '• 분쟁 발생 시 우선 대화를 통한 해결을 시도합니다.',
                  '• 해결되지 않을 경우 한국 법원의 관할을 따릅니다.',
                  '• 한국 법을 준거법으로 합니다.',
                  '• 소액 분쟁은 온라인 분쟁 해결 시스템을 이용할 수 있습니다.',
                ],
              ),

              // 10. 약관 변경
              _buildSection(
                '10. 약관 변경',
                [
                  '• 당사는 필요에 따라 이 약관을 변경할 수 있습니다.',
                  '• 중요한 변경사항은 30일 전 공지합니다.',
                  '• 변경 후 계속 이용하는 경우 변경된 약관에 동의한 것으로 간주합니다.',
                  '• 동의하지 않는 경우 서비스 이용을 중단할 수 있습니다.',
                ],
              ),

              // 11. 개인정보 보호
              _buildSection(
                '11. 개인정보 보호',
                [
                  '• 개인정보 수집 및 이용에 대해서는 별도의 개인정보처리방침을 따릅니다.',
                  '• 개인정보처리방침은 이 약관의 일부로 간주됩니다.',
                  '• 개인정보 보호 관련 문의는 privacy@gostop-game.com으로 연락주세요.',
                ],
              ),

              // 12. 기타
              _buildSection(
                '12. 기타',
                [
                  '• 이 약관에서 정하지 않은 사항은 관련 법령 및 상관례에 따릅니다.',
                  '• 약관의 일부가 무효한 경우 나머지 부분은 유효합니다.',
                  '• 당사와 사용자 간의 합의는 이 약관을 우선합니다.',
                ],
              ),

              const SizedBox(height: 24),

              // 중요 공지사항
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          '중요 공지사항',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '이 이용약관은 기본적인 글로벌 약관입니다. 사용자가 거주하는 지역에 따라 추가적인 법적 요구사항이 있을 수 있습니다. 당사는 지역별 특화 약관을 단계적으로 제공할 예정입니다.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 마지막 업데이트
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '마지막 업데이트: 2024년 12월',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchEmail('legal@gostop-game.com'),
                    child: const Text(
                      '문의하기',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=이용약관 문의',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
} 