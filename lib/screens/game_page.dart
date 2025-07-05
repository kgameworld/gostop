import 'package:flutter/material.dart';
import '../utils/matgo_engine.dart';
import '../models/card_model.dart';
import '../screens/gostop_board.dart';
import '../utils/deck_manager.dart';
import '../widgets/card_deck_widget.dart';
import '../animations.dart';
import '../widgets/particle_system.dart';
import '../widgets/animated_card_deck.dart';
import '../utils/animation_pool.dart';
import '../widgets/game_log_viewer.dart';
import 'dart:async';

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
  
  // 애니메이션 풀
  final AnimationPool animationPool = AnimationPool();
  
  // 긴장감 모드
  bool isTensionMode = false;

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
    
    // 애니메이션 이벤트 리스너 설정 (임시 비활성화)
    // engine.setAnimationListener(_handleAnimationEvent);
    
    _runAiTurnIfNeeded();
  }

  @override
  void dispose() {
    super.dispose();
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
        // 먹은 카드들 먹은 카드 영역으로 이동
        final cards = event.data['cards'] as List<GoStopCard>;
        final player = event.data['player'] as int;
        final fromOffset = _getCardPosition('field', cards.first);
        final toOffset = _getCardPosition('captured', cards.first);
        setState(() {
          isAnimating = true;
          activeAnimations.add(
            CardCaptureAnimation(
              cardImages: cards.map((c) => c.imageUrl).toList(),
              startPosition: fromOffset,
              endPosition: toOffset,
              onComplete: () {
                setState(() {
                  activeAnimations.removeWhere((anim) => anim is CardCaptureAnimation);
                  if (activeAnimations.isEmpty) isAnimating = false;
                });
              },
              duration: const Duration(milliseconds: 600),
            ),
          );
        });
        break;
      case AnimationEventType.specialEffect:
        _handleSpecialEffect(event.data);
        break;
      case AnimationEventType.bonusCard:
        // 보너스카드: 낸 카드가 바로 먹은 카드 영역으로 이동
        final card = event.data['card'] as GoStopCard;
        final player = event.data['player'] as int;
        final fromOffset = _getCardPosition(player == 1 ? 'hand' : 'ai_hand', card);
        final toOffset = _getCardPosition('captured', card);
        setState(() {
          isAnimating = true;
          activeAnimations.add(
            CardCaptureAnimation(
              cardImages: [card.imageUrl],
              startPosition: fromOffset,
              endPosition: toOffset,
              onComplete: () {
                setState(() {
                  activeAnimations.removeWhere((anim) => anim is CardCaptureAnimation);
                  if (activeAnimations.isEmpty) isAnimating = false;
                });
              },
              duration: const Duration(milliseconds: 600),
            ),
          );
        });
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
    final effect = data['effect'] as String;
    final player = data['player'] as int;
    
    setState(() {
      isAnimating = true;
      
      // 특수 효과 애니메이션
      activeAnimations.add(
        animationPool.getSpecialEffectAnimation(
          effectType: effect,
          onComplete: () {
            setState(() {
              activeAnimations.removeWhere((anim) => anim is SpecialEffectAnimation);
            });
          },
        ),
      );
      
      // 화면 파티클 효과
      activeAnimations.add(
        animationPool.getScreenParticleEffect(
          effectType: effect,
          onComplete: () {
            setState(() {
              activeAnimations.removeWhere((anim) => anim is ScreenParticleEffect);
              if (activeAnimations.isEmpty) {
                isAnimating = false;
              }
            });
          },
        ),
      );
    });
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

  // 필드에 카드가 놓일 빈 자리(그룹) 위치를 계산하는 헬퍼 함수
  Offset _getEmptyFieldGroupPosition(int groupIndex) {
    // _fieldZone의 배치 규칙과 동일하게 좌표 계산
    // 윗 행 4개
    if (groupIndex < 4) {
      return Offset(80.0 + groupIndex * 90.0, 0.0);
    }
    // 왼쪽 2개
    if (groupIndex < 6) {
      return Offset(0.0, 90.0 + (groupIndex - 4) * 90.0);
    }
    // 오른쪽 2개
    if (groupIndex < 8) {
      return Offset(520.0 - 48.0, 90.0 + (groupIndex - 6) * 90.0);
    }
    // 아래 행 4개
    return Offset(80.0 + (groupIndex - 8) * 90.0, 360.0 - 72.0);
  }

  // 1단계: 손패 카드 탭 처리
  Future<void> onCardTap(GoStopCard card) async {
    if (isAnimating) return;
    if (engine.currentPlayer != 1 || engine.currentPhase != TurnPhase.playingCard) {
      return;
    }
    
    // 실제 카드가 이동하는 것처럼 보이도록 즉시 손패에서 제거
    final playerIdx = engine.currentPlayer - 1;
    engine.deckManager.playerHands[playerIdx]?.removeWhere((c) => c.id == card.id);
    setState(() {}); // UI 즉시 업데이트
    
    // 손패에서 실제 카드 위치 계산 (제거된 후의 위치)
    final fromOffset = _getCardPosition('hand', card);
    
    // 매치 카드의 실제 위치 계산
    GoStopCard? matchCard;
    for (final c in engine.getField()) {
      if (c.month == card.month && !c.isBonus) {
        matchCard = c;
        break;
      }
    }
    Offset? matchCardOffset;
    if (matchCard != null) {
      final key = fieldCardKeys[matchCard.id.toString()];
      if (key is GlobalKey && key.currentContext != null && fieldStackKey.currentContext != null) {
        final RenderBox cardBox = key.currentContext!.findRenderObject() as RenderBox;
        final RenderBox stackBox = fieldStackKey.currentContext!.findRenderObject() as RenderBox;
        final Offset stackTopLeft = stackBox.localToGlobal(Offset.zero);
        final Offset cardInStack = cardBox.localToGlobal(Offset.zero, ancestor: stackBox);
        matchCardOffset = stackTopLeft + cardInStack;
      }
    }

    
    final completer = Completer<void>();
    _playCardWithAnimation(card, fromOffset, matchCardOffset ?? _getActualFieldPosition(card), () async {
      if (matchCard != null && matchCardOffset != null && matchCard.imageUrl != null) {
        setState(() {
          activeAnimations.add(
            Stack(
              children: [
                if (matchCardOffset != null && matchCard?.imageUrl != null)
                  Positioned(
                    left: matchCardOffset.dx,
                    top: matchCardOffset.dy,
                    child: Image.asset(matchCard!.imageUrl, width: 48, height: 72),
                  ),
                if (matchCardOffset != null)
                  Positioned(
                    left: matchCardOffset.dx + 12,
                    top: matchCardOffset.dy + 6,
                    child: Image.asset(card.imageUrl, width: 48, height: 72),
                  ),
              ],
            ),
          );
        });
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          activeAnimations.removeWhere((w) => w is Stack);
        });
      }
      setState(() {
        engine.playCard(card, groupIndex: null);
      });
      // 따닥(choosingMatch) 상태면 바로 선택 다이얼로그 호출
      if (engine.currentPhase == TurnPhase.choosingMatch) {
        await _showMatchChoiceDialog();
      }
      completer.complete();
    });
    await completer.future;
    await Future.delayed(const Duration(milliseconds: 500));
    await _flipCardFromDeck();
  }

  // 2단계: 카드 더미 뒤집기 로직 (자연스러운 뒤집기+이동 애니메이션)
  Future<void> _flipCardFromDeck() async {
    if (engine.currentPhase != TurnPhase.flippingCard) {
      return;
    }
    final drawnCard = engine.deckManager.drawPile.isNotEmpty ? engine.deckManager.drawPile.first : null;
    if (drawnCard != null) {
      // 카드가 필드에 깔릴 자리의 GlobalKey 위치 계산
      final groupKeys = boardKey.currentState?.getEmptyGroupKeys();
      Offset? fieldOffset;
      if (drawnCard.month > 0 && drawnCard.month <= 12 && groupKeys != null && drawnCard.month - 1 < groupKeys.length) {
        final fieldKey = groupKeys[drawnCard.month - 1];
        if (fieldKey is GlobalKey && fieldKey.currentContext != null) {
          final RenderBox box = fieldKey.currentContext!.findRenderObject() as RenderBox;
          fieldOffset = box.localToGlobal(Offset.zero);
        }
      }
      // 카드 더미 위치 계산
      final deckKey = boardKey.currentState?.deckKey;
      Offset? deckOffset;
      if (deckKey is GlobalKey && deckKey.currentContext != null) {
        final RenderBox box = deckKey.currentContext!.findRenderObject() as RenderBox;
        deckOffset = box.localToGlobal(Offset.zero);
      }
      // 통합된 뒤집기+이동 애니메이션 실행
      if (fieldOffset == null || deckOffset == null) {
        // 한 프레임 대기 후 재시도
        await Future.delayed(const Duration(milliseconds: 16));
        if (deckKey is GlobalKey && deckKey.currentContext != null) {
          final RenderBox box = deckKey.currentContext!.findRenderObject() as RenderBox;
          deckOffset = box.localToGlobal(Offset.zero);
        }
        // fieldOffset도 마찬가지로 재계산 필요 (여기서는 이미 위에서 계산된 값 사용)
      }
      // 그래도 null이면 기본값(중앙) 사용
      final size = MediaQuery.of(context).size;
      deckOffset ??= Offset(size.width / 2 - 24, size.height / 2 - 36);
      fieldOffset ??= Offset(size.width / 2 - 24, size.height / 2 - 36);
      // 반드시 애니메이션 실행
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
    } else if (engine.currentPhase == TurnPhase.choosingMatch) {
      // 플레이어 턴에서는 선택창 표시
      await _showMatchChoiceDialog();
    }
    
    if (engine.currentPhase == TurnPhase.playingCard && engine.currentPlayer == 2) {
      await _runAiTurnIfNeeded();
    }
    
    setState(() {}); // 상태 꼬임 방지: 항상 UI 갱신
  }

  // '따닥' 선택 대화상자
  Future<void> _showMatchChoiceDialog() async {
    final chosenCard = await showDialog<GoStopCard>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('먹을 카드를 선택하세요'),
          content: Row(
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
      } else if (engine.currentPhase == TurnPhase.playingCard) {
        await _runAiTurnIfNeeded();
      }
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
    
    final fromOffset = _getCardPosition('ai_hand', aiCardToPlay);
    // 매치 카드의 실제 위치 계산 (플레이어와 동일)
    GoStopCard? matchCard;
    for (final c in engine.getField()) {
      if (c.month == aiCardToPlay.month && !c.isBonus) {
        matchCard = c;
        break;
      }
    }
    Offset? matchCardOffset;
    if (matchCard != null) {
      final key = fieldCardKeys[matchCard.id.toString()];
      if (key is GlobalKey && key.currentContext != null && fieldStackKey.currentContext != null) {
        final RenderBox cardBox = key.currentContext!.findRenderObject() as RenderBox;
        final RenderBox stackBox = fieldStackKey.currentContext!.findRenderObject() as RenderBox;
        final Offset stackTopLeft = stackBox.localToGlobal(Offset.zero);
        final Offset cardInStack = cardBox.localToGlobal(Offset.zero, ancestor: stackBox);
        matchCardOffset = stackTopLeft + cardInStack;
      }
    }
    // AI도 먹을 카드가 없으면 카드더미 뒤집기와 동일하게 빈자리 위치로 애니메이션
    if (matchCard == null) {
      int groupIdx = -1;
      final boardState = boardKey.currentState;
      if (boardState != null) {
        final emptyKeys = boardState.getEmptyGroupKeys();
        groupIdx = aiCardToPlay.month - 1;
        if (groupIdx >= 0 && groupIdx < emptyKeys.length) {
          final key = emptyKeys[groupIdx];
          Offset? groupOffset;
          if (key is GlobalKey && key.currentContext != null) {
            final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
            final Offset pos = box.localToGlobal(Offset.zero);
            groupOffset = pos;
          } else {
            await Future.delayed(const Duration(milliseconds: 16));
            if (key is GlobalKey && key.currentContext != null) {
              final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
              final Offset pos = box.localToGlobal(Offset.zero);
              groupOffset = pos;
            }
          }
          if (groupOffset != null) {
            final completer = Completer<void>();
            _playCardWithAnimation(aiCardToPlay, fromOffset, groupOffset, () async {
              setState(() => engine.playCard(aiCardToPlay));
              completer.complete();
            });
            await completer.future;
            await Future.delayed(const Duration(milliseconds: 500));
            await _flipCardFromDeck();
            
            // AI 턴에서도 고/스톱 결정과 턴 계속 처리
            if (engine.awaitingGoStop) {
              if (engine.calculateScore(2) >= 3) {
                setState(() => engine.declareGo());
                await _runAiTurnIfNeeded();
              } else {
                setState(() => engine.declareStop());
                _showGameOverDialog();
              }
            } else if (engine.currentPhase == TurnPhase.playingCard && engine.currentPlayer == 2) {
              await _runAiTurnIfNeeded();
            }
            
            return;
          }
        }
      }
      // fallback: 애니메이션 없이 처리
      setState(() => engine.playCard(aiCardToPlay));
      await Future.delayed(const Duration(milliseconds: 500));
      await _flipCardFromDeck();
      return;
    }
    final toOffset = matchCardOffset ?? _getCardPosition('field', aiCardToPlay);
    final completer = Completer<void>();
    _playCardWithAnimation(aiCardToPlay, fromOffset, toOffset, () async {
      if (matchCard != null && matchCardOffset != null && matchCard.imageUrl != null) {
        setState(() {
          activeAnimations.add(
            Stack(
              children: [
                if (matchCardOffset != null && matchCard?.imageUrl != null)
                  Positioned(
                    left: matchCardOffset.dx,
                    top: matchCardOffset.dy,
                    child: Image.asset(matchCard!.imageUrl, width: 48, height: 72),
                  ),
                if (matchCardOffset != null)
                  Positioned(
                    left: matchCardOffset.dx + 12,
                    top: matchCardOffset.dy + 6,
                    child: Image.asset(aiCardToPlay.imageUrl, width: 48, height: 72),
                  ),
              ],
            ),
          );
        });
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          activeAnimations.removeWhere((w) => w is Stack);
        });
      }
      setState(() => engine.playCard(aiCardToPlay));
      completer.complete();
    });
    await completer.future;
    await Future.delayed(const Duration(milliseconds: 500));
    
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
      if (engine.calculateScore(2) >= 3) {
        setState(() => engine.declareGo());
        await _runAiTurnIfNeeded();
      } else {
        setState(() => engine.declareStop());
        _showGameOverDialog();
      }
    } else if (engine.currentPhase == TurnPhase.playingCard && engine.currentPlayer == 2) {
      await _runAiTurnIfNeeded();
    }
  }

  void _showGameOverDialog() {
    if (!engine.isGameOver()) return;
    final result = engine.getResult();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('게임 종료'),
        content: Text(result),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => engine.reset());
              _runAiTurnIfNeeded();
            },
            child: const Text('다시 시작'),
          ),
        ],
      ),
    );
  }

  // 획득한 카드를 UI에 표시하기 위해 타입별로 그룹화하는 헬퍼 함수
  Map<String, List<String>> groupCapturedByType(List<dynamic> cards) {
    final Map<String, List<String>> grouped = {};
    for (final card in cards) {
      final type = card.type ?? '기타';
      grouped.putIfAbsent(type, () => <String>[]);
      grouped[type]!.add(card.imageUrl.toString());
    }
    return grouped.map((k, v) => MapEntry(k, v.map((e) => e.toString()).toList()));
  }

  // 안전하게 isAwaitingGoStop 호출
  bool getIsAwaitingGoStop() {
    return engine.awaitingGoStop;
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

  // 카드 위치 계산 함수 (실제 UI 위치에 맞게 수정)
  Offset _getCardPosition(String area, GoStopCard card) {
    final size = MediaQuery.of(context).size;
    Offset position;
    
    switch (area) {
      case 'hand':
        // 플레이어 손패는 화면 하단 중앙
        position = Offset(size.width / 2 - 48, size.height - 200);
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
        // 필드는 실제 월별 그룹 배치 위치로 수정
        position = _getActualFieldPosition(card);
        break;
      case 'captured':
        // 획득 카드는 화면 하단 (획득 카드 영역)
        position = Offset(size.width / 2 - 48, size.height - 120);
        break;
      default:
        position = Offset(size.width / 2 - 24, size.height / 2 - 36);
    }
    
    return position;
  }
  
  // 필드 카드의 실제 배치 위치 계산 (GoStopBoard Stack 내부 좌표와 100% 일치)
  Offset _getActualFieldPosition(GoStopCard card) {
    if (card.month <= 0) {
      // 월이 없는 카드는 중앙
      final size = MediaQuery.of(context).size;
      return Offset(size.width / 2 - 24, size.height / 2 - 36);
    }
    final month = card.month - 1; // 0-based index
    double x = 0, y = 0;
    if (month < 4) {
      // 윗 행 4개
      x = 80 + month * 90;
      y = 0;
    } else if (month < 6) {
      // 왼쪽 2개
      x = 0;
      y = 90 + (month - 4) * 90;
    } else if (month < 8) {
      // 오른쪽 2개
      x = 520 - 48;
      y = 90 + (month - 6) * 90;
    } else {
      // 아래 행 4개
      x = 80 + (month - 8) * 90;
      y = 360 - 72;
    }
    return Offset(x, y);
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
      if (card.isBonus || (card.month > 0 && fieldMonths.contains(card.month))) {
        highlightHandIndexes.add(i);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2f4f2f),
      body: Stack(
        children: [
          // 메인 게임 화면
          GoStopBoard(
            key: boardKey,
            playerHand: playerHand,
            playerCaptured: groupCapturedByType([...engine.getCaptured(1), ...engine.pendingCaptured.where((c) => c.isBonus && engine.handBonusCard?.id == c.id)]),
            opponentCaptured: groupCapturedByType(engine.getCaptured(2)),
            tableCards: fieldCards,
            drawnCard: '',
            deckBackImage: 'assets/cards/back.png',
            opponentName: 'AI',
            playerScore: engine.calculateScore(1),
            opponentScore: engine.calculateScore(2),
            statusLabel: engine.currentPhase.toString(),
            onCardTap: (index) async {
              if (index < playerHand.length) {
                await onCardTap(playerHand[index]);
              }
            },
            effectBanner: null,
            lastCapturedType: null,
            lastCapturedIndex: null,
            opponentHandCount: opponentHand.length,
            isGoStopPhase: getIsAwaitingGoStop(),
            playedCard: null,
            capturedCards: null,
            onGo: getIsAwaitingGoStop() ? () => setState(() => engine.declareGo()) : null,
            onStop: getIsAwaitingGoStop()
              ? () {
                  setState(() => engine.declareStop());
                  _showGameOverDialog();
                }
              : null,
            highlightHandIndexes: highlightHandIndexes,
            cardStackController: cardDeckController,
            drawPileCount: drawPileCount,
            fieldCardKeys: fieldCardKeys,
            fieldStackKey: fieldStackKey,
            bonusCard: engine.bonusCard,
          ),
          
          // 활성 애니메이션들을 화면에 표시
          ...activeAnimations,
          
          // 로그 뷰어 버튼
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  showLogViewer = !showLogViewer;
                });
              },
              backgroundColor: Colors.black87,
              child: Icon(
                showLogViewer ? Icons.close : Icons.article,
                color: Colors.white,
              ),
            ),
          ),
          
          // 로그 뷰어
          if (showLogViewer)
            Positioned(
              top: 120,
              right: 20,
              child: GameLogViewer(
                logger: engine.logger,
                isVisible: showLogViewer,
              ),
            ),
        ],
      ),
    );
  }
}

// MatgoEngine 에 isGameOver() 메서드 추가 필요
extension MatgoEngineExtension on MatgoEngine {
  bool isGameOver() => gameOver;
}