import 'package:shared_preferences/shared_preferences.dart';

class CoinService {
  static const _key = 'coins';
  static final CoinService instance = CoinService._internal();
  CoinService._internal();

  Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 1000;
  }

  Future<void> _setCoins(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value.clamp(0, 1000000000));
  }

  /// delta 양수: 지급, 음수: 차감. 차감 후 음수이면 false 반환.
  Future<bool> addCoins(int delta) async {
    final current = await getCoins();
    final next = current + delta;
    if (next < 0) return false;
    await _setCoins(next);
    return true;
  }
} 