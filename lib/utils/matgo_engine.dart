import '../models/card_model.dart';
import 'event_evaluator.dart';
import 'deck_manager.dart';
import 'game_logger.dart';
import '../utils/sound_manager.dart';
import 'dart:async';

// 게임의 현재 단계를 나타내는 열거형
enum TurnPhase {
  playingCard, // 손패 내는 중
  flippingCard, // 카드 더미 뒤집는 중
  choosingMatch, // 짝 선택 중 (따닥)
  turnEnd, // 턴 종료 및 정산
}

// 애니메이션 이벤트 타입
enum AnimationEventType {
  cardFlip,      // 카드 뒤집기
  cardMove,      // 카드 이동
  specialEffect, // 특수 효과 (뻑, 따닥 등)
  cardCapture,   // 카드 획득
  bonusCard,     // 보너스 카드
  ppeok,        // 뻑 발생 애니메이션
  piSteal,      // 피 강탈 애니메이션
  sseul,        // 쓸 발생 애니메이션
  bomb,         // 폭탄 효과 애니메이션
}

// 애니메이션 이벤트 데이터
class AnimationEvent {
  final AnimationEventType type;
  final Map<String, dynamic> data;
  
  AnimationEvent(this.type, this.data);
}

class MatgoEngine {
  final DeckManager deckManager;
  int currentPlayer = 1;
  int goCount = 0;
  int? goPlayer; // GO를 선언한 플레이어
  String? winner;
  bool gameOver = false;
  final EventEvaluator eventEvaluator = EventEvaluator();
  bool awaitingGoStop = false;
  final GameLogger logger = GameLogger();

  // 입력 락
  bool tapLock = false;

  // 턴 진행 관련 상태
  TurnPhase currentPhase = TurnPhase.playingCard;
  GoStopCard? playedCard; // 이번 턴에 낸 카드
  List<GoStopCard> pendingCaptured = []; // 이번 턴에 획득할 예정인 카드들
  List<GoStopCard> choices = []; // 따닥 발생 시 선택할 카드들
  GoStopCard? drawnCard; // 뒤집은 카드 (따닥 상황에서 사용)
  int? ppeokMonth; // 뻑이 발생한 월 (null이면 뻑 상태 아님)
  bool hadTwoMatch = false; // 카드 내기 단계에서 2장 매치가 있었는지 여부
  // 카드더미에서 뒤집힌 보너스패를 임시로 필드에 올려두고
  // 턴 종료 시 한꺼번에 캡처하기 위한 버퍼
  List<GoStopCard> bonusOverlayCards = [];

  // 애니메이션 이벤트 콜백
  Function(AnimationEvent)? onAnimationEvent;
  
  // 턴 종료 후 UI 업데이트 콜백
  Function()? onTurnEnd;

  // 추가: 배수 적용 플래그
  final Set<int> bombPlayers = {};   // 폭탄 선언한 플레이어 번호 집합
  final Set<int> heundalPlayers = {}; // 흔들 선언한 플레이어 번호 집합
  final Set<int> piBakPlayers = {};   // 피박 플레이어 번호 집합
  final Set<int> gwangBakPlayers = {}; // 광박 플레이어 번호 집합
  final Set<int> mungBakPlayers = {}; // 멍박 플레이어 번호 집합
  int nagariCount = 0; // 나가리 횟수 (최대 4회, ×16까지)

  MatgoEngine(this.deckManager);

  // 애니메이션 이벤트 리스너 설정
  void setAnimationListener(Function(AnimationEvent) listener) {
    onAnimationEvent = listener;
  }

  // 애니메이션 이벤트 발생
  void _triggerAnimation(AnimationEventType type, Map<String, dynamic> data) {
    // cardMove 사운드는 유지
    if (type == AnimationEventType.cardMove) {
      SoundManager.instance.play(Sfx.cardOverlap);
    }
    // 이벤트 전달
    onAnimationEvent?.call(AnimationEvent(type, data));
  }

  void reset() {
    deckManager.reset();
    currentPlayer = 1;
    goCount = 0;
    goPlayer = null;
    winner = null;
    gameOver = false;
    awaitingGoStop = false;
    currentPhase = TurnPhase.playingCard;
    playedCard = null;
    drawnCard = null;
    pendingCaptured.clear();
    choices.clear();
    ppeokMonth = null;
    hadTwoMatch = false;
    bonusOverlayCards.clear();
    logger.clearLogs();

    // 초기 흔들 감지 (플레이어 손패에 같은 월 3장 이상)
    heundalPlayers.clear(); // 실제 흔들 선언 시점에만 추가 예정
    bombPlayers.clear();
    piBakPlayers.clear();
    gwangBakPlayers.clear();
    mungBakPlayers.clear();
    nagariCount = 0;
  }

  // 동일 월 카드가 3장 이상 손패에 있으면 흔들 조건 충족으로 간주
  bool _detectHeundal(List<GoStopCard> hand) {
    final Map<int, int> monthCount = {};
    for (final c in hand) {
      monthCount[c.month] = (monthCount[c.month] ?? 0) + 1;
      if (monthCount[c.month]! >= 3) return true;
    }
    return false;
  }

  // 흔들 조건을 만족하는 월들을 반환
  List<int> getHeundalMonths(int playerNum) {
    final hand = getHand(playerNum);
    final Map<int, int> monthCount = {};
    final heundalMonths = <int>[];
    
    for (final c in hand) {
      monthCount[c.month] = (monthCount[c.month] ?? 0) + 1;
      if (monthCount[c.month]! >= 3 && !heundalMonths.contains(c.month)) {
        heundalMonths.add(c.month);
      }
    }
    
    return heundalMonths;
  }

  // 흔들 선언
  void declareHeundal(int playerNum) {
    if (!heundalPlayers.contains(playerNum)) {
      heundalPlayers.add(playerNum);
      logger.addLog(playerNum, 'heundal', LogLevel.info, 
        '흔들 선언: 플레이어 $playerNum이 흔들을 선언했습니다.'
      );
      
      // 흔들 선언 애니메이션 트리거
      _triggerAnimation(AnimationEventType.specialEffect, {
        'effect': 'heundal',
        'player': playerNum,
      });
    }
  }

  // 카드 내기 전 흔들 조건 체크
  bool shouldShowHeundalDialog(GoStopCard card, int playerNum) {
    final hand = getHand(playerNum);
    final sameMonthCards = hand.where((c) => c.month == card.month).toList();
    final field = getField();
    final fieldSameMonth = field.where((c) => c.month == card.month).toList();
    // 폭탄 조건: 손패 3장+필드 1장 이상이면 흔들 다이얼로그 X (자동 폭탄)
    if (sameMonthCards.length >= 3 && fieldSameMonth.isNotEmpty) {
      return false;
    }
    // 흔들 조건: 손패 3장+필드 0장+아직 흔들 미선언이면 다이얼로그 표시
    return sameMonthCards.length >= 3 && fieldSameMonth.isEmpty && !heundalPlayers.contains(playerNum);
  }

  // 흔들 카드들 가져오기
  List<GoStopCard> getHeundalCards(GoStopCard card, int playerNum) {
    final hand = getHand(playerNum);
    return hand.where((c) => c.month == card.month).toList();
  }

  // 흔들 취소 (게임 종료 시)
  void clearHeundal() {
    heundalPlayers.clear();
  }

  // 피박/광박 판정 (게임 종료 시 호출)
  void checkPiBakAndGwangBak() {
    piBakPlayers.clear();
    gwangBakPlayers.clear();
    
    // 승자 결정
    final player1Score = calculateScore(1);
    final player2Score = calculateScore(2);
    
    int winner;
    int loser;
    if (player1Score > player2Score) {
      winner = 1;
      loser = 2;
    } else if (player2Score > player1Score) {
      winner = 2;
      loser = 1;
    } else {
      // 무승부인 경우 피박/광박 없음
      return;
    }
    
    // 승자의 획득 카드 분석
    final winnerCaptured = getCaptured(winner);
    final loserCaptured = getCaptured(loser);
    
    // 피박 판정: 승자가 피 점수를 얻었고, 패자가 피 7장 이하인 경우
    final winnerPiCards = winnerCaptured.where((c) => c.type == '피').toList();
    final loserPiCards = loserCaptured.where((c) => c.type == '피').toList();
    
    // 승자의 피 점수 계산
    int winnerPiScore = 0;
    for (final c in winnerPiCards) {
      final img = c.imageUrl;
      if (img.contains('bonus_3pi') || img.contains('bonus_ssangpi') || c.isBonus) {
        winnerPiScore += 3; // 보너스피 (3점)
      } else if (img.contains('3pi') || img.contains('ssangpi')) {
        winnerPiScore += 2; // 쌍피 (2점)
      } else {
        winnerPiScore += 1; // 일반 피 (1점)
      }
    }
    
    // 패자의 피 개수 계산 (점수가 아닌 카드 개수)
    int loserPiCount = 0;
    for (final c in loserPiCards) {
      final img = c.imageUrl;
      if (img.contains('bonus_3pi') || img.contains('bonus_ssangpi') || c.isBonus) {
        loserPiCount += 1; // 보너스피도 1장으로 계산
      } else if (img.contains('3pi') || img.contains('ssangpi')) {
        loserPiCount += 1; // 쌍피도 1장으로 계산
      } else {
        loserPiCount += 1; // 일반 피 1장
      }
    }
    
    // 피박 조건: 승자가 피 점수를 얻었고, 패자가 피 7장 이하
    if (winnerPiScore > 0 && loserPiCount <= 7) {
      piBakPlayers.add(loser);
      logger.addLog(loser, 'gameEnd', LogLevel.info, 
        '피박 발생: 플레이어 $loser (피 $loserPiCount장) - 승자 피 점수: $winnerPiScore'
      );
    }
    
    // 광박 판정: 승자가 광 점수를 얻었고, 패자가 광 0장인 경우
    final winnerGwangCards = winnerCaptured.where((c) => c.type == '광').toList();
    final loserGwangCards = loserCaptured.where((c) => c.type == '광').toList();
    
    // 승자의 광 점수 계산
    int winnerGwangScore = 0;
    final hasRainGwang = winnerGwangCards.any((c) => c.month == 12);
    if (winnerGwangCards.length == 3) {
      winnerGwangScore = hasRainGwang ? 2 : 3;
    } else if (winnerGwangCards.length == 4) {
      winnerGwangScore = 4;
    } else if (winnerGwangCards.length >= 5) {
      winnerGwangScore = 15;
    }
    
    // 광박 조건: 승자가 광 점수를 얻었고, 패자가 광 0장
    if (winnerGwangScore > 0 && loserGwangCards.isEmpty) {
      gwangBakPlayers.add(loser);
      logger.addLog(loser, 'gameEnd', LogLevel.info, 
        '광박 발생: 플레이어 $loser (광 0장) - 승자 광 점수: $winnerGwangScore'
      );
    }
    
    // 멍박 판정: 승자가 동물 점수를 얻었고, 패자가 동물 7장 미만인 경우
    final winnerAnimalCards = winnerCaptured.where((c) => c.type == '동물' || c.type == '오').toList();
    final loserAnimalCards = loserCaptured.where((c) => c.type == '동물' || c.type == '오').toList();
    
    // 승자의 동물 점수 계산
    int winnerAnimalScore = 0;
    if (winnerAnimalCards.length >= 5) {
      winnerAnimalScore = winnerAnimalCards.length - 4; // 5장=1점, 6장=2점, 7장=3점
    }
    
    // 멍박 조건: 승자가 동물 점수를 얻었고, 패자가 동물 7장 미만
    if (winnerAnimalScore > 0 && loserAnimalCards.length < 7) {
      mungBakPlayers.add(loser);
      logger.addLog(loser, 'gameEnd', LogLevel.info, 
        '멍박 발생: 플레이어 $loser (동물 ${loserAnimalCards.length}장) - 승자 동물 점수: $winnerAnimalScore'
      );
    }
  }

  List<GoStopCard> getHand(int playerNum) => deckManager.getPlayerHand(playerNum - 1);
  List<GoStopCard> getField() => deckManager.getFieldCards();
  List<GoStopCard> getCaptured(int playerNum) => deckManager.capturedCards[playerNum - 1] ?? [];
  int get drawPileCount => deckManager.drawPile.length;

  void logAllCardStates(String context) {
    logger.addLog(currentPlayer, context, LogLevel.info, '================ 카드 상태 스냅샷 ================');
    for (int p = 1; p <= 2; p++) {
      logger.addLog(p, context, LogLevel.info, '[P$p] 손패: ${getHand(p).map((c) => c.id).toList()}');
      logger.addLog(p, context, LogLevel.info, '[P$p] 먹은 카드: ${getCaptured(p).map((c) => c.id).toList()}');
    }
    logger.addLog(currentPlayer, context, LogLevel.info, '[공통] 필드: ${getField().map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, context, LogLevel.info, '[공통] 카드더미: ${deckManager.drawPile.map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, context, LogLevel.info, '=================================================');
  }

  // 1단계: 플레이어가 손에서 카드를 냄
  void playCard(GoStopCard card, {int? groupIndex}) {
    assert(currentPhase == TurnPhase.playingCard, 'playCard는 playingCard phase에서만 호출되어야 합니다.');
    logAllCardStates('playingCard-시작');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '[DEBUG] 턴 시작: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '손패: ${getHand(currentPlayer).map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '필드: ${getField().map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '카드더미: ${deckManager.drawPile.map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '획득: ${getCaptured(currentPlayer).map((c) => c.id).toList()}');
    
    if (currentPhase != TurnPhase.playingCard) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.error, 
        '잘못된 phase에서 카드 내기 시도', 
        data: {'currentPhase': currentPhase.name}
      );
      return;
    }

    final playerIdx = currentPlayer - 1;
    playedCard = card;
    
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
      'playedCard 설정: ${playedCard?.id}(${playedCard?.name})'
    );

    // 폭탄카드(폭탄피) 낼 때만 폭탄 분기 실행
    if (card.isBomb) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '폭탄카드(폭탄피) 처리 시작', 
        data: {'cardId': card.id, 'cardName': card.name}
      );
      // 클릭한 폭탄카드 한 장만 손패에서 제거
      deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == card.id);
      // 필드에 추가하지 않고, 애니메이션 트리거도 없음
      // 카드더미에서 바로 한 장 뒤집기
      currentPhase = TurnPhase.flippingCard;
      return;
    }

    // 보너스카드(쌍피 등) 낼 때 바로 먹은 카드로 이동
    if (card.isBonus) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '보너스카드 처리 시작', 
        data: {'cardId': card.id, 'cardName': card.name}
      );
      // ① 즉시 캡처 (이미 위에서 손패에서 제거했으므로 바로 캡처)
      deckManager.capturedCards[playerIdx]?.add(card);
      // ② 카드더미 한 장 교체
      if (deckManager.drawPile.isNotEmpty) {
        final bonusDrawnCard = deckManager.drawPile.removeAt(0);
        deckManager.playerHands[playerIdx]?.add(bonusDrawnCard);
        logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
          '보너스카드 효과: 카드더미에서 한 장 가져옴 - ${bonusDrawnCard.id}(${bonusDrawnCard.name})'
        );
      }
      // ③ Phase 유지 (playingCard) - 턴 계속 유지
      // ④ tapLock 해제 + hand 입력 재활성화
      tapLock = false;
      // ⑤ 턴 계속 (일반카드 낼 때까지 반복)
      logger.logActualProcessing('보너스카드 처리', {
        'capturedCard': '${card.id}(${card.name})',
        'replacementCard': deckManager.drawPile.isNotEmpty ? '카드더미에서 한 장' : '카드더미 없음',
        'nextPhase': 'playingCard (턴 계속)',
      }, currentPlayer, 'playingCard');
      return;
    }

    // 뻑 완성 체크
    if (ppeokMonth != null && card.month == ppeokMonth) {
      logger.logPpeok(ppeokMonth, card, currentPlayer);
      
      // 뻑 완성: 4장 모두 먹기 + 피 강탈
      final fieldSameMonthCards = deckManager.fieldCards.where((c) => c.month == ppeokMonth).toList();
      pendingCaptured.addAll([card, ...fieldSameMonthCards]);
      
      // 필드에서 해당 월 카드들 제거
      deckManager.fieldCards.removeWhere((c) => c.month == ppeokMonth);
      
      // 피 강탈
      _stealOpponentPi(currentPlayer - 1);
      
      // 뻑 상태 초기화
      ppeokMonth = null;
      
      logger.logActualProcessing('뻑 완성 처리', {
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'fieldCardsRemoved': fieldSameMonthCards.map((c) => '${c.id}(${c.name})').toList(),
        'nextPhase': 'flippingCard',
      }, currentPlayer, 'playingCard');
      currentPhase = TurnPhase.flippingCard;
      return;
    }

    // 폭탄 체크 (손패 3장 + 필드 1장 조건) - 카드를 내기 전에 체크
    if (EventEvaluator.isBomb(deckManager.getPlayerHand(playerIdx), card, deckManager.fieldCards)) {
      logger.logBomb(deckManager.getPlayerHand(playerIdx), deckManager.fieldCards, currentPlayer);
      
      // 폭탄 처리: 4장 모두 먹기 + 피 강탈 + 폭탄카드 2장 획득
      final bombMonth = card.month;
      final handSameMonth = deckManager.getPlayerHand(playerIdx).where((c) => c.month == bombMonth).toList();
      final fieldSameMonth = deckManager.fieldCards.where((c) => c.month == bombMonth).toList();
      
      // 폭탄 이펙트 트리거 추가
      _triggerAnimation(AnimationEventType.specialEffect, {
        'effect': 'bomb',
        'player': currentPlayer,
        'anchorCard': card,
      });
      
      // 폭탄 플레이어 표시
      bombPlayers.add(currentPlayer);
      
      // 폭탄카드 2장을 손패에 추가
      final bombCard1 = GoStopCard.bomb();
      final bombCard2 = GoStopCard.bomb();
      deckManager.playerHands[playerIdx]?.addAll([bombCard1, bombCard2]);
      
      // 피 강탈
      _stealOpponentPi(currentPlayer - 1);
      
      // 폭탄 카드들을 pendingCaptured에 추가 (손패 3장 + 필드 1장 = 총 4장)
      final bombCards = [...handSameMonth, ...fieldSameMonth];
      pendingCaptured.addAll(bombCards);
      
      // 필드에서 폭탄 카드들 제거
      deckManager.fieldCards.removeWhere((c) => c.month == bombMonth);
      
      logger.logActualProcessing('폭탄 처리', {
        'bombMonth': bombMonth,
        'handCardsForAnimation': handSameMonth.map((c) => '${c.id}(${c.name})').toList(),
        'fieldCardsRemoved': fieldSameMonth.map((c) => '${c.id}(${c.name})').toList(),
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'bombCardsAdded': ['폭탄카드 2장'],
        'nextPhase': 'bombAnimation',
      }, currentPlayer, 'playingCard');
      
      // 폭탄 애니메이션: 손패의 3장을 한장씩 필드로 이동하는 애니메이션
      _triggerAnimation(AnimationEventType.bomb, {
        'handCards': handSameMonth, // 손패에서 나올 실제 카드들
        'fieldCards': fieldSameMonth, // 필드에 있던 카드들
        'player': currentPlayer,
        'bombMonth': bombMonth,
        'onComplete': () {
          // 카드더미에서 한 장 뒤집기
          currentPhase = TurnPhase.flippingCard;
          flipFromDeck();
        },
      });
      return;
    }
    
    // 일반 매치 처리 - 폭탄이 아닌 경우에만 손패에서 카드 제거
    deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == card.id);

    final fieldMatches = getField().where((c) => c.month == card.month).toList();
    logger.logCardMatch(card, getField(), currentPlayer);

    // 내가 낸 카드를 필드에 반드시 추가 (매치 여부와 무관하게)
    deckManager.fieldCards.add(card);

    // 일반 매치 처리
    // 먹을 카드가 있으면 임시 목록에 추가 (하지만 필드에서 제거하지 않음)
    if (fieldMatches.length == 1) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '1장 매치 발견: ${card.id}(${card.name}) ↔ ${fieldMatches.first.id}(${fieldMatches.first.name})'
      );
      pendingCaptured.addAll([card, fieldMatches.first]);
      logger.logActualProcessing('1장 매치 처리', {
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'fieldCardsAdded': [card.id],
      }, currentPlayer, 'playingCard');
      _triggerAnimation(AnimationEventType.cardMove, {
        'cards': [card, fieldMatches.first],
        'from': 'hand',
        'to': 'fieldOverlap',
        'player': currentPlayer,
      });
      currentPhase = TurnPhase.flippingCard;
      return;
    } else if (fieldMatches.length == 2) {
      logger.logTtak(fieldMatches, playedCard, currentPlayer);
      hadTwoMatch = true;
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '2장 매치 발견: 카드더미 뒤집기로 진행 - ${fieldMatches.map((c) => '${c.id}(${c.name})').toList()}'
      );
      logger.logActualProcessing('2장 매치 처리', {
        'fieldCardsAdded': [card.id],
        'nextPhase': 'flippingCard',
        'hadTwoMatch': hadTwoMatch,
      }, currentPlayer, 'playingCard');
      currentPhase = TurnPhase.flippingCard;
      return;
    } else if (fieldMatches.length == 3) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '3장 매치 발견: ${card.id}(${card.name}) ↔ ${fieldMatches.map((c) => '${c.id}(${c.name})').join(', ')}'
      );
      pendingCaptured.addAll([card, ...fieldMatches]);
      logger.logActualProcessing('3장 매치 처리', {
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'fieldCardsAdded': [card.id],
      }, currentPlayer, 'playingCard');
      _triggerAnimation(AnimationEventType.cardMove, {
        'cards': [card, ...fieldMatches],
        'from': 'hand',
        'to': 'fieldOverlap',
        'player': currentPlayer,
      });
      currentPhase = TurnPhase.flippingCard;
      return;
    } else {
      // 먹을 카드가 없으면 groupIndex 위치에 카드 추가 (이미 위에서 추가했으므로 중복 방지)
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '매치 없음: 필드에 카드 추가'
      );
      currentPhase = TurnPhase.flippingCard;
    }

    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '[DEBUG] 턴 종료: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '손패: ${getHand(currentPlayer).map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '필드: ${getField().map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '카드더미: ${deckManager.drawPile.map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '획득: ${getCaptured(currentPlayer).map((c) => c.id).toList()}');
    logAllCardStates('playingCard-종료');
  }
  
  // 2단계: 카드 더미에서 카드를 뒤집음
  void flipFromDeck({GoStopCard? overrideCard}) {
    assert(currentPhase == TurnPhase.flippingCard, 'flipFromDeck는 flippingCard phase에서만 호출되어야 합니다.');
    logAllCardStates('flippingCard-시작');
    if (currentPhase != TurnPhase.flippingCard) return;
    
    // 카드더미에서 카드 한 장을 뒤집음 (보너스피 연속 처리)
    GoStopCard? drawnCard = overrideCard ?? deckManager.drawPile.removeAt(0);

    // 보너스피가 나오면 애니메이션 완료 후 재귀적으로 flipFromDeck()을 호출하여
    // "겹침 → 애니메이션 종료 → 다음 카드 뒤집기" 순서를 보장한다.
    if (drawnCard.isBonus) {
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info,
          '보너스피 발견: ${drawnCard.id}(${drawnCard.name})');

      // ① 내가 낸 카드 위에 겹침 처리 (UI 표시용)
      if (playedCard != null) {
        deckManager.fieldCards.add(drawnCard);
        pendingCaptured.addAll([playedCard!, drawnCard]);
        logger.addLog(currentPlayer, 'flippingCard', LogLevel.info,
            '보너스피 겹침: ${playedCard!.id}(${playedCard!.name}) + ${drawnCard.id}(${drawnCard.name})');
      } else {
        // AI가 먼저 뒤집어 보너스피가 나온 경우 등
        pendingCaptured.add(drawnCard);
        logger.addLog(currentPlayer, 'flippingCard', LogLevel.info,
            '보너스피 단독 획득: ${drawnCard.id}(${drawnCard.name})');
      }

      // ② 애니메이션 실행. 완료 후 다음 카드 뒤집기.
      _triggerAnimation(AnimationEventType.bonusCard, {
        'card': drawnCard,
        'player': currentPlayer,
        'onComplete': () {
          // 애니메이션 종료 후 재귀 호출로 다음 카드 처리
          if (deckManager.drawPile.isEmpty) {
            logger.addLog(currentPlayer, 'flippingCard', LogLevel.info,
                '[DEBUG] 카드더미 소진: 보너스피만 뒤집힘');
            checkReverseGo();
            _endTurn();
          } else {
            flipFromDeck();
          }
        },
      });

      return; // 보너스피 처리 후 즉시 반환 (다음 로직은 onComplete에서 실행)
    }

    // 뒤집은 결과가 없거나(모두 보너스) 더는 카드가 없으면 턴 종료 처리
    if (drawnCard == null) {
      // 보너스피가 아닌 카드가 나올 때까지 반복 완료
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '[DEBUG] 카드더미 소진: 보너스피만 뒤집힘');
      checkReverseGo();
      _endTurn();
      return;
    }

    // 보너스피가 아닌 카드가 나온 경우: 일반카드 뒤집었을 때 알고리즘 실행

    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '카드 뒤집음: ${drawnCard.id}(${drawnCard.name})');

    this.drawnCard = drawnCard;
    _processDrawnCard(drawnCard);

    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '[DEBUG] 카드더미 뒤집기 후 상태: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '손패: ${getHand(currentPlayer).map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '필드: ${getField().map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '카드더미: ${deckManager.drawPile.map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '획득: ${getCaptured(currentPlayer).map((c) => c.id).toList()}');
    logAllCardStates('flippingCard-종료');
  }

  // 역GO(Go Bust) 체크
  void checkReverseGo() {
    if (goCount > 0 && currentPlayer != goPlayer && calculateBaseScore(currentPlayer) >= 7) {
      // 역GO: 상대방이 GO 상태에서 현재 플레이어가 7점 달성
      // 박 판정은 GO/STOP 선택 후에 처리되므로 여기서는 즉시 승리 처리
      winner = 'player$currentPlayer';
      gameOver = true;
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
        '역GO 발생: 플레이어 $currentPlayer이 7점 달성으로 승리 (goCount: $goCount, goPlayer: $goPlayer)'
      );
      return;
    }
  }

  // --- 분기별 핸들러 ---
  void handlePpeokFinish(GoStopCard drawnCard) {
    // 뻑 완성: 필드+낸 카드+뒤집은 카드(총 4장) 모두 먹고 피 1장 강탈
    final allPpeokCards = <GoStopCard>[];
    allPpeokCards.addAll(deckManager.fieldCards.where((c) => c.month == ppeokMonth));
    if (playedCard != null && playedCard!.month == ppeokMonth && !allPpeokCards.any((c) => c.id == playedCard!.id)) {
      allPpeokCards.add(playedCard!);
    }
    if (!allPpeokCards.any((c) => c.id == drawnCard.id)) {
      allPpeokCards.add(drawnCard);
    }
    // 4장 모두 pendingCaptured에 추가
    pendingCaptured.clear();
    pendingCaptured.addAll(allPpeokCards);
    choices.clear();
    // 필드에서 해당 월 카드들 제거
    deckManager.fieldCards.removeWhere((c) => c.month == ppeokMonth);
    // 피 강탈
    _stealOpponentPi(currentPlayer - 1);
    // 상태 초기화
    ppeokMonth = null;
    
    // 뻑 완성 매치 사운드 재생 (즉시)
    SoundManager.instance.play(Sfx.cardOverlap);
    
    logger.logActualProcessing('뻑 완성 처리 (4장 모두 획득)', {
      'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
    }, currentPlayer, 'flippingCard');
    checkReverseGo();
    _endTurn();
    
    // 뻑 완성 이펙트 트리거 (anchorCard: drawnCard)
    _triggerAnimation(AnimationEventType.specialEffect, {
      'effect': 'ppeokFinish',
      'player': currentPlayer,
      'anchorCard': drawnCard,
    });
  }

  void handleChok(GoStopCard drawnCard) {
    // 기존 pendingCaptured가 있으면 유지하고 추가 (폭탄 등)
    if (pendingCaptured.isEmpty) {
      pendingCaptured.addAll([playedCard!, drawnCard]);
    } else {
      // 기존 pendingCaptured에 추가 (중복 방지)
      if (!pendingCaptured.any((c) => c.id == playedCard!.id)) {
        pendingCaptured.add(playedCard!);
      }
      if (!pendingCaptured.any((c) => c.id == drawnCard.id)) {
        pendingCaptured.add(drawnCard);
      }
    }
    deckManager.fieldCards.removeWhere((c) => c.id == playedCard!.id);
    
    // 쪽 애니메이션 트리거 (anchorCard: drawnCard)
    _triggerAnimation(AnimationEventType.specialEffect, {
      'effect': 'chok',
      'player': currentPlayer,
      'anchorCard': drawnCard,
    });
    
    // 쪽 매치 사운드 재생 (즉시)
    SoundManager.instance.play(Sfx.cardOverlap);
    
    _stealOpponentPi(currentPlayer - 1);
    checkReverseGo();
    _endTurn();
  }

  void handlePpeokStart(GoStopCard drawnCard) {
    // 뻑 발생 매치 사운드 재생 (즉시)
    SoundManager.instance.play(Sfx.cardOverlap);
    
    final allPpeokCards = <GoStopCard>[];
    allPpeokCards.addAll(deckManager.fieldCards.where((c) => c.month == drawnCard.month));
    if (playedCard != null && playedCard!.month == drawnCard.month && !allPpeokCards.any((c) => c.id == playedCard!.id)) {
      allPpeokCards.add(playedCard!);
    }
    if (!allPpeokCards.any((c) => c.id == drawnCard.id)) {
      allPpeokCards.add(drawnCard);
    }
    pendingCaptured.clear();
    choices.clear();
    deckManager.fieldCards.removeWhere((c) => c.month == drawnCard.month);
    deckManager.fieldCards.addAll(allPpeokCards);
    ppeokMonth = drawnCard.month;
    
    // 뻑 발생 애니메이션 트리거 (anchorCard: drawnCard)
    _triggerAnimation(AnimationEventType.specialEffect, {
      'effect': 'ppeok',
      'player': currentPlayer,
      'anchorCard': drawnCard,
    });
    
    logger.logActualProcessing('뻑 상태 설정 (필드에 4장 유지)', {
      'ppeokMonth': ppeokMonth,
      'fieldCards': deckManager.fieldCards.map((c) => '${c.id}(${c.name})').toList(),
      'pendingCapturedCleared': true,
    }, currentPlayer, 'flippingCard');
    checkReverseGo();
    _endTurn();
  }

  void handleTtakTtak(GoStopCard drawnCard, List<GoStopCard> fieldMatches) {
    // 따닥 매치 사운드 재생 (즉시)
    SoundManager.instance.play(Sfx.cardOverlap);
    
    // 기존 pendingCaptured에 추가 (중복 방지)
    if (!pendingCaptured.any((c) => c.id == playedCard!.id)) {
      pendingCaptured.add(playedCard!);
    }
    if (!pendingCaptured.any((c) => c.id == drawnCard.id)) {
      pendingCaptured.add(drawnCard);
    }
    for (final match in fieldMatches) {
      if (!pendingCaptured.any((c) => c.id == match.id)) {
        pendingCaptured.add(match);
      }
    }
    deckManager.fieldCards.add(drawnCard);
    
    // 따닥 이펙트 트리거 (anchorCard: drawnCard)
    _triggerAnimation(AnimationEventType.specialEffect, {
      'effect': 'ttak',
      'player': currentPlayer,
      'anchorCard': drawnCard,
    });
    
    _stealOpponentPi(currentPlayer - 1);
    checkReverseGo();
    _endTurn();
  }

  void startChoosingMatch(List<GoStopCard> matches, GoStopCard drawnCard, {bool isHadTwoMatch = false}) {
    // 2장 모두 일반 1피(쌍피/보너스피/특수피 아님)면 선택창 없이 자동 처리
    if (matches.length == 2 &&
        matches.every((c) => c.type == '피' &&
            !(c.imageUrl.contains('ssangpi') || c.imageUrl.contains('3pi') || c.isBonus))) {
      // 자동 매치 사운드 재생 (즉시)
      SoundManager.instance.play(Sfx.cardOverlap);
      
      // 한글 주석: 모두 일반 1피일 때는 선택창 없이 첫 번째 카드를 자동으로 먹음
      pendingCaptured.add(matches.first);
      deckManager.fieldCards.removeWhere((c) => c.id == matches.first.id);
      // 내가 낸 카드가 일반피가 아닌 경우(예: 8광 등)에는 내가 낸 카드도 같이 먹음
      if (playedCard != null && !(playedCard!.type == '피' &&
          !(playedCard!.imageUrl.contains('ssangpi') || playedCard!.imageUrl.contains('3pi') || playedCard!.isBonus))) {
        pendingCaptured.add(playedCard!);
        deckManager.fieldCards.removeWhere((c) => c.id == playedCard!.id);
      }
      // 선택창 띄우지 않고 바로 턴 종료
      choices.clear();
      
      currentPhase = TurnPhase.playingCard;
      _endTurn();
      return;
    }
    // 기존 로직: 선택창 띄우기
    choices = matches;
    // 뒤집은 카드를 필드에 추가 (UI 표시를 위해)
    deckManager.fieldCards.add(drawnCard);
    if (isHadTwoMatch && playedCard != null) {
      // 기존 pendingCaptured에 추가 (중복 방지)
      if (!pendingCaptured.any((c) => c.id == playedCard!.id)) {
        pendingCaptured.add(playedCard!);
      }
      final drawnMatches = getField().where((c) => c.month == drawnCard.month).toList();
      if (drawnMatches.isNotEmpty) {
        if (!pendingCaptured.any((c) => c.id == drawnCard.id)) {
          pendingCaptured.add(drawnCard);
        }
        for (final match in drawnMatches) {
          if (!pendingCaptured.any((c) => c.id == match.id)) {
            pendingCaptured.add(match);
          }
        }
      }
    } else {
      if (!pendingCaptured.any((c) => c.id == drawnCard.id)) {
        pendingCaptured.add(drawnCard);
      }
    }
    currentPhase = TurnPhase.choosingMatch;
  }

  void captureOnePair(GoStopCard drawnCard, GoStopCard match) {
    // 1장 매치 사운드 재생 (즉시)
    SoundManager.instance.play(Sfx.cardOverlap);
    
    // 뒤집은 카드를 필드에 추가 (UI 표시를 위해)
    deckManager.fieldCards.add(drawnCard);
    
    if (!pendingCaptured.any((c) => c.id == drawnCard.id)) {
      pendingCaptured.add(drawnCard);
    }
    if (!pendingCaptured.any((c) => c.id == match.id)) {
      pendingCaptured.add(match);
    }
    
    checkReverseGo();
    _endTurn();
  }

  void leaveOnField(GoStopCard drawnCard) {
    deckManager.fieldCards.add(drawnCard);
    checkReverseGo();
    _endTurn();
  }

  // --- 분기 순서에 따라 _processDrawnCard 리팩터링 ---
  void _processDrawnCard(GoStopCard drawnCard) {
    // 1. 뻑 완성
    if (ppeokMonth != null && drawnCard.month == ppeokMonth) {
      handlePpeokFinish(drawnCard);
      return;
    }
    // 2. 쪽
    if (pendingCaptured.isEmpty && playedCard != null && playedCard!.month == drawnCard.month) {
      handleChok(drawnCard);
      return;
    }
    // 3. 뻑 발생
    if (playedCard != null && playedCard!.month == drawnCard.month && getField().any((c) => c.month == drawnCard.month)) {
      handlePpeokStart(drawnCard);
      return;
    }
    // 4. 따닥 (hadTwoMatch 포함)
    final fieldMatches =
        getField().where((c) => c.month == drawnCard.month).toList();
    if (playedCard != null && playedCard!.month == drawnCard.month &&
        fieldMatches.length >= 2) {
      // 실제 매치 카드(플레이드/드로 카드 제외) 2장 여부 확인
      final realMatches = fieldMatches
          .where((c) => c.id != playedCard!.id && c.id != drawnCard.id)
          .toList();
      if (realMatches.length == 2) {
        handleTtakTtak(drawnCard, realMatches);
        return;
      }
    }
    // 5. hadTwoMatch 후 2장 매치
    if (hadTwoMatch && playedCard != null) {
      final previousFieldMatches = getField().where((c) => c.month == playedCard!.month && c.id != playedCard!.id).toList();
      startChoosingMatch(previousFieldMatches, drawnCard, isHadTwoMatch: true);
      return;
    }
    // 6. 일반 2장 매치
    if (fieldMatches.length == 2) {
      startChoosingMatch(fieldMatches, drawnCard);
      return;
    }
    // 7. 일반 1장 매치
    if (fieldMatches.length == 1) {
      captureOnePair(drawnCard, fieldMatches.first);
      return;
    }
    // 8. 매치 없음
    leaveOnField(drawnCard);
  }

  // 2-1단계: '따닥'에서 카드 선택
  void chooseMatch(GoStopCard chosenCard) {
    assert(currentPhase == TurnPhase.choosingMatch, 'chooseMatch는 choosingMatch phase에서만 호출되어야 합니다.');
    logAllCardStates('chooseMatch-시작');
    if (currentPhase != TurnPhase.choosingMatch) return;
    
    logger.addLog(currentPlayer, 'chooseMatch', LogLevel.info, 
      '카드 선택: [36m${chosenCard.id}(${chosenCard.name})[0m'
    );
    
    // 카드 선택 매치 사운드 재생 (즉시)
    SoundManager.instance.play(Sfx.cardOverlap);
    
    // 선택한 카드만 먹은 카드로 분류, 선택 안 한 카드는 필드에 남김
    pendingCaptured.add(chosenCard); // 선택한 카드만 먹음
    deckManager.fieldCards.removeWhere((c) => c.id == chosenCard.id); // 필드에서 제거
    choices.clear();
    
    // 뒤집은 카드가 매치가 안 됐으면 필드에 남기고, 먹은 카드에서 제거
    if (drawnCard != null) {
      final drawnCardMatches = getField().where((c) => c.month == drawnCard!.month && c.id != drawnCard!.id).toList();
      if (drawnCardMatches.isEmpty) {
        // 매치가 없으면 drawnCard는 필드에 남김(먹지 않음)
        pendingCaptured.removeWhere((c) => c.id == drawnCard!.id);
      }
      // 뒤집은 카드도 2장 매치라면 두 번째 선택창을 위한 상태 세팅
      else if (drawnCardMatches.length == 2) {
        logger.addLog(currentPlayer, 'chooseMatch', LogLevel.info, 
          '두 번째 2장 매치 발견: 두 번째 선택창 세팅'
        );
        choices = drawnCardMatches;
        pendingCaptured.add(drawnCard!);
        logger.logActualProcessing('두 번째 2장 선택창 설정', {
          'choices': choices.map((c) => '${c.id}(${c.name})').toList(),
          'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
          'phase': currentPhase.name,
        }, currentPlayer, 'chooseMatch');
        return; // _endTurn() 호출하지 않고 선택창 대기
      }
    }
    // 두 번째 2장 매치가 없으면 턴 종료
    logger.addLog(currentPlayer, 'chooseMatch', LogLevel.info, 
      '두 번째 2장 매치 없음: 턴 종료'
    );
    // 상태 초기화
    drawnCard = null;
    hadTwoMatch = false;
    choices.clear();
    currentPhase = TurnPhase.playingCard;
    _endTurn();
    return;
  }

  // 3단계: 턴 종료 및 정산
  void _endTurn() {
    // 턴 종료 시 애니메이션 실행 (필드 → 획득 영역) 및 해당 턴에 먹은 카드들과 보너스피를 현재 플레이어 획득 영역에 추가
    if (bonusOverlayCards.isNotEmpty) {
      _addAllToPendingCaptured(bonusOverlayCards);
      bonusOverlayCards.clear();
    }
    // pendingCaptured 중복 제거
    pendingCaptured = pendingCaptured.toSet().toList();
    logAllCardStates('endTurn-시작');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '[DEBUG] 턴 종료 처리 전 상태: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '손패: ${getHand(currentPlayer).map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '필드: ${getField().map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '카드더미: ${deckManager.drawPile.map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '획득: ${getCaptured(currentPlayer).map((c) => c.id).toList()}');
    
    final playerIdx = currentPlayer - 1;
    
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '턴 종료 시작');
    
    // 턴 상태 초기화
    hadTwoMatch = false;

    // [고스톱 규칙] 매치된 카드는 무조건 내 획득 카드로 이동 (뻑 월 4장만 필드에 남김)
    if (pendingCaptured.isNotEmpty) {
      // 뻑 상태면 뻑월 카드는 제외하고 획득 애니메이션 트리거
      List<GoStopCard> toCapture = List<GoStopCard>.from(pendingCaptured);
      if (ppeokMonth != null) {
        toCapture = toCapture.where((c) => c.month != ppeokMonth).toList();
      }
      _triggerAnimation(AnimationEventType.cardCapture, {
        'cards': toCapture,
        'player': currentPlayer,
      });
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '획득 카드 처리 시작: ${toCapture.map((c) => '${c.id}(${c.name})').toList()}');
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '매치 처리 시점 필드 카드: ${deckManager.fieldCards.map((c) => '${c.id}(${c.name})[월${c.month}]').toList()}');

      // 애니메이션 완료 후 실제 카드 데이터 이동은 UI에서 처리
      // 여기서는 pendingCaptured를 유지하여 애니메이션 중에도 필드에 카드가 보이도록 함
    }

    // 쓸(Sseul) 조건 체크 및 처리
    _handleSseul();

    // 상태 초기화
    pendingCaptured.clear();
    playedCard = null;
    drawnCard = null;
    bonusOverlayCards.clear();

    // [고스톱 규칙] 점수 계산 후 7점 이상이면 GO/STOP 판정
    if (_checkVictoryCondition()) {
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '승리 조건 충족: 고/스톱 선택 대기');
      awaitingGoStop = true;
      currentPhase = TurnPhase.turnEnd;
      // 턴을 넘기지 않고 '고/스톱' 결정을 기다림
      return;
    }

    // 게임 종료 시 최종 박 판정 처리
    if (gameOver) {
      _processFinalBakJudgment();
    }

    // 다음 플레이어로 턴 넘김
    final nextPlayer = (currentPlayer % 2) + 1;
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '턴 전환: P$currentPlayer → P$nextPlayer');
    currentPlayer = nextPlayer;
    currentPhase = TurnPhase.playingCard;
    logger.incrementTurn();
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '[DEBUG] 턴 종료 처리 후 상태: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '손패: ${getHand(currentPlayer).map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '필드: ${getField().map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '카드더미: ${deckManager.drawPile.map((c) => c.id).toList()}');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '획득: ${getCaptured(currentPlayer).map((c) => c.id).toList()}');
    logAllCardStates('endTurn-종료');
    tapLock = false;
    
    // UI 갱신 콜백 호출 (폭탄 처리 후 획득카드/필드카드 이동 완료 후)
    onTurnEnd?.call();
  }
  
  bool _checkVictoryCondition() {
    final score = calculateBaseScore(currentPlayer);
    
    // 3. goCount > 0 상태에서 상대가 7점↑ 달성(역GO) ⇒ winner = opponent ; gameOver = true ; GO/STOP 배수는 무시한다.
    if (goCount > 0) {
      final opponent = (currentPlayer % 2) + 1;
      final opponentScore = calculateBaseScore(opponent);
      if (opponentScore >= 7) {
        // 역GO: 상대방이 승리 (박 판정은 GO/STOP 선택 후에 처리)
        winner = 'player$opponent';
        gameOver = true;
        logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
          '역GO 발생: 상대방 $opponent이 7점 달성으로 승리 (현재 플레이어: $currentPlayer, goCount: $goCount)'
        );
        return true;
      }
    }
    
    // 맞고는 7점부터 (박 판정은 GO/STOP 선택 후에 처리)
    if (score >= 7) {
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
        '7점 이상 달성: GO/STOP 선택 대기 (점수: $score)'
      );
      return true;
    }
    
    return false;
  }

  void declareGo() {
    if (!awaitingGoStop) return;
    goCount++;
    goPlayer = currentPlayer; // GO를 선언한 플레이어 설정
    awaitingGoStop = false;
    
    // GO 선언 후 상대방 턴으로 전환
    currentPlayer = currentPlayer == 1 ? 2 : 1; // 상대방 턴으로 변경
    currentPhase = TurnPhase.playingCard;
    logger.addLog(goPlayer ?? currentPlayer, 'declareGo', LogLevel.info, 
      'GO 선언: 플레이어 $goPlayer가 게임 계속 (goCount: $goCount)'
    );
  }

  void declareStop() {
    if (!awaitingGoStop) return;
    // 박 판정 처리 (STOP 선언 시)
    _processFinalBakJudgment();
    winner = 'player$currentPlayer';
    gameOver = true;
    currentPhase = TurnPhase.turnEnd;
    logger.addLog(currentPlayer, 'declareStop', LogLevel.info, 
      'STOP 선언: 플레이어 $currentPlayer 승리'
    );
  }

  // 게임 종료 시 최종 박 판정 처리 (모든 특수 규칙 처리 후 호출)
  void _processFinalBakJudgment() {
    // 박 판정은 게임 종료 시점에 한 번만 처리
    checkPiBakAndGwangBak();
    logger.addLog(currentPlayer, 'finalBakJudgment', LogLevel.info, 
      '최종 박 판정 완료'
    );
  }

  // 기존 로직들 (일부 수정 필요)
  void _stealOpponentPi(int playerIdx) {
    // playerIdx: 피를 가져갈 플레이어(0 또는 1)
    int opponentIdx = 1 - playerIdx;
    final opponentCaptured = deckManager.capturedCards[opponentIdx];
    final myCaptured = deckManager.capturedCards[playerIdx];
    
    logger.logPiSteal(opponentCaptured ?? [], playerIdx + 1);
    
    if (opponentCaptured == null || opponentCaptured.isEmpty) {
      logger.addLog(playerIdx + 1, 'turnEnd', LogLevel.info, 
        '피 강탈 실패: 상대방 획득 카드가 없음'
      );
      return;
    }
    
    // 1. 일반 피
    final normalPi = opponentCaptured.where((c) =>
      c.type == '피' &&
      !(c.imageUrl.contains('ssangpi') || c.imageUrl.contains('3pi')) &&
      !c.isBonus
    ).toList();
    if (normalPi.isNotEmpty) {
      final stolen = normalPi.first;
      opponentCaptured.remove(stolen);
      myCaptured?.add(stolen); // 즉시 내 획득 카드로 이동
      // UI 획득 애니메이션을 위해 pendingCaptured에도 추가
      _addToPendingCaptured(stolen);
      // 피 강탈 애니메이션 트리거
      _triggerAnimation(AnimationEventType.specialEffect, {
        'effect': 'piSteal',
        'player': playerIdx + 1,
      });
      logger.logActualProcessing('피 강탈 (일반피)', {
        'stolenCard': '${stolen.id}(${stolen.name})',
        'myCaptured': myCaptured?.map((c) => '${c.id}(${c.name})').toList(),
      }, playerIdx + 1, 'turnEnd');
      return;
    }
    // 2. 쌍피
    final ssangpi = opponentCaptured.where((c) =>
      c.type == '피' &&
      c.imageUrl.contains('ssangpi') &&
      !c.isBonus
    ).toList();
    if (ssangpi.isNotEmpty) {
      final stolen = ssangpi.first;
      opponentCaptured.remove(stolen);
      myCaptured?.add(stolen);
      // UI 획득 애니메이션을 위해 pendingCaptured에도 추가
      _addToPendingCaptured(stolen);
      _triggerAnimation(AnimationEventType.specialEffect, {
        'effect': 'piSteal',
        'player': playerIdx + 1,
      });
      logger.logActualProcessing('피 강탈 (쌍피)', {
        'stolenCard': '${stolen.id}(${stolen.name})',
        'myCaptured': myCaptured?.map((c) => '${c.id}(${c.name})').toList(),
      }, playerIdx + 1, 'turnEnd');
      return;
    }
    // 3. 보너스 3점 피
    final bonusPi = opponentCaptured.where((c) =>
      c.type == '피' &&
      (c.imageUrl.contains('3pi') || c.isBonus)
    ).toList();
    if (bonusPi.isNotEmpty) {
      final stolen = bonusPi.first;
      opponentCaptured.remove(stolen);
      myCaptured?.add(stolen);
      // UI 획득 애니메이션을 위해 pendingCaptured에도 추가
      _addToPendingCaptured(stolen);
      _triggerAnimation(AnimationEventType.specialEffect, {
        'effect': 'piSteal',
        'player': playerIdx + 1,
      });
      logger.logActualProcessing('피 강탈 (보너스피)', {
        'stolenCard': '${stolen.id}(${stolen.name})',
        'myCaptured': myCaptured?.map((c) => '${c.id}(${c.name})').toList(),
      }, playerIdx + 1, 'turnEnd');
      return;
    }
    logger.addLog(playerIdx + 1, 'turnEnd', LogLevel.warning, 
      '피 강탈 실패: 강탈할 피가 없음'
    );
  }
  
  // 점수 계산 결과를 상세히 반환하는 메서드
  Map<String, dynamic> calculateScoreDetails(int playerNum) {
    // 현재 플레이어의 pendingCaptured만 포함 (무한 루프 방지)
    final captured = [...getCaptured(playerNum)];
    if (playerNum == currentPlayer && pendingCaptured.isNotEmpty) {
      captured.addAll(pendingCaptured);
    }
    
    if (captured.isEmpty) {
      return {
        'totalScore': 0,
        'baseScore': 0,
        'gwangScore': 0,
        'ttiScore': 0,
        'piScore': 0,
        'animalScore': 0,
        'godoriScore': 0,
        'danScore': 0,
        'goBonus': 0,
        'gwangCards': [],
        'ttiCards': [],
        'piCards': [],
        'animalCards': [],
        'totalPi': 0,
      };
    }

    // ① 기본점수(base) 계산
    int baseScore = 0;
    int gwangScore = 0;
    int ttiScore = 0;
    int piScore = 0;
    int animalScore = 0;
    int godoriScore = 0;
    int danScore = 0;
    
    // 광 점수 계산
    final gwangCards = captured.where((c) => c.type == '광').toList();
    final hasRainGwang = gwangCards.any((c) => c.month == 12); // 비광(12월 광) 포함 여부
    if (gwangCards.length == 3) {
      if (hasRainGwang) {
        gwangScore = 2; // 비광 포함 3광
      } else {
        gwangScore = 3; // 비광 없는 3광
      }
    } else if (gwangCards.length == 4) {
      gwangScore = 4;
    } else if (gwangCards.length >= 5) {
      gwangScore = 15;
    }
    baseScore += gwangScore;
    
    // 띠 점수 계산
    final ttiCards = captured.where((c) => c.type == '띠').toList();
    if (ttiCards.length >= 5) {
      ttiScore = ttiCards.length - 4; // 5띠=1점, 6띠=2점, 7띠=3점
      baseScore += ttiScore;
    }
    
    // 고도리 (새 동물 3종: 2,4,8월 동물)
    final godoriMonths = {2, 4, 8};
    final godoriHas = godoriMonths.every((m) => captured.any((c) => c.type == '동물' && c.month == m));
    if (godoriHas) {
      godoriScore = 5;
      baseScore += godoriScore;
    }

    // 단(청단/홍단/초단) 세트 점수 계산
    const hongdanMonths = {1, 2, 3};
    const chungdanMonths = {6, 9, 10};
    const chodanMonths = {4, 5, 7};
    int danPoints = 0;
    if (hongdanMonths.every((m) => captured.any((c) => c.type == '띠' && c.month == m))) {
      danPoints += 3;
    }
    if (chungdanMonths.every((m) => captured.any((c) => c.type == '띠' && c.month == m))) {
      danPoints += 3;
    }
    if (chodanMonths.every((m) => captured.any((c) => c.type == '띠' && c.month == m))) {
      danPoints += 3;
    }
    danScore = danPoints;
    baseScore += danScore;

    // 피 점수 계산 (총 피 점수: 일반피=1, 쌍피/보너스쌍피=2, 쓰리피/보너스쓰리피=3)
    final piCards = captured.where((c) => c.type == '피').toList();
    int totalPiScore = 0;
    for (final c in piCards) {
      final img = c.imageUrl;
      if (img.contains('bonus_3pi') || (c.isBonus && img.contains('3pi'))) {
        totalPiScore += 3; // 보너스 쓰리피
      } else if (img.contains('bonus_ssangpi') || (c.isBonus && img.contains('ssangpi'))) {
        totalPiScore += 2; // 보너스 쌍피
      } else if (img.contains('3pi')) {
        totalPiScore += 3; // 쓰리피
      } else if (img.contains('ssangpi')) {
        totalPiScore += 2; // 쌍피
      } else {
        totalPiScore += 1; // 일반피
      }
    }
    if (totalPiScore >= 10) {
      piScore = totalPiScore - 9;
      baseScore += piScore;
    }

    // 동물(열끗) 점수: 5장부터 1점, 이후 1장마다 +1
    final animalCards = captured.where((c) => c.type == '동물' || c.type == '오').toList();
    if (animalCards.length >= 5) {
      animalScore = animalCards.length - 4;
      baseScore += animalScore;
    }

    // ② GO 가산점(+1/+2) 추가
    int goBonus = 0;
    int score = baseScore;
    if (goCount == 1) {
      goBonus = 1;
      score += goBonus;
    } else if (goCount == 2) {
      goBonus = 2;
      score += goBonus;
    }

    // ③ 3GO 이상 ⇒ GO 배수
    if (goCount >= 3) {
      goBonus = (baseScore + 2) * (1 << (goCount - 2)) - baseScore;
      score = (baseScore + 2) * (1 << (goCount - 2));
    }

    // ④ 흔들·폭탄 배수 (중첩 가능)
    if (heundalPlayers.contains(playerNum)) {
      score *= 2;
      logger.addLog(playerNum, 'turnEnd', LogLevel.info, 
        '흔들 배수 적용: 점수 2배 (${score ~/ 2} → $score)'
      );
    }
    if (bombPlayers.contains(playerNum)) score *= 2;
    
    // ⑤ 나가리 배수 적용
    if (nagariCount > 0) {
      final nagariMultiplier = 1 << nagariCount;
      score *= nagariMultiplier;
      logger.addLog(playerNum, 'turnEnd', LogLevel.info, 
        '나가리 배수 적용: 점수 ×$nagariMultiplier (${score ~/ nagariMultiplier} → $score)'
      );
    }

    // ⑥ 피박·광박·멍박 배수 적용 (게임 종료 시에만 적용)
    // 규칙: 상대방이 박에 걸렸으면 "내" 점수를 2배 한다.
    final int opponent = playerNum == 1 ? 2 : 1;
    if (piBakPlayers.contains(opponent)) {
      score *= 2;
      logger.addLog(playerNum, 'gameEnd', LogLevel.info, 
        '피박 배수 적용 (상대 피박): 점수 2배 (${score ~/ 2} → $score)'
      );
    }
    if (gwangBakPlayers.contains(opponent)) {
      score *= 2;
      logger.addLog(playerNum, 'gameEnd', LogLevel.info, 
        '광박 배수 적용 (상대 광박): 점수 2배 (${score ~/ 2} → $score)'
      );
    }
    if (mungBakPlayers.contains(opponent)) {
      score *= 2;
      logger.addLog(playerNum, 'gameEnd', LogLevel.info, 
        '멍박 배수 적용 (상대 멍박): 점수 2배 (${score ~/ 2} → $score)'
      );
    }

    return {
      'totalScore': score,
      'baseScore': baseScore,
      'gwangScore': gwangScore,
      'ttiScore': ttiScore,
      'piScore': piScore,
      'animalScore': animalScore,
      'godoriScore': godoriScore,
      'danScore': danScore,
      'goBonus': goBonus,
      'gwangCards': gwangCards.map((c) => '${c.id}(${c.name})').toList(),
      'ttiCards': ttiCards.map((c) => '${c.id}(${c.name})').toList(),
      'piCards': piCards.map((c) => '${c.id}(${c.name})').toList(),
      'animalCards': animalCards.map((c) => '${c.id}(${c.name})').toList(),
      'totalPi': totalPiScore,
    };
  }

  int calculateBaseScore(int playerNum) {
    final details = calculateScoreDetails(playerNum);
    return (details['baseScore'] ?? 0) as int;
  }

  // ─────────────────────────────────────────────────────────────
  // 최종 점수(배수 포함) 계산 - 기존 로직 복원
  // ─────────────────────────────────────────────────────────────
  int calculateScore(int playerNum) {
    final details = calculateScoreDetails(playerNum);
    return (details['totalScore'] ?? 0) as int;
  }

  String getResult() {
    if (!gameOver || winner == null) return "게임이 진행 중입니다.";
    
    final player1Score = calculateScore(1);
    final player2Score = calculateScore(2);
    
    if (winner == 'player1') {
      return "플레이어 1 승리!\n점수: $player1Score vs $player2Score";
    } else if (winner == 'player2') {
      return "플레이어 2 승리!\n점수: $player1Score vs $player2Score";
    } else {
      return "무승부\n점수: $player1Score vs $player2Score";
    }
  }
  
  bool isGameOver() => gameOver;

  // ... 기타 헬퍼 메서드들

  // pendingCaptured에 중복 카드 추가 방지 함수
  void _addToPendingCaptured(GoStopCard card) {
    if (!pendingCaptured.any((c) => c.id == card.id)) {
      pendingCaptured.add(card);
    }
  }
  void _addAllToPendingCaptured(List<GoStopCard> cards) {
    for (final card in cards) {
      _addToPendingCaptured(card);
    }
  }

  // 새 라운드 시작 (ppeokMonth 리셋)
  void newRound() {
    // ... 기존 코드 ...
    ppeokMonth = null;
  }

  // 무승부 처리 (나가리 시스템)
  void gameDraw() {
    // 나가리 횟수 증가 (최대 4회)
    if (nagariCount < 4) {
      nagariCount++;
      logger.addLog(currentPlayer, 'gameEnd', LogLevel.info, 
        '나가리 발생: 다음 판 승점 ×${1 << nagariCount} ($nagariCount회째)'
      );
    }
    ppeokMonth = null;
  }

  // 쓸(Sseul) 조건 체크: 바닥(필드)이 0장 됨
  bool _checkSseulCondition() {
    return deckManager.fieldCards.isEmpty;
  }
  
  // 쓸 처리: 상대방 피 1장 강탈
  void _handleSseul() {
    if (_checkSseulCondition()) {
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
        '쓸 발생: 바닥이 0장이 되어 상대방 피 1장 강탈'
      );
      
      // 쓸 애니메이션 트리거
      _triggerAnimation(AnimationEventType.specialEffect, {
        'effect': 'sseul',
        'player': currentPlayer,
      });
      
      // 피 강탈
      _stealOpponentPi(currentPlayer - 1);
    }
  }
  
  // 테스트용: 뻑 등 검증을 위해 drawnCard 처리 메서드 공개
  void processDrawnCardForTest(GoStopCard drawnCard) {
    _processDrawnCard(drawnCard);
  }

  // ── 실시간 박 상태 체크 (게임 종료 전에도 활성화) ──
  void checkBakConditions() {
    // 기존 박 상태 초기화
    piBakPlayers.clear();
    gwangBakPlayers.clear();
    mungBakPlayers.clear();
    
    // 각 플레이어의 현재 상태 체크
    for (int player = 1; player <= 2; player++) {
      final opponent = player == 1 ? 2 : 1;
      final playerCaptured = getCaptured(player);
      final opponentCaptured = getCaptured(opponent);
      
      // ── 피박 체크 ──
      // 플레이어의 피 점수 계산
      final playerPiCards = playerCaptured.where((c) => c.type == '피').toList();
      int playerPiScore = 0;
      int totalPiScore = 0;
      for (final c in playerPiCards) {
        final img = c.imageUrl;
        if (img.contains('bonus_3pi') || (c.isBonus && img.contains('3pi'))) {
          totalPiScore += 3;
        } else if (img.contains('bonus_ssangpi') || (c.isBonus && img.contains('ssangpi'))) {
          totalPiScore += 2;
        } else if (img.contains('3pi')) {
          totalPiScore += 3;
        } else if (img.contains('ssangpi')) {
          totalPiScore += 2;
        } else {
          totalPiScore += 1;
        }
      }
      if (totalPiScore >= 10) {
        playerPiScore = totalPiScore - 9;
      }
      
      // 상대방의 피 개수 계산
      final opponentPiCards = opponentCaptured.where((c) => c.type == '피').toList();
      int opponentPiCount = 0;
      for (final c in opponentPiCards) {
        final img = c.imageUrl;
        if (img.contains('bonus_3pi') || (c.isBonus && img.contains('3pi'))) {
          opponentPiCount += 3;
        } else if (img.contains('bonus_ssangpi') || (c.isBonus && img.contains('ssangpi'))) {
          opponentPiCount += 2;
        } else if (img.contains('3pi')) {
          opponentPiCount += 3;
        } else if (img.contains('ssangpi')) {
          opponentPiCount += 2;
        } else {
          opponentPiCount += 1;
        }
      }
      
      // 피박 조건: 플레이어가 피 점수를 얻었고, 상대방이 피 6장 이하
      if (playerPiScore > 0 && opponentPiCount <= 6) {
        piBakPlayers.add(opponent);
        logger.addLog(opponent, 'turnEnd', LogLevel.info, 
          '피박 발생: 플레이어 $opponent (피 $opponentPiCount장) - 플레이어 $player 피 점수: $playerPiScore'
        );
      }
      
      // ── 광박 체크 ──
      // 플레이어의 광 점수 계산
      final playerGwangCards = playerCaptured.where((c) => c.type == '광').toList();
      final opponentGwangCards = opponentCaptured.where((c) => c.type == '광').toList();
      
      int playerGwangScore = 0;
      final hasRainGwang = playerGwangCards.any((c) => c.month == 12);
      if (playerGwangCards.length == 3) {
        playerGwangScore = hasRainGwang ? 2 : 3;
      } else if (playerGwangCards.length == 4) {
        playerGwangScore = 4;
      } else if (playerGwangCards.length >= 5) {
        playerGwangScore = 15;
      }
      
      // 광박 조건: 플레이어가 광 점수를 얻었고, 상대방이 광 0장
      if (playerGwangScore > 0 && opponentGwangCards.isEmpty) {
        gwangBakPlayers.add(opponent);
        logger.addLog(opponent, 'turnEnd', LogLevel.info, 
          '광박 발생: 플레이어 $opponent (광 0장) - 플레이어 $player 광 점수: $playerGwangScore'
        );
      }
      
      // ── 멍박 체크 ──
      // 플레이어의 동물 점수 계산
      final playerAnimalCards = playerCaptured.where((c) => c.type == '동물' || c.type == '오').toList();
      final opponentAnimalCards = opponentCaptured.where((c) => c.type == '동물' || c.type == '오').toList();
      
      int playerAnimalScore = 0;
      if (playerAnimalCards.length >= 5) {
        playerAnimalScore = playerAnimalCards.length - 4;
      }
      
      // 멍박 조건: 플레이어가 동물 점수를 얻었고, 상대방이 동물 7장 미만
      if (playerAnimalScore > 0 && opponentAnimalCards.length < 7) {
        mungBakPlayers.add(opponent);
        logger.addLog(opponent, 'turnEnd', LogLevel.info, 
          '멍박 발생: 플레이어 $opponent (동물 ${opponentAnimalCards.length}장) - 플레이어 $player 동물 점수: $playerAnimalScore'
        );
      }
    }
  }
}