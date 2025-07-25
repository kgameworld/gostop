import 'dart:math';

import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../widgets/card_widget.dart';
import '../widgets/card_deck_widget.dart';
import '../widgets/profile_card.dart';
import '../utils/coin_service.dart';
import '../l10n/app_localizations.dart';

// 피 점수 계산 (쌍피, 쓰리피, 보너스 포함)
int countPiScore(List<String> images) {
  int total = 0;
  for (final img in images) {
    if (img.contains('3pi')) {
      total += 3;
    } else if (img.contains('ssangpi')) {
      total += 2;
    } else {
      total += 1;
    }
  }
  return total;
}

Widget overlappedCardStack(List<String> images, {bool showBadge = false, double cardWidth = 48, double cardHeight = 72, double overlapX = 20}) {
  final badgeCount = showBadge ? countPiScore(images) : null;
  
  return Stack(
    clipBehavior: Clip.none,
    children: [
      for (int i = 0; i < images.length; i++)
        Positioned(
          left: i * overlapX, // 겹치는 정도 비율 적용
          child: CardWidget(
            key: ValueKey('${images[i]}_$i'), // 중복 이미지 대비 index 포함 고유 Key
            imageUrl: images[i],
            width: cardWidth,
            height: cardHeight,
          ),
        ),
      if (showBadge && badgeCount != null && images.isNotEmpty)
        Positioned(
          left: (images.length - 1) * overlapX + cardWidth * 0.67,
          top: -cardHeight * 0.11,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.17, vertical: cardHeight * 0.06),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardHeight * 0.17),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              '$badgeCount',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: cardHeight * 0.22,
              ),
            ),
          ),
        ),
    ],
  );
}

// 카드 타입 한글 → 다국어 변환 함수
String getTypeLabel(BuildContext context, String type) {
  switch (type) {
    case '광':
      return AppLocalizations.of(context)!.bright;
    case '띠':
      return AppLocalizations.of(context)!.ribbon;
    case '피':
      return AppLocalizations.of(context)!.junk;
    case '끗':
      return AppLocalizations.of(context)!.animal;
    default:
      return type;
  }
}

Widget capturedOverlapRow(BuildContext context, Map<String, List<String>> captured,
    {bool isPlayer = true, Map<String, GlobalKey>? capturedKeys}) {
  const order = ['광', '끗', '띠', '피'];
  const int maxPerRow = 5;

  final screenWidth = WidgetsBinding.instance.window.physicalSize.width /
      WidgetsBinding.instance.window.devicePixelRatio;
  final screenHeight = WidgetsBinding.instance.window.physicalSize.height /
      WidgetsBinding.instance.window.devicePixelRatio;
  final minSide = screenWidth < screenHeight ? screenWidth : screenHeight;
  final cardWidth = minSide * 0.0455;
  final cardHeight = cardWidth * 1.5;
  final overlapX = cardWidth * 0.45;
  final fixedWidth = cardWidth + overlapX * (maxPerRow - 1);
  final rowGap = cardHeight * 0.6;

  // 피 점수 계산 함수 (일반피=1, 쌍피=2, 쓰리피=3, 보너스 포함)
  int _calculatePiScore(List<String> piCards) {
    int totalScore = 0;
    for (final cardPath in piCards) {
      if (cardPath.contains('bonus_3pi') || (cardPath.contains('3pi') && cardPath.contains('bonus'))) {
        totalScore += 3; // 보너스 쓰리피
      } else if (cardPath.contains('bonus_ssangpi') || (cardPath.contains('ssangpi') && cardPath.contains('bonus'))) {
        totalScore += 2; // 보너스 쌍피
      } else if (cardPath.contains('3pi')) {
        totalScore += 3; // 쓰리피
      } else if (cardPath.contains('ssangpi')) {
        totalScore += 2; // 쌍피
      } else {
        totalScore += 1; // 일반피
      }
    }
    return totalScore;
  }

  Widget buildStack(List<String> list, {bool showBadge = false, Key? stackKey}) {
    final rows = ((list.length - 1) ~/ maxPerRow) + 1;
    return SizedBox(
      key: stackKey,
      width: fixedWidth,
      height: cardHeight + (rows - 1) * rowGap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int idx = 0; idx < list.length; idx++)
            Positioned(
              left: (idx % maxPerRow) * overlapX,
              top: (idx ~/ maxPerRow) * rowGap,
              child: Image.asset(
                list[idx],
                width: cardWidth,
                height: cardHeight,
                fit: BoxFit.contain,
              ),
            ),
          if (showBadge && list.isNotEmpty)
            Positioned(
              right: 0,
              top: -6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_calculatePiScore(list)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: cardHeight * 0.22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final type in order) ...[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    getTypeLabel(context, type),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: cardHeight * 0.19),
                  ),
                ),
                if (type == '피') ...[
                  SizedBox(width: cardWidth * 0.3),
                  Builder(builder: (context) {
                    List<String> list = captured[type] ?? [];
                    if (list.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_calculatePiScore(list)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: cardHeight * 0.19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ],
            ),
            Builder(builder: (context) {
              List<String> list;
              if (type == '끗') {
                list = captured['동물'] ?? [];
              } else {
                list = captured[type] ?? [];
              }
              final keyName = type == '끗' ? '동물' : type;
              return buildStack(list,
                  showBadge: false, // 피는 라벨 옆에 표시하므로 뱃지 제거
                  stackKey: capturedKeys?[keyName]);
            }),
          ],
        ),
        SizedBox(width: cardWidth * 0.9),
      ]
    ],
  );
}

class _AnimatedDrawnCard extends StatefulWidget {
  final String backImage;
  final String frontImage;
  final Offset start;
  final Offset end;
  final bool flip;
  final VoidCallback? onEnd;
  final bool toCaptured;
  final Offset? capturedOffset;
  const _AnimatedDrawnCard({
    required this.backImage,
    required this.frontImage,
    required this.start,
    required this.end,
    required this.flip,
    this.onEnd,
    required this.toCaptured,
    this.capturedOffset,
  });
  @override
  State<_AnimatedDrawnCard> createState() => _AnimatedDrawnCardState();
}

class _AnimatedDrawnCardState extends State<_AnimatedDrawnCard> with TickerProviderStateMixin {
  late AnimationController moveCtrl;
  late AnimationController flipCtrl;
  late AnimationController scaleCtrl;
  late Animation<Offset> moveAnim;
  late Animation<double> flipAnim;
  late Animation<double> scaleAnim;
  bool movedToCaptured = false;

  @override
  void initState() {
    super.initState();
    moveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    moveAnim = Tween<Offset>(begin: widget.start, end: widget.end)
        .animate(CurvedAnimation(parent: moveCtrl, curve: Curves.easeInOut));
    flipAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: flipCtrl, curve: Curves.easeInOut));
    // 중앙에서 확대 후 다시 축소: 0~0.4까지 1.0, 0.4~0.7까지 2.0, 0.7~1.0까지 1.0
    scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 2.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 2.0, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: scaleCtrl, curve: Curves.easeInOut));

    // 애니메이션 시퀀스: 이동+확대 → 뒤집기 → 스케일
    moveCtrl.forward();
    scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && widget.flip) flipCtrl.forward();
    });
    moveCtrl.addListener(() => setState(() {}));
    flipCtrl.addListener(() => setState(() {}));
    scaleCtrl.addListener(() => setState(() {}));
    moveCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.toCaptured && widget.capturedOffset != null) {
        setState(() { movedToCaptured = true; });
        Future.delayed(const Duration(milliseconds: 400), () {
          widget.onEnd?.call();
        });
      } else if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          widget.onEnd?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    moveCtrl.dispose();
    flipCtrl.dispose();
    scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = movedToCaptured && widget.capturedOffset != null ? widget.capturedOffset! : moveAnim.value;
    final angle = flipAnim.value * pi;
    final isBack = angle < pi / 2;
    final scale = scaleAnim.value;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(2, 8),
              ),
            ],
            border: Border.all(color: Colors.amber, width: scale > 1.5 ? 4 : 0),
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: SizedBox(
              width: 48,
              height: 72,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(isBack ? 0 : pi),
                child: Image.asset(
                  isBack ? widget.backImage : widget.frontImage,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GoStopBoard extends StatefulWidget {
  final List<GoStopCard> playerHand;
  final Map<String, List<String>> playerCaptured;
  final Map<String, List<String>> opponentCaptured;
  final List<GoStopCard> tableCards;
  final String drawnCard;
  final String deckBackImage;
  final String opponentName;
  final int playerScore;
  final int opponentScore;
  final String statusLabel;
  final Function(int)? onCardTap;
  final String? effectBanner;
  final String? lastCapturedType;
  final int? lastCapturedIndex;
  final int opponentHandCount;
  final bool isGoStopPhase;
  final String? playedCard;
  final List<String>? capturedCards;
  final VoidCallback? onGo;
  final VoidCallback? onStop;
  final List<int> highlightHandIndexes;
  final CardDeckController? cardStackController;
  final int? drawPileCount;
  final Map<String, GlobalKey>? fieldCardKeys;
  final GlobalKey? fieldStackKey;
  final GoStopCard? bonusCard; // 카드더미에서 깐 보너스피
  // engine 인스턴스 직접 전달
  final dynamic engine;
  // 플레이어가 직접 GO/STOP 선택해야 할 때 자동 호출을 막기 위한 플래그
  final bool autoGoStop; // true: onGo 콜백을 자동 실행, false: 사용자가 직접 눌러야 함

  const GoStopBoard({
    super.key,
    required this.playerHand,
    required this.playerCaptured,
    required this.opponentCaptured,
    required this.tableCards,
    required this.drawnCard,
    required this.deckBackImage,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.statusLabel,
    this.onCardTap,
    this.effectBanner,
    this.lastCapturedType,
    this.lastCapturedIndex,
    required this.opponentHandCount,
    required this.isGoStopPhase,
    this.autoGoStop = false,
    this.playedCard,
    this.capturedCards,
    this.onGo,
    this.onStop,
    required this.highlightHandIndexes,
    this.cardStackController,
    this.drawPileCount,
    this.fieldCardKeys,
    this.fieldStackKey,
    this.bonusCard,
    this.engine,
  });

  @override
  State<GoStopBoard> createState() => GoStopBoardState();
}

class GoStopBoardState extends State<GoStopBoard> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool showEffect = false;
  int? selectedHandIndex;
  bool isDealing = true;
  int dealStep = 0;
  final int totalDealCount = 28; // 2인 맞고: 10+10+8

  // GO/STOP 다이얼로그 중복 방지 플래그
  bool _goStopDialogShown = false;
  
  // 애니메이션 상태
  String? animDrawnFront;
  bool animatingDraw = false;
  Offset animStart = Offset.zero;
  Offset animEnd = Offset.zero;
  bool animToCaptured = false;
  Offset? animCapturedOffset;
  
  // 손패 카드 애니메이션 상태
  Map<int, AnimationController> handCardAnimations = {};
  Map<int, Offset> handCardTargetPositions = {};
  Map<int, bool> handCardAnimating = {};
  
  // 손패 카드별 GlobalKey 관리
  final Map<int, GlobalKey> handCardKeys = {};
  
  // 카드더미 위치를 저장할 GlobalKey
  final GlobalKey deckKey = GlobalKey();
  // 12개 그룹용 빈자리 GlobalKey
  final List<Key> emptyGroupKeys = List.generate(12, (_) => GlobalKey());
  
  // 획득 영역 GlobalKey (플레이어용)
  final Map<String, GlobalKey> playerCapturedKeys = {
    '광': GlobalKey(),
    '띠': GlobalKey(),
    '동물': GlobalKey(),
    '피': GlobalKey(),
  };
  
  // 획득 영역 GlobalKey (AI용)
  final Map<String, GlobalKey> aiCapturedKeys = {
    '광': GlobalKey(),
    '띠': GlobalKey(),
    '동물': GlobalKey(),
    '피': GlobalKey(),
  };

  void playEatAnimation(int handIndex, int fieldIndex) {
    // 애니메이션 로직은 나중에 구현
  }

  void triggerDrawAnimation(String frontImage, {bool toCaptured = false, Offset? capturedOffset}) {
    if (mounted) {
      // 카드더미의 실제 위치 계산
      final RenderBox? deckRenderBox = deckKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? screenRenderBox = context.findRenderObject() as RenderBox?;
      
      if (deckRenderBox != null && screenRenderBox != null) {
        final deckPosition = deckRenderBox.localToGlobal(Offset.zero, ancestor: screenRenderBox);
        final deckSize = deckRenderBox.size;
        
        // 카드더미 중앙에서 시작
        final startX = deckPosition.dx + deckSize.width / 2 - 36; // 카드 너비의 절반
        final startY = deckPosition.dy + deckSize.height / 2 - 48; // 카드 높이의 절반
        
        // 필드 중앙으로 이동
        final screenSize = MediaQuery.of(context).size;
        final endX = screenSize.width / 2 - 36;
        final endY = screenSize.height / 2 - 48;
        
        setState(() {
          animDrawnFront = frontImage;
          animatingDraw = true;
          animStart = Offset(startX, startY);
          animEnd = Offset(endX, endY);
          animToCaptured = toCaptured;
          animCapturedOffset = capturedOffset;
        });
        
        // 애니메이션 완료 후 상태 초기화
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              animatingDraw = false;
              animDrawnFront = null;
            });
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 300), _dealNextCard);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 화면 회전 시 모든 애니메이션 컨트롤러 정지
    for (final controller in handCardAnimations.values) {
      controller.stop();
    }
    // 다음 프레임에서 카드 위치 재설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        resetCardPositions();
      }
    });
  }

  void resetCardPositions() {
    setState(() {
      // 카드 위치 초기화
      handCardAnimating.clear();
      handCardTargetPositions.clear();
    });
  }

  void _dealNextCard() {
    if (dealStep < totalDealCount) {
      setState(() => dealStep++);
      Future.delayed(const Duration(milliseconds: 80), _dealNextCard);
    } else {
      if (isDealing) {
      setState(() => isDealing = false);
      }
    }
  }

  void _onHandCardTap(int idx) {
    // 애니메이션 로직 제거 후 콜백만 직접 호출
    widget.onCardTap?.call(idx);
  }

  // 손패 카드 애니메이션 함수
  void animateHandCard(int cardIndex, Offset targetPosition, VoidCallback onComplete) {
    if (handCardAnimating[cardIndex] == true) return; // 이미 애니메이션 중이면 무시

    // 위치 측정은 반드시 프레임 이후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        handCardAnimating[cardIndex] = true;
        handCardTargetPositions[cardIndex] = targetPosition;
      });

      // 애니메이션 완료 후 콜백 실행
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            handCardAnimating[cardIndex] = false;
            handCardTargetPositions.remove(cardIndex);
          });
          onComplete();
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant GoStopBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effectBanner != null && widget.effectBanner != oldWidget.effectBanner) {
      setState(() => showEffect = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => showEffect = false);
      });
    }
  }

  Widget _opponentHandZone() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.opponentHandCount, (i) =>
        CardWidget(
          imageUrl: widget.deckBackImage,
          isFaceDown: true,
          width: 48 * 0.2, // 기존 크기의 20%
          height: 72 * 0.2, // 기존 크기의 20%
        )
      ),
    );
  }

  Widget _fieldZone() {
    // 필드 zone 디버깅 로그 추가
    print('[필드 zone] 현재 필드 카드: ${widget.tableCards.map((c) => '${c.id}(${c.name})[월${c.month}]').join(', ')}');

    // 1. 카드를 월별로 그룹화
    final Map<int, List<GoStopCard>> monthlyCards = {};
    final List<GoStopCard> otherCards = [];
    for (final card in widget.tableCards) {
      if (card.month > 0) {
        monthlyCards.putIfAbsent(card.month, () => []).add(card);
      } else {
        otherCards.add(card);
      }
    }

    // 필드 카드별 GlobalKey를 관리하는 맵의 타입을 Map<String, Key>로 변경
    final Map<String, Key> fieldCardKeys = widget.fieldCardKeys ?? {};

    // 한글 주석: 사각형 그리드(4x3)로 필드카드 배치
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridRows = 3;
        final gridCols = 4;
        final minSide = constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight;
        final cardWidth = minSide * 0.13 * 0.8; // 기존 비율 유지
        final cardHeight = cardWidth * 1.5;
        final hGap = (constraints.maxWidth - (cardWidth * gridCols)) / (gridCols + 1);
        final vGap = (constraints.maxHeight - (cardHeight * gridRows)) / (gridRows + 1);
        // 필드카드 12장(월별)만 사각형 그리드에 배치
        List<Widget> stackChildren = [];
        int cardIdx = 0;
        for (int row = 0; row < gridRows; row++) {
          for (int col = 0; col < gridCols; col++) {
            if (cardIdx >= 12) break;
            final month = cardIdx + 1;
            final cards = monthlyCards[month] ?? [];
            final left = hGap + col * (cardWidth + hGap);
            final top = vGap + row * (cardHeight + vGap);
            Widget groupWidget;
            if (cards.isEmpty) {
              groupWidget = Container(key: emptyGroupKeys[cardIdx], width: cardWidth, height: cardHeight, color: Colors.transparent);
            } else if (cards.length == 1) {
              final key = emptyGroupKeys[cardIdx];
              fieldCardKeys[cards.first.id.toString()] = key;
              groupWidget = CardWidget(
                key: key,
                imageUrl: cards.first.imageUrl,
                width: cardWidth,
                height: cardHeight,
              );
            } else {
              // 겹침(최대 3장) 처리
              groupWidget = SizedBox(
                width: cardWidth + (cards.length - 1) * (cardWidth * 0.3),
                height: cardHeight + (cards.length - 1) * (cardHeight * 0.11),
                child: Stack(
                  children: [
                    for (int j = 0; j < cards.length; j++)
                      Positioned(
                        left: j * (cardWidth * 0.3),
                        top: j * (cardHeight * 0.11),
                        child: (() {
                          // 한글 주석: 겹침 카드의 GlobalKey를 fieldCardKeys 맵에 저장하여 애니메이션에서 실제 위치를 계산할 수 있도록 함
                          // 두 번째 이후 겹침 카드에도 GlobalKey를 사용해 타입 불일치(TypeError) 방지
                          final key = j == 0 ? emptyGroupKeys[cardIdx] : GlobalKey();
                          fieldCardKeys[cards[j].id.toString()] = key;
                          return CardWidget(
                            key: key,
                            imageUrl: cards[j].imageUrl,
                            width: cardWidth,
                            height: cardHeight,
                          );
                        })(),
                      ),
                  ],
                ),
              );
            }
            stackChildren.add(Positioned(
              left: left,
              top: top,
              child: groupWidget,
            ));
            cardIdx++;
          }
        }
        // 기타 카드(월 0/12초과)는 무시 또는 별도 배치 가능
        // 카드더미(필드 중앙에 항상 표시)
        final deckWidth = cardWidth;
        final deckHeight = cardHeight;
        stackChildren.add(
          Positioned(
            left: (constraints.maxWidth - deckWidth) / 2,
            top: (constraints.maxHeight - deckHeight) / 2,
            child: CardDeckWidget(
              key: deckKey,
              remainingCards: widget.drawPileCount ?? 0,
              cardBackImage: widget.deckBackImage,
              emptyDeckImage: widget.deckBackImage,
              controller: widget.cardStackController,
              showCountLabel: true,
              width: deckWidth,
              height: deckHeight,
            ),
          ),
        );
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: stackChildren,
          ),
        );
      },
    );
  }

  Widget _myCapturedRow() {
    // 획득 zone 디버깅 로그 추가
    print('[획득 zone] 플레이어 획득 카드: ${widget.playerCaptured.entries.map((e) => '${e.key}: ${e.value.length}장').join(', ')}');
    return capturedOverlapRow(context, widget.playerCaptured, isPlayer: true, capturedKeys: playerCapturedKeys);
  }

  Widget _opponentCapturedRow() {
    // AI 획득 zone 디버깅 로그 추가
    print('[획득 zone] AI 획득 카드: ${widget.opponentCaptured.entries.map((e) => '${e.key}: ${e.value.length}장').join(', ')}');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 24),
        Expanded(child: capturedOverlapRow(context, widget.opponentCaptured, isPlayer: false, capturedKeys: aiCapturedKeys)),
        // 상대방 손패 개수 표시
        Container(
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Text(
            '${widget.opponentHandCount}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> triggerDrawnCardAnimation({
    required String frontImage,
    required Offset start,
    required Offset end,
    bool toCaptured = false,
    Offset? capturedOffset,
    VoidCallback? onEnd,
  }) async {
    setState(() {
      animDrawnFront = frontImage;
      animatingDraw = true;
      animStart = start;
      animEnd = end;
      animToCaptured = toCaptured;
      animCapturedOffset = capturedOffset;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      animatingDraw = false;
      animDrawnFront = null;
    });
    if (onEnd != null) onEnd();
  }

  // 빈자리 그룹 key getter
  List<Key> getEmptyGroupKeys() => emptyGroupKeys;

  // ================================
  // game_page.dart에서 참조하는 Key 헬퍼 메서드
  // ================================
  // 손패(index) → GlobalKey
  GlobalKey? getHandCardKey(int index) {
    return handCardKeys[index];
  }

  // 손패 카드 id(String) → GlobalKey
  GlobalKey? getHandCardKeyById(String cardId) {
    for (final entry in handCardKeys.entries) {
      final idx = entry.key;
      if (idx < widget.playerHand.length && widget.playerHand[idx].id.toString() == cardId) {
        return entry.value;
      }
    }
    return null;
  }

  // 월 그룹(index) → GlobalKey (emptyGroupKeys에 저장된 키를 GlobalKey로 캐스팅)
  GlobalKey? getFieldGroupKey(int groupIndex) {
    final key = emptyGroupKeys[groupIndex];
    return key is GlobalKey ? key : null;
  }

  // 획득 영역 타입(예: '피') → GlobalKey (플레이어용)
  GlobalKey? getCapturedTypeKey(String type) {
    return playerCapturedKeys[type];
  }
  
  // 획득 영역 타입(예: '피') → GlobalKey (AI용)
  GlobalKey? getAiCapturedTypeKey(String type) {
    return aiCapturedKeys[type];
  }

  // 상단 AI 카드패를 내 손패와 동일한 간격/크기로 배치하는 함수 추가
  Widget _opponentHandZoneWithGap(double minSide) {
    // 내 손패와 동일한 비율로 카드 크기/간격 계산
    final cardWidth = minSide * 0.13 * 0.2; // AI 카드패 크기를 20%로 줄임
    final cardHeight = cardWidth * 1.5;
    final gap = cardWidth * 0.08;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(widget.opponentHandCount, (i) =>
        Padding(
          padding: EdgeInsets.only(right: i == widget.opponentHandCount - 1 ? 0 : gap),
          child: CardWidget(
            imageUrl: widget.deckBackImage,
            isFaceDown: true,
            width: cardWidth,
            height: cardHeight,
          ),
        )
      ),
    );
  }

  // 필드 zone이 전체 Stack(화면) 중앙 기준으로 카드더미/필드카드를 배치하도록 보정한 버전
  Widget _fieldZoneWithCenterFix(double width, double height, double bottomOverlayHeight) {
    // 필드 카드별 GlobalKey를 관리하는 맵의 타입을 Map<String, Key>로 변경
    final Map<String, Key> fieldCardKeys = widget.fieldCardKeys ?? {};
    // tableCards를 월별로 그룹화
    final Map<int, List<GoStopCard>> monthlyCards = {};
    for (final card in widget.tableCards) {
      if (card.month > 0) {
        monthlyCards.putIfAbsent(card.month, () => []).add(card);
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final minSide = constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight;
        final centerX = constraints.maxWidth / 2;
        // 필드 zone(상단/하단 제외) 중앙에서 하단 오버레이 높이의 절반만큼 위로 보정
        final centerY = constraints.maxHeight / 2 - (bottomOverlayHeight / 2);
        // 손패카드, 필드카드, 카드더미 크기 비율 분리
        final handCardWidth = minSide * 0.13;
        final handCardHeight = handCardWidth * 1.5;
        final fieldCardWidth = handCardWidth * 0.8;
        final fieldCardHeight = fieldCardWidth * 1.5;
        final deckCardWidth = fieldCardWidth;
        // deckCardHeight는 위에서 이미 선언됨
        final overlapX = fieldCardWidth * 0.3;
        final overlapY = fieldCardHeight * 0.11;
        final maxCardsInGroup = 3;
        final radius = minSide * 0.28;
        final a = radius;
        final b = radius;
        List<Widget> stackChildren = [];
        // 12개 월 그룹을 원형 배치
        for (int i = 0; i < 12; i++) {
          final month = i + 1;
          final cards = monthlyCards[month] ?? [];
          final hasBonusCard = widget.bonusCard != null && widget.bonusCard!.month == month;
          final angle = (i / 12) * 2 * pi - pi / 2;
          final groupWidth = fieldCardWidth + (maxCardsInGroup - 1) * overlapX;
          final groupHeight = fieldCardHeight + (maxCardsInGroup - 1) * overlapY;
          final dx = centerX + a * cos(angle) - groupWidth / 2;
          final dy = centerY + b * sin(angle) - groupHeight / 2;
          // ... 기존 groupWidget 생성 코드 동일 ...
          Widget groupWidget;
          if (cards.isEmpty) {
            groupWidget = Container(key: emptyGroupKeys[i], width: fieldCardWidth, height: fieldCardHeight, color: Colors.transparent);
          } else if (cards.length == 1 && !hasBonusCard) {
            final key = emptyGroupKeys[i];
            fieldCardKeys[cards.first.id.toString()] = key;
            groupWidget = CardWidget(
              key: key, 
              imageUrl: cards.first.imageUrl,
              width: fieldCardWidth,
              height: fieldCardHeight,
            );
          } else if (hasBonusCard) {
            final key = emptyGroupKeys[i];
            fieldCardKeys[cards.first.id.toString()] = key;
            groupWidget = SizedBox(
              width: fieldCardWidth + (fieldCardWidth * 0.375), // 18.0 대신 비율로
              height: fieldCardHeight + (fieldCardHeight * 0.111), // 8.0 대신 비율로
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: CardWidget(
                      key: key, 
                      imageUrl: cards.first.imageUrl,
                      width: fieldCardWidth,
                      height: fieldCardHeight,
                    ),
                  ),
                  Positioned(
                    left: fieldCardWidth * 0.375, // 18.0 대신 비율로
                    top: fieldCardHeight * 0.111, // 8.0 대신 비율로
                    child: CardWidget(
                      key: UniqueKey(),
                      imageUrl: widget.bonusCard!.imageUrl,
                      highlight: true,
                      width: fieldCardWidth,
                      height: fieldCardHeight,
                    ),
                  ),
                ],
              ),
            );
          } else {
            final totalCards = hasBonusCard ? cards.length + 1 : cards.length;
            final key = emptyGroupKeys[i];
            fieldCardKeys[cards.first.id.toString()] = key;
            groupWidget = SizedBox(
              width: fieldCardWidth + (totalCards - 1) * (fieldCardWidth * 0.375),
              height: fieldCardHeight + (totalCards - 1) * (fieldCardHeight * 0.111),
              child: Stack(
                children: [
                  ...List.generate(cards.length, (j) {
                    final cardKey = j == 0 ? key : UniqueKey();
                    // 모든 카드의 id → key 매핑 저장 (겹침 애니메이션 좌표 계산용)
                    fieldCardKeys[cards[j].id.toString()] = cardKey;
                    return Positioned(
                      left: j * (fieldCardWidth * 0.375),
                      top: j * (fieldCardHeight * 0.111),
                      child: CardWidget(
                        key: cardKey, 
                        imageUrl: cards[j].imageUrl,
                        width: fieldCardWidth,
                        height: fieldCardHeight,
                      ),
                    );
                  }),
                  if (hasBonusCard)
                    Positioned(
                      left: cards.length * (fieldCardWidth * 0.375),
                      top: cards.length * (fieldCardHeight * 0.111),
                      child: CardWidget(
                        key: UniqueKey(),
                        imageUrl: widget.bonusCard!.imageUrl,
                        highlight: true,
                        width: fieldCardWidth,
                        height: fieldCardHeight,
                      ),
                    ),
                ],
              ),
            );
          }

          stackChildren.add(Positioned(
            left: dx,
            top: dy,
            child: groupWidget,
          ));
        }

        // 카드더미(중앙)
        stackChildren.add(
          Positioned(
            left: centerX - (deckCardWidth / 2),
            top: centerY - (fieldCardHeight / 2), // deckCardHeight 대신 fieldCardHeight 사용
            child: CardDeckWidget(
              key: deckKey,
              remainingCards: widget.drawPileCount ?? 0,
              cardBackImage: widget.deckBackImage,
              emptyDeckImage: widget.deckBackImage,
              controller: widget.cardStackController,
              showCountLabel: true,
              width: deckCardWidth,
              height: fieldCardHeight,
            ),
          ),
        );
        // ... 기타 카드 배치 동일 ...
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: stackChildren,
          ),
        );
      },
    );
  }

  // 점수 옆 배수 상태 뱃지 위젯 생성 함수
  Widget _buildStatusBadge(String label, {required bool isActive, required Color activeColor, required Color inactiveColor, required double minSide}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: minSide * 0.012, vertical: minSide * 0.004),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.13) : inactiveColor.withOpacity(0.13),
        borderRadius: BorderRadius.circular(minSide * 0.012),
        border: Border.all(color: isActive ? activeColor : inactiveColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? activeColor : inactiveColor,
          fontWeight: FontWeight.bold,
          fontSize: minSide * 0.018,
        ),
      ),
    );
  }

  // 상단 점수/상태/설정 버튼 영역
  Widget buildTopPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final minSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    final topPanelHeight = minSide * 0.10;
    return Container(
      width: screenWidth,
      height: topPanelHeight,
      color: Colors.black.withOpacity(0.08),
      padding: EdgeInsets.symmetric(horizontal: minSide * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: minSide * 0.0225),
            onPressed: () {},
            tooltip: '설정',
          ),
        ],
      ),
    );
  }

  // 상태+프로필 Row
  Widget buildPlayerStatusAndProfile({
    required String avatarUrl,
    required String nickname,
    required String countryCode,
    required int level,
    required int coins,
    required int score,
    required bool isOpponent,
    required bool isGwangBak,
    required bool isPiBak,
    required bool isHeundal,
    required bool isBomb,
    required bool isMeongtta,
    required int goCount,
    double? height,
    double? avatarSize,
    double? fontSize,
    double? iconSize,
    double? coinFontSize,
    double? levelFontSize,
  }) {
    final minSide = MediaQuery.of(context).size.shortestSide;
    // 크기 1.5배로 확대
    final badgeSize = minSide * 0.0525;
    final badgeTextStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: minSide * 0.0225);
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.bottomLeft,
      // Row 전체를 SizedBox.expand로 감싸서 상태+프로필 높이 일치
      child: SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 상태정보(좌측정렬, 2행 3열)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // 상태정보와 프로필박스의 높이가 항상 일치하도록 spaceBetween 적용
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1행: 점수, 광박, 흔들
                  Row(
                    children: [
                      // 점수박스
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(right: minSide * 0.008, bottom: minSide * 0.003),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(badgeSize * 0.25),
                        ),
                        child: Text('$score', style: badgeTextStyle.copyWith(color: Colors.yellowAccent)),
                      ),
                      // 광박
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(right: minSide * 0.008, bottom: minSide * 0.003),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: isGwangBak ? Colors.red : Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(badgeSize * 0.25),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppLocalizations.of(context)!.gwangBak,
                            style: badgeTextStyle.copyWith(color: isGwangBak ? Colors.red : Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      // 흔들
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(right: minSide * 0.008, bottom: minSide * 0.003),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: isHeundal ? Colors.blue : Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(badgeSize * 0.25),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppLocalizations.of(context)!.heundal,
                            style: badgeTextStyle.copyWith(color: isHeundal ? Colors.blue : Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 2행: 몇고, 피박, 폭탄
                  Row(
                    children: [
                      // 몇고
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(right: minSide * 0.008, top: minSide * 0.003),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: goCount > 0 ? Colors.yellow : Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(badgeSize * 0.25),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${goCount}${AppLocalizations.of(context)!.go}',
                            style: badgeTextStyle.copyWith(color: goCount > 0 ? Colors.yellow : Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      // 피박
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(right: minSide * 0.008, top: minSide * 0.003),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: isPiBak ? Colors.red : Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(badgeSize * 0.25),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppLocalizations.of(context)!.piBak,
                            style: badgeTextStyle.copyWith(color: isPiBak ? Colors.red : Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      // 폭탄
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(right: minSide * 0.008, top: minSide * 0.003),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: isBomb ? Colors.blue : Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(badgeSize * 0.25),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppLocalizations.of(context)!.bombStatus,
                            style: badgeTextStyle.copyWith(color: isBomb ? Colors.blue : Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 프로필박스(우측정렬, 크기 1.5배)
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomRight,
                child: ProfileCard(
                  avatarUrl: avatarUrl,
                  nickname: nickname,
                  countryCode: countryCode,
                  level: level,
                  coins: coins,
                  height: (height ?? minSide * 0.10) * 1.5,
                  avatarSize: (avatarSize ?? minSide * 0.065) * 1.5,
                  fontSize: (fontSize ?? minSide * 0.028) * 1.5,
                  iconSize: (iconSize ?? minSide * 0.022) * 1.5,
                  coinFontSize: (coinFontSize ?? minSide * 0.022) * 1.5,
                  levelFontSize: (levelFontSize ?? minSide * 0.022) * 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 획득카드 Row (부모의 height를 반드시 따라가도록 Container로 감쌈)
  Widget buildPlayerCapturedRow({
    required Map<String, List<String>> captured,
    required bool isPlayer,
    required Map<String, GlobalKey> capturedKeys,
  }) {
    // 항상 부모 크기를 따라가도록 SizedBox.expand로 감쌈
    return SizedBox.expand(
      child: Container(
        alignment: Alignment.topLeft,
        child: FittedBox(
          alignment: Alignment.topLeft,
          fit: BoxFit.scaleDown, // 공간을 초과하면 자동 축소
          child: capturedOverlapRow(context, captured, isPlayer: isPlayer, capturedKeys: capturedKeys),
        ),
      ),
    );
  }

  Widget buildPlayerBox({
    required bool isOpponent,
    required Map<String, List<String>> captured,
    required Map<String, GlobalKey> capturedKeys,
    required String avatarUrl,
    required String nickname,
    required String countryCode,
    required int level,
    required int coins,
    required int score,
    required bool isGwangBak,
    required bool isPiBak,
    required bool isHeundal,
    required bool isBomb,
    required bool isMeongtta,
    required int goCount,
    double? height,
    double? avatarSize,
    double? fontSize,
    double? iconSize,
    double? coinFontSize,
    double? levelFontSize,
  }) {
    final minSide = MediaQuery.of(context).size.shortestSide;
    // 항상 부모 크기를 따라가도록 SizedBox.expand로 감쌈
    return SizedBox.expand(
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.only(top: minSide * 0.012, left: minSide * 0.01, right: minSide * 0.01, bottom: 0),
        decoration: BoxDecoration(
          color: isOpponent
              ? Colors.blueGrey.withOpacity(0.18)
              : Colors.amber.withOpacity(0.13),
          borderRadius: BorderRadius.circular(minSide * 0.03),
          border: Border.all(
            color: isOpponent ? Colors.blueGrey : Colors.amber,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            // 획득카드 영역 60% (부모 Expanded의 높이를 반드시 따라가도록 SizedBox.expand로 감쌈)
            Expanded(
              flex: 6,
              child: SizedBox.expand(
                child: buildPlayerCapturedRow(
                  captured: captured,
                  isPlayer: !isOpponent,
                  capturedKeys: capturedKeys,
                ),
              ),
            ),
            // 상태+프로필 영역 40% (부모 Expanded의 높이를 반드시 따라가도록 SizedBox.expand로 감쌈)
            Expanded(
              flex: 4,
              child: SizedBox.expand(
                child: buildPlayerStatusAndProfile(
                  avatarUrl: avatarUrl,
                  nickname: nickname,
                  countryCode: countryCode,
                  level: level,
                  coins: coins,
                  score: score,
                  isOpponent: isOpponent,
                  isGwangBak: isGwangBak,
                  isPiBak: isPiBak,
                  isHeundal: isHeundal,
                  isBomb: isBomb,
                  isMeongtta: isMeongtta,
                  goCount: goCount,
                  height: height,
                  // 프로필사진/닉네임 크기를 70%에서 추가로 20% 더 축소(총 56%)
                  avatarSize: minSide * 0.065 * 0.56,
                  fontSize: minSide * 0.028 * 0.56,
                  iconSize: minSide * 0.022 * 0.56,
                  coinFontSize: minSide * 0.022 * 0.56,
                  levelFontSize: minSide * 0.022 * 0.56,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 좌측 패널(상대+내 플레이어박스 모두 표시)
  Widget buildLeftPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final minSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    final leftPanelRatio = 0.33;
    final fieldPanelHeight = screenHeight - (minSide * 0.19) - (minSide * 0.10);

    // engine 상태값 안전하게 가져오기 (widget.engine 사용)
    final engine = widget.engine;
    // 플레이어 번호: 1(나), 2(AI)
    final int myPlayerNum = 1;
    final int aiPlayerNum = 2;
    // 각 상태값 안전하게 추출 (없으면 false)
    final bool isMeHeundal = engine?.heundalPlayers?.contains(myPlayerNum) ?? false;
    final bool isAiHeundal = engine?.heundalPlayers?.contains(aiPlayerNum) ?? false;
    final bool isMeBomb = engine?.bombPlayers?.contains(myPlayerNum) ?? false;
    final bool isAiBomb = engine?.bombPlayers?.contains(aiPlayerNum) ?? false;
    final bool isMePiBak = engine?.piBakPlayers?.contains(myPlayerNum) ?? false;
    final bool isAiPiBak = engine?.piBakPlayers?.contains(aiPlayerNum) ?? false;
    final bool isMeGwangBak = engine?.gwangBakPlayers?.contains(myPlayerNum) ?? false;
    final bool isAiGwangBak = engine?.gwangBakPlayers?.contains(aiPlayerNum) ?? false;
    final bool isMeMeongtta = engine?.mungBakPlayers?.contains(myPlayerNum) ?? false;
    final bool isAiMeongtta = engine?.mungBakPlayers?.contains(aiPlayerNum) ?? false;
    // ── GO 횟수 표시 ──
    // goPlayer가 어느 쪽인지에 따라 해당 박스에만 표시하고, 다른 쪽은 0으로
    final int meGoCount = (engine != null && engine.goPlayer == myPlayerNum) ? engine.goCount : 0;
    final int aiGoCount = (engine != null && engine.goPlayer == aiPlayerNum) ? engine.goCount : 0;

    // 오른쪽에 위치해도 항상 크기를 제대로 할당받도록 SizedBox.expand로 감쌈
    return SizedBox.expand(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // AI(상대) 박스
          Expanded(
            child: buildPlayerBox(
              isOpponent: true,
              captured: widget.opponentCaptured,
              capturedKeys: aiCapturedKeys,
              avatarUrl: 'assets/avatars/default.png',
              nickname: widget.opponentName,
              countryCode: 'kr',
              level: 1,
              coins: 0,
              score: widget.opponentScore,
              isGwangBak: isAiGwangBak, // 광박 상태
              isPiBak: isAiPiBak,       // 피박 상태
              isHeundal: isAiHeundal,   // 흔들 상태
              isBomb: isAiBomb,         // 폭탄 상태
              isMeongtta: isAiMeongtta, // 멍박 상태
              goCount: aiGoCount,       // AI의 go 횟수(필요시)
              height: minSide * 0.10,
              // 프로필사진/닉네임 크기를 70%로 축소
              avatarSize: minSide * 0.065 * 0.7,
              fontSize: minSide * 0.028 * 0.7,
              iconSize: minSide * 0.022 * 0.7,
              coinFontSize: minSide * 0.022 * 0.7,
              levelFontSize: minSide * 0.022 * 0.7,
            ),
          ),
          // 내(플레이어) 박스
          Expanded(
            child: FutureBuilder<int>(
              future: CoinService.instance.getCoins(),
              builder: (context, snapshot) {
                final coins = snapshot.data ?? 0;
                return buildPlayerBox(
                  isOpponent: false,
                  captured: widget.playerCaptured,
                  capturedKeys: playerCapturedKeys,
                  avatarUrl: 'assets/avatars/default.png',
                  nickname: '나',
                  countryCode: 'kr',
                  level: 1,
                  coins: coins,
                  score: widget.playerScore,
                  isGwangBak: isMeGwangBak, // 광박 상태
                  isPiBak: isMePiBak,       // 피박 상태
                  isHeundal: isMeHeundal,   // 흔들 상태
                  isBomb: isMeBomb,         // 폭탄 상태
                  isMeongtta: isMeMeongtta, // 멍박 상태
                  goCount: meGoCount,       // 내 go 횟수
                  height: minSide * 0.10,
                  // 프로필사진/닉네임 크기를 70%로 축소
                  avatarSize: minSide * 0.065 * 0.7,
                  fontSize: minSide * 0.028 * 0.7,
                  iconSize: minSide * 0.022 * 0.7,
                  coinFontSize: minSide * 0.022 * 0.7,
                  levelFontSize: minSide * 0.022 * 0.7,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 중앙 필드 영역
  Widget buildFieldArea() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final minSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fieldPanelRatio = 0.67;
    final fieldPanelHeight = screenHeight - (minSide * 0.19) - (minSide * 0.10);
    return Container(
      width: screenWidth * fieldPanelRatio,
      height: fieldPanelHeight,
      alignment: Alignment.center,
      child: _fieldZone(),
    );
  }

  // 한글 주석: 하단 손패카드 영역
  Widget buildHandPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final minSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    final handPanelHeight = minSide * 0.19;
    final handCount = widget.playerHand.length;
    final maxHandWidth = screenWidth * 0.82;
    final minCardWidth = minSide * 0.07;
    final maxCardWidth = minSide * 0.13;
    final cardW = (maxHandWidth / handCount).clamp(minCardWidth, maxCardWidth);
    final cardH = cardW * 1.5;
    // 폭탄 가능한 카드 인덱스 계산
    // 1. 손패를 월별로 그룹화
    final Map<int, List<int>> handMonthToIndexes = {};
    for (int i = 0; i < widget.playerHand.length; i++) {
      final m = widget.playerHand[i].month;
      handMonthToIndexes.putIfAbsent(m, () => []).add(i);
    }
    // 2. 필드를 월별로 그룹화
    final Map<int, int> fieldMonthCount = {};
    for (final card in widget.tableCards) {
      fieldMonthCount.update(card.month, (v) => v + 1, ifAbsent: () => 1);
    }
    // 3. 폭탄 가능한 손패카드 인덱스 집합 구하기
    final Set<int> bombIndexes = {};
    handMonthToIndexes.forEach((month, idxList) {
      if (idxList.length == 3 && (fieldMonthCount[month] ?? 0) >= 1) {
        bombIndexes.addAll(idxList);
      }
    });
    // 4. 뻑 완성 가능한 손패카드 인덱스 집합 구하기 (필드에 3장 쌓인 월)
    final Set<int> ppeokIndexes = {};
    fieldMonthCount.forEach((month, count) {
      if (count == 3 && handMonthToIndexes[month] != null) {
        ppeokIndexes.addAll(handMonthToIndexes[month]!);
      }
    });
    // 5. 보너스 손패카드 인덱스 집합 구하기 (이미지 파일명에 bonus 포함, 대소문자 무관)
    final Set<int> bonusIndexes = {};
    for (int i = 0; i < widget.playerHand.length; i++) {
      final img = widget.playerHand[i].imageUrl.toLowerCase();
      if (img.contains('bonus')) {
        bonusIndexes.add(i);
      }
    }
    return Container(
      width: screenWidth,
      height: handPanelHeight,
      color: Colors.black.withOpacity(0.07),
      padding: EdgeInsets.symmetric(horizontal: minSide * 0.01, vertical: minSide * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < widget.playerHand.length; i++)
            (() {
              final globalKey = handCardKeys.putIfAbsent(i, () => GlobalKey());
              return Padding(
                padding: EdgeInsets.only(right: i == widget.playerHand.length - 1 ? 0 : cardW * 0.08),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // 먹을 수 있는 카드에 화살표 표시
                    if (widget.highlightHandIndexes.contains(i))
                      Positioned(
                        top: -cardH * 0.17,
                        child: Icon(Icons.arrow_drop_down, color: Colors.orange, size: cardH * 0.28),
                      ),
                    GestureDetector(
                      onTap: () => _onHandCardTap(i),
                      child: CardWidget(
                        key: globalKey,
                        imageUrl: widget.playerHand[i].imageUrl,
                        width: cardW,
                        height: cardH,
                        dimmed: !widget.highlightHandIndexes.contains(i),
                        // 폭탄 조건(같은 월 3장+필드 1장 이상)만 bombHighlight 적용
                        bombHighlight: bombIndexes.contains(i),
                        // 뻑 완성(필드에 3장 쌓인 월+내 손패에 해당 월)만 ppeokHighlight 적용 (폭탄과 중복 시 폭탄 우선)
                        ppeokHighlight: !bombIndexes.contains(i) && ppeokIndexes.contains(i),
                        // 보너스 손패(이미지 파일명에 bonus 포함)만 bonusHighlight 적용 (폭탄/뻑과 중복 시 우선순위 적용)
                        bonusHighlight: !bombIndexes.contains(i) && !ppeokIndexes.contains(i) && bonusIndexes.contains(i),
                      ),
                    ),
                  ],
                ),
              );
            })(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final minSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    final fieldPanelHeight = screenHeight - (minSide * 0.19) - (minSide * 0.10);
    final scaffold = Scaffold(
      backgroundColor: const Color(0xFF2f4f2f),
      body: Column(
        children: [
          buildTopPanel(),
          SizedBox(
            height: fieldPanelHeight,
            child: Row(
              children: [
                Expanded(flex: 7, child: buildFieldArea()), // 필드 영역 70%
                Expanded(flex: 3, child: buildLeftPanel()), // 플레이어박스/획득카드 패널 30%
              ],
            ),
          ),
          buildHandPanel(),
        ],
      ),
    );

    // 7점 이상일 때 자동으로 GO/STOP 선택창 띄우기 (한 번만)
    if (widget.isGoStopPhase && widget.onGo != null && !_goStopDialogShown && widget.autoGoStop) {
      _goStopDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onGo!());
    } else if (!widget.isGoStopPhase && _goStopDialogShown) {
      _goStopDialogShown = false;
    }

    return scaffold;
  }
}