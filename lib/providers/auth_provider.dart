import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _userProfile?['is_guest'] == true;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // 현재 사용자 상태 확인
    _currentUser = _authService.currentUser;
    
    // 인증 상태 변경 리스너
    _authService.authStateChanges.listen((data) {
      _handleAuthStateChange(data);
    });
  }

  void _handleAuthStateChange(AuthState data) {
    _currentUser = data.session?.user;
    _error = null;
    
    if (_currentUser != null) {
      _loadUserProfile();
    } else {
      _userProfile = null;
    }
    
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    
    try {
      _userProfile = await _authService.getUserProfile(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      _error = '프로필 로드 실패: $e';
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    
    try {
      await _authService.signInWithGoogle();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _error = _getErrorMessage(e);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _setLoading(true);
    _error = null;
    
    try {
      await _authService.signInWithApple();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _error = _getErrorMessage(e);
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    _error = null;
    
    try {
      await _authService.signInWithFacebook();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _error = _getErrorMessage(e);
      return false;
    }
  }

  Future<bool> signInAsGuest() async {
    _setLoading(true);
    _error = null;
    
    try {
      await _authService.signInAsGuest();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _error = _getErrorMessage(e);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authService.signOut();
      _currentUser = null;
      _userProfile = null;
      _error = null;
    } catch (e) {
      _error = _getErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? nickname,
    String? avatarUrl,
    int? level,
  }) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    _error = null;
    
    try {
      await _authService.updateUserProfile(
        userId: _currentUser!.id,
        nickname: nickname,
        avatarUrl: avatarUrl,
        level: level,
      );
      
      // 프로필 다시 로드
      await _loadUserProfile();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _error = _getErrorMessage(e);
      return false;
    }
  }

  Future<void> saveGameHistory({
    required int score,
    required bool isWin,
    required Map<String, dynamic> gameData,
  }) async {
    if (_currentUser == null) return;
    
    try {
      await _authService.saveGameHistory(
        userId: _currentUser!.id,
        score: score,
        isWin: isWin,
        gameData: gameData,
      );
      
      // 프로필 다시 로드 (레벨 업데이트 등)
      await _loadUserProfile();
    } catch (e) {
      _error = _getErrorMessage(e);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return '로그인에 실패했습니다. 다시 시도해주세요.';
        case 'Email not confirmed':
          return '이메일 인증이 필요합니다.';
        case 'User already registered':
          return '이미 등록된 계정입니다.';
        case 'OAuth account not linked':
          return '소셜 계정이 연결되지 않았습니다.';
        case 'Signup disabled':
          return '회원가입이 비활성화되어 있습니다.';
        default:
          return error.message;
      }
    }
    return error.toString();
  }
} 