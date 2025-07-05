import 'dart:math';
import '../models/card_model.dart';
import 'event_evaluator.dart';
import 'deck_manager.dart';
import 'game_logger.dart';

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
  String? winner;
  bool gameOver = false;
  final EventEvaluator eventEvaluator = EventEvaluator();
  bool awaitingGoStop = false;
  final GameLogger logger = GameLogger();

  // 턴 진행 관련 상태
  TurnPhase currentPhase = TurnPhase.playingCard;
  GoStopCard? playedCard; // 이번 턴에 낸 카드
  List<GoStopCard> pendingCaptured = []; // 이번 턴에 획득할 예정인 카드들
  List<GoStopCard> choices = []; // 따닥 발생 시 선택할 카드들
  GoStopCard? drawnCard; // 뒤집은 카드 (따닥 상황에서 사용)
  int? ppeokMonth; // 뻑이 발생한 월 (null이면 뻑 상태 아님)
  bool hadTwoMatch = false; // 카드 내기 단계에서 2장 매치가 있었는지 여부
  GoStopCard? bonusCard; // 카드더미에서 나온 보너스피 (내가 낸 카드 위에 올려놓을 카드)
  GoStopCard? handBonusCard; // 손패에서 낸 보너스피 (즉시 먹은 카드로 처리)

  // 애니메이션 이벤트 콜백
  Function(AnimationEvent)? onAnimationEvent;

  MatgoEngine(this.deckManager);

  // 애니메이션 이벤트 리스너 설정
  void setAnimationListener(Function(AnimationEvent) listener) {
    onAnimationEvent = listener;
  }

  // 애니메이션 이벤트 발생
  void _triggerAnimation(AnimationEventType type, Map<String, dynamic> data) {
    onAnimationEvent?.call(AnimationEvent(type, data));
  }

  void reset() {
    deckManager.reset();
    currentPlayer = 1;
    goCount = 0;
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
    bonusCard = null;
    logger.clearLogs();
  }

  List<GoStopCard> getHand(int playerNum) => deckManager.getPlayerHand(playerNum - 1);
  List<GoStopCard> getField() => deckManager.getFieldCards();
  List<GoStopCard> getCaptured(int playerNum) => deckManager.capturedCards[playerNum - 1] ?? [];
  int get drawPileCount => deckManager.drawPile.length;

  void logAllCardStates(String context) {
    logger.addLog(currentPlayer, context, LogLevel.info, '================ 카드 상태 스냅샷 ================');
    for (int p = 1; p <= 2; p++) {
      logger.addLog(p, context, LogLevel.info, '[P$p] 손패: ' + getHand(p).map((c) => c.id).toList().toString());
      logger.addLog(p, context, LogLevel.info, '[P$p] 먹은 카드: ' + getCaptured(p).map((c) => c.id).toList().toString());
    }
    logger.addLog(currentPlayer, context, LogLevel.info, '[공통] 필드: ' + getField().map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, context, LogLevel.info, '[공통] 카드더미: ' + deckManager.drawPile.map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, context, LogLevel.info, '=================================================');
  }

  // 1단계: 플레이어가 손에서 카드를 냄
  void playCard(GoStopCard card, {int? groupIndex}) {
    logAllCardStates('playingCard-시작');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '[DEBUG] 턴 시작: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '손패: ' + getHand(currentPlayer).map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '필드: ' + getField().map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '카드더미: ' + deckManager.drawPile.map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '획득: ' + getCaptured(currentPlayer).map((c) => c.id).toList().toString());
    
    if (currentPhase != TurnPhase.playingCard) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.error, 
        '잘못된 phase에서 카드 내기 시도', 
        data: {'currentPhase': currentPhase.name}
      );
      return;
    }

    final playerIdx = currentPlayer - 1;
    // 애니메이션 완료 후에 손패에서 제거되므로 여기서는 제거하지 않음
    // deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == card.id);
    playedCard = card;
    
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
      'playedCard 설정: ${playedCard?.id}(${playedCard?.name})'
    );

    // 보너스카드(쌍피 등) 낼 때 바로 먹은 카드로 이동
    if (card.isBonus) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '보너스카드 처리 시작', 
        data: {'cardId': card.id, 'cardName': card.name}
      );
      
      // 손패에서 낸 보너스피는 즉시 먹은 카드로 처리
      handBonusCard = card;
      pendingCaptured.add(card);
      _triggerAnimation(AnimationEventType.bonusCard, {
        'card': card,
        'player': currentPlayer,
      });
      
      // 보너스카드 효과: 카드더미에서 한 장을 뒤집지 않고 상대방에게 보이지 않는 상태로 가져옴
      if (deckManager.drawPile.isNotEmpty) {
        final bonusDrawnCard = deckManager.drawPile.removeAt(0);
        // 상대방에게 보이지 않는 상태로 손패에 추가
        final playerIdx = currentPlayer - 1;
        deckManager.playerHands[playerIdx]?.add(bonusDrawnCard);
        
        logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
          '보너스카드 효과: 카드더미에서 한 장 가져옴 - ${bonusDrawnCard.id}(${bonusDrawnCard.name})'
        );
      }
      
      logger.logActualProcessing('보너스카드 처리', {
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'newPhase': currentPhase.name,
      }, currentPlayer, 'playingCard');
      
      // 보너스카드 처리 후 같은 플레이어가 계속 턴 유지 (다시 한 장을 낼 수 있는 상태)
      currentPhase = TurnPhase.playingCard;
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '보너스카드 처리 완료: 같은 플레이어 턴 계속'
      );
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
        'newPhase': currentPhase.name,
      }, currentPlayer, 'playingCard');
      currentPhase = TurnPhase.flippingCard;
      return;
    }

    final fieldMatches = getField().where((c) => c.month == card.month).toList();
    logger.logCardMatch(card, getField(), currentPlayer);
    
    // 먹을 카드가 있으면 임시 목록에 추가 (하지만 필드에서 제거하지 않음)
    if (fieldMatches.length == 1) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '1장 매치 발견: ${card.id}(${card.name}) ↔ ${fieldMatches.first.id}(${fieldMatches.first.name})'
      );
      
      pendingCaptured.addAll([card, fieldMatches.first]);
      // 내가 낸 카드도 필드에 추가하여 시각적으로 겹침 상태 표시
      deckManager.fieldCards.add(card);
      
      logger.logActualProcessing('1장 매치 처리', {
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'fieldCardsAdded': [card.id],
      }, currentPlayer, 'playingCard');
      
      // 겹침 애니메이션 트리거
      _triggerAnimation(AnimationEventType.cardMove, {
        'cards': [card, fieldMatches.first],
        'from': 'hand',
        'to': 'fieldOverlap',
        'player': currentPlayer,
      });
      // 먹기 애니메이션 트리거(겹침 후)
      _triggerAnimation(AnimationEventType.cardCapture, {
        'cards': [card, fieldMatches.first],
        'player': currentPlayer,
      });
      currentPhase = TurnPhase.flippingCard;
      return;
    } else if (fieldMatches.length == 2) {
      logger.logTtak(fieldMatches, playedCard, currentPlayer);
      
      // 2장 매치: 카드더미 뒤집기로 진행 (따닥 판단은 뒤집은 후에)
      hadTwoMatch = true; // 2장 매치 여부 저장
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '2장 매치 발견: 카드더미 뒤집기로 진행 - ${fieldMatches.map((c) => '${c.id}(${c.name})').toList()}'
      );
      // 내가 낸 카드를 필드에 추가하여 시각적으로 겹침 상태 표시
      deckManager.fieldCards.add(card);
      logger.logActualProcessing('2장 매치 처리', {
        'fieldCardsAdded': [card.id],
        'nextPhase': 'flippingCard',
        'hadTwoMatch': hadTwoMatch,
      }, currentPlayer, 'playingCard');
      // 카드더미 뒤집기로 진행
      currentPhase = TurnPhase.flippingCard;
      return;
    } else if (fieldMatches.length == 3) {
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '3장 매치 발견: ${card.id}(${card.name}) ↔ ${fieldMatches.map((c) => '${c.id}(${c.name})').join(', ')}'
      );
      
      pendingCaptured.addAll([card, ...fieldMatches]);
      // 내가 낸 카드도 필드에 추가하여 시각적으로 겹침 상태 표시
      deckManager.fieldCards.add(card);
      
      logger.logActualProcessing('3장 매치 처리', {
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'fieldCardsAdded': [card.id],
      }, currentPlayer, 'playingCard');
      
      // 겹침 애니메이션 트리거
      _triggerAnimation(AnimationEventType.cardMove, {
        'cards': [card, ...fieldMatches],
        'from': 'hand',
        'to': 'fieldOverlap',
        'player': currentPlayer,
      });
      // 먹기 애니메이션 트리거(겹침 후)
      _triggerAnimation(AnimationEventType.cardCapture, {
        'cards': [card, ...fieldMatches],
        'player': currentPlayer,
      });
      currentPhase = TurnPhase.flippingCard;
      return;
    } else {
      // 먹을 카드가 없으면 groupIndex 위치에 카드 추가
      logger.addLog(currentPlayer, 'playingCard', LogLevel.info, 
        '매치 없음: 필드에 카드 추가'
      );
      
      if (groupIndex != null) {
        // 필드 그룹별로 정렬된 리스트 생성
        final fieldGroups = <int, List<GoStopCard>>{};
        for (final c in deckManager.fieldCards) {
          if (c.month > 0) {
            fieldGroups.putIfAbsent(c.month, () => []).add(c);
          }
        }
        // 그룹 인덱스에 맞는 위치에 카드 삽입
        final sortedGroups = fieldGroups.keys.toList()..sort();
        int insertPos = 0;
        if (groupIndex <= sortedGroups.length) {
          // 그룹 인덱스에 맞는 위치 찾기
          for (int i = 0; i < groupIndex; i++) {
            final month = sortedGroups.length > i ? sortedGroups[i] : null;
            if (month != null) {
              insertPos += fieldGroups[month]?.length ?? 0;
            }
          }
        }
        deckManager.fieldCards.insert(insertPos, card);
        
        logger.logActualProcessing('그룹 인덱스로 카드 추가', {
          'groupIndex': groupIndex,
          'insertPos': insertPos,
          'fieldCardsAdded': [card.id],
        }, currentPlayer, 'playingCard');
      } else {
        deckManager.fieldCards.add(card);
        
        logger.logActualProcessing('일반 카드 추가', {
          'fieldCardsAdded': [card.id],
        }, currentPlayer, 'playingCard');
      }
      currentPhase = TurnPhase.flippingCard;
    }

    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '[DEBUG] 턴 종료: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '손패: ' + getHand(currentPlayer).map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '필드: ' + getField().map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '카드더미: ' + deckManager.drawPile.map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'playingCard', LogLevel.info, '획득: ' + getCaptured(currentPlayer).map((c) => c.id).toList().toString());
    logAllCardStates('playingCard-종료');
  }
  
  // 2단계: 카드 더미에서 카드를 뒤집음
  void flipFromDeck([GoStopCard? overrideCard]) {
    logAllCardStates('flippingCard-시작');
    if (currentPhase != TurnPhase.flippingCard) return;
    
    // 카드더미에서 카드 한 장을 뒤집음
    final drawnCard = overrideCard ?? deckManager.drawPile.removeAt(0);
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '카드 뒤집음: ${drawnCard.id}(${drawnCard.name})');
    
    // 보너스피(보너스카드)인 경우: 내가 낸 카드 위에 올려놓고 한 장 더 드로우
    if (drawnCard.isBonus) {
      // 보너스피를 임시로 저장 (매치 처리 후 뻑 여부에 따라 처리)
      bonusCard = drawnCard;
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '보너스피를 내가 낸 카드 위에 올림: ${drawnCard.id}(${drawnCard.name})');
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '보너스피 추가 드로우: ${drawnCard.id}(${drawnCard.name})');
      // 한 장 더 드로우 (재귀 호출)
      if (deckManager.drawPile.isNotEmpty) {
        flipFromDeck();
        return;
      }
    }

    // 뻑 완성 체크 (카드더미에서 뒤집은 카드)
    if (ppeokMonth != null && drawnCard.month == ppeokMonth) {
      logger.logPpeok(ppeokMonth, drawnCard, currentPlayer);
      // 뻑 완성: 해당 월의 모든 카드를 필드에 남김(획득/제거X)
      final allPpeokCards = <GoStopCard>[];
      // 필드에 이미 있는 해당 월 카드
      allPpeokCards.addAll(deckManager.fieldCards.where((c) => c.month == ppeokMonth));
      // 내가 낸 카드, 보너스피, 뒤집은 카드 등도 포함(중복X)
      if (playedCard != null && playedCard!.month == ppeokMonth && !allPpeokCards.any((c) => c.id == playedCard!.id)) {
        allPpeokCards.add(playedCard!);
      }
      if (!allPpeokCards.any((c) => c.id == drawnCard.id)) {
        allPpeokCards.add(drawnCard);
      }
      // 보너스피가 임시로 필드에 올라간 경우도 포함(중복X)
      // (이미 필드에 있으면 중복X)
      // pendingCaptured, choices 등도 모두 초기화
      pendingCaptured.clear();
      choices.clear();
      // 필드에 해당 월 카드만 남기고, 중복 없이 유지
      deckManager.fieldCards.removeWhere((c) => c.month == ppeokMonth);
      deckManager.fieldCards.addAll(allPpeokCards);
      // 뻑 상태 초기화
      ppeokMonth = null;
      logger.logActualProcessing('뻑 완성 처리 (필드에 4장 유지)', {
        'ppeokMonth': ppeokMonth,
        'fieldCards': deckManager.fieldCards.map((c) => '${c.id}(${c.name})').toList(),
        'pendingCapturedCleared': true,
      }, currentPlayer, 'flippingCard');
      _endTurn();
      return;
    }
    
    final fieldMatches = getField().where((c) => c.month == drawnCard.month).toList();

    // 쪽(쪽따먹기) 체크: 이전 턴에 낸 카드가 필드에 깔렸고, 이번에 뒤집은 카드가 같은 월이면 쪽
    if (pendingCaptured.isEmpty && playedCard != null) {
      final lastPlayedCard = playedCard!;
      logger.logJjok(lastPlayedCard, drawnCard, currentPlayer);
      
      if (lastPlayedCard.month == drawnCard.month) {
        logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, 
          '쪽 발생: ${lastPlayedCard.id}(${lastPlayedCard.name}) ↔ ${drawnCard.id}(${drawnCard.name})'
        );
        
        // 쪽 발생: 방금 낸 카드와 뒤집은 카드 모두 먹기
        pendingCaptured.addAll([lastPlayedCard, drawnCard]);
        // 필드에서 방금 낸 카드 제거
        deckManager.fieldCards.removeWhere((c) => c.id == lastPlayedCard.id);
        // 쪽 효과: 피 1장 강탈
        _stealOpponentPi(currentPlayer - 1);
        
        logger.logActualProcessing('쪽 처리', {
          'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
          'fieldCardsRemoved': [lastPlayedCard.id],
        }, currentPlayer, 'flippingCard');
        
        _endTurn();
        return;
      }
    }

    // 뻑 발생: 내가 낸 카드와 뒤집은 카드가 같은 월이고, 필드에 같은 월 카드가 있음
    if (playedCard != null && playedCard!.month == drawnCard.month && getField().any((c) => c.month == drawnCard.month)) {
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, 
        '뻑 발생: ${drawnCard.id}(${drawnCard.name}) - 월 ${drawnCard.month}'
      );
      // 해당 월의 모든 카드를 필드에 남김(획득/제거X)
      final allPpeokCards = <GoStopCard>[];
      allPpeokCards.addAll(deckManager.fieldCards.where((c) => c.month == drawnCard.month));
      if (playedCard != null && playedCard!.month == drawnCard.month && !allPpeokCards.any((c) => c.id == playedCard!.id)) {
        allPpeokCards.add(playedCard!);
      }
      if (!allPpeokCards.any((c) => c.id == drawnCard.id)) {
        allPpeokCards.add(drawnCard);
      }
      // 보너스피가 있으면 뻑에 포함
      if (bonusCard != null && bonusCard!.month == drawnCard.month && !allPpeokCards.any((c) => c.id == bonusCard!.id)) {
        allPpeokCards.add(bonusCard!);
        logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, 
          '보너스피를 뻑에 포함: ${bonusCard!.id}(${bonusCard!.name})'
        );
      }
      pendingCaptured.clear();
      choices.clear();
      deckManager.fieldCards.removeWhere((c) => c.month == drawnCard.month);
      deckManager.fieldCards.addAll(allPpeokCards);
      // 뻑 상태 설정
      ppeokMonth = drawnCard.month;
      logger.logActualProcessing('뻑 상태 설정 (필드에 4장 유지)', {
        'ppeokMonth': ppeokMonth,
        'fieldCards': deckManager.fieldCards.map((c) => '${c.id}(${c.name})').toList(),
        'pendingCapturedCleared': true,
      }, currentPlayer, 'flippingCard');
      _endTurn();
      return;
    }
    
    // 따닥 체크: 현재 낸 카드 + 뒤집은 카드 + 필드 2장 = 4장 모두 같은 월
    if (fieldMatches.length == 2 && playedCard != null && 
        playedCard!.month == drawnCard.month && 
        fieldMatches[0].month == drawnCard.month && 
        fieldMatches[1].month == drawnCard.month) {
      
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, 
        '따닥 발생: 4장 모두 같은 월 - ${playedCard!.id}(${playedCard!.name}) + ${drawnCard.id}(${drawnCard.name}) + ${fieldMatches.map((c) => '${c.id}(${c.name})').join(', ')}'
      );
      
      // 따닥: 4장 모두 먹기 + 피 강탈
      pendingCaptured.addAll([playedCard!, drawnCard, ...fieldMatches]);
      deckManager.fieldCards.add(drawnCard);
      _stealOpponentPi(currentPlayer - 1); // 따닥 시 피 강탈
      
      logger.logActualProcessing('따닥 처리', {
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'fieldCardsAdded': [drawnCard.id],
      }, currentPlayer, 'flippingCard');
      
      _endTurn();
      return;
    }
    
    // 카드더미 뒤집기에서 2장 매치 후 선택창 표시(따닥 아님)
    if (hadTwoMatch && playedCard != null) {
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, 
        '2장 매치 후 카드 뒤집음: 선택창 표시 - ${playedCard!.id}(${playedCard!.name}) + ${drawnCard.id}(${drawnCard.name})'
      );
      // 필드에 깔린 두 장만 선택지로 (내가 낸 카드 제외)
      final previousFieldMatches = getField().where((c) => c.month == playedCard!.month && c.id != playedCard!.id).toList();
      choices = previousFieldMatches;
      // 내가 낸 카드는 무조건 먹음
      pendingCaptured.add(playedCard!);
      // (추가) 뒤집은 카드와 매치되는 필드 카드가 있으면 같이 먹기
      final drawnMatches = getField().where((c) => c.month == drawnCard.month).toList();
      if (drawnMatches.isNotEmpty) {
        pendingCaptured.add(drawnCard);
        pendingCaptured.addAll(drawnMatches);
      }
      this.drawnCard = drawnCard; // 뒤집은 카드 저장
      currentPhase = TurnPhase.choosingMatch;
      logger.logActualProcessing('2장 선택창 설정', {
        'choices': choices.map((c) => '${c.id}(${c.name})').toList(),
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'newPhase': TurnPhase.choosingMatch.name,
      }, currentPlayer, 'flippingCard');
      return;
    }
    
    // 일반적인 2장 매치 (따닥이 아닌 경우): 선택창 표시
    if (fieldMatches.length == 2) {
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, 
        '2장 매치: ${drawnCard.id}(${drawnCard.name}) ↔ ${fieldMatches.map((c) => '${c.id}(${c.name})').join(', ')}'
      );
      
      choices = fieldMatches;
      pendingCaptured.add(drawnCard);
      this.drawnCard = drawnCard; // 뒤집은 카드 저장
      
      logger.logActualProcessing('2장 선택창 설정', {
        'choices': choices.map((c) => '${c.id}(${c.name})').toList(),
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'newPhase': TurnPhase.choosingMatch.name,
      }, currentPlayer, 'flippingCard');
      
      currentPhase = TurnPhase.choosingMatch;
      return;
    }

    // 일반 먹기
    if (fieldMatches.length == 1) {
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, 
        '일반 먹기: ${drawnCard.id}(${drawnCard.name}) ↔ ${fieldMatches.first.id}(${fieldMatches.first.name})'
      );
      
      // 뒤집은 카드와 매치된 카드 추가 (중복 방지)
      if (!pendingCaptured.any((c) => c.id == drawnCard.id)) {
        pendingCaptured.add(drawnCard);
      }
      if (!pendingCaptured.any((c) => c.id == fieldMatches.first.id)) {
        pendingCaptured.add(fieldMatches.first);
      }
      
      // 뒤집은 카드도 필드에 추가하여 시각적으로 겹침 상태 표시
      deckManager.fieldCards.add(drawnCard);
      
      logger.logActualProcessing('일반 먹기 처리', {
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
        'fieldCardsAdded': [drawnCard.id],
      }, currentPlayer, 'flippingCard');
      
      _endTurn();
      return;
    } else {
      // 못 먹는 경우
      logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, 
        '매치 없음: 필드에 카드 추가 - ${drawnCard.id}(${drawnCard.name})'
      );
      
      deckManager.fieldCards.add(drawnCard);
      
      logger.logActualProcessing('매치 없음 처리', {
        'fieldCardsAdded': [drawnCard.id],
      }, currentPlayer, 'flippingCard');
      
      _endTurn();
      return;
    }

    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '[DEBUG] 카드더미 뒤집기 후 상태: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '손패: ' + getHand(currentPlayer).map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '필드: ' + getField().map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '카드더미: ' + deckManager.drawPile.map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'flippingCard', LogLevel.info, '획득: ' + getCaptured(currentPlayer).map((c) => c.id).toList().toString());
    logAllCardStates('flippingCard-종료');
  }

  // 2-1단계: '따닥'에서 카드 선택
  void chooseMatch(GoStopCard chosenCard) {
    logAllCardStates('chooseMatch-시작');
    if (currentPhase != TurnPhase.choosingMatch) return;
    
    logger.addLog(currentPlayer, 'chooseMatch', LogLevel.info, 
      '카드 선택: [36m${chosenCard.id}(${chosenCard.name})[0m'
    );
    
    // 선택한 카드만 먹은 카드로 분류, 선택 안 한 카드는 필드에 남김
    pendingCaptured.add(chosenCard); // 선택한 카드 획득
    deckManager.fieldCards.removeWhere((c) => c.id == chosenCard.id); // 필드에서 제거
    choices.clear();
    
    // 첫 번째 선택 완료 후, 카드더미에서 뒤집은 카드도 2장 매치인지 확인
    if (drawnCard != null) {
      final drawnCardMatches = getField().where((c) => c.month == drawnCard!.month && c.id != drawnCard!.id).toList();
      
      logger.addLog(currentPlayer, 'chooseMatch', LogLevel.info, 
        '두 번째 2장 매치 확인: drawnCard=${drawnCard!.id}(${drawnCard!.name}), matches=${drawnCardMatches.map((c) => '${c.id}(${c.name})').toList()}'
      );
      
      // 뒤집은 카드도 2장 매치라면 두 번째 선택창을 위한 상태 세팅
      if (drawnCardMatches.length == 2) {
        logger.addLog(currentPlayer, 'chooseMatch', LogLevel.info, 
          '두 번째 2장 매치 발견: 두 번째 선택창 세팅'
        );
        
        // 뒤집은 카드와 매치된 필드 2장을 선택지로
        choices = drawnCardMatches;
        // 뒤집은 카드는 무조건 먹음
        pendingCaptured.add(drawnCard!);
        // phase는 choosingMatch로 유지 (두 번째 선택창을 위해)
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
    logAllCardStates('endTurn-시작');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '[DEBUG] 턴 종료 처리 전 상태: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '손패: ' + getHand(currentPlayer).map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '필드: ' + getField().map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '카드더미: ' + deckManager.drawPile.map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '획득: ' + getCaptured(currentPlayer).map((c) => c.id).toList().toString());
    
    final playerIdx = currentPlayer - 1;
    
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
      '턴 종료 시작'
    );
    
    // 턴 상태 초기화
    hadTwoMatch = false;
    
    if (pendingCaptured.isNotEmpty) {
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
        '획득 카드 처리 시작: ${pendingCaptured.map((c) => '${c.id}(${c.name})').toList()}'
      );
      
      // 매치 처리 시점의 필드 카드 위치 정보 로그
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
        '매치 처리 시점 필드 카드: ${deckManager.fieldCards.map((c) => '${c.id}(${c.name})[월${c.month}]').toList()}'
      );
      
      // pendingCaptured에 있는 카드들을 실제로 필드에서 제거
      final cardsToRemove = <GoStopCard>[];
      for (final card in pendingCaptured) {
        final matchingCards = deckManager.fieldCards.where((c) => c.id == card.id).toList();
        cardsToRemove.addAll(matchingCards);
        logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
          '제거할 카드 찾음: ${card.id}(${card.name}) - ${matchingCards.length}개'
        );
      }
      
      for (final card in cardsToRemove) {
        deckManager.fieldCards.remove(card);
        logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
          '카드 제거 완료: ${card.id}(${card.name})'
        );
      }
      
      // capturedCards로 이동 (중복 제거)
      final uniqueCards = <GoStopCard>[];
      final seenIds = <int>{};
      for (final card in pendingCaptured) {
        if (!seenIds.contains(card.id)) {
          uniqueCards.add(card);
          seenIds.add(card.id);
        }
      }
      deckManager.capturedCards[playerIdx] = [...deckManager.capturedCards[playerIdx]!, ...uniqueCards];
      
      logger.logActualProcessing('획득 카드 처리 완료', {
        'uniqueCards': uniqueCards.map((c) => '${c.id}(${c.name})').toList(),
        'totalCaptured': deckManager.capturedCards[playerIdx]?.map((c) => '${c.id}(${c.name})').toList(),
        'remainingField': deckManager.fieldCards.map((c) => '${c.id}(${c.name})').toList(),
      }, currentPlayer, 'turnEnd');
    }
    
    // 보너스피 처리: 뻑이 아니면 먹은 카드로 처리
    if (bonusCard != null) {
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
        '보너스피를 먹은 카드로 처리: ${bonusCard!.id}(${bonusCard!.name})'
      );
      // 보너스피를 먹은 카드에 추가
      pendingCaptured.add(bonusCard!);
      bonusCard = null;
    }
    
    // 상태 초기화
    pendingCaptured.clear();
    playedCard = null;
    drawnCard = null;
    handBonusCard = null;

    if (_checkVictoryCondition()) {
      logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
        '승리 조건 충족: 고/스톱 선택 대기'
      );
      
      awaitingGoStop = true;
      currentPhase = TurnPhase.turnEnd;
      // 턴을 넘기지 않고 '고/스톱' 결정을 기다림
      return;
    }
    
    // 다음 플레이어로 턴 넘김
    final nextPlayer = (currentPlayer % 2) + 1;
    
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, 
      '턴 전환: P$currentPlayer → P$nextPlayer'
    );
    
    currentPlayer = nextPlayer;
    currentPhase = TurnPhase.playingCard;
    logger.incrementTurn();

    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '[DEBUG] 턴 종료 처리 후 상태: 플레이어 $currentPlayer');
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '손패: ' + getHand(currentPlayer).map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '필드: ' + getField().map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '카드더미: ' + deckManager.drawPile.map((c) => c.id).toList().toString());
    logger.addLog(currentPlayer, 'turnEnd', LogLevel.info, '획득: ' + getCaptured(currentPlayer).map((c) => c.id).toList().toString());
    logAllCardStates('endTurn-종료');
  }
  
  bool _checkVictoryCondition() {
    final score = calculateScore(currentPlayer);
    // 맞고는 7점부터
    return score >= 7;
  }

  void declareGo() {
    if (!awaitingGoStop) return;
    goCount++;
    awaitingGoStop = false;
    
    // '고'를 했으므로 턴을 넘기지 않음
    currentPhase = TurnPhase.playingCard;
  }

  void declareStop() {
    if (!awaitingGoStop) return;
    winner = 'player$currentPlayer';
    gameOver = true;
    
    currentPhase = TurnPhase.turnEnd;
  }

  // 기존 로직들 (일부 수정 필요)
  void _stealOpponentPi(int playerIdx) {
    // playerIdx: 피를 가져갈 플레이어(0 또는 1)
    int opponentIdx = 1 - playerIdx;
    final opponentCaptured = deckManager.capturedCards[opponentIdx];
    
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
      pendingCaptured.add(stolen);
      
      logger.logActualProcessing('피 강탈 (일반피)', {
        'stolenCard': '${stolen.id}(${stolen.name})',
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
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
      pendingCaptured.add(stolen);
      
      logger.logActualProcessing('피 강탈 (쌍피)', {
        'stolenCard': '${stolen.id}(${stolen.name})',
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
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
      pendingCaptured.add(stolen);
      
      logger.logActualProcessing('피 강탈 (보너스피)', {
        'stolenCard': '${stolen.id}(${stolen.name})',
        'pendingCaptured': pendingCaptured.map((c) => '${c.id}(${c.name})').toList(),
      }, playerIdx + 1, 'turnEnd');
      
      return;
    }
    
    logger.addLog(playerIdx + 1, 'turnEnd', LogLevel.warning, 
      '피 강탈 실패: 강탈할 피가 없음'
    );
  }
  
  int calculateScore(int playerNum) {
    final captured = [...getCaptured(playerNum), ...pendingCaptured.where((c) => playerNum == currentPlayer)];
    
    logger.logScoreCalculation(captured, goCount, playerNum);
    
    if (captured.isEmpty) {
      logger.addLog(playerNum, 'turnEnd', LogLevel.info, 
        '점수 계산: 획득 카드 없음 → 0점'
      );
      return 0;
    }
    int baseScore = 0;
    // 광 점수 계산
    final gwangCards = captured.where((c) => c.type == '광').toList();
    final hasRainGwang = gwangCards.any((c) => c.month == 11); // 비광(11월 광) 포함 여부
    if (gwangCards.length == 3) {
      if (hasRainGwang) {
        baseScore += 2; // 비광 포함 3광
      } else {
        baseScore += 3; // 비광 없는 3광
      }
    } else if (gwangCards.length == 4) {
      baseScore += 4;
    } else if (gwangCards.length >= 5) {
      baseScore += 15;
    }
    // 띠 점수 계산
    final ttiCards = captured.where((c) => c.type == '띠').toList();
    if (ttiCards.length >= 5) {
      baseScore += ttiCards.length - 4; // 5띠=1점, 6띠=2점, 7띠=3점
    }
    // 피 점수 계산 (고스톱 규칙에 맞게)
    final piCards = captured.where((c) => c.type == '피').toList();
    int totalPi = 0;
    for (final c in piCards) {
      final img = c.imageUrl;
      if (img.contains('bonus_3pi')) {
        totalPi += 3; // 보너스 쓰리피
      } else if (img.contains('bonus_ssangpi')) {
        totalPi += 2; // 보너스 쌍피
      } else if (img.contains('3pi')) {
        totalPi += 3; // 쓰리피
      } else if (img.contains('ssangpi')) {
        totalPi += 2; // 쌍피
      } else {
        totalPi += 1; // 일반 피
      }
    }
    if (totalPi >= 10) {
      baseScore += (totalPi - 9);
    }
    // 오 점수 계산
    final ohCards = captured.where((c) => c.type == '오').toList();
    if (ohCards.length >= 2) {
      baseScore += ohCards.length - 1; // 2오=1점, 3오=2점, 4오=3점
    }
    // 고스톱 보너스 적용
    int totalScore = baseScore;
    if (goCount == 1) {
      totalScore += 1;
    } else if (goCount == 2) {
      totalScore += 2;
    } else if (goCount >= 3) {
      totalScore = (baseScore + 2) * (1 << (goCount - 2));
    }
    
    logger.logActualProcessing('점수 계산 완료', {
      'baseScore': baseScore,
      'totalScore': totalScore,
      'goCount': goCount,
    }, playerNum, 'turnEnd');
    
    return totalScore;
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
}