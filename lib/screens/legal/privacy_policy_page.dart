import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.privacyPolicy, style: const TextStyle(color: Colors.white)),
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
              Text(
                AppLocalizations.of(context)!.privacyPolicy,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.privacyPolicyGlobal,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),

              // 1. 수집하는 개인정보
              _buildSection(
                AppLocalizations.of(context)!.section1CollectedInfo,
                [
                  AppLocalizations.of(context)!.section1CollectedInfo1,
                  AppLocalizations.of(context)!.section1CollectedInfo2,
                  AppLocalizations.of(context)!.section1CollectedInfo3,
                  AppLocalizations.of(context)!.section1CollectedInfo4,
                ],
              ),

              // 2. 개인정보 수집 목적
              _buildSection(
                AppLocalizations.of(context)!.section2Purpose,
                [
                  AppLocalizations.of(context)!.section2Purpose1,
                  AppLocalizations.of(context)!.section2Purpose2,
                  AppLocalizations.of(context)!.section2Purpose3,
                  AppLocalizations.of(context)!.section2Purpose4,
                  AppLocalizations.of(context)!.section2Purpose5,
                ],
              ),

              // 3. 개인정보 보관 기간
              _buildSection(
                AppLocalizations.of(context)!.section3Retention,
                [
                  AppLocalizations.of(context)!.section3Retention1,
                  AppLocalizations.of(context)!.section3Retention2,
                  AppLocalizations.of(context)!.section3Retention3,
                ],
              ),

              // 4. 개인정보 제3자 제공
              _buildSection(
                AppLocalizations.of(context)!.section4Provision,
                [
                  AppLocalizations.of(context)!.section4Provision1,
                  AppLocalizations.of(context)!.section4Provision2,
                  AppLocalizations.of(context)!.section4Provision3,
                ],
              ),

              // 5. 사용자 권리
              _buildSection(
                AppLocalizations.of(context)!.section5Rights,
                [
                  AppLocalizations.of(context)!.section5Rights1,
                  AppLocalizations.of(context)!.section5Rights2,
                  AppLocalizations.of(context)!.section5Rights3,
                  AppLocalizations.of(context)!.section5Rights4,
                  AppLocalizations.of(context)!.section5Rights5,
                ],
              ),

              // 6. 데이터 보안
              _buildSection(
                AppLocalizations.of(context)!.section6Security,
                [
                  AppLocalizations.of(context)!.section6Security1,
                  AppLocalizations.of(context)!.section6Security2,
                  AppLocalizations.of(context)!.section6Security3,
                  AppLocalizations.of(context)!.section6Security4,
                ],
              ),

              // 7. 국제 데이터 이전
              _buildSection(
                AppLocalizations.of(context)!.section7International,
                [
                  AppLocalizations.of(context)!.section7International1,
                  AppLocalizations.of(context)!.section7International2,
                  AppLocalizations.of(context)!.section7International3,
                  AppLocalizations.of(context)!.section7International4,
                ],
              ),

              // 8. 아동 개인정보 보호
              _buildSection(
                AppLocalizations.of(context)!.section8Children,
                [
                  AppLocalizations.of(context)!.section8Children1,
                  AppLocalizations.of(context)!.section8Children2,
                  AppLocalizations.of(context)!.section8Children3,
                ],
              ),

              // 9. 쿠키 및 추적 기술
              _buildSection(
                AppLocalizations.of(context)!.section9Cookies,
                [
                  AppLocalizations.of(context)!.section9Cookies1,
                  AppLocalizations.of(context)!.section9Cookies2,
                  AppLocalizations.of(context)!.section9Cookies3,
                ],
              ),

              // 10. 개인정보처리방침 변경
              _buildSection(
                AppLocalizations.of(context)!.section10Changes,
                [
                  AppLocalizations.of(context)!.section10Changes1,
                  AppLocalizations.of(context)!.section10Changes2,
                  AppLocalizations.of(context)!.section10Changes3,
                ],
              ),

              // 11. 문의 및 신고
              _buildSection(
                AppLocalizations.of(context)!.section11Inquiries,
                [
                  AppLocalizations.of(context)!.section11Inquiries1,
                  AppLocalizations.of(context)!.section11Inquiries2,
                  AppLocalizations.of(context)!.section11Inquiries3,
                  AppLocalizations.of(context)!.section11Inquiries4,
                  AppLocalizations.of(context)!.section11Inquiries5,
                ],
              ),

              // 12. 권리 행사 방법
              _buildSection(
                AppLocalizations.of(context)!.section12ExerciseRights,
                [
                  AppLocalizations.of(context)!.section12ExerciseRights1,
                  AppLocalizations.of(context)!.section12ExerciseRights2,
                  AppLocalizations.of(context)!.section12ExerciseRights3,
                  AppLocalizations.of(context)!.section12ExerciseRights4,
                  AppLocalizations.of(context)!.section12ExerciseRights5,
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
                        Text(
                          AppLocalizations.of(context)!.importantNotice,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.privacyPolicyNotice,
                      style: const TextStyle(
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
                  Text(
                    AppLocalizations.of(context)!.lastUpdated,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchEmail('privacy@gostop-game.com'),
                    child: Text(
                      AppLocalizations.of(context)!.contactUs,
                      style: const TextStyle(color: Colors.white),
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
      query: 'subject=개인정보처리방침 문의',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
} 