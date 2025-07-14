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
  bool showPpeokEffect = false;

  // 필드 카드별 GlobalKey 관리
  final Map<String, GlobalKey> fieldCardKeys = {};
  
  // 로그 뷰어 상태
  bool showLogViewer = false;

  // 1. 필드 Stack의 GlobalKey 선언
  final GlobalKey fieldStackKey = GlobalKey();

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
    engine.onTurnEnd = () {
      setState(() {
        // 턴 종료 후에만 UI 업데이트
      });
      
      // AI 턴인 경우 자동으로 시작 (단, GO/STOP 대기 상태가 아닐 때만)
      if (engine.currentPlayer == 2 && !engine.isGameOver() && !engine.awaitingGoStop) {
        _runAiTurnIfNeeded();
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
        final baseOffset = _getCardPosition(from == 'hand' ? (player == 1 ? 'hand' : 'ai_hand') : from, cards.first);
        final fieldOffset = _getCardPosition('field', cards.first);
        for (int i = 0; i < cards.length; i++) {
          final dx = fieldOffset.dx + i * 18.0; // 사선 겹침 x축
          final dy = fieldOffset.dy + i * 8.0;  // 사선 겹침 y축
          setState(() {
            isAnimating = true;
            activeAnimations.add(
              CardMoveAnimation(
                cardImage: cards[i].imageUrl,
                startPosition: baseOffset,
                endPosition: Offset(dx, dy),
                onComplete: () {
                  setState(() {
                    activeAnimations.removeWhere((anim) => anim is CardMoveAnimation);
                    if (activeAnimations.isEmpty) isAnimating = false;
                  });
                },
                duration: const Duration(milliseconds: 400),
                withTrail: false,
              ),
            );
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
      case AnimationEventType.bomb:
        _handleSpecialEffect(event.data);
        break;
      case AnimationEventType.bonusCard:
        // 보너스카드 애니메이션 제거 - 즉시 처리
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
    // 특수 효과 애니메이션/이펙트 비활성화
    return;
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

    // 폭탄 조건: 손패 3장+필드 1장 이상이면 흔들 다이얼로그 없이 자동 폭탄 발동
    final hand = engine.getHand(1);
    final sameMonthCards = hand.where((c) => c.month == card.month).toList();
    final field = engine.getField();
    final fieldSameMonth = field.where((c) => c.month == card.month).toList();
    if (sameMonthCards.length >= 3 && fieldSameMonth.isNotEmpty) {
      // 3장 모두 playCard로 전달 (자동 폭탄)
      for (final bombCard in sameMonthCards.take(3)) {
        setState(() {
          engine.playCard(bombCard, groupIndex: null);
        });
        await Future.delayed(const Duration(milliseconds: 300));
      }
      await _flipCardFromDeck();
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
      
      // 따닥(choosingMatch) 상태면 바로 선택 다이얼로그 호출
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
            final double handW = minSide * 0.13;
            final double fieldW = handW * 0.8;
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
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    final aiHand = engine.getHand(2);
    if (aiHand.isEmpty) return;
    final aiCardToPlay = aiHand.first;
    
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
      final aiScore = engine.calculateScore(2);
      final playerScore = engine.calculateScore(1);
      
      // AI의 지능적인 GO/STOP 결정 로직
      bool shouldGo = _aiDecideGoOrStop(aiScore, playerScore);
      
      if (shouldGo) {
        // AI가 GO를 선택하여 게임을 계속
        await _showGoAnimation(engine.goCount);
        setState(() => engine.declareGo());
        // GO 선언 후 AI 턴이 계속되므로 재귀 호출
        await _runAiTurnIfNeeded();
      } else {
        // AI가 STOP을 선택하여 게임을 종료
        setState(() => engine.declareStop());
        await _showGameOverDialog();
      }
    }
    // AI 턴이 끝나면 onTurnEnd 콜백에서 자동으로 다음 턴 처리됨
  }

  Future<void> _showGameOverDialog() async {
    if (!engine.isGameOver()) return;
    
    // 점수 계산 및 코인 증감 처리 (특수 상황 배수 포함)
    final player1Score = engine.calculateScoreDetails(1)['totalScore'] as int;
    final player2Score = engine.calculateScoreDetails(2)['totalScore'] as int;
    
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

  // GO/STOP 선택 다이얼로그 표시
  Future<bool?> _showGoStopSelectionDialog() async {
    final playerScore = engine.calculateScore(1);
    final aiScore = engine.calculateScore(2);
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GoSelectionDialog(
        currentGoCount: engine.goCount,
        playerScore: playerScore,
        opponentScore: aiScore,
        onSelection: (isGo) {
          Navigator.of(context).pop(isGo);
        },
      ),
    );
  }



  // AI의 지능적인 GO/STOP 결정 로직 (실제 프로 플레이어 기준)
  bool _aiDecideGoOrStop(int aiScore, int playerScore) {
    // 기본 규칙: 7점 이상일 때만 GO/STOP 선택 가능
    if (aiScore < 7) {
      return false; // 7점 미만이면 STOP
    }
    
    // 실제 프로 플레이어의 GO/STOP 결정 로직
    if (aiScore >= 12) {
      // 12점 이상: 상대방 점수가 매우 낮을 때만 GO
      if (playerScore <= 1) {
        // 상대방이 1점 이하면 GO (상대방이 매우 낮은 점수이므로 더 높은 점수로 승리)
        return true;
      } else {
        // 상대방이 2점 이상이면 STOP (현재 점수로 충분히 승리 가능)
        return false;
      }
    } else if (aiScore >= 10) {
      // 10-11점: 상대방 점수가 낮을 때만 GO
      if (playerScore <= 3) {
        // 상대방이 3점 이하면 GO (상대방이 매우 낮은 점수이므로 더 높은 점수로 승리)
        return true;
      } else {
        // 상대방이 4점 이상이면 STOP (현재 점수로 충분히 승리 가능)
        return false;
      }
    } else if (aiScore >= 8) {
      // 8-9점: 상대방 점수가 매우 낮을 때만 GO
      if (playerScore <= 2) {
        // 상대방이 2점 이하면 GO (상대방이 매우 낮은 점수이므로 더 높은 점수로 승리)
        return true;
      } else {
        // 상대방이 3점 이상이면 STOP (현재 점수로 충분히 승리 가능)
        return false;
      }
    } else {
      // 7점: 상대방 점수가 매우 낮을 때만 GO
      if (playerScore <= 1) {
        // 상대방이 1점 이하면 GO (상대방이 매우 낮은 점수이므로 더 높은 점수로 승리)
        return true;
      } else {
        // 상대방이 2점 이상이면 STOP (현재 점수로 충분히 승리 가능)
        return false;
      }
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
    // 카드 우선순위: 광 > 띠 > 동물 > 피 순서로 정렬
    cards.sort((a, b) {
      final priorityA = _getCardPriority(a);
      final priorityB = _getCardPriority(b);
      return priorityA.compareTo(priorityB);
    });

    final playerIdx = player - 1;

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
              if (activeAnimations.isEmpty) isAnimating = false;
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

        // ── 겹침 offset 보정(이미 보유한 카드 수 만큼 오른쪽으로 이동) ──
        final capturedList = engine.deckManager.capturedCards[(playerId ?? 1) - 1] ?? [];
        final grouped = groupCapturedByType(capturedList);
        int idxInGroup = 0;
        if (grouped.containsKey(groupType)) {
          idxInGroup = grouped[groupType]!.length; // 현재 보유 수 (새 카드 index)
        }

        // 카드 폭, overlapX 계산 캡처된 카드 UI와 동일 공식
        final minSide = size.width < size.height ? size.width : size.height;
        final cWidth = minSide * 0.0455;
        final overlapX = cWidth * 0.45;

        position = position.translate(idxInGroup * overlapX, 0);
        break;
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
    final highlightHandIndexes = <int>[];
    for (int i = 0; i < playerHand.length; i++) {
      final card = playerHand[i];
      // 폭탄카드(폭탄피)는 항상 선택 가능
      if (card.isBomb) {
        highlightHandIndexes.add(i);
        continue;
      }
      // 보너스카드(쌍피, 쓰리피 등)는 항상 선택 가능
      if (card.isBonus) {
        highlightHandIndexes.add(i);
        continue;
      }
      // 필드에 매치되는 월이 있는 카드만 선택 가능
      if (card.month > 0 && fieldMonths.contains(card.month)) {
        highlightHandIndexes.add(i);
      }
      // 그 외(아무것도 매치 안 되는 일반카드)는 선택 불가(어둡게 처리)
    }

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
              // 턴 종료 후에만 점수 업데이트하도록 확정된 점수만 사용
              playerScore: engine.getCaptured(1).isEmpty ? 0 : engine.calculateScore(1),
              opponentScore: engine.getCaptured(2).isEmpty ? 0 : engine.calculateScore(2),
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
                // GO/STOP 선택 다이얼로그 표시
                final isGo = await _showGoStopSelectionDialog();
                if (isGo == true) {
                  // GO 애니메이션 먼저 표시 (goCount + 1)
                  await _showGoAnimation(engine.goCount + 1);
                  setState(() => engine.declareGo());
                  // GO 선언 후 AI 턴을 바로 실행 (onTurnEnd 콜백에서 자동으로 처리됨)
                } else if (isGo == false) {
                  // STOP 선택 시 게임 종료
                  setState(() => engine.declareStop());
                  _showGameOverDialog();
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
                      const SizedBox(height: 12),
                      // 뻑 이펙트 테스트 버튼
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() => showPpeokEffect = true);
                          Future.delayed(const Duration(milliseconds: 1100), () {
                            if (mounted) setState(() => showPpeokEffect = false);
                          });
                        },
                        child: const Text('Show PPEOK Effect'),
                      ),
                    ],
                  );
                },
              ),
            ),
            // 카드더미 옆에 뻑 이펙트 표시 (테스트용)
            if (showPpeokEffect)
              Positioned(
                // 카드더미는 중앙 기준, 약간 오른쪽에 띄움 (반응형)
                left: MediaQuery.of(context).size.width / 2 + 80,
                top: MediaQuery.of(context).size.height / 2 - 36,
                child: IgnorePointer(
                  child: SpecialEffectAnimation(
                    effectType: 'ppeok',
                    onComplete: () {}, // 자동 사라짐
                  ),
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

            // 흔들 상태 표시
            if (engine.heundalPlayers.isNotEmpty)
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.whatshot, color: Colors.white, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        AppLocalizations.of(context)!.heundalStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
}

// MatgoEngine 에 isGameOver() 메서드 추가 필요
extension MatgoEngineExtension on MatgoEngine {
  bool isGameOver() => gameOver;
}