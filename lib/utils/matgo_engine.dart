import 'dart:math';
import '../models/card_model.dart';
import 'event_evaluator.dart';
import 'deck_manager.dart';

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

enum SpecialEvent { bomb, shake, chok, ddak, sseul, chongtong }

class MatgoEngine {
  final DeckManager deckManager;
  int currentPlayer = 1;
  int goCount = 0;
  String? winner;
  bool gameOver = false;
  final EventEvaluator eventEvaluator = EventEvaluator();
  bool awaitingGoStop = false;

  // 턴 진행 관련 상태
  TurnPhase currentPhase = TurnPhase.playingCard;
  GoStopCard? playedCard; // 이번 턴에 낸 카드
  List<GoStopCard> pendingCaptured = []; // 이번 턴에 획득할 예정인 카드들
  List<GoStopCard> choices = []; // 따닥 발생 시 선택할 카드들
  GoStopCard? drawnCard; // 뒤집은 카드 (따닥 상황에서 사용)

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
  }

  List<GoStopCard> getHand(int playerNum) => deckManager.getPlayerHand(playerNum - 1);
  List<GoStopCard> getField() => deckManager.getFieldCards();
  List<GoStopCard> getCaptured(int playerNum) => deckManager.capturedCards[playerNum - 1] ?? [];
  int get drawPileCount => deckManager.drawPile.length;

  // 1단계: 플레이어가 손에서 카드를 냄
  void playCard(GoStopCard card, {int? groupIndex}) {
    print('[playCard] 진입: currentPlayer=$currentPlayer, currentPhase=$currentPhase, card=${card.id}, name=${card.name}');
    print('[playCard] playerHands[0] (플레이어): ${deckManager.playerHands[0]?.map((c) => c.id).toList()}');
    print('[playCard] playerHands[1] (AI): ${deckManager.playerHands[1]?.map((c) => c.id).toList()}');
    print('[playCard] fieldCards: ${deckManager.fieldCards.map((c) => c.id).toList()}');
    print('[playCard] capturedCards[0]: ${deckManager.capturedCards[0]?.map((c) => c.id).toList()}');
    print('[playCard] capturedCards[1]: ${deckManager.capturedCards[1]?.map((c) => c.id).toList()}');
    if (currentPhase != TurnPhase.playingCard) return;

    final playerIdx = currentPlayer - 1;
    // 애니메이션 완료 후에 손패에서 제거되므로 여기서는 제거하지 않음
    // deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == card.id);
    playedCard = card;
    print('[playCard] playedCard: ${playedCard?.id}, name=${playedCard?.name}');

    // 보너스카드(쌍피 등) 낼 때 바로 먹은 카드로 이동
    if (card.isBonus) {
      pendingCaptured.add(card);
      _triggerAnimation(AnimationEventType.bonusCard, {
        'card': card,
        'player': currentPlayer,
      });
      currentPhase = TurnPhase.flippingCard;
      print('[playCard] 보너스카드 처리: pendingCaptured=${pendingCaptured.map((c) => c.id).toList()}');
      return;
    }

    final fieldMatches = getField().where((c) => c.month == card.month).toList();
    print('[playCard] fieldMatches: ${fieldMatches.map((c) => c.id).toList()}');
    
    // 먹을 카드가 있으면 임시 목록에 추가 (하지만 필드에서 제거하지 않음)
    if (fieldMatches.length == 1) {
      print('[playCard] 1장 매치: card=${card.id}(${card.name}), matchCard=${fieldMatches.first.id}(${fieldMatches.first.name})');
      pendingCaptured.addAll([card, fieldMatches.first]);
      // 내가 낸 카드도 필드에 추가하여 시각적으로 겹침 상태 표시
      deckManager.fieldCards.add(card);
      print('[playCard] pendingCaptured 추가 후: ${pendingCaptured.map((c) => '${c.id}(${c.name})').toList()}');
      print('[playCard] fieldCards 추가 후: ${deckManager.fieldCards.map((c) => '${c.id}(${c.name})').toList()}');
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
    } else if (fieldMatches.length == 2) {
      deckManager.fieldCards.add(card);
      print('[playCard] 2장 매치: fieldCards=${deckManager.fieldCards.map((c) => c.id).toList()}');
    } else if (fieldMatches.length == 3) {
      pendingCaptured.addAll([card, ...fieldMatches]);
      // 내가 낸 카드도 필드에 추가하여 시각적으로 겹침 상태 표시
      deckManager.fieldCards.add(card);
      // 카드가 사라지지 않도록 필드에서 제거하지 않고, 시각적으로만 겹침 상태 표시
      print('[playCard] 3장 매치: pendingCaptured=${pendingCaptured.map((c) => c.id).toList()}');
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
    } else {
      // 먹을 카드가 없으면 groupIndex 위치에 카드 추가
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
      } else {
        deckManager.fieldCards.add(card);
      }
    }

    currentPhase = TurnPhase.flippingCard;
    print('[playCard] 종료: currentPlayer=$currentPlayer, currentPhase=$currentPhase, playerHands[0]=${deckManager.playerHands[0]?.map((c) => c.id).toList()}, playerHands[1]=${deckManager.playerHands[1]?.map((c) => c.id).toList()}, fieldCards=${deckManager.fieldCards.map((c) => c.id).toList()}, capturedCards[0]=${deckManager.capturedCards[0]?.map((c) => c.id).toList()}, capturedCards[1]=${deckManager.capturedCards[1]?.map((c) => c.id).toList()}');
  }
  
  // 2단계: 카드 더미에서 카드를 뒤집음
  void flipFromDeck() {
    if (currentPhase != TurnPhase.flippingCard) return;
    if (deckManager.drawPile.isEmpty) {
      _endTurn();
      return;
    }

    GoStopCard drawnCard = deckManager.drawPile.removeAt(0);

    // 카드 뒤집기 애니메이션 트리거 (임시 비활성화)
    // _triggerAnimation(AnimationEventType.cardFlip, {
    //   'card': drawnCard,
    //   'from': 'deck',
    // });

    // 보너스 카드 처리
    if (drawnCard.isBonus) {
        pendingCaptured.add(drawnCard);
        
        // 보너스 카드 특수 효과 (임시 비활성화)
        // _triggerAnimation(AnimationEventType.bonusCard, {
        //   'card': drawnCard,
        //   'player': currentPlayer,
        // });
        
        // 보너스 카드를 뒤집었으면 한 장 더 뒤집음
        flipFromDeck(); 
        return;
    }
    
    final fieldMatches = getField().where((c) => c.month == drawnCard.month).toList();

    // 뻑 (Ppeok) 체크
    if (playedCard != null && playedCard!.month == drawnCard.month && getField().any((c) => c.month == drawnCard.month)) {
      deckManager.fieldCards.add(drawnCard);
      // 먹으려던 카드들도 다시 바닥으로
      if (pendingCaptured.isNotEmpty) {
        deckManager.fieldCards.addAll(pendingCaptured);
        pendingCaptured.clear();
      }
      
      // 뻑 특수 효과 (임시 비활성화)
      // _triggerAnimation(AnimationEventType.specialEffect, {
      //   'effect': 'ppeok',
      //   'card': drawnCard,
      //   'player': currentPlayer,
      // });
      
       _endTurn();
       return;
    }
    
    // 따닥 (Choice)
    if (fieldMatches.length == 2) {
      choices = fieldMatches;
      pendingCaptured.add(drawnCard);
      this.drawnCard = drawnCard; // 뒤집은 카드 저장
      
      // 따닥 특수 효과 (임시 비활성화)
      // _triggerAnimation(AnimationEventType.specialEffect, {
      //   'effect': 'ttak',
      //   'card': drawnCard,
      //   'choices': fieldMatches,
      //   'player': currentPlayer,
      // });
      
      currentPhase = TurnPhase.choosingMatch;
      return;
    }

    // 일반 먹기
    if (fieldMatches.length == 1) {
      print('[flipFromDeck] 일반 먹기: drawnCard=${drawnCard.id}(${drawnCard.name}), matchCard=${fieldMatches.first.id}(${fieldMatches.first.name})');
      
      // 뒤집은 카드와 매치된 카드 추가 (중복 방지)
      if (!pendingCaptured.any((c) => c.id == drawnCard.id)) {
        pendingCaptured.add(drawnCard);
      }
      if (!pendingCaptured.any((c) => c.id == fieldMatches.first.id)) {
        pendingCaptured.add(fieldMatches.first);
      }
      
      // 뒤집은 카드도 필드에 추가하여 시각적으로 겹침 상태 표시
      deckManager.fieldCards.add(drawnCard);
      print('[flipFromDeck] pendingCaptured 추가 후: ${pendingCaptured.map((c) => '${c.id}(${c.name})').toList()}');
      print('[flipFromDeck] fieldCards 추가 후: ${deckManager.fieldCards.map((c) => '${c.id}(${c.name})').toList()}');
      
      // 카드 획득 애니메이션 (임시 비활성화)
      // _triggerAnimation(AnimationEventType.cardCapture, {
      //   'cards': [drawnCard, fieldMatches.first],
      //   'player': currentPlayer,
      // });
    } else {
      // 못 먹는 경우
      print('[flipFromDeck] 못 먹는 경우: drawnCard=${drawnCard.id}(${drawnCard.name})');
      deckManager.fieldCards.add(drawnCard);
      
      // 카드 이동 애니메이션 (더미에서 필드로) (임시 비활성화)
      // _triggerAnimation(AnimationEventType.cardMove, {
      //   'card': drawnCard,
      //   'from': 'deck',
      //   'to': 'field',
      // });
    }

    _endTurn();
  }

  // 2-1단계: '따닥'에서 카드 선택
  void chooseMatch(GoStopCard chosenCard) {
    if (currentPhase != TurnPhase.choosingMatch) return;
    final otherCard = choices.firstWhere((c) => c.id != chosenCard.id);
    // drawnCard(뒤집은 카드)는 이미 pendingCaptured에 있음, 필드에는 추가하지 않음
    pendingCaptured.add(chosenCard); // 선택한 카드 획득
    // 뒤집은 카드도 필드에 추가하여 시각적으로 겹침 상태 표시
    if (drawnCard != null) {
      deckManager.fieldCards.add(drawnCard!);
    }
    // 카드가 사라지지 않도록 필드에서 제거하지 않고, 시각적으로만 겹침 상태 표시
    // 선택하지 않은 카드는 필드에 그대로 둠 (정상)
    // drawnCard가 필드에 남지 않도록 보장
    choices.clear();
    _endTurn();
  }

  // 3단계: 턴 종료 및 정산
  void _endTurn() {
    final playerIdx = currentPlayer - 1;
    if (pendingCaptured.isNotEmpty) {
      print('[_endTurn] pendingCaptured 처리 시작: ${pendingCaptured.map((c) => '${c.id}(${c.name})').toList()}');
      print('[_endTurn] 처리 전 fieldCards: ${deckManager.fieldCards.map((c) => '${c.id}(${c.name})').toList()}');
      
      // pendingCaptured에 있는 카드들을 실제로 필드에서 제거
      final cardsToRemove = <GoStopCard>[];
      for (final card in pendingCaptured) {
        final matchingCards = deckManager.fieldCards.where((c) => c.id == card.id).toList();
        cardsToRemove.addAll(matchingCards);
        print('[_endTurn] 제거할 카드 찾음: id=${card.id}, name=${card.name}, found=${matchingCards.length}개');
      }
      
      for (final card in cardsToRemove) {
        deckManager.fieldCards.remove(card);
        print('[_endTurn] 카드 제거 완료: id=${card.id}, name=${card.name}');
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
      print('[_endTurn] 처리 후 fieldCards: ${deckManager.fieldCards.map((c) => '${c.id}(${c.name})').toList()}');
      print('[_endTurn] capturedCards[$playerIdx]: ${deckManager.capturedCards[playerIdx]?.map((c) => '${c.id}(${c.name})').toList()}');
    }
    
    // 상태 초기화
    pendingCaptured.clear();
    playedCard = null;
    drawnCard = null;

    if (_checkVictoryCondition()) {
      awaitingGoStop = true;
      currentPhase = TurnPhase.turnEnd;
      // 턴을 넘기지 않고 '고/스톱' 결정을 기다림
      return;
    }
    
    // 다음 플레이어로 턴 넘김
    currentPlayer = (currentPlayer % 2) + 1;
    currentPhase = TurnPhase.playingCard;
  }
  
  bool _checkVictoryCondition() {
    final score = calculateScore(currentPlayer);
    // 맞고는 3점부터
    return score >= 3; 
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
    // ... 이 로직은 pendingCaptured에 추가하는 방식으로 수정되어야 함
  }
  
  int calculateScore(int playerNum) {
    final captured = getCaptured(playerNum);
    if (captured.isEmpty) return 0;
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
    // 피 점수 계산
    final piCards = captured.where((c) => c.type == '피').toList();
    if (piCards.length >= 10) {
      baseScore += piCards.length - 9; // 10피=1점, 11피=2점, 12피=3점
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

  // Special 이벤트 처리
  Future<List<SpecialEvent>> _resolveSpecials() async {
    final events = <SpecialEvent>[];
    // 폭탄: 피 1 스틸 + 흔들기 + scoreMultiplier ×2
    // 흔들기: 손패 3동월 → UI 선택
    // 쪽/따닥/쓸: 상대 피 1 스틸(+전멸 시 모든 상대)
    // 총통: 핸드 4동월 → 7 점 또는 계속 / 필드 4동월 → 나가리, 다음 판 2×
    // (실제 구현은 이후 단계에서 추가)
    return events;
  }

  // ... 기타 헬퍼 메서드들
}