class ScoreResult {
  final int base;
  final int mult;
  final int total;
  final Map<String, int> detail;
  const ScoreResult({required this.base, required this.mult, required this.total, required this.detail});
}

class PlayerState {
  final List<dynamic> captured; // GoStopCard 또는 CardModel 리스트
  final int goCount;
  final bool bomb;
  final bool shake;
  final bool bak;
  final bool chongtong;
  // ... 필요시 추가
  PlayerState({required this.captured, this.goCount = 0, this.bomb = false, this.shake = false, this.bak = false, this.chongtong = false});
}

ScoreResult compute(PlayerState s) {
  int base = 0;
  int mult = 1;
  final detail = <String, int>{};

  // 광 점수
  final gwang = s.captured.where((c) => c.type == '광').toList();
  final hasRain = gwang.any((c) => c.month == 11);
  if (gwang.length == 3) {
    detail['gwang'] = hasRain ? 2 : 3;
    base += detail['gwang']!;
  } else if (gwang.length == 4) {
    detail['gwang'] = 4;
    base += 4;
  } else if (gwang.length >= 5) {
    detail['gwang'] = 15;
    base += 15;
  }

  // 띠 점수
  final tti = s.captured.where((c) => c.type == '띠').length;
  if (tti >= 5) {
    detail['tti'] = tti - 4;
    base += tti - 4;
  }

  // 피 점수
  final pi = s.captured.where((c) => c.type == '피').length;
  if (pi >= 10) {
    detail['pi'] = pi - 9;
    base += pi - 9;
  }

  // 오 점수
  final oh = s.captured.where((c) => c.type == '오').length;
  if (oh >= 2) {
    detail['oh'] = oh - 1;
    base += oh - 1;
  }

  // 폭탄/흔들기/박/총통 등 멀티플라이어
  if (s.bomb) {
    mult *= 2;
    detail['bomb'] = 2;
  }
  if (s.shake) {
    mult *= 2;
    detail['shake'] = 2;
  }
  if (s.bak) {
    mult *= 2;
    detail['bak'] = 2;
  }
  if (s.chongtong) {
    base += 7;
    detail['chongtong'] = 7;
  }

  // 고 보너스
  if (s.goCount == 1) {
    base += 1;
    detail['go'] = 1;
  } else if (s.goCount == 2) {
    base += 2;
    detail['go'] = 2;
  } else if (s.goCount >= 3) {
    base += 2;
    mult *= (1 << (s.goCount - 2));
    detail['go'] = 2;
    detail['goMult'] = (1 << (s.goCount - 2));
  }

  int total = base * mult;
  return ScoreResult(base: base, mult: mult, total: total, detail: detail);
} 