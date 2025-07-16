import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/matgo_engine.dart';
import '../models/card_model.dart';
import '../screens/gostop_board.dart';
import '../utils/deck_manager.dart';
import '../widgets/card_deck_widget.dart';
import '../animations.dart';
import '../widgets/particle_system.dart';
import '../utils/animation_pool.dart';
import '../widgets/game_log_viewer.dart';
import 'dart:async';
import '../utils/sound_manager.dart';
import '../widgets/bgm_toggle_button.dart';
import '../widgets/score_board.dart';
import '../widgets/heundal_selection_dialog.dart';
import '../widgets/go_animation_widget.dart';
import '../widgets/go_selection_dialog.dart';
import '../utils/coin_service.dart';
import '../widgets/coin_box.dart';
import '../widgets/language_selector.dart';
import '../screens/settings_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/settings_dialog.dart';
import 'dart:math';
import '../providers/locale_provider.dart';
import '../widgets/floating_text_effect.dart';

class GamePage extends StatefulWidget {
  final String mode;
  const GamePage({required this.mode, super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late MatgoEngine engine;
  late DeckManager deckManager;
  final GlobalKey<GoStopBoardState> boardKey = GlobalKey<GoStopBoardState>();
  final CardDeckController cardDeckController = CardDeckController();

  // 애니메이션 상태 관리
  List<Widget> activeAnimations = [];
  bool isAnimating = false;
  // 최근 플레이된 카드 위치(id -> Offset). 필드에 Key가 아직 없을 때 사용
  final Map<int, Offset> _recentCardPositions = {};
  
  // 애니메이션 풀
  final AnimationPool animationPool = AnimationPool();
  
  // 긴장감 모드
  bool isTensionMode = false;

  // 뻑 이펙트 테스트 상태


  // 필드 카드별 GlobalKey 관리
  final Map<String, GlobalKey> fieldCardKeys = {};
  
  // 로그 뷰어 상태
  bool showLogViewer = false;

  // 1. 필드 Stack의 GlobalKey 선언
  final GlobalKey fieldStackKey = GlobalKey();

  int? _lastPlayedCardId; // 최근 손에서 낸 카드 id (중복 애니메이션 방지)

  // 턴 종료 후 확정된 점수만 표시하기 위한 상태 변수
  int _displayPlayerScore = 0;
  int _displayOpponentScore = 0;
  
  // 즉시 점수 업데이트 및 GO/STOP 조건 확인을 위한 메서드
  void _updateScoresAndCheckGoStop() {
    setState(() {
      _displayPlayerScore = engine.calculateBaseScore(1);
      _displayOpponentScore = engine.calculateBaseScore(2);
    });
    
    // 점수 표시만 갱신하고, GO/STOP 여부는 엔진에서 결정한 awaitingGoStop 값만 신뢰한다.
  }

  @override
  void initState() {
    super.initState();
    deckManager = DeckManager(
      playerCount: widget.mode == 'matgo' ? 2 : 3,
      isMatgo: widget.mode == 'matgo',
    );
    engine = MatgoEngine(deckManager);
    
    // 애니메이션 이벤트 리스너 설정
    engine.setAnimationListener(_handleAnimationEvent);
    
    // 턴 종료 후 UI 업데이트 콜백 설정
    engine.onTurnEnd = () async {
      // ── 점수 및 GO/STOP 상태 즉시 반영 ──
      _updateScoresAndCheckGoStop();
      // ── 실시간 박 상태 체크 (광박/피박/멍박) ──
      engine.checkBakConditions();
      
      // ── 플레이어(나) 7점 이상 달성 → 즉시 GO/STOP 다이얼로그 표시 ──
      if (engine.awaitingGoStop && engine.currentPlayer == 1) {
        // 이미 다른 다이얼로그가 떠 있지 않을 때만 실행
        _showGoStopSelectionDialog().then((isGo) async {
          if (isGo == true) {
            // 게임 상태를 먼저 업데이트한 후, GO 애니메이션 실행
            setState(() => engine.declareGo());
            await _showGoAnimation(engine.goCount); // 증가된 goCount 반영
            _runAiTurnIfNeeded();
          } else if (isGo == false) {
            setState(() => engine.declareStop());
            _showGameOverDialog();
          }
        });
        return; // 다이얼로그 뜨면 AI 턴 대기
      }
      
      // ── AI 7점 이상 달성 시 자동 GO/STOP 결정 ──
      if (engine.awaitingGoStop && engine.currentPlayer == 2) {
        final int aiScore = engine.calculateBaseScore(2);
        final int playerScore = engine.calculateBaseScore(1);
        bool aiWillGo;
        // 간단 로직: 10점 미만이거나 플레이어보다 점수 차가 3점 이하이면 GO, 아니면 STOP
        if (aiScore < 10 && (aiScore - playerScore) <= 3) {
          aiWillGo = true;
        } else {
          aiWillGo = false;
        }

        if (aiWillGo) {
          setState(() => engine.declareGo());
          await _showGoAnimation(engine.goCount);
        } else {
          setState(() => engine.declareStop());
          _showGameOverDialog();
        }
        // AI 턴이 끝나면 onTurnEnd 콜백에서 자동으로 다음 턴 처리됨
      }
      
      // ── GO/STOP 대기 상태가 아닐 때만 AI 턴 시작 ──
      if (engine.currentPlayer == 2 && !engine.isGameOver() && !engine.awaitingGoStop) {
        // 추가 안전장치: 점수 재확인
        final int pScore = engine.calculateBaseScore(1);
        final int aiScore = engine.calculateBaseScore(2);
        if (pScore < 7 && aiScore < 7) {
          _runAiTurnIfNeeded();
        }
      }
    };
    
    _runAiTurnIfNeeded();
  }


  // 애니메이션 헬퍼: 애니메이션 완료 후 로직 실행
  Future<void> runAndAwait(Future<void> anim) async {
    await anim;
  }

  // 애니메이션 이벤트 처리
  void _handleAnimationEvent(AnimationEvent event) async {
    switch (event.type) {
      case AnimationEventType.cardFlip:
        _handleCardFlip(event.data);
        break;
      case AnimationEventType.cardMove:
        // 겹침(사선) 연출: 여러 장이면 x, y축 어긋나게
        final cards = event.data['cards'] as List<GoStopCard>;
        final from = event.data['from'] as String;
        final to = event.data['to'] as String;
        final player = event.data['player'] as int;
        final fieldOffset = _getCardPosition('field', cards.first);
        for (int i = 0; i < cards.length; i++) {
          // 카드가 현재 필드에 존재하면 필드에서 출발, 아니면 hand/ai_hand
          final bool inField = engine.getField().any((c) => c.id == cards[i].id);
          final String originArea = inField
              ? 'field'
              : (player == 1 ? 'hand' : 'ai_hand');
          final Offset startOffset = _getCardPosition(originArea, cards[i]);

          if (originArea == 'field') {
            // 이미 필드에 있던 카드는 위치 고정 (애니메이션 생략)
            continue;
          }

          // 한 프레임 뒤에 목적지·시작 좌표를 계산하여 레이아웃 완료 이후 정확한 위치로 이동
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 실제 필드 카드 위치(시작)
            final Offset refreshedStart = _getCardPosition(originArea, cards[i]);
            // 도착 좌표 (겹침 위치)
            final Offset refreshedFieldOffset = _getCardPosition('field', cards[i]);
            final double rdx = refreshedFieldOffset.dx + i * 18.0;
            final double rdy = refreshedFieldOffset.dy + i * 8.0;

            // 필드 카드 원본 이미지 제거(중복 방지)
            if (originArea == 'field') {
              engine.deckManager.fieldCards.removeWhere((c) => c.id == cards[i].id);
            }

            setState(() {
              isAnimating = true;
              activeAnimations.add(
                CardMoveAnimation(
                  cardImage: cards[i].imageUrl,
                  startPosition: refreshedStart,
                  endPosition: Offset(rdx, rdy),
                  onComplete: () {
                    setState(() {
                      activeAnimations.removeWhere((anim) => anim is CardMoveAnimation);
                      final bool noActive = activeAnimations.isEmpty;
                      if (noActive) {
                        isAnimating = false;
                      }
                    });
                  },
                  duration: const Duration(milliseconds: 400),
                  withTrail: false,
                ),
              );
            });
          });
        }
        break;
      case AnimationEventType.cardCapture:
        // 카드들을 순서대로 획득 영역으로 이동하는 애니메이션
        final cards = event.data['cards'] as List<GoStopCard>;
        final player = event.data['player'] as int;
        _playCardCaptureAnimation(cards, player);
        break;
      case AnimationEventType.specialEffect:
      case AnimationEventType.ppeok:
      case AnimationEventType.piSteal:
      case AnimationEventType.sseul:
        _handleSpecialEffect(event.data);
        break;
      case AnimationEventType.bomb:
        _handleBombAnimation(event.data);
        break;
      case AnimationEventType.bonusCard:
        _handleBonusCardAnimation(event.data);
        break;
    }
  }

  void _handleCardFlip(Map<String, dynamic> data) {
    final card = data['card'] as GoStopCard;
    final from = data['from'] as String;
    
    setState(() {
      isAnimating = true;
      activeAnimations.add(
        animationPool.getCardFlipAnimation(
          backImage: 'assets/cards/back.png',
          frontImage: card.imageUrl,
          onComplete: () {
            setState(() {
              activeAnimations.removeWhere((anim) => anim is CardFlipAnimation);
              if (activeAnimations.isEmpty) {
                isAnimating = false;
              }
            });
          },
        ),
      );
    });
  }

  void _handleSpecialEffect(Map<String, dynamic> data) {
    final effect = data['effect'] as String? ?? 'unknown';
    final GoStopCard? anchorCard = data['anchorCard'] as GoStopCard?;

    // 텍스트 매핑
    final Map<String, String> textMap = {
      'ppeok': '뻑!',
      'ppeokFinish': '오예!',
      'bomb': '폭탄!',
      'chok': '쪽!',
      'ttak': '따닥!',
      'sseul': '쓸!',
    };

    final displayText = textMap[effect] ?? effect;

    // 위치 계산
    Offset pos;
    final Size screenSize = MediaQuery.of(context).size;
    final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    // 필드 카드 비율(손패 카드의 80%)과 동일한 값 사용
    final double cardWidth = minSide * 0.13 * 0.8; // 약 10.4% 비율
    const double gap = 8.0; // 카드와 텍스트 간 간격

    if (effect == 'sseul') {
      // 카드더미 기준 위치 → 오른쪽으로 이동 후 살짝 위로 보정
      final Offset deckPos = _getCardPosition('deck', anchorCard ?? GoStopCard.bomb());
      pos = deckPos.translate(cardWidth + gap, -10);
    } else if (anchorCard != null) {
      // 앵커 카드 기준 위치 → 오른쪽으로 이동 후 살짝 위로 보정
      final Offset cardPos = _getCardPosition('field', anchorCard);
      pos = cardPos.translate(cardWidth + gap, -10);
    } else {
      // 화면 중앙 fallback
      pos = Offset(screenSize.width / 2, screenSize.height / 2);
    }

    setState(() {
      activeAnimations.add(
        FloatingTextEffect(
          text: displayText,
          position: pos,
          onComplete: () {
            setState(() {
              activeAnimations.removeWhere((w) => w is FloatingTextEffect && (w as FloatingTextEffect).text == displayText);
            });
          },
        ),
      );
    });
  }

  // 폭탄 애니메이션 처리: 손패의 3장을 한장씩 필드로 이동하면서 실시간 매치 처리
  void _handleBombAnimation(Map<String, dynamic> data) async {
    final handCards = data['handCards'] as List<GoStopCard>;
    final fieldCards = data['fieldCards'] as List<GoStopCard>;
    final player = data['player'] as int;
    final bombMonth = data['bombMonth'] as int;
    final onComplete = data['onComplete'] as Function();
    
    // 폭탄 효과음 재생
    SoundManager.instance.play(Sfx.bonusCard);
    
    // 손패의 3장을 한장씩 순차적으로 필드로 이동하면서 실시간 매치 처리
    for (int i = 0; i < handCards.length; i++) {
      final card = handCards[i];
      
      // 손패에서 카드 위치 계산
      final fromOffset = _getCardPosition('hand', card);
      
      // 필드 겹침 위치 계산 (기존 필드 카드 위에 겹치도록)
      final fieldCard = fieldCards.isNotEmpty ? fieldCards.first : null;
      Offset toOffset;
      if (fieldCard != null) {
        toOffset = _getCardPosition('field', fieldCard);
        // 겹침 효과를 위해 약간의 오프셋 추가
        toOffset = Offset(toOffset.dx + i * 8.0, toOffset.dy + i * 4.0);
      } else {
        toOffset = _getCardPosition('field', card);
      }
      
      // 카드 이동 애니메이션 시작
      await Future.delayed(Duration(milliseconds: 200 * i)); // 순차 애니메이션
      
      // 실제 카드가 필드로 이동하는 애니메이션 (손패에서 제거하지 않고 이동)
      setState(() {
        isAnimating = true;
        activeAnimations.add(
          CardPlayAnimation(
            cardImage: card.imageUrl,
            startPosition: fromOffset,
            endPosition: toOffset,
            onComplete: () {
              // 애니메이션 완료 후 손패에서 카드 제거
              final playerIdx = player - 1;
              engine.deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == card.id);
              
              // 실시간 매치 처리: 현재 카드가 필드에 추가된 후 매치 확인
              engine.deckManager.fieldCards.add(card);
              
              // 현재 필드에서 같은 월의 카드들과 매치 확인
              final matchingCards = engine.deckManager.fieldCards
                  .where((c) => c.month == card.month && c.id != card.id)
                  .toList();
              
              if (matchingCards.isNotEmpty) {
                // 매치 발견: 매치된 카드들을 획득 영역으로 이동
                final allMatchedCards = [card, ...matchingCards];
                
                // 매치된 카드들을 pendingCaptured에 추가
                engine.pendingCaptured.addAll(allMatchedCards);
                
                // 필드에서 매치된 카드들 제거
                engine.deckManager.fieldCards.removeWhere((c) => 
                    allMatchedCards.any((matched) => matched.id == c.id));
                
                // 매치 애니메이션 직접 처리: 획득 영역으로 이동
                for (final matchedCard in allMatchedCards) {
                  final captureOffset = _getCardPosition('captured', matchedCard, playerId: player);
                  setState(() {
                    activeAnimations.add(
                      CardMoveAnimation(
                        cardImage: matchedCard.imageUrl,
                        startPosition: toOffset, // 현재 필드 위치에서 시작
                        endPosition: captureOffset,
                        onComplete: () {
                          setState(() {
                            activeAnimations.removeWhere((anim) => anim is CardMoveAnimation);
                            if (activeAnimations.isEmpty) {
                              isAnimating = false;
                            }
                          });
                        },
                        duration: const Duration(milliseconds: 500),
                        withTrail: true,
                      ),
                    );
                  });
                }
                
                // 매치 효과음 재생
                SoundManager.instance.play(Sfx.cardOverlap);
              }
              
              setState(() {
                activeAnimations.removeWhere((anim) => anim is CardPlayAnimation);
                if (activeAnimations.isEmpty) {
                  isAnimating = false;
                }
              });
            },
            duration: const Duration(milliseconds: 600),
          ),
        );
      });
    }
    
    // 모든 애니메이션 완료 후 콜백 실행
    await Future.delayed(Duration(milliseconds: 200 * handCards.length + 600));
    onComplete();
  }

  // 긴장감 모드 시작
  void _startTensionMode() {
    setState(() {
      isTensionMode = true;
    });
  }

  // 긴장감 모드 종료
  void _stopTensionMode() {
    setState(() {
      isTensionMode = false;
    });
  }

  // 필드에 카드가 놓일 빈 자리(그룹) 위치를 계산하는 헬퍼 함수 (원형 배치에 맞게 수정)
  Offset _getEmptyFieldGroupPosition(int groupIndex) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 원형 배치: 가로와 세로 반지름을 동일하게 설정
    final radius = (size.width < size.height 
      ? size.width * 0.35  // 세로가 긴 경우 가로 기준
      : size.height * 0.35); // 가로가 긴 경우 세로 기준
    
    final angle = (groupIndex / 12) * 2 * pi - pi / 2; // 12시 방향부터 시작
    
    // 원형 배치 좌표 계산
    final x = centerX + radius * cos(angle) - 24; // 카드 너비의 절반만큼 조정
    final y = centerY + radius * sin(angle) - 36; // 카드 높이의 절반만큼 조정
    
    return Offset(x, y);
  }

  // 1단계: 손패 카드 탭 처리
  Future<void> onCardTap(GoStopCard card) async {
    // 입력 락 체크
    if (engine.tapLock) return;
    engine.tapLock = true;
    
    if (isAnimating) return;
    if (engine.currentPlayer != 1 || engine.currentPhase != TurnPhase.playingCard) {
      engine.tapLock = false; // 락 해제
      return;
    }

    // 폭탄 조건: 손패 3장+필드 1장 이상이면 engine에서 자동 폭탄 처리
    final hand = engine.getHand(1);
    final sameMonthCards = hand.where((c) => c.month == card.month).toList();
    final field = engine.getField();
    final fieldSameMonth = field.where((c) => c.month == card.month).toList();
    if (sameMonthCards.length >= 3 && fieldSameMonth.isNotEmpty) {
      // engine에서 폭탄 애니메이션과 함께 처리
      setState(() {
        engine.playCard(card, groupIndex: null);
      });
      engine.tapLock = false;
      return;
    }

    // 흔들 조건 체크
    if (engine.shouldShowHeundalDialog(card, 1)) {
      final heundalCards = engine.getHeundalCards(card, 1);
      final bool? heundalChoice = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => HeundalSelectionDialog(
          heundalCards: heundalCards,
          selectedCard: card,
          onHeundalChoice: (bool choice) {
            Navigator.of(context).pop(choice);
          },
        ),
      );
      
      if (heundalChoice == null) {
        engine.tapLock = false;
        return;
      }
      
      if (heundalChoice) {
        // 흔들 선언
        engine.declareHeundal(1);
      }
    }
    
    // 손패에서 실제 카드 위치 계산 (제거 전에 GlobalKey로 위치 계산)
    Offset fromOffset;
    final playerHandList = engine.getHand(1);
    final cardIdx = playerHandList.indexWhere((c) => c.id == card.id);
    final GlobalKey? cardKey = boardKey.currentState?.getHandCardKey(cardIdx);
    if (cardKey != null && cardKey.currentContext != null) {
      final RenderBox box = cardKey.currentContext!.findRenderObject() as RenderBox;
      fromOffset = box.localToGlobal(Offset.zero);
    } else {
      // fallback
      fromOffset = _getCardPosition('hand', card);
    }
    
    // 최근 플레이한 카드 id 기록 (중복 애니메이션 방지)
    _lastPlayedCardId = card.id;
    
    // 실제 카드가 이동하는 것처럼 보이도록 즉시 손패에서 제거
    final playerIdx = engine.currentPlayer - 1;
    engine.deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == card.id);
    setState(() {}); // UI 즉시 업데이트
    
    // 보너스피는 필드를 거치지 않고 바로 획득 영역으로 이동
    GoStopCard? matchCard;
    Offset destinationOffset;
    if (card.isBonus) {
      destinationOffset = _getCardPosition('captured', card, playerId: 1);
    } else {
      // 매치 카드의 실제 위치 계산 (GlobalKey 사용 - 하나의 기준 좌표계)
      for (final c in engine.getField()) {
        if (c.month == card.month && !c.isBonus) {
          matchCard = c;
          break;
        }
      }
      if (matchCard != null) {
        final key = fieldCardKeys[matchCard.id.toString()];
        if (key is GlobalKey && key.currentContext != null) {
          final RenderBox cardBox = key.currentContext!.findRenderObject() as RenderBox;
          final baseOffset = cardBox.localToGlobal(Offset.zero);
          // 캡처 애니메이션을 위해 기존 필드 카드 위치 캐시
          _recentCardPositions[matchCard.id] = baseOffset;
          // ========= 보드의 카드 크기 / 겹침 오프셋과 동일 공식 =========
          final Size screenSize = MediaQuery.of(context).size;
          final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
          final double handCardWidth = minSide * 0.13;
          final double fieldCardWidth = handCardWidth * 0.8;
          final double fieldCardHeight = fieldCardWidth * 1.5;
          final double overlapOffsetX = fieldCardWidth * 0.375; // 보드와 동일 비율
          final double overlapOffsetY = fieldCardHeight * 0.111;

          // 같은 월 카드들 중 현재 필드에서 가장 위(=가장 겹침이 많이 된) 카드의 위치를 찾는다.
          Offset topMostOffset = baseOffset;
          int maxLayer = -1;
          for (final fc in engine.getField()) {
            if (fc.month != card.month || fc.isBonus) continue;
            final GlobalKey? fk = fieldCardKeys[fc.id.toString()] as GlobalKey?;
            if (fk != null && fk.currentContext != null) {
              final RenderBox fb = fk.currentContext!.findRenderObject() as RenderBox;
              final Offset off = fb.localToGlobal(Offset.zero);
              // 레이어는 x(또는 y) 증가량 / overlap 으로 계산 가능
              final int layer = ((off.dx - baseOffset.dx) / overlapOffsetX).round();
              if (layer > maxLayer) {
                maxLayer = layer;
                topMostOffset = off;
              }
            }
          }

          // 새 카드는 topMostOffset 바로 위 레이어에 놓인다.
          destinationOffset = topMostOffset.translate(overlapOffsetX, overlapOffsetY);
        } else {
          destinationOffset = _getCardPosition('field', card);
        }
      } else {
        destinationOffset = _getCardPosition('field', card);
      }
    }

    // 매치 애니메이션에서 정확한 시작 좌표를 위해 미리 저장
    _recentCardPositions[card.id] = destinationOffset;

    final completer = Completer<void>();
    _playCardWithAnimation(card, fromOffset, destinationOffset, () async {
      // 애니메이션 완료 = 겹침 연출 완료 (하나의 연속된 동작)
      setState(() {
        engine.playCard(card, groupIndex: null);
      });
      
      // 보너스피를 낸 경우 턴이 계속되므로 카드더미 뒤집기 생략
      if (card.isBonus) {
        completer.complete();
        return;
      }
      
      // 따닥(choosingMatch) : 애니메이션이 모두 끝난 뒤(_flipCardFromDeck 내부) 처리하도록 연기
      if (engine.currentPhase == TurnPhase.choosingMatch) {
        await _showMatchChoiceDialog();
      }
      completer.complete();
    });
    await completer.future;
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 보너스피를 낸 경우 턴이 계속되므로 카드더미 뒤집기 생략
    if (card.isBonus) {
      // 애니메이션 완료 후 입력 락 해제 (턴 계속)
      engine.tapLock = false;
      return;
    }
    
    await _flipCardFromDeck();
    
    // 애니메이션 완료 후 입력 락 해제
    engine.tapLock = false;
  }

  // 2단계: 카드 더미 뒤집기 로직 (자연스러운 뒤집기+이동 애니메이션)
  Future<void> _flipCardFromDeck() async {
    if (engine.currentPhase != TurnPhase.flippingCard) {
      return;
    }
    final drawnCard = engine.deckManager.drawPile.isNotEmpty ? engine.deckManager.drawPile.first : null;
    if (drawnCard != null) {
      // 카드 더미 위치 계산 (GlobalKey 사용)
      final deckKey = boardKey.currentState?.deckKey;
      Offset? deckOffset;
      if (deckKey is GlobalKey && deckKey.currentContext != null) {
        final RenderBox box = deckKey.currentContext!.findRenderObject() as RenderBox;
        deckOffset = box.localToGlobal(Offset.zero);
      }
      
      // 필드 도착 위치 계산 (겹침 스택 고려)
      Offset? fieldOffset;

      if (drawnCard.month > 0 && drawnCard.month <= 12) {
        // 1) 이미 같은 월 카드가 있는 경우 → 최상위 카드 계산
        final List<GoStopCard> sameMonth = engine.getField()
            .where((c) => c.month == drawnCard.month && !c.isBonus)
            .toList();

        if (sameMonth.isNotEmpty) {
          // 기준이 될 첫 번째 카드의 baseOffset
          final firstKey = fieldCardKeys[sameMonth.first.id.toString()];
          if (firstKey is GlobalKey && firstKey.currentContext != null) {
            final RenderBox baseBox = firstKey.currentContext!.findRenderObject() as RenderBox;
            final Offset baseOffset = baseBox.localToGlobal(Offset.zero);

            // 화면 크기 기반 카드/겹침 크기 계산 (보드와 동일)
            final Size scr = MediaQuery.of(context).size;
            final double minSide = scr.width < scr.height ? scr.width : scr.height;
            final double fieldW = (minSide * 0.13) * 0.8;
            final double fieldH = fieldW * 1.5;
            final double oX = fieldW * 0.375;
            final double oY = fieldH * 0.111;

            // 최상위 레이어 탐색
            Offset topOffset = baseOffset;
            int topLayer = -1;
            for (final fc in sameMonth) {
              final key = fieldCardKeys[fc.id.toString()];
              if (key is GlobalKey && key.currentContext != null) {
                final RenderBox bx = key.currentContext!.findRenderObject() as RenderBox;
                final Offset off = bx.localToGlobal(Offset.zero);
                final int layer = ((off.dx - baseOffset.dx) / oX).round();
                if (layer > topLayer) {
                  topLayer = layer;
                  topOffset = off;
                }
              }
            }

            fieldOffset = topOffset.translate(oX, oY);
          }
        } else {
          // 2) 같은 월 카드 없음 → 빈 그룹 위치 사용
          final groupKeys = boardKey.currentState?.getEmptyGroupKeys();
          if (groupKeys != null && drawnCard.month - 1 < groupKeys.length) {
            final groupKey = groupKeys[drawnCard.month - 1];
            if (groupKey is GlobalKey && groupKey.currentContext != null) {
              final RenderBox groupBox = groupKey.currentContext!.findRenderObject() as RenderBox;
              fieldOffset = groupBox.localToGlobal(Offset.zero);
            }
          }
        }
      }
      
      // fallback 위치 (GlobalKey 측정 실패 시)
      final size = MediaQuery.of(context).size;
      deckOffset ??= Offset(size.width / 2 - 24, size.height / 2 - 36);
      fieldOffset ??= Offset(size.width / 2 - 24, size.height / 2 - 36);

      final completer = Completer<void>();
      setState(() {
        isAnimating = true;
        activeAnimations.add(
          CardDeckToFieldAnimation(
            backImage: 'assets/cards/back.png',
            frontImage: drawnCard.imageUrl,
            startPosition: deckOffset!,
            endPosition: fieldOffset!,
            onComplete: () {
              setState(() {
                activeAnimations.removeWhere((anim) => anim is CardDeckToFieldAnimation);
                if (activeAnimations.isEmpty) {
                  isAnimating = false;
                }
              });
              // 애니메이션 완료 시 필드에 놓인 카드 좌표를 cache (GlobalKey가 아직 없을 수 있음)
              _recentCardPositions[drawnCard.id] = fieldOffset!;
              completer.complete();
            },
            duration: const Duration(milliseconds: 900),
          ),
        );
      });
      await completer.future;
    }
    setState(() {
      engine.flipFromDeck();
    });
    await Future.delayed(const Duration(milliseconds: 100));
    if (engine.currentPhase == TurnPhase.choosingMatch && engine.currentPlayer == 2) {
      final choices = engine.choices;
      if (choices.isNotEmpty) {
        GoStopCard selectedCard = choices.first;
        for (final choice in choices) {
          if (choice.type == '광') {
            selectedCard = choice;
            break;
          } else if (choice.type == '띠' && selectedCard.type != '광') {
            selectedCard = choice;
          } else if (choice.type == '동물' && selectedCard.type != '광' && selectedCard.type != '띠') {
            selectedCard = choice;
          } else if (choice.type == '피' && selectedCard.type == '피') {
            selectedCard = choice;
          }
        }
        setState(() => engine.chooseMatch(selectedCard));
        await Future.delayed(const Duration(milliseconds: 500));
        if (engine.currentPhase == TurnPhase.choosingMatch && engine.currentPlayer == 2) {
          final secondChoices = engine.choices;
          if (secondChoices.isNotEmpty) {
            GoStopCard secondSelectedCard = secondChoices.first;
            for (final choice in secondChoices) {
              if (choice.type == '광') {
                secondSelectedCard = choice;
                break;
              } else if (choice.type == '띠' && secondSelectedCard.type != '광') {
                secondSelectedCard = choice;
              } else if (choice.type == '동물' && secondSelectedCard.type != '광' && secondSelectedCard.type != '띠') {
                secondSelectedCard = choice;
              } else if (choice.type == '피' && secondSelectedCard.type == '피') {
                secondSelectedCard = choice;
              }
            }
            setState(() => engine.chooseMatch(secondSelectedCard));
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
    } else if (engine.currentPhase == TurnPhase.choosingMatch) {
      await _showMatchChoiceDialog();
    }
    setState(() {});
  }

  // '따닥' 선택 대화상자
  Future<void> _showMatchChoiceDialog() async {
    final chosenCard = await showDialog<GoStopCard>(
      context: context,
      builder: (context) {
        // 적응형 레이아웃: 화면 크기에 따른 선택창 배치 조정
        final maxWidth = MediaQuery.of(context).size.width;
        final useGridLayout = maxWidth < 320;
        
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectCardToEat),
          content: useGridLayout
              ? GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  children: engine.choices
                      .map((card) => GestureDetector(
                            onTap: () => Navigator.pop(context, card),
                            child: Image.asset(card.imageUrl, width: 80),
                          ))
                      .toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: engine.choices
                      .map((card) => GestureDetector(
                            onTap: () => Navigator.pop(context, card),
                            child: Image.asset(card.imageUrl, width: 80),
                          ))
                      .toList(),
                ),
        );
      },
    );

    if (chosenCard != null) {
      setState(() => engine.chooseMatch(chosenCard));
      
      // 애니메이션 완료 대기
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 첫 번째 선택 완료 후, 여전히 choosingMatch 상태라면 두 번째 선택창 띄우기
      if (engine.currentPhase == TurnPhase.choosingMatch) {
        await _showMatchChoiceDialog(); // 재귀 호출로 두 번째 선택창
      }
      // AI 턴 호출 제거 - onTurnEnd 콜백에서만 호출되도록 함
    }
  }

  // AI 턴 실행 로직
  Future<void> _runAiTurnIfNeeded() async {
    if (engine.isGameOver() || engine.currentPlayer != 2) return;
    // ── GO/STOP 대기 상태인지 확인 ──
    if (engine.awaitingGoStop) return;
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    final aiHand = engine.getHand(2);
    if (aiHand.isEmpty) return;
    final aiCardToPlay = aiHand.first;
    
    // AI도 마지막 낸 카드 id 기록 (보너스 카드 겹침 계산용)
    _lastPlayedCardId = aiCardToPlay.id;
    
    // 실제 카드가 이동하는 것처럼 보이도록 즉시 AI 손패에서 제거
    final playerIdx = engine.currentPlayer - 1;
    engine.deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == aiCardToPlay.id);
    setState(() {}); // UI 즉시 업데이트
    
    // AI 카드의 실제 위치 계산 (GlobalKey 사용 - 하나의 기준 좌표계)
    Offset fromOffset;
    final aiHandList = engine.getHand(2);
    final aiCardIdx = aiHandList.indexWhere((c) => c.id == aiCardToPlay.id);
    final GlobalKey? aiCardKey = boardKey.currentState?.getHandCardKey(aiCardIdx);
    if (aiCardKey != null && aiCardKey.currentContext != null) {
      final RenderBox box = aiCardKey.currentContext!.findRenderObject() as RenderBox;
      fromOffset = box.localToGlobal(Offset.zero);
    } else {
      fromOffset = _getCardPosition('ai_hand', aiCardToPlay);
    }
    
    // AI 카드가 이동할 필드 위치 계산 (GlobalKey 사용)
    Offset toOffset;
    GoStopCard? aiMatchCard; // AI가 매치할 카드
    
    if (aiCardToPlay.month > 0 && aiCardToPlay.month <= 12) {
      // 먼저 매치할 카드가 있는지 확인
      for (final c in engine.getField()) {
        if (c.month == aiCardToPlay.month && !c.isBonus) {
          aiMatchCard = c;
          break;
        }
      }
      
      // 매치할 카드가 있으면 해당 카드 위치로, 없으면 빈 그룹 위치로
      if (aiMatchCard != null) {
        final key = fieldCardKeys[aiMatchCard.id.toString()];
        if (key is GlobalKey && key.currentContext != null) {
          final RenderBox cardBox = key.currentContext!.findRenderObject() as RenderBox;
          final baseOffset = cardBox.localToGlobal(Offset.zero);
          // 매치가 있으면 겹침 위치로, 없으면 원래 위치로 (애니메이션과 겹침 통합)
          const double cardWidth = 48.0;
          const double cardHeight = 72.0;
          const double overlapOffsetX = cardWidth * 0.3; // 카드 너비의 30% 겹침
          const double overlapOffsetY = cardHeight * 0.1; // 카드 높이의 10% 겹침
          toOffset = Offset(
            baseOffset.dx + overlapOffsetX,
            baseOffset.dy + overlapOffsetY,
          );
        } else {
          toOffset = _getCardPosition('field', aiCardToPlay);
        }
      } else {
        final groupKeys = boardKey.currentState?.getEmptyGroupKeys();
        if (groupKeys != null && aiCardToPlay.month - 1 < groupKeys.length) {
          final groupKey = groupKeys[aiCardToPlay.month - 1];
          if (groupKey is GlobalKey && groupKey.currentContext != null) {
            final RenderBox groupBox = groupKey.currentContext!.findRenderObject() as RenderBox;
            toOffset = groupBox.localToGlobal(Offset.zero);
          } else {
            toOffset = _getCardPosition('field', aiCardToPlay);
          }
        } else {
          toOffset = _getCardPosition('field', aiCardToPlay);
        }
      }
    } else {
      toOffset = _getCardPosition('field', aiCardToPlay);
    }

    final completer = Completer<void>();
    
          // 보너스피인 경우 바로 먹은 카드로 이동하는 애니메이션
      if (aiCardToPlay.isBonus) {
        // 보너스피는 필드로 가지 않고 바로 먹은 카드 영역으로 이동
        final capturedOffset = _getCardPosition('ai_captured', aiCardToPlay);
        
        _playCardWithAnimation(aiCardToPlay, fromOffset, capturedOffset, () async {
          // 애니메이션 완료 = 보너스피 즉시 캡처
          setState(() => engine.playCard(aiCardToPlay));
          SoundManager.instance.play(Sfx.cardPlay);
          
          completer.complete();
        });
      } else {
        // 일반 카드는 필드로 이동하는 애니메이션
        _playCardWithAnimation(aiCardToPlay, fromOffset, toOffset, () async {
          // 애니메이션 완료 = 겹침 연출 완료 (하나의 연속된 동작)
          setState(() => engine.playCard(aiCardToPlay));
          SoundManager.instance.play(Sfx.cardPlay);
          
          completer.complete();
        });
      }
    
    await completer.future;
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 보너스피를 낸 경우 턴이 계속되므로 카드더미 뒤집기 생략하고 다음 카드 선택
    if (aiCardToPlay.isBonus) {
      // 보너스피를 낸 후에도 턴이 계속되므로 재귀적으로 다음 카드 선택
      await _runAiTurnIfNeeded();
      return;
    }
    
    // AI 턴에서 2장 선택창이 뜨면 자동으로 선택
    if (engine.currentPhase == TurnPhase.choosingMatch && engine.currentPlayer == 2) {
      final choices = engine.choices;
      if (choices.isNotEmpty) {
        // AI는 점수에 유리한 카드를 선택 (광 > 띠 > 동물 > 피 순서)
        GoStopCard selectedCard = choices.first; // 기본값
        for (final choice in choices) {
          if (choice.type == '광') {
            selectedCard = choice;
            break;
          } else if (choice.type == '띠' && selectedCard.type != '광') {
            selectedCard = choice;
          } else if (choice.type == '동물' && selectedCard.type != '광' && selectedCard.type != '띠') {
            selectedCard = choice;
          } else if (choice.type == '피' && selectedCard.type == '피') {
            // 피는 마지막 선택
            selectedCard = choice;
          }
        }
        
                            setState(() => engine.chooseMatch(selectedCard));
        
        await Future.delayed(const Duration(milliseconds: 500));
            
            // 두 번째 2장 매치가 있을 수도 있으므로 재귀적으로 처리
            if (engine.currentPhase == TurnPhase.choosingMatch && engine.currentPlayer == 2) {
              final secondChoices = engine.choices;
              if (secondChoices.isNotEmpty) {
                GoStopCard secondSelectedCard = secondChoices.first;
                for (final choice in secondChoices) {
                  if (choice.type == '광') {
                    secondSelectedCard = choice;
                    break;
                  } else if (choice.type == '띠' && secondSelectedCard.type != '광') {
                    secondSelectedCard = choice;
                  } else if (choice.type == '동물' && secondSelectedCard.type != '광' && secondSelectedCard.type != '띠') {
                    secondSelectedCard = choice;
                  } else if (choice.type == '피' && secondSelectedCard.type == '피') {
                    secondSelectedCard = choice;
                  }
                }
                
                setState(() => engine.chooseMatch(secondSelectedCard));
                
                await Future.delayed(const Duration(milliseconds: 500));
              }
            }
      }
    }
    
    // AI가 카드를 낸 후 반드시 카드더미 뒤집기 실행
    await _flipCardFromDeck();
    
    // AI 턴에서도 고/스톱 결정과 턴 계속 처리
    if (engine.awaitingGoStop && engine.currentPlayer == 2) {
      final aiScore = engine.calculateBaseScore(2);
      final playerScore = engine.calculateBaseScore(1);
      
      // AI가 7점 이상일 때 자동으로 GO/STOP 결정 (사용자에게 물어보지 않음)
      if (aiScore >= 7) {
        // AI의 전문가 수준 GO/STOP 결정 로직
        bool shouldGo = _aiDecideGoOrStop(aiScore, playerScore);
        
        if (shouldGo) {
          // AI가 GO를 선택하여 게임을 계속
          setState(() => engine.declareGo());
          await _showGoAnimation(engine.goCount);
          // ── GO/STOP 대기 상태 해제 ──
          engine.awaitingGoStop = false;
          // GO 선언 후 AI 턴이 계속되므로 재귀 호출
          await _runAiTurnIfNeeded();
        } else {
          // AI가 STOP을 선택하여 게임을 종료
          setState(() => engine.declareStop());
          // ── GO/STOP 대기 상태 해제 ──
          engine.awaitingGoStop = false;
          await _showGameOverDialog();
        }
      }
      // AI가 7점 미만이면 GO/STOP 선택하지 않고 턴 종료
    }
    // AI 턴이 끝나면 onTurnEnd 콜백에서 자동으로 다음 턴 처리됨
  }

  Future<void> _showGameOverDialog() async {
    if (!engine.isGameOver()) return;
    
    // 점수 계산 및 코인 증감 처리 (박 배수 포함한 최종 점수)
    final player1Score = engine.calculateScore(1);
    final player2Score = engine.calculateScore(2);
    
    String result;
    int coinChange = 0;
    
    if (player1Score > player2Score) {
      // 플레이어 1 승리
      result = AppLocalizations.of(context)!.player1Win + '\n' + AppLocalizations.of(context)!.scoreVs(player1Score, player2Score);
      coinChange = player1Score; // 승자 점수만큼 코인 획득
      await CoinService.instance.addCoins(coinChange);
    } else if (player2Score > player1Score) {
      // 플레이어 2(AI) 승리
      result = AppLocalizations.of(context)!.player2Win + '\n' + AppLocalizations.of(context)!.scoreVs(player1Score, player2Score);
      coinChange = -player2Score; // AI 점수만큼 코인 차감
      await CoinService.instance.addCoins(coinChange);
    } else {
      // 무승부
      result = AppLocalizations.of(context)!.draw + '\n' + AppLocalizations.of(context)!.scoreVs(player1Score, player2Score);
      coinChange = 0;
    }
    
    // 코인 증감 결과 메시지 추가
    String coinMessage = "";
    if (coinChange > 0) {
      coinMessage = '\n\n' + AppLocalizations.of(context)!.coinEarned(coinChange);
    } else if (coinChange < 0) {
      coinMessage = '\n\n' + AppLocalizations.of(context)!.coinLost(coinChange);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.gameOver),
        content: Text(result + coinMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => engine.reset());
              _runAiTurnIfNeeded();
            },
            child: Text(AppLocalizations.of(context)!.restart),
          ),
          TextButton(
            onPressed: () {
              // 로비로 이동: 두 번 pop (게임페이지, 다이얼로그)
              Navigator.of(context).pop(); // 다이얼로그 pop
              Navigator.of(context, rootNavigator: true).pop(); // 게임페이지 pop
            },
            child: Text(AppLocalizations.of(context)!.lobby),
          ),
        ],
      ),
    );
  }

  // 획득한 카드를 UI에 표시하기 위해 타입별로 그룹화하는 헬퍼 함수
  Map<String, List<String>> groupCapturedByType(List<dynamic> cards) {
    // 항상 모든 그룹이 존재하도록 초기화
    final Map<String, List<String>> grouped = {
      '광': [],
      '띠': [],
      '동물': [],
      '피': [],
    };
    for (final card in cards) {
      // '끗' 타입도 '동물'로 매핑
      final type = (card.type == '끗') ? '동물' : (card.type ?? '기타');
      if (grouped.containsKey(type)) {
        grouped[type]!.add(card.imageUrl.toString());
      }
    }
    return grouped;
  }

  // 안전하게 isAwaitingGoStop 호출
  bool getIsAwaitingGoStop() {
    return engine.awaitingGoStop;
  }

  // GO 애니메이션 표시
  Future<void> _showGoAnimation(int goCount) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => GoAnimationWidget(
        goCount: goCount,
        onComplete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // GO/STOP 선택 다이얼로그 표시 (박 상태 포함한 최종 점수 계산)
  Future<bool?> _showGoStopSelectionDialog() async {
    // ── 박 상태 체크 및 최종 점수 계산 ──
    engine.checkBakConditions(); // 박 상태 최신화
    
    // 박 상태를 포함한 최종 점수 계산 (calculateScore 사용으로 박 배수 적용)
    final playerFinalScore = engine.calculateScore(1);
    final aiFinalScore = engine.calculateScore(2);
    
    // ── 박 상태 정보 ──
    final isPlayerGwangBak = engine.gwangBakPlayers.contains(1);
    final isPlayerPiBak = engine.piBakPlayers.contains(1);
    final isAiGwangBak = engine.gwangBakPlayers.contains(2);
    final isAiPiBak = engine.piBakPlayers.contains(2);
    
    // ── 코인 변화 계산 (박 상태 포함) ──
    int coinChange = 0;
    if (playerFinalScore > aiFinalScore) {
      coinChange = playerFinalScore; // 승리 시 획득 코인
    } else if (aiFinalScore > playerFinalScore) {
      coinChange = -aiFinalScore; // 패배 시 손실 예상치
    }
    
    // ── 디버깅: 박 상태 및 점수 확인 ──
    print('🎯 GO/STOP 다이얼로그 점수 계산:');
    print('   플레이어 최종 점수: $playerFinalScore (광박: $isPlayerGwangBak, 피박: $isPlayerPiBak)');
    print('   AI 최종 점수: $aiFinalScore (광박: $isAiGwangBak, 피박: $isAiPiBak)');
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GoSelectionDialog(
        currentGoCount: engine.goCount,
        playerScore: playerFinalScore, // 박 상태 포함한 최종 점수
        opponentScore: aiFinalScore,   // 박 상태 포함한 최종 점수
        coinChangeIfStop: coinChange,
        isPlayerGwangBak: isPlayerGwangBak,
        isPlayerPiBak: isPlayerPiBak,
        isOpponentGwangBak: isAiGwangBak,
        isOpponentPiBak: isAiPiBak,
        onSelection: (isGo) {
          Navigator.of(context).pop(isGo);
        },
      ),
    );
  }



  // AI의 전문가 수준 GO/STOP 결정 로직 (전체 판세, 손패, 필드 상태, 상대방 상황 종합 고려)
  bool _aiDecideGoOrStop(int aiScore, int playerScore) {
    // 기본 규칙: 7점 이상일 때만 GO/STOP 선택 가능
    if (aiScore < 7) {
      return false; // 7점 미만이면 STOP
    }
    
    // ── 1. 기본 조건 및 가중치 계산 ──
    double adjustedScore = aiScore.toDouble();
    if (engine.goCount == 1 || engine.goCount == 2) {
      adjustedScore += 1.0; // 1GO/2GO 시 +1점 가중치
    } else if (engine.goCount >= 3) {
      adjustedScore *= 2.0; // 3GO부터 전체 점수 2배
    }
    
    // ── 2. 위험도 평가 (Risk Score 계산) ──
    double riskScore = 0.0;
    
    // 상대 점수가 5점 이상이면 역전 가능성 → 위험 증가
    if (playerScore >= 5) {
      riskScore += 2.0;
    }
    
    // 상대가 박에서 벗어날 가능성 체크
    final playerCaptured = engine.getCaptured(1);
    final playerPiCount = playerCaptured.where((c) => c.type == '피').length;
    final playerGwangCount = playerCaptured.where((c) => c.type == '광').length;
    
    // 상대가 피박에서 벗어날 가능성 (피가 7개 이하)
    if (playerPiCount <= 7) {
      riskScore += 1.5; // 피박 탈출 가능성
    }
    
    // 상대가 광박에서 벗어날 가능성 (광이 2개 이하)
    if (playerGwangCount <= 2) {
      riskScore += 1.0; // 광박 탈출 가능성
    }
    
    // AI 손패가 적을 경우 → 다음 턴 전환 위험 증가
    final aiHand = engine.getHand(2);
    if (aiHand.length <= 3) {
      riskScore += 2.0; // 손패 부족으로 인한 위험
    }
    
    // 필드에 고득점 카드가 많을 경우 → 상대에게 기회 제공
    final fieldCards = engine.getField();
    final highValueCards = fieldCards.where((c) => 
      c.type == '광' || c.type == '띠' || c.type == '동물' || 
      c.imageUrl.contains('bonus_') || c.imageUrl.contains('ssangpi')
    ).length;
    if (highValueCards >= 3) {
      riskScore += 1.5; // 필드에 고득점 카드 많음
    }
    
    // ── 3. 기대 보상 평가 (Expected Gain Score 계산) ──
    double expectedGainScore = 0.0;
    
    // AI 손패에 광, 띠, 동물 콤보 가능성 체크
    final aiGwangInHand = aiHand.where((c) => c.type == '광').length;
    final aiTtiInHand = aiHand.where((c) => c.type == '띠').length;
    final aiAnimalInHand = aiHand.where((c) => c.type == '동물').length;
    
    // 광 콤보 기대
    if (aiGwangInHand >= 1) {
      expectedGainScore += 1.0;
    }
    
    // 띠 콤보 기대
    if (aiTtiInHand >= 2) {
      expectedGainScore += 1.5;
    }
    
    // 동물 콤보 기대
    if (aiAnimalInHand >= 2) {
      expectedGainScore += 1.0;
    }
    
    // 특수 카드 (보너스, 쌍피) 기대
    final specialCards = aiHand.where((c) => 
      c.imageUrl.contains('bonus_') || c.imageUrl.contains('ssangpi')
    ).length;
    if (specialCards >= 1) {
      expectedGainScore += 1.5;
    }
    
    // ── 4. 상대 상황 분석 ──
    // 상대 점수가 낮고 손패가 적으면 GO 유리
    final playerHand = engine.getHand(1);
    if (playerScore <= 3 && playerHand.length <= 4) {
      expectedGainScore += 1.0; // 상대가 약한 상황
    }
    
    // 상대가 피박에 걸릴 가능성이 높으면 GO 유리
    if (playerPiCount >= 9) {
      expectedGainScore += 1.5; // 피박 유도 가능
    }
    
    // ── 5. GO 반복 위험성 평가 ──
    if (engine.goCount >= 3) {
      riskScore += 2.0; // 3GO 이상은 높은 리스크
    }
    
    // ── 6. 보수적 전략 조건 ──
    // 점수가 10점 이상이지만 다음 조합이 불확실할 때
    if (aiScore >= 10 && expectedGainScore < 2.0) {
      riskScore += 1.5;
    }
    
    // ── 7. 확률 기반 예외 처리 ──
    // 손패 내에서 확실한 콤보가 있는 경우
    if (aiGwangInHand >= 2 || aiTtiInHand >= 3) {
      expectedGainScore += 2.0; // 확실한 콤보
    }
    
    // ── 최종 판단 기준 ──
    // 기대 보상 점수가 위험 점수보다 1.0 이상 높으면 GO
    // 반대로 위험 점수가 더 높거나 GO 횟수가 많고 조합 기대값이 낮으면 STOP
    final decisionThreshold = expectedGainScore - riskScore;
    
    // 디버깅용 로그 (실제 배포 시 제거 가능)
    print('🤖 AI GO/STOP 결정 분석:');
    print('   현재 점수: $aiScore, 조정 점수: $adjustedScore');
    print('   상대 점수: $playerScore');
    print('   GO 횟수: ${engine.goCount}');
    print('   위험도 점수: $riskScore');
    print('   기대 보상 점수: $expectedGainScore');
    print('   판단 임계값: $decisionThreshold');
    
    if (decisionThreshold >= 1.0) {
      print('   📌 결과: GO (기대 보상이 위험도보다 ${decisionThreshold.toStringAsFixed(1)} 높음)');
      return true;
    } else {
      print('   📌 결과: STOP (위험도가 기대 보상보다 ${(-decisionThreshold).toStringAsFixed(1)} 높음)');
      return false;
    }
  }

  // AI 카드 이동 애니메이션 (뒤집기 포함)
  void _playAiCardWithAnimation(GoStopCard card, Offset from, Offset to, VoidCallback onComplete) {
    setState(() {
      isAnimating = true;
      // AI 카드는 뒷면에서 시작해서 앞면으로 뒤집으면서 이동 (자연스러운 연출)
      activeAnimations.add(
        CardFlipMoveAnimation(
          backImage: 'assets/cards/back.png',
          frontImage: card.imageUrl,
          startPosition: from,
          endPosition: to,
          onComplete: () {
            setState(() {
              activeAnimations.removeWhere((anim) => anim is CardFlipMoveAnimation);
              if (activeAnimations.isEmpty) {
                isAnimating = false;
              }
            });
            onComplete();
          },
          duration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  void _playCardWithAnimation(GoStopCard card, Offset from, Offset to, VoidCallback onComplete) {
    SoundManager.instance.play(Sfx.cardPlay);
    setState(() {
      isAnimating = true;
      // 자연스러운 카드 내기 애니메이션 사용
      activeAnimations.add(
        CardPlayAnimation(
          cardImage: card.imageUrl,
          startPosition: from,
          endPosition: to,
          onComplete: () {
            setState(() {
              activeAnimations.removeWhere((anim) => anim is CardPlayAnimation);
              if (activeAnimations.isEmpty) {
                isAnimating = false;
              }
            });
            onComplete();
          },
          duration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  // 카드 내기/뒤집기 시 실제 위치 계산 및 애니메이션 실행
  void _handleCardPlayOrDraw(GoStopCard card, String from, String to, VoidCallback onComplete) {
    // from, to에 따라 위치 계산 (예시: 손패, 카드더미, 필드 등)
    final fromOffset = _getCardPosition(from, card);
    final toOffset = _getCardPosition(to, card);
    _playCardWithAnimation(card, fromOffset, toOffset, onComplete);
  }

  // 카드들을 순서대로 획득 영역으로 이동하는 애니메이션
  void _playCardCaptureAnimation(List<GoStopCard> cards, int player) async {
    // 보너스피가 포함되어 있고, 방금 플레이한 카드 위에 겹치기 애니메이션이 진행 중이라면
    if (cards.any((c) => c.isBonus)) {
      // 겹치기 애니메이션(CardMoveAnimation) 길이(≈500ms) 만큼 기다려 준다.
      await Future.delayed(const Duration(milliseconds: 550));
    }
    // 카드 우선순위: 광 > 띠 > 동물 > 피 순서로 정렬
    cards.sort((a, b) {
      final priorityA = _getCardPriority(a);
      final priorityB = _getCardPriority(b);
      return priorityA.compareTo(priorityB);
    });

    final playerIdx = player - 1;
    int completedAnimations = 0; // 완료된 애니메이션 개수 추적

    // 각 카드를 순서대로 애니메이션 실행
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final fromOffset = _getCardPosition('field', card);
      // 캡처 그룹 레이아웃이 아직 준비되지 않은 경우 fallback 좌표(화면 중앙 하단)가 반환될 수 있음
      // 이런 경우 한 프레임 뒤에 다시 계산하여 실제 캡처 영역 좌표를 사용하도록 보정한다.
      Size _screenSize = MediaQuery.of(context).size;
      Offset toOffset = _getCardPosition('captured', card, playerId: player);

      bool _isFallbackOffset(Offset o) {
        // player 1(하단) fallback: 화면 하단 중앙 근처, player 2(상단) fallback: 화면 상단 중앙 근처
        if (player == 1) {
          return (o.dx - (_screenSize.width / 2 - 48)).abs() < 2 &&
                 (o.dy - (_screenSize.height - 120)).abs() < 2;
        } else {
          return (o.dx - (_screenSize.width / 2 - 48)).abs() < 2 &&
                 (o.dy - 120).abs() < 2;
        }
      }

      if (_isFallbackOffset(toOffset)) {
        // 한 프레임 대기 후 재계산 (레이아웃 완료 대기)
        await Future.delayed(const Duration(milliseconds: 16));
        toOffset = _getCardPosition('captured', card, playerId: player);
      }

      // 획득 카드 영역의 카드 크기 계산 (capturedOverlapRow와 동일 공식)
      final screenSize = MediaQuery.of(context).size;
      final minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
      final capturedCardWidth = minSide * 0.0455;
      final capturedCardHeight = capturedCardWidth * 1.5;
      
      // 각 카드마다 200ms 간격으로 애니메이션 실행
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // 원본 필드 카드 즉시 제거 + 애니메이션 위젯 추가를 한 번의 setState로 통합
      setState(() {
        engine.deckManager.fieldCards.removeWhere((c) => c.id == card.id);
        isAnimating = true;

        // 고유 키로 애니메이션 위젯 식별
        final uniqKey = UniqueKey();

        final anim = SimpleCardMoveAnimation(
          cardImage: card.imageUrl,
          startPosition: fromOffset,
          endPosition: toOffset,
          cardWidth: capturedCardWidth,
          cardHeight: capturedCardHeight,
          onComplete: () {
            // 애니메이션 완료 시 해당 카드만 즉시 획득 리스트에 추가 (불변 리스트 갱신)
            final current = engine.deckManager.capturedCards[playerIdx] ?? [];
            engine.deckManager.capturedCards[playerIdx] = List<GoStopCard>.from(current)..add(card);

            // pendingCaptured 리스트 정리
            engine.pendingCaptured.removeWhere((c) => c.id == card.id);

            // 자신(Key)만 제거하여 다른 애니메이션에 영향 없도록 함
            setState(() {
              activeAnimations.removeWhere((w) => w.key == uniqKey);
              completedAnimations++;
              
              // ── 모든 캡처 애니메이션이 완료된 후에만 점수 업데이트 ──
              if (completedAnimations == cards.length) {
                isAnimating = false;
                
                // 모든 카드가 획득 영역에 도착한 후 점수 계산
                _updateScoresAndCheckGoStop();
                
                // ── 디버깅: 피 점수 계산 확인 ──
                final playerCaptured = engine.getCaptured(1);
                final piCards = playerCaptured.where((c) => c.type == '피').toList();
                int totalPiScore = 0;
                for (final c in piCards) {
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
                final piScore = totalPiScore >= 10 ? totalPiScore - 9 : 0;
                print('DEBUG: 피 카드 ${piCards.length}장, 총 피 점수 $totalPiScore, 게임 피 점수 $piScore, 총 점수 $_displayPlayerScore');
              }
            });
          },
          duration: const Duration(milliseconds: 500),
        );

        // KeyedSubtree로 감싸서 List<Widget>에서도 고유 식별 가능
        activeAnimations.add(KeyedSubtree(key: uniqKey, child: anim));
      });
    }
    // 모든 애니메이션이 끝난 후 별도의 _moveCardsToCaptured 호출은 필요 없음
  }

  // 카드 우선순위 계산 (광 > 띠 > 동물 > 피)
  int _getCardPriority(GoStopCard card) {
    if (card.type == '광') return 0;
    if (card.type == '띠') return 1;
    if (card.type == '동물') return 2;
    if (card.type == '피') return 3;
    return 4;
  }

  // 애니메이션 완료 후 실제 카드 데이터를 획득 영역으로 이동
  void _moveCardsToCaptured(List<GoStopCard> cards, int player) {
    final playerIdx = player - 1;
    
    // 애니메이션에 전달된 카드들을 획득 카드로 이동
    engine.deckManager.capturedCards[playerIdx]?.addAll(cards);
    // 필드에서 획득 카드 제거
    engine.deckManager.fieldCards.removeWhere((c) => cards.any((rc) => rc.id == c.id));
    
    // pendingCaptured에서도 해당 카드들 제거
    engine.pendingCaptured.removeWhere((c) => cards.any((rc) => rc.id == c.id));
    
    // UI 업데이트
    setState(() {});
  }

  // 카드 위치 계산 함수 (실제 UI 위치에 맞게 수정)
  Offset _getCardPosition(String area, GoStopCard card, {int? playerId}) {
    final size = MediaQuery.of(context).size;
    Offset position;
    
    switch (area) {
      case 'hand':
        Offset? handOffset;
        // GoStopBoard에서 손패 카드 GlobalKey 가져오기
        final GlobalKey? handKey = boardKey.currentState?.getHandCardKeyById(card.id.toString());
        if (handKey != null && handKey.currentContext != null) {
          final RenderBox box = handKey.currentContext!.findRenderObject() as RenderBox;
          handOffset = box.localToGlobal(Offset.zero);
        }
        // fallback: 화면 하단 중앙 근사값
        position = handOffset ?? Offset(size.width / 2 - 48, size.height - 200);
        break;
      case 'ai_hand':
        // AI 손패는 화면 상단 중앙
        position = Offset(size.width / 2 - 48, 200);
        break;
      case 'deck':
        // 카드더미는 화면 중앙
        position = Offset(size.width / 2 - 24, size.height / 2 - 36);
        break;
      case 'field':
        Offset? cardOffset;
        // 1) 개별 카드 GlobalKey 우선
        final key = fieldCardKeys[card.id.toString()];
        if (key is GlobalKey && key.currentContext != null) {
          final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
          cardOffset = box.localToGlobal(Offset.zero);
        }

        // 2) 월 그룹 placeholder (이전 방식) - 백업용
        if (cardOffset == null && card.month > 0) {
          final GlobalKey? groupKey = boardKey.currentState?.getFieldGroupKey(card.month - 1);
          if (groupKey != null && groupKey.currentContext != null) {
            final RenderBox box = groupKey.currentContext!.findRenderObject() as RenderBox;
            cardOffset = box.localToGlobal(Offset.zero);
          }
        }

        // 3) recentCardPositions에 저장된 좌표 사용 (필드 키가 아직 없을 경우)
        if (cardOffset == null) {
          cardOffset = _recentCardPositions[card.id];
        }

        // 4) 계산식 fallback
        position = cardOffset ?? _getActualFieldPosition(card);
        break;
      case 'captured':
        // 카드 타입별 그룹 Key 결정
        String groupType = card.type;
        if (groupType == '끗') groupType = '동물';

        Offset? groupOffset;
        final GlobalKey? groupKey = playerId == 2
            ? boardKey.currentState?.getAiCapturedTypeKey(groupType)
            : boardKey.currentState?.getCapturedTypeKey(groupType);

        if (groupKey != null && groupKey.currentContext != null) {
          final RenderBox box = groupKey.currentContext!.findRenderObject() as RenderBox;
          groupOffset = box.localToGlobal(Offset.zero);
        }

        // fallback 위치도 플레이어 구분 (대략적인 위치)
        position = groupOffset ?? (playerId == 2
            ? Offset(size.width / 2 - 48, 120)
            : Offset(size.width / 2 - 48, size.height - 120));

        // ── 겹침 offset 보정(다중 행 고려) ──
        final capturedList = engine.deckManager.capturedCards[(playerId ?? 1) - 1] ?? [];
        final grouped = groupCapturedByType(capturedList);
        int idxInGroup = grouped[groupType]?.length ?? 0; // 새 카드 index

        // 카드 폭 및 겹침 간격 (capturedOverlapRow와 동일)
        final minSide = size.width < size.height ? size.width : size.height;
        final cWidth = minSide * 0.0455;
        final cHeight = cWidth * 1.5;
        const int maxPerRow = 5;
        final overlapX = cWidth * 0.45;
        final rowGap = cHeight * 0.6;

        final int row = idxInGroup ~/ maxPerRow;
        final int col = idxInGroup % maxPerRow;

        position = position.translate(col * overlapX, row * rowGap);
      case 'ai_captured':
        // AI의 먹은 카드 영역 위치 (상단)
        Offset? aiCapturedOffset;
        final GlobalKey? aiPiKey = boardKey.currentState?.getAiCapturedTypeKey('피');
        if (aiPiKey != null && aiPiKey.currentContext != null) {
          final RenderBox box = aiPiKey.currentContext!.findRenderObject() as RenderBox;
          aiCapturedOffset = box.localToGlobal(Offset.zero);
        }
        position = aiCapturedOffset ?? Offset(size.width / 2 - 48, 120); // AI 획득 영역 (상단)
        break;
      default:
        position = Offset(size.width / 2 - 24, size.height / 2 - 36);
    }
    
    return position;
  }
  
  // 필드 카드의 실제 배치 위치 계산 (원형 배치에 맞게 수정)
  Offset _getActualFieldPosition(GoStopCard card) {
    if (card.month <= 0) {
      // 월이 없는 카드는 중앙
      final size = MediaQuery.of(context).size;
      return Offset(size.width / 2 - 24, size.height / 2 - 36);
    }
    
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 원형 배치: 가로와 세로 반지름을 동일하게 설정
    final radius = (size.width < size.height 
      ? size.width * 0.35  // 세로가 긴 경우 가로 기준
      : size.height * 0.35); // 가로가 긴 경우 세로 기준
    
    final month = card.month - 1; // 0-based index
    final angle = (month / 12) * 2 * pi - pi / 2; // 12시 방향부터 시작
    
    // 원형 배치 좌표 계산
    final x = centerX + radius * cos(angle) - 24; // 카드 너비의 절반만큼 조정
    final y = centerY + radius * sin(angle) - 36; // 카드 높이의 절반만큼 조정
    
    return Offset(x, y);
  }

  void _ensureBgm() {
    if (!SoundManager.instance.isBgmPlaying && !SoundManager.instance.isBgmMuted) {
      SoundManager.instance.playBgm('lobby2', volume: 0.6);
    }
  }

  String _buildGameResultText(BuildContext context, int player1Score, int player2Score, int coinChange) {
    String result;
    if (player1Score > player2Score) {
      result = AppLocalizations.of(context)!.player1Win + '\n' + AppLocalizations.of(context)!.scoreVs(player1Score, player2Score);
    } else if (player2Score > player1Score) {
      result = AppLocalizations.of(context)!.player2Win + '\n' + AppLocalizations.of(context)!.scoreVs(player1Score, player2Score);
    } else {
      result = AppLocalizations.of(context)!.draw + '\n' + AppLocalizations.of(context)!.scoreVs(player1Score, player2Score);
    }
    if (coinChange > 0) {
      result += '\n\n' + AppLocalizations.of(context)!.coinEarned(coinChange);
    } else if (coinChange < 0) {
      result += '\n\n' + AppLocalizations.of(context)!.coinLost(coinChange);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final List<GoStopCard> playerHand = List<GoStopCard>.from(engine.getHand(1));
    final List<GoStopCard> opponentHand = List<GoStopCard>.from(engine.getHand(2));
    final List<GoStopCard> fieldCards = List<GoStopCard>.from(engine.getField());
    final int drawPileCount = engine.drawPileCount;
    // 먹을 수 있는 카드 인덱스 계산
    final fieldMonths = fieldCards.map((c) => c.month).where((m) => m > 0).toSet();
    List<int> highlightHandIndexes = <int>[];
    
    // ── 폭탄 카드와 매치되는 카드는 항상 선택 가능하도록 별도 처리 ──
    for (int i = 0; i < playerHand.length; i++) {
      final card = playerHand[i];
      // 폭탄카드(폭탄피)는 항상 선택 가능 (애니메이션 중에도)
      if (card.isBomb) {
        highlightHandIndexes.add(i);
      }
      // 보너스카드(쌍피, 쓰리피 등)는 항상 선택 가능 (애니메이션 중에도)
      if (card.isBonus) {
        highlightHandIndexes.add(i);
      }
      // 필드에 매치되는 월이 있는 카드는 항상 선택 가능 (애니메이션 중에도)
      if (card.month > 0 && fieldMonths.contains(card.month)) {
        highlightHandIndexes.add(i);
      }
    }
    
    // ── 중복 제거 (Set으로 변환 후 다시 List로) ──
    highlightHandIndexes = highlightHandIndexes.toSet().toList();

    // 캡처 영역에는 확정된 카드만 보여준다. pendingCaptured는 필드·애니메이션으로만 표현.
    // 턴 종료 후에만 UI 업데이트하도록 확정된 카드만 사용
    final playerCapturedCards = engine.getCaptured(1);
    final opponentCapturedCards = engine.getCaptured(2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _ensureBgm,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 배경 텍스처 + 그라디언트 오버레이
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/backgrounds/pink_glass_cards.png'), // 향후 velvet 이미지로 교체 가능
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [Colors.transparent, Colors.black54],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
            // 메인 게임 화면
            GoStopBoard(
              key: boardKey,
              playerHand: playerHand,
              playerCaptured: groupCapturedByType(playerCapturedCards),
              opponentCaptured: groupCapturedByType(opponentCapturedCards),
              tableCards: fieldCards,
              drawnCard: '',
              deckBackImage: 'assets/cards/back.png',
              opponentName: 'AI',
              // 턴 종료 후 확정된 점수만 표시
              playerScore: _displayPlayerScore,
              opponentScore: _displayOpponentScore,
              statusLabel: engine.currentPhase.toString(),
              onCardTap: (index) async {
                if (index < playerHand.length) {
                  final card = playerHand[index];
                  // 폭탄피(폭탄카드)는 애니메이션 없이 바로 playCard만 호출
                  if (card.isBomb) {
                    setState(() {
                      engine.playCard(card, groupIndex: null);
                    });
                    engine.tapLock = false;
                    return;
                  }
                  await onCardTap(card);
                }
              },
              effectBanner: null,
              lastCapturedType: null,
              lastCapturedIndex: null,
              opponentHandCount: opponentHand.length,
              isGoStopPhase: getIsAwaitingGoStop(),
              playedCard: null,
              capturedCards: null,
              onGo: getIsAwaitingGoStop() ? () async {
                // ── 명확한 분기 처리: AI 턴 vs 플레이어 턴 ──
                if (engine.currentPlayer == 2) {
                  // AI 턴일 때만 자동 판단
                  final aiScore = engine.calculateBaseScore(2);
                  final playerScore = engine.calculateBaseScore(1);
                  
                  // AI가 7점 이상일 때만 GO/STOP 판단
                  if (aiScore >= 7) {
                    final shouldGo = _aiDecideGoOrStop(aiScore, playerScore);
                    print('🤖 AI GO/STOP 자동 판단: $aiScore점 → ${shouldGo ? 'GO' : 'STOP'}');
                    
                    if (shouldGo) {
                      setState(() => engine.declareGo());
                      await _showGoAnimation(engine.goCount);
                      engine.awaitingGoStop = false;
                      _runAiTurnIfNeeded();
                    } else {
                      setState(() => engine.declareStop());
                      engine.awaitingGoStop = false;
                      _showGameOverDialog();
                    }
                  } else {
                    // AI가 7점 미만이면 자동으로 STOP
                    print('🤖 AI 7점 미만: 자동 STOP');
                    setState(() => engine.declareStop());
                    engine.awaitingGoStop = false;
                    _showGameOverDialog();
                  }
                  return;
                } else {
                  // 플레이어(나) 턴일 때는 반드시 선택 다이얼로그를 띄움
                  print('👤 플레이어 GO/STOP 선택 다이얼로그 표시');
                  final isGo = await _showGoStopSelectionDialog();
                  if (isGo == true) {
                    setState(() => engine.declareGo());
                    await _showGoAnimation(engine.goCount);
                    engine.awaitingGoStop = false;
                    _runAiTurnIfNeeded();
                  } else if (isGo == false) {
                    setState(() => engine.declareStop());
                    engine.awaitingGoStop = false;
                    _showGameOverDialog();
                  }
                }
              } : null,
              onStop: null, // onGo에서 통합 처리하므로 null로 설정
              highlightHandIndexes: highlightHandIndexes,
              cardStackController: cardDeckController,
              drawPileCount: drawPileCount,
              fieldCardKeys: fieldCardKeys,
              fieldStackKey: fieldStackKey,
              bonusCard: null,
              engine: engine,
              autoGoStop: engine.currentPlayer == 2,
            ),
            
            // 활성 애니메이션들을 화면에 표시
            ...activeAnimations,
            
            // 설정 버튼 (좌측 상단)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.018,
              left: MediaQuery.of(context).size.width * 0.018,
              child: Builder(
                builder: (context) {
                  final minSide = MediaQuery.of(context).size.shortestSide;
                  final iconSize = minSide * 0.035;
                  final containerSize = iconSize * 2.0;
                  final borderRadius = containerSize / 2;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: containerSize,
                        height: containerSize,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0,2))],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.settings, color: Colors.amberAccent, size: iconSize),
                          padding: EdgeInsets.all(iconSize * 0.28),
                          constraints: BoxConstraints(),
                          onPressed: () {
                            String selectedLang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
                            bool isMuted = SoundManager.instance.isBgmMuted;
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
                            showCustomSettingsDialog(
                              context,
                              selectedLang: selectedLang,
                              onLangChanged: (val) {
                                selectedLang = val;
                                localeProvider.setLocale(Locale(val));
                              },
                              isMuted: isMuted,
                              onMuteChanged: (val) async {
                                isMuted = val;
                                await SoundManager.instance.setBgmMuted(val);
                                setState(() {});
                              },
                              onLogout: () async {
                                Navigator.of(context).pop();
                                await authProvider.signOut();
                                if (mounted) {
                                  Navigator.of(context).pushReplacementNamed('/login');
                                }
                              },
                            );
                          },
                          tooltip: AppLocalizations.of(context)!.settings,
                        ),
                      ),

                      
                    ],
                  );
                },
              ),
            ),

            
            // AI 실시간 점수표 (턴 종료 후에만 업데이트)
            // Positioned(
            //   top: 50,
            //   left: 20,
            //   child: ScoreBoard(
            //     scoreDetails: engine.getCaptured(2).isEmpty ? 
            //       {'totalScore': 0, 'baseScore': 0, 'gwangScore': 0, 'ttiScore': 0, 'piScore': 0, 'animalScore': 0, 'godoriScore': 0, 'danScore': 0, 'goBonus': 0, 'gwangCards': [], 'ttiCards': [], 'piCards': [], 'animalCards': [], 'totalPi': 0} : 
            //       engine.calculateScoreDetails(2),
            //     playerName: 'AI',
            //     isAI: true,
            //     isPiBak: engine.piBakPlayers.contains(2),
            //     isGwangBak: engine.gwangBakPlayers.contains(2),
            //   ),
            // ),

            // 흔들 상태 표시 - 제거: 플레이어 박스 내부에 이미 표시되므로 중복 방지
            // if (engine.heundalPlayers.isNotEmpty)
            //   Positioned(
            //     top: 50,
            //     right: 20,
            //     child: Container(
            //       padding: const EdgeInsets.all(8),
            //       decoration: BoxDecoration(
            //         color: Colors.orange.withOpacity(0.9),
            //         borderRadius: BorderRadius.circular(8),
            //         border: Border.all(color: Colors.orange, width: 2),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           const Icon(Icons.whatshot, color: Colors.white, size: 20),
            //           const SizedBox(width: 5),
            //           Text(
            //             AppLocalizations.of(context)!.heundalStatus,
            //             style: const TextStyle(
            //               color: Colors.white,
            //               fontSize: 16,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),

            // 폭탄 상태 표시 - 제거: 플레이어 박스 내부에 이미 표시되므로 중복 방지
            // if (engine.bombPlayers.isNotEmpty)
            //   Positioned(
            //     top: 50,
            //     right: engine.heundalPlayers.isNotEmpty ? 120 : 20,
            //     child: Container(
            //       padding: const EdgeInsets.all(8),
            //       decoration: BoxDecoration(
            //         color: Colors.purple.withOpacity(0.9),
            //         borderRadius: BorderRadius.circular(8),
            //         border: Border.all(color: Colors.purple, width: 2),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
            //           const SizedBox(width: 5),
            //           Text(
            //             AppLocalizations.of(context)!.bombStatus,
            //             style: const TextStyle(
            //               color: Colors.white,
            //               fontSize: 16,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            
            // 플레이어 실시간 점수표 (턴 종료 후에만 업데이트)
            // Positioned(
            //   bottom: 180,
            //   left: 20,
            //   child: ScoreBoard(
            //     scoreDetails: engine.getCaptured(1).isEmpty ? 
            //       {'totalScore': 0, 'baseScore': 0, 'gwangScore': 0, 'ttiScore': 0, 'piScore': 0, 'animalScore': 0, 'godoriScore': 0, 'danScore': 0, 'goBonus': 0, 'gwangCards': [], 'ttiCards': [], 'piCards': [], 'animalCards': [], 'totalPi': 0} : 
            //       engine.calculateScoreDetails(1),
            //     playerName: '나',
            //     isAI: false,
            //     isPiBak: engine.piBakPlayers.contains(1),
            //     isGwangBak: engine.gwangBakPlayers.contains(1),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // 보너스피 애니메이션: 카드더미에서 "한 번만" 뒤집힌 뒤 곧바로 내가 낸 카드 위로 이동하여 겹침
  void _handleBonusCardAnimation(Map<String, dynamic> data) {
    final GoStopCard card = data['card'] as GoStopCard;
    final Function()? onComplete = data['onComplete'] as Function()?;

    // ① 카드더미 위치 (시작)
    final Offset deckOffset = _getCardPosition('deck', card);

    // ② 도착 위치: 방금 낸 카드(playedCard) 위치
    final GoStopCard? baseCard = engine.playedCard;
    if (baseCard == null) return; // 방어
    final Offset targetOffset = _getCardPosition('field', baseCard);

    setState(() {
      isAnimating = true;

      // 1단계: 제자리 뒤집기 (카드더미 위에서 앞면 확인)
      activeAnimations.add(
        CardFlipMoveAnimation(
          backImage: 'assets/cards/back.png',
          frontImage: card.imageUrl,
          startPosition: deckOffset,
          endPosition: deckOffset, // 이동 없음 – 제자리에서 뒤집기만
          duration: const Duration(milliseconds: 400),
          onComplete: () {
            // 뒤집기 완료 → 뒤집기 애니메이션 제거
            setState(() {
              activeAnimations.removeWhere((anim) => anim is CardFlipMoveAnimation);
            });

            // 2단계: 이동 애니메이션 (추가 뒤집기 없이 바로 겹침)
            setState(() {
              activeAnimations.add(
                CardMoveAnimation(
                  cardImage: card.imageUrl,
                  startPosition: deckOffset,
                  endPosition: targetOffset,
                  withTrail: false,
                  duration: const Duration(milliseconds: 400),
                  onComplete: () {
                    setState(() {
                      activeAnimations.removeWhere((anim) => anim is CardMoveAnimation);
                      if (activeAnimations.isEmpty) isAnimating = false;
                    });
                    // 엔진 콜백 실행 (다음 로직 진행)
                    if (onComplete != null) onComplete();
                  },
                ),
              );
            });
          },
        ),
      );
    });
  }
}

// MatgoEngine 에 isGameOver() 메서드 추가 필요
extension MatgoEngineExtension on MatgoEngine {
  bool isGameOver() => gameOver;
}