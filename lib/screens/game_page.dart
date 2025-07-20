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
import '../widgets/animated_card_widget.dart';

// 애니메이션 상태 관리 클래스들
enum AnimationPhase {
  none,
  shuffle,
  deal,
  game
}

class AnimationStateManager {
  bool isAnimating = false;
  AnimationPhase currentPhase = AnimationPhase.none;
  
  void startAnimation(AnimationPhase phase) {
    isAnimating = true;
    currentPhase = phase;
  }
  
  void completeAnimation(AnimationPhase phase) {
    if (currentPhase == phase) {
      currentPhase = AnimationPhase.none;
      // 다음 애니메이션이 없을 때만 false
      if (!hasNextAnimation()) {
        isAnimating = false;
      }
    }
  }
  
  bool hasNextAnimation() {
    // 다음 애니메이션 예정 여부 확인
    return false;
  }
}

class DeckPositionCache {
  Offset? _cachedPosition;
  int _cachedCardCount = 0;
  
  Offset getDeckPosition(BuildContext context, int cardCount) {
    // 카드 수가 변경되지 않았다면 캐시된 위치 사용
    if (_cachedPosition != null && _cachedCardCount == cardCount) {
      return _cachedPosition!;
    }
    
    // 새로운 위치 계산
    final newPosition = _calculateDeckPosition(context, cardCount);
    _cachedPosition = newPosition;
    _cachedCardCount = cardCount;
    
    return newPosition;
  }
  
  Offset _calculateDeckPosition(BuildContext context, int cardCount) {
    // 셔플 애니메이션은 필드 영역의 정중앙에서 실행
        final Size screenSize = MediaQuery.of(context).size;
        final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    
    // 필드 영역의 정확한 위치 계산 (buildFieldArea와 동일한 로직)
    final fieldPanelRatio = 0.67; // 필드 영역이 화면의 67% 차지
    final fieldPanelHeight = screenSize.height - (minSide * 0.19) - (minSide * 0.10);
    final fieldWidth = screenSize.width * fieldPanelRatio;
    final fieldHeight = fieldPanelHeight;
    
    // 필드 영역의 중앙 좌표
    final fieldCenterX = fieldWidth / 2; // 필드 영역 내에서의 중앙 X
    final fieldCenterY = fieldHeight / 2; // 필드 영역 내에서의 중앙 Y
    
    // 카드 크기 계산
    final double deckCardWidth = minSide * 0.08;
    final double deckCardHeight = deckCardWidth * 1.5;
    
    // 카드더미의 top card 위치 계산
    final visibleCount = min(10, cardCount);
    final topCardOffsetX = (visibleCount - 1) * (deckCardWidth * 0.0625);
    final topCardOffsetY = (visibleCount - 1) * (deckCardHeight * 0.021);
    
    return Offset(
      fieldCenterX + topCardOffsetX,
      fieldCenterY + topCardOffsetY,
    );
  }
  
  void invalidateCache() {
    _cachedPosition = null;
    _cachedCardCount = 0;
  }
}

class CardStyleManager {
  static const double cardWidthRatio = 0.08;
  static const double cardHeightRatio = 1.5;
  static const double borderRadius = 8.0;
  static const double shadowBlur = 8.0;
  static const Offset shadowOffset = Offset(2, 4);
  
  static double getCardWidth(double minSide) => minSide * cardWidthRatio;
  static double getCardHeight(double minSide) => getCardWidth(minSide) * cardHeightRatio;
  
  static BoxDecoration getCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: shadowBlur,
          offset: shadowOffset,
        ),
      ],
    );
  }
}

// 전역 인스턴스들
final AnimationStateManager animationStateManager = AnimationStateManager();
final DeckPositionCache deckPositionCache = DeckPositionCache();

class GamePage extends StatefulWidget {
  final String mode;
  const GamePage({required this.mode, super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late MatgoEngine engine;
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late AnimationController _bounceController;
  late AnimationController _scaleController;

  // 애니메이션 상태 관리
  bool isAnimating = false;
  bool showDeck = true; // 카드더미 표시 여부
  List<Widget> activeAnimations = [];
  
  // 밤일낮장(선 결정) 관련 상태 변수들
  bool isPreGameSelection = true; // 밤일낮장 단계 여부
  bool isPlayerCardSelected = false; // 플레이어 카드 선택 여부
  bool isAiCardSelected = false; // AI 카드 선택 여부
  GoStopCard? playerSelectedCard; // 플레이어가 선택한 카드
  GoStopCard? aiSelectedCard; // AI가 선택한 카드
  List<GoStopCard> preGameCards = []; // 밤일낮장용 6장 카드
  int selectedCardIndex = -1; // 플레이어가 선택한 카드 인덱스
  bool isPreGameAnimating = false; // 밤일낮장 애니메이션 중 여부
  
  // 밤일낮장 결과 표시 관련 상태 변수들
  bool showPreGameResult = false; // 밤일낮장 결과 표시 여부
  String preGameResultMessage = ''; // 결과 메시지
  bool isPlayerFirst = false; // 플레이어가 선인지 여부
  int resultDisplayDuration = 0; // 결과 표시 지속 시간 (초)
  
  // 카드 분배 애니메이션 관련
  List<Map<String, dynamic>> dealingQueue = [];
  bool isDealing = false;
  int currentDealIndex = 0;
  
  late AnimationController _scoreAnimationController;
  late AnimationController _coinAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _floatingTextController;
  late AnimationController _bonusCardController;
  late AnimationController _bombController;
  late AnimationController _goStopController;
  late AnimationController _heundalController;
  late AnimationController _dealAnimationController;
  
  // 카드 분배 애니메이션 추적

  
  // 최근 플레이된 카드 위치(id -> Offset). 필드에 Key가 아직 없을 때 사용
  final Map<int, Offset> _recentCardPositions = {};
  
  // 덱 매니저와 카드 덱 컨트롤러
  late DeckManager deckManager;
  final CardDeckController cardDeckController = CardDeckController();
  
  // 긴장감 모드
  bool isTensionMode = false;

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
    
    // 첫 번째 프레임 이후에 밤일낮장 단계 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPreGameSelection();
    });
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
              activeAnimations.removeWhere((w) => w is FloatingTextEffect && (w).text == displayText);
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
                  final captureOffset = _getCardPosition('captured', matchedCard);
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
    
    // 애니메이션 중 체크 제거 - 카드 선택은 항상 가능하도록
    // if (isAnimating) return;
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
      
      // 안전장치: 3초 후에도 락이 남아있으면 강제 해제
      Future.delayed(const Duration(seconds: 3), () {
        if (engine.tapLock) {
          engine.tapLock = false;
        }
      });
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
      destinationOffset = _getCardPosition('captured', card);
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
            final GlobalKey? fk = fieldCardKeys[fc.id.toString()];
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
      
      // 안전장치: 3초 후에도 락이 남아있으면 강제 해제
      Future.delayed(const Duration(seconds: 3), () {
        if (engine.tapLock) {
          engine.tapLock = false;
        }
      });
      return;
    }
    
    await _flipCardFromDeck();
    
    // 애니메이션 완료 후 입력 락 해제
    engine.tapLock = false;
    
    // 안전장치: 3초 후에도 락이 남아있으면 강제 해제
    Future.delayed(const Duration(seconds: 3), () {
      if (engine.tapLock) {
    engine.tapLock = false;
      }
    });
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
        // AI 손패 카드 애니메이션 (간단한 버전)
          setState(() => engine.playCard(aiCardToPlay));
          SoundManager.instance.play(Sfx.cardPlay);
          
        // 간단한 지연 후 완료
        await Future.delayed(const Duration(milliseconds: 500));
          completer.complete();
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
      result = '${AppLocalizations.of(context)!.player1Win}\n${AppLocalizations.of(context)!.scoreVs(player1Score, player2Score)}';
      coinChange = player1Score; // 승자 점수만큼 코인 획득
      await CoinService.instance.addCoins(coinChange);
    } else if (player2Score > player1Score) {
      // 플레이어 2(AI) 승리
      result = '${AppLocalizations.of(context)!.player2Win}\n${AppLocalizations.of(context)!.scoreVs(player1Score, player2Score)}';
      coinChange = -player2Score; // AI 점수만큼 코인 차감
      await CoinService.instance.addCoins(coinChange);
    } else {
      // 무승부
      result = '${AppLocalizations.of(context)!.draw}\n${AppLocalizations.of(context)!.scoreVs(player1Score, player2Score)}';
      coinChange = 0;
    }
    
    // 코인 증감 결과 메시지 추가
    String coinMessage = "";
    if (coinChange > 0) {
      coinMessage = '\n\n${AppLocalizations.of(context)!.coinEarned(coinChange)}';
    } else if (coinChange < 0) {
      coinMessage = '\n\n${AppLocalizations.of(context)!.coinLost(coinChange)}';
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

  // capturedOverlapRow와 동일한 정확한 배치 좌표 계산 함수
  Offset _getExactCapturedPosition(GoStopCard card, int player) {
    final Size screenSize = MediaQuery.of(context).size;
    final minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final cardWidth = minSide * 0.0455;
    final cardHeight = cardWidth * 1.5;
    final overlapX = cardWidth * 0.45;
    final rowGap = cardHeight * 0.6;
    const maxPerRow = 5;
    
    // 획득 영역의 시작 위치 (실제 획득 영역 위치)
    // gostop_board.dart의 레이아웃을 참고하여 정확한 위치 계산
    final capturedY = player == 1 
        ? screenSize.height * 0.75  // 플레이어 획득 영역 (하단)
        : screenSize.height * 0.25; // AI 획득 영역 (상단)
    
    // 카드 타입별 그룹핑 (capturedOverlapRow와 동일한 로직)
    final order = ['광', '끗', '띠', '피'];
    final cardType = card.type == '동물' ? '끗' : card.type;
    final typeIndex = order.indexOf(cardType);
    
    // 타입별 수직 간격 (타입 라벨 + 카드 스택)
    final typeGap = cardWidth * 0.9; // capturedOverlapRow에서 사용하는 간격
    
    // 현재 타입 내에서의 카드 인덱스 계산
    final currentCaptured = engine.getCaptured(player);
    final typeCards = currentCaptured.where((c) => 
        (c.type == '동물' && cardType == '끗') || c.type == cardType
    ).toList();
    
    // 새로 추가될 카드의 인덱스
    final cardIndexInType = typeCards.length;
    final row = cardIndexInType ~/ maxPerRow;
    final col = cardIndexInType % maxPerRow;
    
    // 타입별 시작 위치 계산 (capturedOverlapRow와 정확히 동일한 계산)
    final totalTypeWidth = 4 * (cardWidth + typeGap) - typeGap; // 4개 타입의 총 너비
    final typeStartX = screenSize.width / 2 - totalTypeWidth / 2 + typeIndex * (cardWidth + typeGap);
    
    // 라벨 높이를 고려한 시작 Y 위치 (capturedOverlapRow의 실제 구조 반영)
    final labelHeight = cardHeight * 0.19; // 라벨 텍스트 높이
    final typeStartY = capturedY - cardHeight / 2 + labelHeight + cardHeight * 0.1; // 라벨 아래 여백
    
    // capturedOverlapRow와 동일한 정확한 좌표 계산
    return Offset(
      typeStartX + col * overlapX,
      typeStartY + row * rowGap,
    );
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
      // 획득 그룹이 아직 완전히 렌더링되지 않아서 fallback 좌표(유령 카드)가 반환되는 경우 fallback 좌표(임시 좌표)가 반환되는 경우가 있다.
      // 이런 경우 1프레임 대기 후 실제 위치로 재계산하여 실제 획득 위치 좌표를 사용하도록 수정했다.
      Size _screenSize = MediaQuery.of(context).size;
      Offset toOffset = _getCardPosition('captured', card, playerId: player);

      bool _isFallbackOffset(Offset o) {
        // player 1(하단) fallback: 임시 하단 좌표, player 2(상단) fallback: 임시 상단 좌표
        if (player == 1) {
          return (o.dx - (_screenSize.width / 2 - 48)).abs() < 2 &&
                 (o.dy - (_screenSize.height - 120)).abs() < 2;
        } else {
          return (o.dx - (_screenSize.width / 2 - 48)).abs() < 2 &&
                 (o.dy - 120).abs() < 2;
        }
      }

      if (_isFallbackOffset(toOffset)) {
        // 1프레임 대기 후 재계산(레이아웃 완료 대기)
        await Future.delayed(const Duration(milliseconds: 16));
        toOffset = _getCardPosition('captured', card, playerId: player);
      }

      // 획득 카드 크기 계산 (capturedOverlapRow와 동일한 방식)
      final screenSize = MediaQuery.of(context).size;
      final minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
      final capturedCardWidth = minSide * 0.0455;
      final capturedCardHeight = capturedCardWidth * 1.5;
      
      // 각 카드마다 200ms 간격으로 애니메이션 실행
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // 즉시 필드에서 카드 제거 + 애니메이션 위젯 추가를 한 번의 setState로 처리
      final uniqKey = UniqueKey();

      final anim = SimpleCardMoveAnimation(
        cardImage: card.imageUrl,
        startPosition: fromOffset,
        endPosition: toOffset,
        cardWidth: capturedCardWidth,
        cardHeight: capturedCardHeight,
        onComplete: () {
          // 애니메이션 완료 시 해당 카드를 즉시 획득 리스트에 추가 (기존 리스트 유지)
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

      // KeyedSubtree로 감싸서 List<Widget>에서의 고유 키 관리
      setState(() {
        engine.deckManager.fieldCards.removeWhere((c) => c.id == card.id);
        isAnimating = true;
        activeAnimations.add(KeyedSubtree(key: uniqKey, child: anim));
      });
    }
    // 모든 애니메이션이 끝난 후 별도로 _moveCardsToCaptured 호출할 필요 없음
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

  // 카드 위치 계산 함수 (실제 배치 위치 기반)
  Offset _getCardPosition(String area, GoStopCard card, {int? playerId}) {
    final Size screenSize = MediaQuery.of(context).size;
    final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    
    switch (area) {
      case 'deck':
        // 덱은 화면 중앙
        return Offset(
          screenSize.width / 2 - 36, // 카드 너비의 절반
          screenSize.height / 2 - 54, // 카드 높이의 절반
        );
        
      case 'field':
        // 필드 카드는 원형 배치 (월별)
        final month = card.month;
        if (month > 0 && month <= 12) {
          final radius = minSide * 0.28;
          final angle = ((month - 1) / 12) * 2 * pi - pi / 2;
          final centerX = screenSize.width / 2;
          final centerY = screenSize.height / 2;
          final fieldCardWidth = minSide * 0.13 * 0.8;
          final fieldCardHeight = fieldCardWidth * 1.5;
          
          return Offset(
            centerX + radius * cos(angle) - fieldCardWidth / 2,
            centerY + radius * sin(angle) - fieldCardHeight / 2,
          );
        }
        // 월이 0이거나 12 초과인 경우 중앙
        return Offset(
          screenSize.width / 2 - 36,
          screenSize.height / 2 - 54,
        );
        
      case 'hand':
        // 플레이어 손패 (하단)
        final handIndex = engine.getHand(1).indexWhere((c) => c.id == card.id);
        if (handIndex >= 0) {
          final handCardWidth = minSide * 0.13;
          final handCardHeight = handCardWidth * 1.5;
          final gap = handCardWidth * 0.08;
          final handY = screenSize.height * 0.85;
          final handX = screenSize.width / 2 + (handIndex - 4.5) * (handCardWidth + gap);
          
          return Offset(
            handX - handCardWidth / 2,
            handY - handCardHeight / 2,
          );
        }
        break;
        
      case 'player1':
        // 플레이어1 손패 (하단) - 실제 인덱스 사용
        final player1Index = engine.getHand(1).indexWhere((c) => c.id == card.id);
        if (player1Index >= 0) {
          final handCardWidth = minSide * 0.13;
          final handCardHeight = handCardWidth * 1.5;
          final gap = handCardWidth * 0.08;
          final handY = screenSize.height * 0.85;
          final handX = screenSize.width / 2 + (player1Index - 4.5) * (handCardWidth + gap);
          
          return Offset(
            handX - handCardWidth / 2,
            handY - handCardHeight / 2,
          );
        }
        // 분배 중인 경우 예상 인덱스 사용
        final expectedPlayer1Index = engine.getHand(1).length;
        final handCardWidth = minSide * 0.13;
        final handCardHeight = handCardWidth * 1.5;
        final gap = handCardWidth * 0.08;
        final handY = screenSize.height * 0.85;
        final handX = screenSize.width / 2 + (expectedPlayer1Index - 4.5) * (handCardWidth + gap);
        
        return Offset(
          handX - handCardWidth / 2,
          handY - handCardHeight / 2,
        );
        
      case 'player2':
        // 플레이어2(AI) 손패 (상단, 2줄 배치) - 실제 인덱스 사용
        final player2Index = engine.getHand(2).indexWhere((c) => c.id == card.id);
        if (player2Index >= 0) {
          final cardWidth = 48 * 0.4; // AI 카드 크기
          final cardHeight = 72 * 0.4;
          final gap = cardWidth * 0.12;
          final verticalGap = cardHeight * 0.15;
          final cardsPerRow = (engine.getHand(2).length / 2).ceil();
          
          int row, col;
          if (player2Index < cardsPerRow) {
            row = 0;
            col = player2Index;
          } else {
            row = 1;
            col = player2Index - cardsPerRow;
          }
          
          final aiHandY = screenSize.height * 0.15;
          final aiHandX = screenSize.width / 2 + (col - (cardsPerRow - 1) / 2) * (cardWidth + gap);
          final finalY = aiHandY + row * (cardHeight + verticalGap);
          
          return Offset(
            aiHandX - cardWidth / 2,
            finalY - cardHeight / 2,
          );
        }
        // 분배 중인 경우 예상 인덱스 사용
        final expectedPlayer2Index = engine.getHand(2).length;
        final cardWidth = 48 * 0.4; // AI 카드 크기
        final cardHeight = 72 * 0.4;
        final gap = cardWidth * 0.12;
        final verticalGap = cardHeight * 0.15;
        final cardsPerRow = ((expectedPlayer2Index + 1) / 2).ceil();
        
        int row, col;
        if (expectedPlayer2Index < cardsPerRow) {
          row = 0;
          col = expectedPlayer2Index;
        } else {
          row = 1;
          col = expectedPlayer2Index - cardsPerRow;
        }
        
        final aiHandY = screenSize.height * 0.15;
        final aiHandX = screenSize.width / 2 + (col - (cardsPerRow - 1) / 2) * (cardWidth + gap);
        final finalY = aiHandY + row * (cardHeight + verticalGap);
        
        return Offset(
          aiHandX - cardWidth / 2,
          finalY - cardHeight / 2,
        );
        
      case 'captured':
        // 카드 타입별 그룹핑 Key 설정
        String groupType = card.type;
        if (groupType == '동물') groupType = '끗';

        Offset? groupOffset;
        final GlobalKey? groupKey = playerId == 2
            ? boardKey.currentState?.getAiCapturedTypeKey(groupType)
            : boardKey.currentState?.getCapturedTypeKey(groupType);

        if (groupKey != null && groupKey.currentContext != null) {
          final RenderBox box = groupKey.currentContext!.findRenderObject() as RenderBox;
          groupOffset = box.localToGlobal(Offset.zero);
        }

        // fallback 좌표 (플레이어별 구분)
        Offset position = groupOffset ?? (playerId == 2
            ? Offset(screenSize.width / 2 - 48, 120)
            : Offset(screenSize.width / 2 - 48, screenSize.height - 120));

        // 카드 개별 overlap offset 조정(같은 타입의 카드들이 겹쳐서 이동) 
        final capturedList = engine.deckManager.capturedCards[(playerId ?? 1) - 1] ?? [];
        final grouped = groupCapturedByType(capturedList);
        int idxInGroup = 0;
        if (grouped.containsKey(groupType)) {
          idxInGroup = grouped[groupType]!.length; // 현재 카드 개수(새 카드 index)
        }

        // 카드 개별 overlapX 계산 (획득 카드 UI와 동일한 방식)
        final minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
        final cWidth = minSide * 0.0455;
        final overlapX = cWidth * 0.45;

        return position.translate(idxInGroup * overlapX, 0);
        
      case 'ai_captured':
        // AI 획득 영역 (상단)
        final aiCapturedY = screenSize.height * 0.25; // AI 획득 영역
        final aiCapturedX = screenSize.width / 2;
        
        return Offset(
          aiCapturedX - 36,
          aiCapturedY - 54,
        );
      case 'ai_hand':
        // AI 손패 (상단, 2줄 배치) - player2와 동일한 로직 사용
        final aiHandIndex = engine.getHand(2).indexWhere((c) => c.id == card.id);
        if (aiHandIndex >= 0) {
          final cardWidth = 48 * 0.4; // AI 카드 크기
          final cardHeight = 72 * 0.4;
          final gap = cardWidth * 0.12;
          final verticalGap = cardHeight * 0.15;
          final cardsPerRow = (engine.getHand(2).length / 2).ceil();
          
          int row, col;
          if (aiHandIndex < cardsPerRow) {
            row = 0;
            col = aiHandIndex;
          } else {
            row = 1;
            col = aiHandIndex - cardsPerRow;
          }
          
          final aiHandY = screenSize.height * 0.15;
          final aiHandX = screenSize.width / 2 + (col - (cardsPerRow - 1) / 2) * (cardWidth + gap);
          final finalY = aiHandY + row * (cardHeight + verticalGap);
          
          return Offset(
            aiHandX - cardWidth / 2,
            finalY - cardHeight / 2,
          );
        }
        // 분배 중인 경우 예상 인덱스 사용 (player2와 동일한 로직)
        final expectedAiHandIndex = engine.getHand(2).length;
        final cardWidth = 48 * 0.4; // AI 카드 크기
        final cardHeight = 72 * 0.4;
        final gap = cardWidth * 0.12;
        final verticalGap = cardHeight * 0.15;
        final cardsPerRow = ((expectedAiHandIndex + 1) / 2).ceil();
        
        int row, col;
        if (expectedAiHandIndex < cardsPerRow) {
          row = 0;
          col = expectedAiHandIndex;
        } else {
          row = 1;
          col = expectedAiHandIndex - cardsPerRow;
        }
        
        final aiHandY = screenSize.height * 0.15;
        final aiHandX = screenSize.width / 2 + (col - (cardsPerRow - 1) / 2) * (cardWidth + gap);
        final finalY = aiHandY + row * (cardHeight + verticalGap);
        
        return Offset(
          aiHandX - cardWidth / 2,
          finalY - cardHeight / 2,
        );
    }
    
    // 기본값: 화면 중앙
    return Offset(
      screenSize.width / 2 - 36,
      screenSize.height / 2 - 54,
    );
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
      result += '\n\n${AppLocalizations.of(context)!.coinLost(coinChange)}';
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final List<GoStopCard> playerHand = List<GoStopCard>.from(engine.getHand(1));
    final List<GoStopCard> opponentHand = List<GoStopCard>.from(engine.getHand(2));
    final List<GoStopCard> fieldCards = List<GoStopCard>.from(engine.getField());
    // 카드더미 개수 계산 (애니메이션 중에는 분배된 카드 수를 고려)
    final int drawPileCount = engine.deckManager.drawPile.isEmpty 
        ? engine.deckManager.drawPile.length
        : engine.drawPileCount;
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
              tableCards: isPreGameSelection ? [] : fieldCards, // 밤일낮장 단계에서는 필드 카드 숨기기
              drawnCard: '',
              deckBackImage: 'assets/cards/back.png',
              opponentName: 'AI',
              // 턴 종료 후 확정된 점수만 표시
              playerScore: _displayPlayerScore,
              opponentScore: _displayOpponentScore,
              statusLabel: isPreGameSelection ? '밤일낮장 - 선 결정' : engine.currentPhase.toString(),
              // 밤일낮장 관련 매개변수들
              isPreGameSelection: isPreGameSelection,
              preGameCards: isPreGameSelection ? preGameCards : null,
              selectedCardIndex: selectedCardIndex,
              isPlayerCardSelected: isPlayerCardSelected,
              isAiCardSelected: isAiCardSelected,
              playerSelectedCard: playerSelectedCard,
              aiSelectedCard: aiSelectedCard,
              onPreGameCardTap: isPreGameSelection ? _onPreGameCardTap : null,
              showPreGameResult: showPreGameResult,
              preGameResultMessage: preGameResultMessage,
              isPlayerFirst: isPlayerFirst,
              resultDisplayDuration: resultDisplayDuration,
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
              showDeck: isPreGameSelection ? false : showDeck, // 밤일낮장 단계에서는 카드더미 숨기기
              actualDeckCards: engine.deckManager.drawPile, // 실제 카드더미 카드 데이터 전달
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

  // 보너스피 애니메이션: engine.mdc 규칙에 따른 올바른 처리
  void _handleBonusCardAnimation(Map<String, dynamic> data) {
    final GoStopCard card = data['card'] as GoStopCard;
    final Function()? onComplete = data['onComplete'] as Function()?;

    // ① 카드더미 위치 (시작)
    final Offset deckOffset = _getCardPosition('deck', card);

    // ② 내가 낸 카드 위치 (필드가 아닌 내가 낸 카드 위)
    final GoStopCard? playedCard = engine.playedCard;
    if (playedCard == null) return; // 방어
    
    // 내가 낸 카드의 실제 위치 계산 (필드 위치가 아닌)
    final playedCardOffset = _getCardPosition('field', playedCard);

    setState(() {
      isAnimating = true;

      // 1단계: 카드더미에서 제자리 뒤집기 (400ms)
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

            // 2단계: 내가 낸 카드 위로 이동 (400ms)
            setState(() {
              activeAnimations.add(
                CardMoveAnimation(
                  cardImage: card.imageUrl,
                  startPosition: deckOffset,
                  endPosition: playedCardOffset,
                  withTrail: false,
                  duration: const Duration(milliseconds: 400),
                  onComplete: () {
                    setState(() {
                      activeAnimations.removeWhere((anim) => anim is CardMoveAnimation);
                      if (activeAnimations.isEmpty) isAnimating = false;
                    });
                    
                    // 3단계: pendingCaptured에 추가 (즉시, 애니메이션 없음)
                    // engine.pendingCaptured.add(card); // 엔진에서 처리됨
                    
                    // 4단계: 엔진 콜백 실행 (카드더미에서 한 장 더 뒤집기)
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

  // 카드 분배 시작 (애니메이션 없이 즉시 분배)
  Future<void> _startDealAnimation() async {
    // 셔플 애니메이션 먼저 실행
    await _runShuffleAnimation();
    
    // 즉시 카드 분배 (애니메이션 없음)
    _dealCardsImmediately();
    
    // 분배 완료 후 게임 시작
    _startGameAfterDeal();
  }

  // 셔플 애니메이션 실행
  Future<void> _runShuffleAnimation() async {
    print('🎯 셔플 애니메이션 시작');
    
    // 새로운 애니메이션 상태 매니저 사용
    animationStateManager.startAnimation(AnimationPhase.shuffle);
    
    // 셔플 중에는 카드더미 숨기기
    setState(() {
      showDeck = false; // 카드더미 숨기기
    });
    
    // 캐시된 위치 사용 (일관성 보장)
    final shuffleCenterPosition = deckPositionCache.getDeckPosition(
      context, 
      engine.deckManager.drawPile.length
    );
    
    print('🎯 셔플 중심 위치: $shuffleCenterPosition');
    
    // 셔플 애니메이션 실행
    setState(() {
      activeAnimations.add(
        ShuffleAnimationWidget(
          centerPosition: shuffleCenterPosition,
          cards: List.from(engine.deckManager.drawPile),
          onShuffleComplete: () {
            print('🎯 셔플 애니메이션 완료');
            setState(() {
              activeAnimations.removeWhere((anim) => anim is ShuffleAnimationWidget);
              // 셔플 완료 후 안정화 시간 대기
              Future.delayed(const Duration(milliseconds: 300), () {
                setState(() {
                  showDeck = true; // 카드더미 보이기
                });
                // 캐시 무효화 (분배 애니메이션에서 새로운 위치 계산)
                deckPositionCache.invalidateCache();
                // 애니메이션 상태 완료
                animationStateManager.completeAnimation(AnimationPhase.shuffle);
              });
            });
          },
        ),
      );
    });
    
    // 셔플 애니메이션 완료 대기
    while (activeAnimations.any((anim) => anim is ShuffleAnimationWidget)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('🎯 셔플 완료, 분배 시작');
  }

  // 즉시 카드 분배 (애니메이션 없음)
  void _dealCardsImmediately() {
    print('🎯 즉시 카드 분배 시작');
    
    // 정확한 고스톱 분배 규칙에 따라 카드 분배
    // === 첫 번째 분배 ===
    // 1. 필드에 4장
    for (int i = 0; i < 4; i++) {
      if (engine.deckManager.drawPile.isNotEmpty) {
        final card = engine.deckManager.drawPile.removeAt(0);
        engine.deckManager.fieldCards.add(card);
        print('🎯 필드 카드 추가: ${card.month}월 ${card.name}');
      }
    }
    
    // 2. 후공(AI)에 5장
    for (int i = 0; i < 5; i++) {
      if (engine.deckManager.drawPile.isNotEmpty) {
        final card = engine.deckManager.drawPile.removeAt(0);
        engine.deckManager.playerHands[1]!.add(card);
        print('🎯 AI 손패 추가: ${card.month}월 ${card.name}');
      }
    }
    
    // 3. 선공(사용자)에 5장
    for (int i = 0; i < 5; i++) {
      if (engine.deckManager.drawPile.isNotEmpty) {
        final card = engine.deckManager.drawPile.removeAt(0);
        engine.deckManager.playerHands[0]!.add(card);
        print('🎯 플레이어 손패 추가: ${card.month}월 ${card.name}');
      }
    }
    
    // === 두 번째 분배 ===
    // 4. 필드에 추가 4장
    for (int i = 0; i < 4; i++) {
      if (engine.deckManager.drawPile.isNotEmpty) {
        final card = engine.deckManager.drawPile.removeAt(0);
        engine.deckManager.fieldCards.add(card);
        print('🎯 필드 카드 추가: ${card.month}월 ${card.name}');
      }
    }
    
    // 5. 선공(사용자)에 추가 5장
    for (int i = 0; i < 5; i++) {
      if (engine.deckManager.drawPile.isNotEmpty) {
        final card = engine.deckManager.drawPile.removeAt(0);
        engine.deckManager.playerHands[0]!.add(card);
        print('🎯 플레이어 손패 추가: ${card.month}월 ${card.name}');
      }
    }
    
    // 6. 후공(AI)에 추가 5장
    for (int i = 0; i < 5; i++) {
      if (engine.deckManager.drawPile.isNotEmpty) {
        final card = engine.deckManager.drawPile.removeAt(0);
        engine.deckManager.playerHands[1]!.add(card);
        print('🎯 AI 손패 추가: ${card.month}월 ${card.name}');
      }
    }
    
    // 보너스 카드 처리
    _handleInitialBonusCards();
    
    // UI 업데이트
    setState(() {});
    
    print('🎯 즉시 카드 분배 완료');
    print('🎯 최종 상태: 필드 ${engine.deckManager.fieldCards.length}장, 플레이어 ${engine.deckManager.playerHands[0]!.length}장, AI ${engine.deckManager.playerHands[1]!.length}장');
    print('🎯 실제 덱 남은장: ${engine.deckManager.drawPile.length}장');
  }
  
  // 분배 완료 후 게임 시작
  void _startGameAfterDeal() {
    print('🎯 분배 완료 후 게임 시작');
    
    // 엔진 상태 초기화
    engine.currentPhase = TurnPhase.playingCard;
    engine.tapLock = false;
    
    print('🎯 엔진 상태 설정: currentPlayer=${engine.currentPlayer}, currentPhase=${engine.currentPhase}');
    
    // 선 플레이어가 1번(사용자)이면 바로 플레이어 턴 시작
    // 선 플레이어가 2번(AI)이면 AI 턴 시작
    if (engine.currentPlayer == 1) {
      print('🎯 플레이어 턴 시작 (선 플레이어)');
      // 플레이어 턴이므로 아무것도 하지 않음 (카드 선택 대기)
          } else {
      print('🎯 AI 턴 시작 (선 플레이어)');
      _runAiTurnIfNeeded();
    }
  }
  
  // 필드 카드들을 앞면으로 뒤집기
  Future<void> _flipFieldCards() async {
    print('🎯 필드 카드 뒤집기 시작');
    
    for (int i = 0; i < engine.deckManager.fieldCards.length; i++) {
      final card = engine.deckManager.fieldCards[i];
      final cardPosition = _getCardPosition('field', card);
      
      setState(() {
        isAnimating = true;
        activeAnimations.add(
          CardFlipAnimation(
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
      
      // 카드 뒤집기 효과음
      SoundManager.instance.play(Sfx.cardFlip);
      
      // 다음 카드 뒤집기까지 대기
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    print('🎯 필드 카드 뒤집기 완료');
  }
  
  // 초기 보너스 카드 처리
  void _handleInitialBonusCards() {
    var bonusCards = engine.deckManager.fieldCards.where((c) => c.isBonus).toList();
    while (bonusCards.isNotEmpty) {
      engine.deckManager.fieldCards.removeWhere((c) => c.isBonus);
      engine.deckManager.capturedCards[0]?.addAll(bonusCards);
      for (var i = 0; i < bonusCards.length; i++) {
        if (engine.deckManager.animationDeck.length > 28) {
          final newCard = engine.deckManager.animationDeck[28 + i];
          engine.deckManager.fieldCards.add(newCard);
        }
      }
      bonusCards = engine.deckManager.fieldCards.where((c) => c.isBonus).toList();
    }
  }

  // 밤일낮장(선 결정) 단계 시작
  Future<void> _startPreGameSelection() async {
    print('🎯 밤일낮장 단계 시작');
    
    // 셔플 효과음 재생
    SoundManager.instance.play(Sfx.cardFlip);
    
    // 밤일낮장용 6장 카드 준비 (보너스 제외)
    _setupPreGameCards();
    
    setState(() {
      isPreGameSelection = true;
      showDeck = false; // 카드더미 숨기기
    });
  }

  // 밤일낮장용 6장 카드 준비 (모든 카드가 다른 월이어야 함)
  void _setupPreGameCards() {
    // 보너스 카드를 제외한 일반 카드들만 필터링
    final normalCards = engine.deckManager.fullDeck
        .where((card) => !card.name.contains('보너스'))
        .toList();
    
    // 월별로 카드를 그룹화
    final Map<int, List<GoStopCard>> cardsByMonth = {};
    for (final card in normalCards) {
      if (card.month > 0 && card.month <= 12) {
        cardsByMonth.putIfAbsent(card.month, () => []).add(card);
      }
    }
    
    // 6개의 서로 다른 월을 랜덤 선택
    final availableMonths = cardsByMonth.keys.toList();
    List<int> selectedMonths;
    
    // 충분한 월이 없는 경우 예외 처리
    if (availableMonths.length < 6) {
      print('⚠️ 경고: 밤일낮장에 필요한 6개의 서로 다른 월이 부족합니다!');
      print('사용 가능한 월: ${availableMonths.length}개 (${availableMonths.join(', ')}월)');
      
      // 사용 가능한 월을 모두 사용하고, 부족한 만큼은 중복 허용
      availableMonths.shuffle();
      selectedMonths = <int>[];
      
      // 먼저 사용 가능한 월을 모두 추가
      selectedMonths.addAll(availableMonths);
      
      // 부족한 만큼 랜덤하게 추가 (중복 허용)
      while (selectedMonths.length < 6) {
        selectedMonths.add(availableMonths[Random().nextInt(availableMonths.length)]);
      }
      
      // 6개만 사용
      selectedMonths = selectedMonths.take(6).toList();
      
      print('⚠️ 중복 허용으로 밤일낮장 진행: ${selectedMonths.join(', ')}월');
    } else {
      availableMonths.shuffle();
      selectedMonths = availableMonths.take(6).toList();
    }
    
    // 각 월에서 1장씩 랜덤 선택
    preGameCards = [];
    for (final month in selectedMonths) {
      final monthCards = cardsByMonth[month]!;
      monthCards.shuffle();
      preGameCards.add(monthCards.first);
    }
    
    // 최종 카드 리스트도 셔플하여 랜덤한 순서로 배치
    preGameCards.shuffle();
    
    print('🎯 밤일낮장 카드 준비 (모든 월 다름): ${preGameCards.map((c) => '${c.month}월 ${c.name}').toList()}');
    
    // 검증: 모든 카드가 다른 월인지 확인
    final months = preGameCards.map((c) => c.month).toSet();
    if (months.length != 6) {
      print('⚠️ 경고: 밤일낮장 카드에 중복 월이 있습니다!');
      print('선택된 월들: $months');
    } else {
      print('✅ 검증 완료: 모든 카드가 서로 다른 월입니다.');
    }
  }

  // 플레이어가 밤일낮장 카드 선택
  void _onPreGameCardTap(int index) {
    if (isPreGameAnimating || isPlayerCardSelected) return;
    
    setState(() {
      selectedCardIndex = index;
      isPlayerCardSelected = true;
      playerSelectedCard = preGameCards[index];
    });
    
    print('🎯 플레이어 카드 선택: ${playerSelectedCard!.month}월 ${playerSelectedCard!.name}');
    
    // 카드 뒤집기 효과음
    SoundManager.instance.play(Sfx.cardFlip);
    
    // 0.5초 후 AI 카드 선택
    Future.delayed(const Duration(milliseconds: 500), () {
      _aiSelectCard();
    });
  }

  // AI 카드 선택
  void _aiSelectCard() {
    if (isPreGameAnimating || isAiCardSelected) return;
    
    // 플레이어가 선택하지 않은 카드 중에서 랜덤 선택
    final availableCards = <int>[];
    for (int i = 0; i < preGameCards.length; i++) {
      if (i != selectedCardIndex) {
        availableCards.add(i);
      }
    }
    
    final aiCardIndex = availableCards[Random().nextInt(availableCards.length)];
    
    setState(() {
      isAiCardSelected = true;
      aiSelectedCard = preGameCards[aiCardIndex];
    });
    
    print('🎯 AI 카드 선택: ${aiSelectedCard!.month}월 ${aiSelectedCard!.name}');
    
    // 카드 뒤집기 효과음
    SoundManager.instance.play(Sfx.cardFlip);
    
    // 1초 후 선 결정
    Future.delayed(const Duration(seconds: 1), () {
      _determineFirstPlayer();
    });
  }

  // 선 결정 및 정식 게임 시작
  void _determineFirstPlayer() {
    if (playerSelectedCard == null || aiSelectedCard == null) return;
    
    final playerMonth = playerSelectedCard!.month;
    final aiMonth = aiSelectedCard!.month;
    
    // 월 중복 검증 (밤일낮장에서는 같은 월이 나오면 안 됨)
    if (playerMonth == aiMonth) {
      print('⚠️ 경고: 플레이어와 AI가 같은 월을 선택했습니다! (${playerMonth}월)');
      print('🎯 밤일낮장 규칙에 따라 다시 카드를 선택합니다.');
      
      // 선택 상태 초기화하고 다시 시작
      setState(() {
        selectedCardIndex = -1;
        isPlayerCardSelected = false;
        isAiCardSelected = false;
        playerSelectedCard = null;
        aiSelectedCard = null;
      });
      
      // 새로운 밤일낮장 카드 준비
      _setupPreGameCards();
      return;
    }
    
    print('🎯 월 비교: 플레이어 ${playerMonth}월 vs AI ${aiMonth}월');
    
    // 월 비교로 선 결정
    int firstPlayer;
    String resultMessage;
    bool playerFirst;
    
    if (playerMonth > aiMonth) {
      firstPlayer = 1; // 플레이어가 선
      playerFirst = true;
      resultMessage = '🎯 플레이어가 선! (${playerMonth}월 > ${aiMonth}월)';
      print('🎯 선 결정: 플레이어 (${playerMonth}월 > ${aiMonth}월)');
    } else {
      firstPlayer = 2; // AI가 선
      playerFirst = false;
      resultMessage = '🎯 AI가 선! (${aiMonth}월 > ${playerMonth}월)';
      print('🎯 선 결정: AI (${aiMonth}월 > ${playerMonth}월)');
    }
    
    // 엔진에 선 플레이어 설정
    engine.currentPlayer = firstPlayer;
    
    // 결과 표시 시작
    setState(() {
      showPreGameResult = true;
      preGameResultMessage = resultMessage;
      isPlayerFirst = playerFirst;
      resultDisplayDuration = 0;
    });
    
    // 결과 표시 애니메이션 (3초간)
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        resultDisplayDuration++;
      });
      
      if (resultDisplayDuration >= 3) {
        timer.cancel();
        
        // 결과 표시 종료 후 밤일낮장 단계 종료
        setState(() {
          showPreGameResult = false;
          isPreGameSelection = false;
          isPreGameAnimating = false;
          showDeck = true; // 카드더미 보이기
        });
        
        // 정식 게임 시작 (셔플 애니메이션)
        _startDealAnimation();
      }
    });
  }

  // 밤일낮장 UI 구현
  Widget _buildPreGameSelectionUI() {
    final Size screenSize = MediaQuery.of(context).size;
    final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final double cardWidth = minSide * 0.12; // 밤일낮장 카드는 조금 크게
    final double cardHeight = cardWidth * 1.5;
    final double cardGap = cardWidth * 0.3;
    
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
                    image: AssetImage('assets/backgrounds/pink_glass_cards.png'),
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
            
            // 제목
            Positioned(
              top: screenSize.height * 0.1,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Text(
                    '밤일낮장 - 선 결정',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: minSide * 0.04,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            
            // 6장 카드 배치
            Positioned(
              top: screenSize.height * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: (cardWidth * 3) + (cardGap * 2),
                  height: (cardHeight * 2) + cardGap,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1 / 1.5,
                      crossAxisSpacing: cardGap,
                      mainAxisSpacing: cardGap,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final card = preGameCards[index];
                      final isSelected = selectedCardIndex == index;
                      final isPlayerCard = isPlayerCardSelected && selectedCardIndex == index;
                      final isAiCard = isAiCardSelected && aiSelectedCard == card;
                      
                      return GestureDetector(
                        onTap: () => _onPreGameCardTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          transform: Matrix4.identity()
                            ..scale(isSelected ? 1.1 : 1.0)
                            ..translate(0.0, isSelected ? -10.0 : 0.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected 
                                    ? Colors.amber.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.3),
                                  blurRadius: isSelected ? 12 : 8,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  // 카드 이미지
                                  Image.asset(
                                    isPlayerCard || isAiCard 
                                      ? card.imageUrl 
                                      : 'assets/cards/back.png',
                                    fit: BoxFit.cover,
                                  ),
                                  // 선택 표시
                                  if (isSelected)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isPlayerCard ? Icons.person : Icons.computer,
                                            color: Colors.amber,
                                            size: cardWidth * 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // 안내 텍스트
            Positioned(
              bottom: screenSize.height * 0.2,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    isPlayerCardSelected 
                      ? 'AI가 카드를 선택하는 중...'
                      : '카드를 선택하여 선을 결정하세요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: minSide * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            // 중복된 설정 버튼 제거됨
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

// 카드 분배 애니메이션 단계
enum DealPhase {
  pickup,     // 카드더미에서 집기
  arc,        // 호를 그리며 이동
  landing,    // 착지
  settling    // 안정화
}









// 셔플 애니메이션 위젯
class ShuffleAnimationWidget extends StatefulWidget {
  final Offset centerPosition;
  final List<GoStopCard> cards;
  final VoidCallback onShuffleComplete;

  const ShuffleAnimationWidget({
    required this.centerPosition,
    required this.cards,
    required this.onShuffleComplete,
    super.key,
  });

  @override
  State<ShuffleAnimationWidget> createState() => _ShuffleAnimationWidgetState();
}

class _ShuffleAnimationWidgetState extends State<ShuffleAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _cardController;
  
  // 애니메이션 단계별 컨트롤러
  late AnimationController _splitController;
  late AnimationController _interleaveController;
  late AnimationController _finalizeController;
  
  // 애니메이션 값들
  late Animation<double> _splitAnimation;
  late Animation<double> _interleaveAnimation;
  late Animation<double> _finalizeAnimation;
  
  // 카드 상태
  List<GoStopCard> leftCards = [];
  List<GoStopCard> rightCards = [];
  List<GoStopCard> shuffledCards = [];
  
  // 위치 계산
  Offset leftDeckPosition = Offset.zero;
  Offset rightDeckPosition = Offset.zero;
  
  // 현재 단계
  ShufflePhase currentPhase = ShufflePhase.initial;
  
  // 카드 개별 애니메이션
  Map<int, AnimationController> cardAnimations = {};
  Map<int, Animation<Offset>> cardMoveAnimations = {};
  Map<int, Animation<double>> cardScaleAnimations = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeShuffle();
    _startShuffleAnimation();
  }

  void _initializeControllers() {
    // 메인 컨트롤러
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800), // 1500 → 800ms로 단축
      vsync: this,
    );
    
    // 분할 컨트롤러
    _splitController = AnimationController(
      duration: const Duration(milliseconds: 300), // 500 → 300ms로 단축
      vsync: this,
    );
    
    // 인터리빙 컨트롤러
    _interleaveController = AnimationController(
      duration: const Duration(milliseconds: 400), // 800 → 400ms로 단축
      vsync: this,
    );
    
    // 완성 컨트롤러
    _finalizeController = AnimationController(
      duration: const Duration(milliseconds: 100), // 200 → 100ms로 단축
      vsync: this,
    );
    
    // 애니메이션 설정
    _splitAnimation = CurvedAnimation(
      parent: _splitController,
      curve: Curves.easeInOutCubic,
    );
    
    _interleaveAnimation = CurvedAnimation(
      parent: _interleaveController,
      curve: Curves.easeInOut,
    );
    
    _finalizeAnimation = CurvedAnimation(
      parent: _finalizeController,
      curve: Curves.easeOutBack,
    );
  }

  void _initializeShuffle() {
    // 카드를 두 개로 나누기
    final midPoint = widget.cards.length ~/ 2;
    leftCards = widget.cards.take(midPoint).toList();
    rightCards = widget.cards.skip(midPoint).toList();
    
    // 분할된 더미 위치 계산
    leftDeckPosition = widget.centerPosition + const Offset(-80, 0);
    rightDeckPosition = widget.centerPosition + const Offset(80, 0);
    
    // 개별 카드 애니메이션 초기화
    _initializeCardAnimations();
    
    print('🎯 셔플 초기화: 왼쪽 ${leftCards.length}장, 오른쪽 ${rightCards.length}장');
  }

  void _initializeCardAnimations() {
    // 왼쪽 카드들 애니메이션 초기화
    for (int i = 0; i < leftCards.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      
      final moveAnimation = Tween<Offset>(
        begin: widget.centerPosition,
        end: leftDeckPosition + Offset(0, i * 1.5),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutCubic,
      ));
      
      final scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      
      cardAnimations[i] = controller;
      cardMoveAnimations[i] = moveAnimation;
      cardScaleAnimations[i] = scaleAnimation;
    }
    
    // 오른쪽 카드들 애니메이션 초기화
    for (int i = 0; i < rightCards.length; i++) {
      final index = leftCards.length + i;
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      
      final moveAnimation = Tween<Offset>(
        begin: widget.centerPosition,
        end: rightDeckPosition + Offset(0, i * 1.5),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutCubic,
      ));
      
      final scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      
      cardAnimations[index] = controller;
      cardMoveAnimations[index] = moveAnimation;
      cardScaleAnimations[index] = scaleAnimation;
    }
  }

  Future<void> _startShuffleAnimation() async {
    print('🎯 셔플 애니메이션 시작');
    
    // 1단계: 분할
    await _splitPhase();
    
    // 2단계: 인터리빙
    await _interleavePhase();
    
    // 3단계: 완성
    await _finalizePhase();
    
    // 완료
    widget.onShuffleComplete();
  }

  Future<void> _splitPhase() async {
    print('🎯 셔플 1단계: 분할');
    setState(() {
      currentPhase = ShufflePhase.splitting;
    });
    
    // 분할 사운드
    SoundManager.instance.play(Sfx.cardPlay);
    
    // 왼쪽 카드들 분할 (매우 빠르게)
    for (int i = 0; i < leftCards.length; i++) {
      await Future.delayed(Duration(milliseconds: 5 + (i * 3))); // 20 + (i * 10) → 5 + (i * 3)
      cardAnimations[i]?.forward();
    }
    
    // 오른쪽 카드들 분할 (매우 빠르게)
    for (int i = 0; i < rightCards.length; i++) {
      final index = leftCards.length + i;
      await Future.delayed(Duration(milliseconds: 5 + (i * 3))); // 20 + (i * 10) → 5 + (i * 3)
      cardAnimations[index]?.forward();
    }
    
    // 분할 완료 대기 (매우 단축)
    await Future.delayed(const Duration(milliseconds: 200)); // 400 → 200ms
  }

  Future<void> _interleavePhase() async {
    print('🎯 셔플 2단계: 인터리빙');
    setState(() {
      currentPhase = ShufflePhase.interleaving;
    });
    
    // 인터리빙 애니메이션 시작
    _interleaveController.forward();
    
    // 카드들이 번갈아가며 중앙으로 이동 (매우 빠르게)
    int leftIndex = 0;
    int rightIndex = 0;
    
    while (leftIndex < leftCards.length || rightIndex < rightCards.length) {
      // 왼쪽 더미에서 카드 이동
      if (leftIndex < leftCards.length) {
        shuffledCards.add(leftCards[leftIndex]);
        leftIndex++;
        
        // 인터리빙 사운드
        SoundManager.instance.play(Sfx.cardPlay);
        await Future.delayed(const Duration(milliseconds: 25)); // 60 → 25ms
      }
      
      // 오른쪽 더미에서 카드 이동
      if (rightIndex < rightCards.length) {
        shuffledCards.add(rightCards[rightIndex]);
        rightIndex++;
        
        // 인터리빙 사운드
        SoundManager.instance.play(Sfx.cardPlay);
        await Future.delayed(const Duration(milliseconds: 25)); // 60 → 25ms
      }
    }
    
    // 인터리빙 완료 대기 (매우 단축)
    await Future.delayed(const Duration(milliseconds: 150)); // 300 → 150ms
  }

  Future<void> _finalizePhase() async {
    print('🎯 셔플 3단계: 완성');
    setState(() {
      currentPhase = ShufflePhase.finalizing;
    });
    
    // 완성 사운드
    SoundManager.instance.play(Sfx.cardPlay);
    
    // 최종 정렬 애니메이션
    _finalizeController.forward();
    
    // 완성 대기 (매우 단축)
    await Future.delayed(const Duration(milliseconds: 100)); // 200 → 100ms
    
    // 셔플 완료 시점에 카드더미를 바로 표시 (새로 렌더링하지 않음)
    setState(() {
      currentPhase = ShufflePhase.completed; // 완료 상태로 변경
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _splitController.dispose();
    _interleaveController.dispose();
    _finalizeController.dispose();
    
    // 개별 카드 애니메이션 정리
    for (final controller in cardAnimations.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 필드카드 수준의 크기 계산
    final Size screenSize = MediaQuery.of(context).size;
    final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final double deckCardWidth = minSide * 0.08; // 0.13 → 0.08 (필드카드 수준)
    final double deckCardHeight = deckCardWidth * 1.5;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _splitController,
        _interleaveController,
        _finalizeController,
        ...cardAnimations.values,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            // 분할 단계: 카드들이 양쪽으로 분리
            if (currentPhase == ShufflePhase.splitting) ...[
              ...leftCards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;
                final animation = cardMoveAnimations[index];
                final scaleAnimation = cardScaleAnimations[index];
                
                if (animation == null || scaleAnimation == null) return const SizedBox.shrink();
                
                return Positioned(
                  left: animation.value.dx - (deckCardWidth / 2), // 카드 중심점 기준
                  top: animation.value.dy - (deckCardHeight / 2),  // 카드 중심점 기준
                  child: Transform.scale(
                    scale: scaleAnimation.value,
                    child: _buildShuffleCard(card, false),
                  ),
                );
              }),
              
              ...rightCards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;
                final animationIndex = leftCards.length + index;
                final animation = cardMoveAnimations[animationIndex];
                final scaleAnimation = cardScaleAnimations[animationIndex];
                
                if (animation == null || scaleAnimation == null) return const SizedBox.shrink();
                
                return Positioned(
                  left: animation.value.dx - (deckCardWidth / 2),
                  top: animation.value.dy - (deckCardHeight / 2),
                  child: Transform.scale(
                    scale: scaleAnimation.value,
                    child: _buildShuffleCard(card, false),
                  ),
                );
              }),
            ],
            
            // 인터리빙 단계: 카드들이 중앙으로 모임
            if (currentPhase == ShufflePhase.interleaving) ...[
              ...shuffledCards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;
                final progress = _interleaveAnimation.value;
                final cardProgress = (index / shuffledCards.length).clamp(0.0, 1.0);
                
                // 카드가 중앙으로 이동하는 애니메이션
                final startX = index % 2 == 0 ? leftDeckPosition.dx : rightDeckPosition.dx;
                final startY = leftDeckPosition.dy + (index ~/ 2) * 1.5;
                final endX = widget.centerPosition.dx;
                final endY = widget.centerPosition.dy + (index * 1.5);
                
                final currentX = startX + (endX - startX) * cardProgress * progress;
                final currentY = startY + (endY - startY) * cardProgress * progress;
                
                return Positioned(
                  left: currentX - (deckCardWidth / 2),
                  top: currentY - (deckCardHeight / 2),
                  child: _buildShuffleCard(card, false),
                );
              }),
            ],
            
            // 완성 단계: 최종 카드더미
            if (currentPhase == ShufflePhase.finalizing || currentPhase == ShufflePhase.completed) ...[
              ...shuffledCards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;
                final progress = currentPhase == ShufflePhase.finalizing ? _finalizeAnimation.value : 1.0;
                
                // 카드가 최종 위치로 정렬
                final finalX = widget.centerPosition.dx;
                final finalY = widget.centerPosition.dy + (index * 1.5);
                
                return Positioned(
                  left: finalX - (deckCardWidth / 2),
                  top: finalY - (deckCardHeight / 2),
                  child: Transform.scale(
                    scale: currentPhase == ShufflePhase.finalizing ? (0.8 + (0.2 * progress)) : 1.0,
                    child: _buildShuffleCard(card, false),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildShuffleCard(GoStopCard card, bool isFaceUp) {
    // 필드카드 수준의 크기로 줄임
    final Size screenSize = MediaQuery.of(context).size;
    final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final double deckCardWidth = minSide * 0.08; // 0.13 → 0.08 (필드카드 수준)
    final double deckCardHeight = deckCardWidth * 1.5;
    
    return Container(
      width: deckCardWidth,
      height: deckCardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          isFaceUp ? card.imageUrl : 'assets/cards/back.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// 셔플 단계 열거형
enum ShufflePhase {
  initial,
  splitting,
  interleaving,
  finalizing,
  completed,
}

// 애니메이션 풀과 보드 키
final AnimationPool animationPool = AnimationPool();
final GlobalKey<GoStopBoardState> boardKey = GlobalKey<GoStopBoardState>();

// 획득카드 애니메이션 위젯 - 애니메이션 완료 후 이미지를 재사용해서 획득영역에 배치
class CapturedCardAnimation extends StatefulWidget {
  final String cardImage;
  final Offset startPosition;
  final Offset endPosition;
  final double cardWidth;
  final double cardHeight;
  final VoidCallback onComplete;
  final Duration duration;

  const CapturedCardAnimation({
    super.key,
    required this.cardImage,
    required this.startPosition,
    required this.endPosition,
    required this.cardWidth,
    required this.cardHeight,
    required this.onComplete,
    required this.duration,
  });

  @override
  State<CapturedCardAnimation> createState() => _CapturedCardAnimationState();
}

class _CapturedCardAnimationState extends State<CapturedCardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isCompleted = true;
        });
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 애니메이션 완료 후에는 획득영역에 고정 배치 (이미지 재사용)
    if (_isCompleted) {
      return Positioned(
        left: widget.endPosition.dx,
        top: widget.endPosition.dy,
        child: Image.asset(
          widget.cardImage,
          width: widget.cardWidth,
          height: widget.cardHeight,
          fit: BoxFit.contain,
        ),
      );
    }

    // 애니메이션 중에는 이동 애니메이션
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: _animation.value.dx,
          top: _animation.value.dy,
          child: Image.asset(
            widget.cardImage,
            width: widget.cardWidth,
            height: widget.cardHeight,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}