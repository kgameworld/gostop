import 'package:shared_preferences/shared_preferences.dart';

class GuestRestrictions {
  static final GuestRestrictions _instance = GuestRestrictions._internal();
  factory GuestRestrictions() => _instance;
  GuestRestrictions._internal();

  // 게스트 모드 제한 설정
  static const int _maxAIMatchesPerDay = 3;
  static const int _maxRandomMatchesPerDay = 3;
  static const int _maxAdRewardsPerDay = 5;
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _aiMatchesTodayKey = 'ai_matches_today';
  static const String _randomMatchesTodayKey = 'random_matches_today';
  static const String _adRewardsTodayKey = 'ad_rewards_today';

  // 일일 제한 초기화 확인
  Future<void> _checkDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString(_lastResetDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastResetDate != today) {
      // 새로운 날짜이므로 카운터 초기화
      await prefs.setString(_lastResetDateKey, today);
      await prefs.setInt(_aiMatchesTodayKey, 0);
      await prefs.setInt(_randomMatchesTodayKey, 0);
      await prefs.setInt(_adRewardsTodayKey, 0);
    }
  }

  // 게임 플레이 제한 확인
  bool canPlayGameMode(String gameMode, bool isGuest) {
    if (!isGuest) return true; // 정식 사용자는 모든 모드 가능
    
    // 게스트는 AI 매치만 가능
    return gameMode == 'ai_match';
  }

  // AI 매치 제한 확인
  Future<bool> canPlayAIMatch(bool isGuest) async {
    if (!isGuest) return true; // 정식 사용자는 무제한
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final matchesToday = prefs.getInt(_aiMatchesTodayKey) ?? 0;
    
    return matchesToday < _maxAIMatchesPerDay;
  }

  // AI 매치 사용 기록
  Future<void> recordAIMatch(bool isGuest) async {
    if (!isGuest) return; // 정식 사용자는 기록하지 않음
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final matchesToday = prefs.getInt(_aiMatchesTodayKey) ?? 0;
    await prefs.setInt(_aiMatchesTodayKey, matchesToday + 1);
  }

  // 남은 AI 매치 횟수 확인
  Future<int> getRemainingAIMatches(bool isGuest) async {
    if (!isGuest) return -1; // 정식 사용자는 무제한 (-1)
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final matchesToday = prefs.getInt(_aiMatchesTodayKey) ?? 0;
    
    return _maxAIMatchesPerDay - matchesToday;
  }

  // 랜덤 매칭 제한 확인
  Future<bool> canPlayRandomMatch(bool isGuest) async {
    if (!isGuest) return true; // 정식 사용자는 무제한
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final matchesToday = prefs.getInt(_randomMatchesTodayKey) ?? 0;
    
    return matchesToday < _maxRandomMatchesPerDay;
  }

  // 랜덤 매칭 사용 기록
  Future<void> recordRandomMatch(bool isGuest) async {
    if (!isGuest) return; // 정식 사용자는 기록하지 않음
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final matchesToday = prefs.getInt(_randomMatchesTodayKey) ?? 0;
    await prefs.setInt(_randomMatchesTodayKey, matchesToday + 1);
  }

  // 남은 랜덤 매칭 횟수 확인
  Future<int> getRemainingRandomMatches(bool isGuest) async {
    if (!isGuest) return -1; // 정식 사용자는 무제한 (-1)
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final matchesToday = prefs.getInt(_randomMatchesTodayKey) ?? 0;
    
    return _maxRandomMatchesPerDay - matchesToday;
  }

  // 광고 보상 제한 확인
  Future<bool> canWatchAdReward(bool isGuest) async {
    if (!isGuest) return true; // 정식 사용자는 무제한
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final rewardsToday = prefs.getInt(_adRewardsTodayKey) ?? 0;
    
    return rewardsToday < _maxAdRewardsPerDay;
  }

  // 광고 보상 사용 기록
  Future<void> recordAdReward(bool isGuest) async {
    if (!isGuest) return; // 정식 사용자는 기록하지 않음
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final rewardsToday = prefs.getInt(_adRewardsTodayKey) ?? 0;
    await prefs.setInt(_adRewardsTodayKey, rewardsToday + 1);
  }

  // 남은 광고 보상 횟수 확인
  Future<int> getRemainingAdRewards(bool isGuest) async {
    if (!isGuest) return -1; // 정식 사용자는 무제한 (-1)
    
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final rewardsToday = prefs.getInt(_adRewardsTodayKey) ?? 0;
    
    return _maxAdRewardsPerDay - rewardsToday;
  }

  // IAP 구매 가능 여부
  bool canPurchaseIAP(bool isGuest) {
    return !isGuest; // 게스트는 IAP 불가
  }

  // 친구 기능 제한 확인
  bool canUseFriendFeatures(String feature, bool isGuest) {
    if (!isGuest) return true; // 정식 사용자는 모든 기능 가능
    
    switch (feature) {
      case 'read_friends':
      case 'read_ranking':
        return true; // 읽기 전용 허용
      case 'send_invite':
      case 'send_dm':
      case 'add_friend':
        return false; // 초대, DM, 친구 추가 불가
      default:
        return false;
    }
  }

  // 클라우드 백업 가능 여부
  bool canUseCloudBackup(bool isGuest) {
    return !isGuest; // 게스트는 로컬 캐시만
  }

  // 고객센터 기능 제한 확인
  bool canUseCustomerService(String feature, bool isGuest) {
    if (!isGuest) return true; // 정식 사용자는 모든 기능 가능
    
    switch (feature) {
      case 'read_faq':
        return true; // FAQ 읽기만 허용
      case 'create_ticket':
      case 'chat_support':
        return false; // 티켓 생성, 채팅 지원 불가
      default:
        return false;
    }
  }

  // 게스트 모드 제한사항 요약
  Map<String, dynamic> getGuestRestrictionsSummary(bool isGuest) {
    if (!isGuest) {
      return {
        'isGuest': false,
        'restrictions': '정식 사용자 - 모든 기능 이용 가능',
      };
    }

    return {
      'isGuest': true,
      'gamePlay': 'AI 매치만 가능 (1일 3판 제한)',
      'randomMatch': '1일 3판 제한',
      'iap': '구매 불가',
      'adRewards': '1일 5회 제한',
      'friends': '읽기 전용 (초대·DM 불가)',
      'cloudBackup': '로컬 캐시만',
      'customerService': 'FAQ 읽기만 가능',
    };
  }

  // 게스트 모드 업그레이드 안내 메시지
  String getUpgradeMessage(String feature) {
    switch (feature) {
      case 'ai_match':
        return 'AI 매치는 1일 3판으로 제한됩니다.\n계정을 만들어서 무제한으로 플레이하세요!';
      case 'random_match':
        return '랜덤 매칭은 1일 3판으로 제한됩니다.\n계정을 만들어서 무제한으로 플레이하세요!';
      case 'ad_reward':
        return '광고 보상은 1일 5회로 제한됩니다.\n계정을 만들어서 더 많은 보상을 받으세요!';
      case 'iap':
        return '게스트 모드에서는 구매가 불가능합니다.\n계정을 만들어서 코인과 배틀패스를 구매하세요!';
      case 'friend_invite':
        return '게스트 모드에서는 친구 초대가 불가능합니다.\n계정을 만들어서 친구들과 함께 플레이하세요!';
      case 'cloud_backup':
        return '게스트 모드에서는 로컬에만 저장됩니다.\n계정을 만들어서 클라우드에 안전하게 백업하세요!';
      case 'customer_service':
        return '게스트 모드에서는 FAQ만 확인 가능합니다.\n계정을 만들어서 전문 상담을 받으세요!';
      default:
        return '이 기능을 사용하려면 계정이 필요합니다.';
    }
  }
} 