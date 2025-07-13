
import '../models/card_model.dart';

class EventEvaluator {
  final List<String> pukHistory = [];

  /// 쪽: 낸 카드 짝 없고, 더미 카드가 바닥에 짝 있을 때
  static bool isChok(GoStopCard played, GoStopCard drawn, List<GoStopCard> field) {
    final playedMatch = field.where((c) => c.month == played.month).toList();
    final drawnMatch = field.where((c) => c.month == drawn.month).toList();
    return playedMatch.isEmpty && drawnMatch.length == 1;
  }

  /// 따닥: 바닥에 동일 월 카드 2장이 있을 때 냈을 경우
  static bool isTtak(GoStopCard played, List<GoStopCard> field) {
    final matches = field.where((c) => c.month == played.month).toList();
    return matches.length == 2;
  }

  /// 폭탄: 낸 카드 기준 손패 동일 월 3장 + 바닥에 해당 월 1장 있을 때
  static bool isBomb(List<GoStopCard> hand, GoStopCard playedCard, List<GoStopCard> field) {
    // 손패에 낸 카드 월이 3장 이상인지 확인
    final sameMonthInHand = hand.where((c) => c.month == playedCard.month).length;
    // 필드에 낸 카드 월이 1장 이상 있는지 확인
    final sameMonthInField = field.where((c) => c.month == playedCard.month).length;
    return sameMonthInHand >= 3 && sameMonthInField >= 1;
  }

  /// 뻑: 낸 카드 포함 동일 월 3장 등장 시
  bool isPuk(GoStopCard played, List<GoStopCard> field) {
    final matchCount = field.where((c) => c.month == played.month).length + 1;
    if (matchCount == 3) {
      pukHistory.add(played.month.toString());
      return true;
    }
    return false;
  }

  /// 3뻑: 뻑 3회 누적 시 즉시 승리 처리 (외부에서 확인)
  bool isTriplePuk() {
    return pukHistory.length >= 3;
  }
}
