import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../config/supabase_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // 현재 사용자 정보
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // 인증 상태 스트림
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Google 로그인 (Supabase OAuth 방식)
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.go-stop-app://login-callback/',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Apple 로그인 (Supabase OAuth 방식)
  Future<void> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.go-stop-app://login-callback/',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Facebook 로그인
  Future<void> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.success) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.facebook,
          redirectTo: 'io.supabase.go-stop-app://login-callback/',
        );
      } else {
        throw Exception('Facebook 로그인 실패:  [${result.status}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 게스트 로그인 (API 연동)
  Future<bool> signInAsGuest() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'guest_$timestamp@guest.com';
      final password = 'guest_pw_$timestamp';
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (_supabase.auth.currentUser == null) {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _createUserProfile(
          userId: user.id,
          email: email,
          nickname: '게스트',
          isGuest: true,
        );
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {}
      await _supabase.auth.signOut();
      await _secureStorage.deleteAll();
    } catch (e) {
      rethrow;
    }
  }

  // 사용자 프로필 생성
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String nickname,
    String? avatarUrl,
    bool isGuest = false,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.profilesTable).insert({
        'id': userId,
        'email': email,
        'nickname': nickname,
        'avatar_url': avatarUrl,
        'level': 1,
        'total_games': 0,
        'wins': 0,
        'is_guest': isGuest,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // 프로필 업데이트
  Future<void> updateUserProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    int? level,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (nickname != null) updates['nickname'] = nickname;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (level != null) updates['level'] = level;
      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // 게임 기록 저장
  Future<void> saveGameHistory({
    required String userId,
    required int score,
    required bool isWin,
    required Map<String, dynamic> gameData,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.gameHistoryTable).insert({
        'user_id': userId,
        'score': score,
        'is_win': isWin,
        'game_data': gameData,
        'played_at': DateTime.now().toIso8601String(),
      });
      // 사용자 통계 업데이트
      final profile = await getUserProfile(userId);
      if (profile != null) {
        await updateUserProfile(
          userId: userId,
          level: profile['level'],
        );
      }
    } catch (e) {
      rethrow;
    }
  }
} 