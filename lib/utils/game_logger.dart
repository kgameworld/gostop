import '../models/card_model.dart';

// 로그 레벨 정의
enum LogLevel {
  info,
  rule,
  actual,
  validation,
  error,
  warning,
}

// 로그 엔트리 클래스
class LogEntry {
  final int turnNumber;
  final int playerNumber;
  final String phase;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  LogEntry({
    required this.turnNumber,
    required this.playerNumber,
    required this.phase,
    required this.level,
    required this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final levelStr = level.name.toUpperCase().padRight(8);
    return '[$timeStr][TURN $turnNumber][P$playerNumber][$phase] $levelStr: $message';
  }

  String toDetailedString() {
    final base = toString();
    if (data != null && data!.isNotEmpty) {
      final dataStr = data!.entries.map((e) => '${e.key}=${e.value}').join(', ');
      return '$base | Data: {$dataStr}';
    }
    return base;
  }
}

// 게임 규칙 검증 클래스
class RuleValidator {
  // 카드 매치 규칙 검증
  static Map<String, dynamic> validateCardMatch(GoStopCard playedCard, List<GoStopCard> fieldCards) {
    final matches = fieldCards.where((c) => c.month == playedCard.month).toList();
    
    return {
      'playedCard': '${playedCard.id}(${playedCard.name})',
      'fieldMatches': matches.map((c) => '${c.id}(${c.name})').toList(),
      'matchCount': matches.length,
      'expectedAction': _getExpectedActionForMatch(matches.length),
      'shouldShowChoice': matches.length == 2,
      'shouldCapture': matches.length >= 1,
    };
  }

  // 뻑 규칙 검증
  static Map<String, dynamic> validatePpeok(int? ppeokMonth, GoStopCard card) {
    final isPpeokCompletion = ppeokMonth != null && card.month == ppeokMonth;
    
    return {
      'ppeokMonth': ppeokMonth,
      'cardMonth': card.month,
      'isPpeokCompletion': isPpeokCompletion,
      'expectedAction': isPpeokCompletion ? '4장 모두 먹기 + 피 강탈' : '뻑 상태 설정',
      'shouldStealPi': isPpeokCompletion,
    };
  }

  // 따닥 규칙 검증
  static Map<String, dynamic> validateTtak(List<GoStopCard> fieldMatches, GoStopCard? playedCard) {
    final isTtak = fieldMatches.length == 2 && 
                   playedCard != null && 
                   fieldMatches.every((c) => c.month == playedCard!.month);
    
    return {
      'fieldMatches': fieldMatches.map((c) => '${c.id}(${c.name})').toList(),
      'playedCard': playedCard != null ? '${playedCard.id}(${playedCard.name})' : null,
      'isTtak': isTtak,
      'expectedAction': isTtak ? '4장 모두 먹기 + 피 강탈' : '2장 선택창',
      'shouldStealPi': isTtak,
    };
  }

  // 쪽 규칙 검증
  static Map<String, dynamic> validateJjok(GoStopCard? lastPlayedCard, GoStopCard drawnCard) {
    final isJjok = lastPlayedCard != null && lastPlayedCard.month == drawnCard.month;
    
    return {
      'lastPlayedCard': lastPlayedCard != null ? '${lastPlayedCard.id}(${lastPlayedCard.name})' : null,
      'drawnCard': '${drawnCard.id}(${drawnCard.name})',
      'isJjok': isJjok,
      'expectedAction': isJjok ? '2장 모두 먹기 + 피 1장 강탈' : '일반 처리',
      'shouldStealPi': isJjok,
    };
  }

  // 피 강탈 규칙 검증
  static Map<String, dynamic> validatePiSteal(List<GoStopCard> opponentCaptured) {
    final normalPi = opponentCaptured.where((c) => 
      c.type == '피' && 
      !c.imageUrl.contains('ssangpi') && 
      !c.imageUrl.contains('3pi') && 
      !c.isBonus
    ).toList();
    
    final ssangpi = opponentCaptured.where((c) => 
      c.type == '피' && 
      c.imageUrl.contains('ssangpi') && 
      !c.isBonus
    ).toList();
    
    final bonusPi = opponentCaptured.where((c) => 
      c.type == '피' && 
      (c.imageUrl.contains('3pi') || c.isBonus)
    ).toList();

    return {
      'totalPi': opponentCaptured.where((c) => c.type == '피').length,
      'normalPi': normalPi.map((c) => '${c.id}(${c.name})').toList(),
      'ssangpi': ssangpi.map((c) => '${c.id}(${c.name})').toList(),
      'bonusPi': bonusPi.map((c) => '${c.id}(${c.name})').toList(),
      'expectedPriority': normalPi.isNotEmpty ? '일반피' : 
                         ssangpi.isNotEmpty ? '쌍피' : 
                         bonusPi.isNotEmpty ? '보너스피' : '강탈 불가',
      'canSteal': normalPi.isNotEmpty || ssangpi.isNotEmpty || bonusPi.isNotEmpty,
    };
  }

  // 점수 계산 규칙 검증
  static Map<String, dynamic> validateScoreCalculation(List<GoStopCard> captured, int goCount) {
    final gwangCards = captured.where((c) => c.type == '광').toList();
    final ttiCards = captured.where((c) => c.type == '띠').toList();
    final piCards = captured.where((c) => c.type == '피').toList();
    final ohCards = captured.where((c) => c.type == '오').toList();

    int baseScore = 0;
    String gwangScore = '0점';
    String ttiScore = '0점';
    String piScore = '0점';
    String ohScore = '0점';

    // 광 점수
    if (gwangCards.length == 3) {
      final hasRainGwang = gwangCards.any((c) => c.month == 11);
      baseScore += hasRainGwang ? 2 : 3;
      gwangScore = hasRainGwang ? '2점 (비광 포함 3광)' : '3점 (3광)';
    } else if (gwangCards.length == 4) {
      baseScore += 4;
      gwangScore = '4점 (4광)';
    } else if (gwangCards.length >= 5) {
      baseScore += 15;
      gwangScore = '15점 (5광+)';
    }

    // 띠 점수
    if (ttiCards.length >= 5) {
      final ttiPoints = ttiCards.length - 4;
      baseScore += ttiPoints;
      ttiScore = '${ttiPoints}점 (${ttiCards.length}띠)';
    }

    // 피 점수
    if (piCards.length >= 10) {
      final piPoints = piCards.length - 9;
      baseScore += piPoints;
      piScore = '${piPoints}점 (${piCards.length}피)';
    }

    // 오 점수
    if (ohCards.length >= 2) {
      final ohPoints = ohCards.length - 1;
      baseScore += ohPoints;
      ohScore = '${ohPoints}점 (${ohCards.length}오)';
    }

    // 고스톱 보너스
    int totalScore = baseScore;
    String bonusScore = '0점';
    if (goCount == 1) {
      totalScore += 1;
      bonusScore = '1점 (고 1회)';
    } else if (goCount == 2) {
      totalScore += 2;
      bonusScore = '2점 (고 2회)';
    } else if (goCount >= 3) {
      totalScore = (baseScore + 2) * (1 << (goCount - 2));
      bonusScore = '${totalScore - baseScore}점 (고 ${goCount}회)';
    }

    return {
      'gwangCards': gwangCards.map((c) => '${c.id}(${c.name})').toList(),
      'ttiCards': ttiCards.map((c) => '${c.id}(${c.name})').toList(),
      'piCards': piCards.map((c) => '${c.id}(${c.name})').toList(),
      'ohCards': ohCards.map((c) => '${c.id}(${c.name})').toList(),
      'gwangScore': gwangScore,
      'ttiScore': ttiScore,
      'piScore': piScore,
      'ohScore': ohScore,
      'bonusScore': bonusScore,
      'baseScore': baseScore,
      'totalScore': totalScore,
      'goCount': goCount,
    };
  }

  // 폭탄 규칙 검증
  static Map<String, dynamic> validateBomb(List<GoStopCard> hand, List<GoStopCard> field) {
    final handGroups = <int, List<GoStopCard>>{};
    for (final card in hand) {
      handGroups.putIfAbsent(card.month, () => []).add(card);
    }

    final bombMonths = <int>[];
    for (final entry in handGroups.entries) {
      if (entry.value.length >= 3) {
        final fieldSameMonth = field.where((c) => c.month == entry.key).toList();
        if (fieldSameMonth.isNotEmpty) {
          bombMonths.add(entry.key);
        }
      }
    }

    return {
      'handGroups': handGroups.map((k, v) => MapEntry(k, v.map((c) => '${c.id}(${c.name})').toList())),
      'bombMonths': bombMonths,
      'canBomb': bombMonths.isNotEmpty,
      'expectedAction': bombMonths.isNotEmpty ? '4장 모두 먹기 + 피 강탈 + bomb 카드 2장 추가' : '일반 처리',
    };
  }

  static String _getExpectedActionForMatch(int matchCount) {
    switch (matchCount) {
      case 0:
        return '필드에 카드 추가';
      case 1:
        return '2장 모두 먹기';
      case 2:
        return '따닥 가능성 체크 후 선택창 또는 4장 모두 먹기';
      case 3:
        return '4장 모두 먹기';
      default:
        return '알 수 없는 상황';
    }
  }
}

// 게임 로거 메인 클래스
class GameLogger {
  static final GameLogger _instance = GameLogger._internal();
  factory GameLogger() => _instance;
  GameLogger._internal();

  final List<LogEntry> _logs = [];
  int _currentTurn = 1;
  bool _enableDetailedLogging = true;
  bool _enableValidation = true;

  // 설정
  void setDetailedLogging(bool enabled) => _enableDetailedLogging = enabled;
  void setValidation(bool enabled) => _enableValidation = enabled;

  // 로그 추가
  void addLog(int playerNumber, String phase, LogLevel level, String message, {Map<String, dynamic>? data}) {
    if (!_enableDetailedLogging) return;
    
    final entry = LogEntry(
      turnNumber: _currentTurn,
      playerNumber: playerNumber,
      phase: phase,
      level: level,
      message: message,
      data: data,
    );
    
    _logs.add(entry);
    print(entry.toString());
  }

  // 턴 증가
  void incrementTurn() {
    _currentTurn++;
  }

  // 규칙 검증 로그
  void logRuleValidation(String ruleName, Map<String, dynamic> validation, int playerNumber, String phase) {
    if (!_enableValidation) return;
    
    addLog(
      playerNumber,
      phase,
      LogLevel.rule,
      '[규칙 검증] $ruleName',
      data: validation,
    );
  }

  // 실제 처리 로그
  void logActualProcessing(String action, Map<String, dynamic> result, int playerNumber, String phase) {
    addLog(
      playerNumber,
      phase,
      LogLevel.actual,
      '[실제 처리] $action',
      data: result,
    );
  }

  // 검증 결과 로그
  void logValidationResult(String ruleName, bool isValid, String expected, String actual, int playerNumber, String phase) {
    final level = isValid ? LogLevel.validation : LogLevel.error;
    final status = isValid ? '일치(O)' : '불일치(X)';
    
    addLog(
      playerNumber,
      phase,
      level,
      '[검증 결과] $ruleName: $status | 기대: $expected | 실제: $actual',
    );
  }

  // 카드 매치 로그
  void logCardMatch(GoStopCard playedCard, List<GoStopCard> fieldCards, int playerNumber) {
    final validation = RuleValidator.validateCardMatch(playedCard, fieldCards);
    logRuleValidation('카드 매치', validation, playerNumber, 'playingCard');
  }

  // 뻑 로그
  void logPpeok(int? ppeokMonth, GoStopCard card, int playerNumber) {
    final validation = RuleValidator.validatePpeok(ppeokMonth, card);
    logRuleValidation('뻑', validation, playerNumber, 'flippingCard');
  }

  // 따닥 로그
  void logTtak(List<GoStopCard> fieldMatches, GoStopCard? playedCard, int playerNumber) {
    final validation = RuleValidator.validateTtak(fieldMatches, playedCard);
    logRuleValidation('따닥', validation, playerNumber, 'choosingMatch');
  }

  // 쪽 로그
  void logJjok(GoStopCard? lastPlayedCard, GoStopCard drawnCard, int playerNumber) {
    final validation = RuleValidator.validateJjok(lastPlayedCard, drawnCard);
    logRuleValidation('쪽', validation, playerNumber, 'flippingCard');
  }

  // 피 강탈 로그
  void logPiSteal(List<GoStopCard> opponentCaptured, int playerNumber) {
    final validation = RuleValidator.validatePiSteal(opponentCaptured);
    logRuleValidation('피 강탈', validation, playerNumber, 'turnEnd');
  }

  // 점수 계산 로그
  void logScoreCalculation(List<GoStopCard> captured, int goCount, int playerNumber) {
    final validation = RuleValidator.validateScoreCalculation(captured, goCount);
    logRuleValidation('점수 계산', validation, playerNumber, 'turnEnd');
  }

  // 폭탄 로그
  void logBomb(List<GoStopCard> hand, List<GoStopCard> field, int playerNumber) {
    final validation = RuleValidator.validateBomb(hand, field);
    logRuleValidation('폭탄', validation, playerNumber, 'playingCard');
  }

  // 로그 조회
  List<LogEntry> getLogs() => List.unmodifiable(_logs);
  
  List<LogEntry> getLogsByLevel(LogLevel level) => 
    _logs.where((log) => log.level == level).toList();
  
  List<LogEntry> getLogsByPlayer(int playerNumber) => 
    _logs.where((log) => log.playerNumber == playerNumber).toList();
  
  List<LogEntry> getLogsByTurn(int turnNumber) => 
    _logs.where((log) => log.turnNumber == turnNumber).toList();

  // 로그 초기화
  void clearLogs() {
    _logs.clear();
    _currentTurn = 1;
  }

  // 로그를 파일로 저장 (선택사항)
  String exportLogs() {
    return _logs.map((log) => log.toDetailedString()).join('\n');
  }

  // 에러 로그만 조회
  List<LogEntry> getErrorLogs() => 
    _logs.where((log) => log.level == LogLevel.error).toList();

  // 경고 로그만 조회
  List<LogEntry> getWarningLogs() => 
    _logs.where((log) => log.level == LogLevel.warning).toList();

  // 검증 실패 로그 조회
  List<LogEntry> getValidationFailures() => 
    _logs.where((log) => log.level == LogLevel.error && log.message.contains('[검증 결과]')).toList();

  // 자동 검증 함수들
  void validateCardMatchResult(GoStopCard playedCard, List<GoStopCard> fieldCards, List<GoStopCard> actualCaptured, bool actualShowChoice) {
    final validation = RuleValidator.validateCardMatch(playedCard, fieldCards);
    final expectedShowChoice = validation['shouldShowChoice'] as bool;
    final expectedCapture = validation['shouldCapture'] as bool;
    
    // 선택창 검증
    if (expectedShowChoice != actualShowChoice) {
      logValidationResult(
        '카드 매치 선택창',
        false,
        '선택창 ${expectedShowChoice ? "표시" : "숨김"}',
        '선택창 ${actualShowChoice ? "표시" : "숨김"}',
        _currentTurn,
        'playingCard'
      );
    }
    
    // 카드 획득 검증
    if (expectedCapture && actualCaptured.isEmpty) {
      logValidationResult(
        '카드 매치 획득',
        false,
        '카드 획득 필요',
        '카드 획득 없음',
        _currentTurn,
        'playingCard'
      );
    }
  }

  void validatePpeokResult(int? ppeokMonth, GoStopCard card, bool actualStealPi, List<GoStopCard> actualCaptured) {
    final validation = RuleValidator.validatePpeok(ppeokMonth, card);
    final expectedStealPi = validation['shouldStealPi'] as bool;
    final isPpeokCompletion = validation['isPpeokCompletion'] as bool;
    
    if (isPpeokCompletion) {
      // 뻑 완성 시 4장 모두 먹어야 함
      if (actualCaptured.length < 4) {
        logValidationResult(
          '뻑 완성 획득',
          false,
          '4장 모두 획득',
          '${actualCaptured.length}장 획득',
          _currentTurn,
          'flippingCard'
        );
      }
      
      // 피 강탈 검증
      if (expectedStealPi != actualStealPi) {
        logValidationResult(
          '뻑 완성 피 강탈',
          false,
          '피 강탈 ${expectedStealPi ? "필요" : "불필요"}',
          '피 강탈 ${actualStealPi ? "실행" : "미실행"}',
          _currentTurn,
          'flippingCard'
        );
      }
    }
  }

  void validateTtakResult(List<GoStopCard> fieldMatches, GoStopCard? playedCard, bool actualStealPi, List<GoStopCard> actualCaptured) {
    final validation = RuleValidator.validateTtak(fieldMatches, playedCard);
    final isTtak = validation['isTtak'] as bool;
    final expectedStealPi = validation['shouldStealPi'] as bool;
    
    if (isTtak) {
      // 따닥 시 4장 모두 먹어야 함
      if (actualCaptured.length < 4) {
        logValidationResult(
          '따닥 획득',
          false,
          '4장 모두 획득',
          '${actualCaptured.length}장 획득',
          _currentTurn,
          'choosingMatch'
        );
      }
      
      // 피 강탈 검증
      if (expectedStealPi != actualStealPi) {
        logValidationResult(
          '따닥 피 강탈',
          false,
          '피 강탈 ${expectedStealPi ? "필요" : "불필요"}',
          '피 강탈 ${actualStealPi ? "실행" : "미실행"}',
          _currentTurn,
          'choosingMatch'
        );
      }
    }
  }

  void validateJjokResult(GoStopCard? lastPlayedCard, GoStopCard drawnCard, bool actualStealPi, List<GoStopCard> actualCaptured) {
    final validation = RuleValidator.validateJjok(lastPlayedCard, drawnCard);
    final isJjok = validation['isJjok'] as bool;
    final expectedStealPi = validation['shouldStealPi'] as bool;
    
    if (isJjok) {
      // 쪽 시 2장 모두 먹어야 함
      if (actualCaptured.length < 2) {
        logValidationResult(
          '쪽 획득',
          false,
          '2장 모두 획득',
          '${actualCaptured.length}장 획득',
          _currentTurn,
          'flippingCard'
        );
      }
      
      // 피 강탈 검증
      if (expectedStealPi != actualStealPi) {
        logValidationResult(
          '쪽 피 강탈',
          false,
          '피 1장 강탈 필요',
          '피 강탈 ${actualStealPi ? "실행" : "미실행"}',
          _currentTurn,
          'flippingCard'
        );
      }
    }
  }

  void validatePiStealResult(List<GoStopCard> opponentCaptured, GoStopCard? actualStolenCard) {
    final validation = RuleValidator.validatePiSteal(opponentCaptured);
    final canSteal = validation['canSteal'] as bool;
    final expectedPriority = validation['expectedPriority'] as String;
    
    if (canSteal && actualStolenCard == null) {
      logValidationResult(
        '피 강탈 실행',
        false,
        '피 강탈 필요 ($expectedPriority)',
        '피 강탈 미실행',
        _currentTurn,
        'turnEnd'
      );
    } else if (!canSteal && actualStolenCard != null) {
      logValidationResult(
        '피 강탈 실행',
        false,
        '피 강탈 불가',
        '피 강탈 실행됨',
        _currentTurn,
        'turnEnd'
      );
    }
  }

  void validateScoreResult(List<GoStopCard> captured, int goCount, int actualScore) {
    final validation = RuleValidator.validateScoreCalculation(captured, goCount);
    final expectedScore = validation['totalScore'] as int;
    
    if (expectedScore != actualScore) {
      logValidationResult(
        '점수 계산',
        false,
        '${expectedScore}점',
        '${actualScore}점',
        _currentTurn,
        'turnEnd'
      );
    }
  }

  // 종합 검증 리포트 생성
  String generateValidationReport() {
    final errorLogs = getErrorLogs();
    final warningLogs = getWarningLogs();
    final validationFailures = getValidationFailures();
    
    final report = StringBuffer();
    report.writeln('=== 고스톱 게임 로그 검증 리포트 ===');
    report.writeln('생성 시간: ${DateTime.now()}');
    report.writeln('총 로그 수: ${_logs.length}');
    report.writeln('에러 수: ${errorLogs.length}');
    report.writeln('경고 수: ${warningLogs.length}');
    report.writeln('검증 실패 수: ${validationFailures.length}');
    report.writeln();
    
    if (validationFailures.isNotEmpty) {
      report.writeln('=== 검증 실패 목록 ===');
      for (final failure in validationFailures) {
        report.writeln('${failure.timestamp}: ${failure.message}');
      }
      report.writeln();
    }
    
    if (errorLogs.isNotEmpty) {
      report.writeln('=== 에러 목록 ===');
      for (final error in errorLogs) {
        report.writeln('${error.timestamp}: ${error.message}');
      }
      report.writeln();
    }
    
    if (warningLogs.isNotEmpty) {
      report.writeln('=== 경고 목록 ===');
      for (final warning in warningLogs) {
        report.writeln('${warning.timestamp}: ${warning.message}');
      }
      report.writeln();
    }
    
    return report.toString();
  }
} 