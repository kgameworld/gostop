import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class PrivacyManager {
  static final PrivacyManager _instance = PrivacyManager._internal();
  factory PrivacyManager() => _instance;
  PrivacyManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // 동의 상태 확인
  Future<Map<String, bool>> getConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'privacy': prefs.getBool('privacy_consent') ?? false,
      'terms': prefs.getBool('terms_consent') ?? false,
      'marketing': prefs.getBool('marketing_consent') ?? false,
      'analytics': prefs.getBool('analytics_consent') ?? false,
    };
  }

  // 동의 상태 업데이트
  Future<void> updateConsentStatus({
    bool? privacy,
    bool? terms,
    bool? marketing,
    bool? analytics,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (privacy != null) await prefs.setBool('privacy_consent', privacy);
    if (terms != null) await prefs.setBool('terms_consent', terms);
    if (marketing != null) await prefs.setBool('marketing_consent', marketing);
    if (analytics != null) await prefs.setBool('analytics_consent', analytics);
    
    await prefs.setString('consent_update_date', DateTime.now().toIso8601String());
  }

  // 동의 날짜 조회
  Future<DateTime?> getConsentDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('consent_date');
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // 개인정보 조회
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // 프로필 정보 조회
      final profileResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', user.id)
          .single();

      // 게임 기록 조회 (최근 10개)
      final gameHistoryResponse = await _supabase
          .from(SupabaseConfig.gameHistoryTable)
          .select()
          .eq('user_id', user.id)
          .order('played_at', ascending: false)
          .limit(10);

      return {
        'profile': profileResponse,
        'game_history': gameHistoryResponse,
        'email': user.email,
        'created_at': user.createdAt, // 이미 문자열
        'last_sign_in': user.lastSignInAt, // 이미 문자열
      };
    } catch (e) {
      print('개인정보 조회 오류: $e');
      return null;
    }
  }

  // 개인정보 수정
  Future<bool> updateUserData({
    String? nickname,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (nickname != null) updates['nickname'] = nickname;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update(updates)
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('개인정보 수정 오류: $e');
      return false;
    }
  }

  // 개인정보 삭제 요청
  Future<bool> requestDataDeletion() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // 삭제 요청 로그 저장
      await _supabase
          .from('deletion_requests')
          .insert({
            'user_id': user.id,
            'requested_at': DateTime.now().toIso8601String(),
            'status': 'pending',
          });

      // 삭제 요청 이메일 발송 (실제 구현 시)
      _sendDeletionRequestEmail(user.email);

      return true;
    } catch (e) {
      print('삭제 요청 오류: $e');
      return false;
    }
  }

  // 데이터 이전 요청
  Future<Map<String, dynamic>?> requestDataPortability() async {
    try {
      final userData = await getUserData();
      if (userData == null) return null;

      // JSON 형태로 데이터 내보내기
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_data': userData,
        'consent_status': await getConsentStatus(),
        'consent_date': await getConsentDate(),
      };

      return exportData;
    } catch (e) {
      print('데이터 이전 요청 오류: $e');
      return null;
    }
  }

  // 개인정보 처리 중단
  Future<bool> pauseDataProcessing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('data_processing_paused', true);
      await prefs.setString('pause_date', DateTime.now().toIso8601String());
      
      // 서버에도 중단 상태 기록
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase
            .from(SupabaseConfig.profilesTable)
            .update({
              'data_processing_paused': true,
              'pause_date': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
      }

      return true;
    } catch (e) {
      print('데이터 처리 중단 오류: $e');
      return false;
    }
  }

  // 개인정보 처리 재개
  Future<bool> resumeDataProcessing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('data_processing_paused', false);
      
      // 서버에서도 중단 상태 해제
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase
            .from(SupabaseConfig.profilesTable)
            .update({
              'data_processing_paused': false,
              'resume_date': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
      }

      return true;
    } catch (e) {
      print('데이터 처리 재개 오류: $e');
      return false;
    }
  }

  // 데이터 처리 중단 상태 확인
  Future<bool> isDataProcessingPaused() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('data_processing_paused') ?? false;
  }

  // 개인정보 수집 최소화 확인
  Future<Map<String, bool>> getDataCollectionStatus() async {
    final consentStatus = await getConsentStatus();
    
    return {
      'essential_data': consentStatus['privacy'] ?? false,
      'marketing_data': consentStatus['marketing'] ?? false,
      'analytics_data': consentStatus['analytics'] ?? false,
      'processing_paused': await isDataProcessingPaused(),
    };
  }

  // 개인정보 보안 상태 확인
  Future<Map<String, dynamic>> getSecurityStatus() async {
    final user = _supabase.auth.currentUser;
    
    return {
      'account_created': user?.createdAt, // 이미 문자열
      'last_sign_in': user?.lastSignInAt, // 이미 문자열
      'email_verified': user?.emailConfirmedAt != null,
      'phone_verified': user?.phoneConfirmedAt != null,
      'two_factor_enabled': false, // 향후 구현
      'session_active': user != null,
    };
  }

  // 개인정보 침해 신고
  Future<bool> reportPrivacyViolation({
    required String description,
    required String category,
    String? evidence,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      
      await _supabase
          .from('privacy_violations')
          .insert({
            'user_id': user?.id,
            'description': description,
            'category': category,
            'evidence': evidence,
            'reported_at': DateTime.now().toIso8601String(),
            'status': 'pending',
          });

      return true;
    } catch (e) {
      print('개인정보 침해 신고 오류: $e');
      return false;
    }
  }

  // 개인정보 처리방침 변경 알림
  Future<void> notifyPolicyChange({
    required String version,
    required String summary,
    required DateTime effectiveDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('policy_version', version);
      await prefs.setString('policy_change_date', DateTime.now().toIso8601String());
      await prefs.setString('policy_summary', summary);
      await prefs.setString('policy_effective_date', effectiveDate.toIso8601String());
    } catch (e) {
      print('정책 변경 알림 오류: $e');
    }
  }

  // 정책 변경 확인
  Future<Map<String, dynamic>?> getPolicyChangeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString('policy_version');
    final changeDate = prefs.getString('policy_change_date');
    final summary = prefs.getString('policy_summary');
    final effectiveDate = prefs.getString('policy_effective_date');

    if (version != null && changeDate != null) {
      return {
        'version': version,
        'change_date': changeDate,
        'summary': summary,
        'effective_date': effectiveDate,
      };
    }
    return null;
  }

  // 이메일 발송 (실제 구현 시)
  void _sendDeletionRequestEmail(String? email) {
    if (email != null) {
      // 실제 이메일 발송 로직 구현
      print('삭제 요청 이메일 발송: $email');
    }
  }

  // 개인정보 처리 로그 기록
  Future<void> logDataProcessing({
    required String action,
    required String dataType,
    String? userId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _supabase
          .from('data_processing_logs')
          .insert({
            'user_id': userId,
            'action': action,
            'data_type': dataType,
            'details': details,
            'timestamp': DateTime.now().toIso8601String(),
            'ip_address': 'client_ip', // 실제 구현 시
          });
    } catch (e) {
      print('처리 로그 기록 오류: $e');
    }
  }
} 