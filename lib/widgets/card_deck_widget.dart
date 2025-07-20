import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/sound_manager.dart';

class CardDeckController {
  VoidCallback? _flip;
  void flipCard() => _flip?.call();
}

class CardDeckWidget extends StatefulWidget {
  final int remainingCards;
  final int maxDeckView;
  final String cardBackImage;
  final String emptyDeckImage;
  final CardDeckController? controller;
  final VoidCallback? onFlipComplete;
  final bool showCountLabel;
  final double? width; // 카드더미 가로 크기(반응형, null이면 자동 계산)
  final double? height; // 카드더미 세로 크기(반응형, null이면 자동 계산)
  final bool visible; // 카드더미 표시 여부
  final List<dynamic>? actualCards; // 실제 카드 데이터 (분배 애니메이션용)

  const CardDeckWidget({
    super.key,
    required this.remainingCards,
    this.maxDeckView = 10,
    required this.cardBackImage,
    required this.emptyDeckImage,
    this.controller,
    this.onFlipComplete,
    this.showCountLabel = true,
    this.width, // null이면 반응형 크기 사용
    this.height, // null이면 반응형 크기 사용
    this.visible = true, // 기본값은 보이기
    this.actualCards, // 실제 카드 데이터
  });

  @override
  State<CardDeckWidget> createState() => _CardDeckWidgetState();
}

class _CardDeckWidgetState extends State<CardDeckWidget> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _drawController;
  bool isFlipping = false;
  bool showFront = false;
  bool isDrawing = false;
  
  // 카드더미에서 분배할 카드 위젯들을 관리
  List<Widget> _deckCardWidgets = [];
  bool _isDealing = false;
  int _dealingCardIndex = -1;
  
  // 각 카드에 개별 GlobalKey 할당
  Map<int, GlobalKey> _cardKeys = {};
  
  // Overlay 엔트리 관리
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller?._flip = _startFlip;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isFlipping = false;
          showFront = false;
        });
        widget.onFlipComplete?.call();
      }
    });
    
    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isDrawing = false;
        });
      }
    });
  }

  void _startFlip() {
    if (isFlipping) return;
    SoundManager.instance.play(Sfx.cardFlip);
    setState(() {
      isFlipping = true;
      showFront = false;
    });
    _flipController.reset();
    _flipController.forward();
  }

  void _startDraw() {
    if (isDrawing) return;
    setState(() {
      isDrawing = true;
    });
    _drawController.reset();
    _drawController.forward();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _drawController.dispose();
    _safeRemoveOverlay();
    super.dispose();
  }

  // 실제 카드들을 가져오는 메서드 (분배 애니메이션용)
  List<dynamic>? getActualCards() {
    return widget.actualCards;
  }

  // 카드더미에서 카드를 제거하는 메서드 (분배 시)
  dynamic removeTopCard() {
    if (widget.actualCards != null && widget.actualCards!.isNotEmpty) {
      return widget.actualCards!.removeAt(0);
    }
    return null;
  }

  // 카드더미에서 실제 카드 위젯을 분배 애니메이션으로 이동시키는 메서드
  Widget? getDeckCardWidgetForAnimation(int cardIndex) {
    if (widget.actualCards == null || cardIndex >= widget.actualCards!.length) {
      return null;
    }
    
    final card = widget.actualCards![cardIndex];
    final Size screenSize = MediaQuery.of(context).size;
    final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final double cardWidth = widget.width ?? (minSide * 0.08);
    final double cardHeight = widget.height ?? (cardWidth * 1.5);
    
    // 실제 카드 위젯 생성
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          card.imageUrl ?? widget.cardBackImage,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 분배 애니메이션 시작 시 호출되는 메서드
  void startDealingAnimation(int cardIndex) {
    setState(() {
      _isDealing = true;
      _dealingCardIndex = cardIndex;
    });
  }

  // 분배 애니메이션 완료 시 호출되는 메서드
  void completeDealingAnimation() {
    setState(() {
      _isDealing = false;
      _dealingCardIndex = -1;
    });
  }

  // 카드더미의 top card 위치를 정확히 계산하는 메서드
  Offset? getTopCardPosition() {
    final visibleCount = min(widget.maxDeckView, widget.remainingCards);
    if (visibleCount == 0) return null;
    
    final topCardIndex = visibleCount - 1;
    final topCardKey = _cardKeys[topCardIndex];
    
    if (topCardKey?.currentContext != null) {
      final RenderBox renderBox = topCardKey!.currentContext!.findRenderObject() as RenderBox;
      return renderBox.localToGlobal(Offset.zero);
    }
    return null;
  }

  // 특정 카드의 위치를 계산하는 메서드
  Offset? getCardPosition(int cardIndex) {
    final cardKey = _cardKeys[cardIndex];
    if (cardKey?.currentContext != null) {
      final RenderBox renderBox = cardKey!.currentContext!.findRenderObject() as RenderBox;
      return renderBox.localToGlobal(Offset.zero);
    }
    return null;
  }

  // 실제 카드 위젯을 Overlay로 이동시키는 메서드 (심플한 애니메이션)
  void moveCardToOverlay(int cardIndex, Offset startPosition, Offset endPosition, VoidCallback onComplete) {
    final cardKey = _cardKeys[cardIndex];
    
    // 위젯이 유효한지 확인
    if (cardKey?.currentContext == null || !mounted) {
      print('⚠️ 카드 위젯이 유효하지 않음: cardIndex=$cardIndex');
      onComplete();
      return;
    }
    
    // 이미 애니메이션 중인지 확인
    if (_overlayEntry != null) {
      print('⚠️ 이미 애니메이션 진행 중');
      return;
    }
    
    try {
      // 카드더미에서 해당 카드 숨기기
      startDealingAnimation(cardIndex);
      
      // 실제 카드 위젯을 Overlay로 이동 (심플한 애니메이션)
      _overlayEntry = OverlayEntry(
        builder: (context) => _SimpleCardAnimation(
          cardKey: cardKey!,
          startPosition: startPosition,
          endPosition: endPosition,
          onComplete: () {
            _safeRemoveOverlay();
            completeDealingAnimation();
            onComplete();
          },
        ),
      );
      
      // Overlay에 안전하게 추가
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          try {
            Overlay.of(context).insert(_overlayEntry!);
          } catch (e) {
            print('⚠️ Overlay 추가 실패: $e');
            _safeRemoveOverlay();
            completeDealingAnimation();
            onComplete();
          }
        }
      });
    } catch (e) {
      print('⚠️ moveCardToOverlay 오류: $e');
      _safeRemoveOverlay();
      completeDealingAnimation();
      onComplete();
    }
  }
  
  // 안전한 Overlay 제거
  void _safeRemoveOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (e) {
      print('⚠️ Overlay 제거 실패: $e');
    } finally {
      _overlayEntry = null;
    }
  }

  // 실제 카드 이미지를 렌더링하는 메서드
  Widget _buildCardImage(int cardIndex, double width, double height) {
    // 카드더미는 항상 뒷면으로 표시
    return Image.asset(
      widget.cardBackImage,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  // 뒤집기 애니메이션용 카드 이미지를 렌더링하는 메서드
  Widget _buildFlipCardImage(bool isBack, double width, double height) {
    if (isBack) {
      // 뒷면일 때는 기본 뒷면 이미지
      return Image.asset(
        widget.cardBackImage,
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    } else {
      // 앞면일 때는 실제 카드 데이터의 첫 번째 카드 사용
      if (widget.actualCards != null && widget.actualCards!.isNotEmpty) {
        final card = widget.actualCards![0];
        if (card is dynamic && card.imageUrl != null) {
          return Image.asset(
            card.imageUrl,
            width: width,
            height: height,
            fit: BoxFit.contain,
          );
        }
      }
      
      // 실제 카드 데이터가 없으면 빈 덱 이미지 사용
      return Image.asset(
        widget.emptyDeckImage,
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // visible이 false이면 숨기기
    if (!widget.visible) {
      return const SizedBox.shrink();
    }
    
    // 반응형 크기 계산 (셔플 애니메이션과 동일)
    final Size screenSize = MediaQuery.of(context).size;
    final double minSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final double cardWidth = widget.width ?? (minSide * 0.08); // 0.13 → 0.08 (필드카드 수준)
    final double cardHeight = widget.height ?? (cardWidth * 1.5); // 셔플 애니메이션과 동일
    
    final visibleCount = min(widget.maxDeckView, widget.remainingCards);
    // 실제 카드 데이터가 없거나 남은 카드가 0장이면 빈 덱 표시
    if (widget.remainingCards == 0 || widget.actualCards == null || widget.actualCards!.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 카드더미가 비었을 때도 반응형 크기 적용
          Image.asset(widget.emptyDeckImage, width: cardWidth, height: cardHeight, fit: BoxFit.contain),
          if (widget.showCountLabel)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('남은장: 0', style: TextStyle(color: Colors.white)),
            ),
        ],
      );
    }
    // 카드더미 전체 크기 계산 (겹침 포함)
    // 겹침 간격을 50% 더 촘촘하게 (0.125 → 0.0625, 0.042 → 0.021)
    final deckWidth = cardWidth + (visibleCount - 1) * (cardWidth * 0.0625);
    final deckHeight = cardHeight + (visibleCount - 1) * (cardHeight * 0.021);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: deckWidth,
          height: deckHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              ...List.generate(visibleCount - (isFlipping ? 1 : 0), (i) {
                // 분배 중인 카드는 숨기기
                if (_isDealing && i == _dealingCardIndex) {
                  return const SizedBox.shrink();
                }
                
                // 겹침 간격을 50% 더 촘촘하게
                final cardKey = _cardKeys[i] ??= GlobalKey();
                return Positioned(
                  left: i * (cardWidth * 0.0625),
                  top: i * (cardHeight * 0.021),
                  child: AnimatedBuilder(
                    animation: _drawController,
                    builder: (context, child) {
                      final drawProgress = _drawController.value;
                      final isTopCard = i == visibleCount - 1;
                      final offset = isTopCard && isDrawing ? drawProgress * (cardHeight * 0.28) : 0.0;
                      return Transform.translate(
                        offset: Offset(0, -offset),
                        child: Transform.rotate(
                          angle: (i % 2 == 0 ? -1 : 1) * 0.03,
                          child: Container(
                            key: cardKey, // 각 카드에 GlobalKey 할당
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
                            ),
                            child: _buildCardImage(i, cardWidth, cardHeight),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
              if (isFlipping)
                AnimatedBuilder(
                  animation: _flipController,
                  builder: (context, child) {
                    final angle = _flipController.value * pi;
                    final isBack = angle < pi / 2 && !showFront;
                    return Positioned(
                      left: (visibleCount - 1) * (cardWidth * 0.0625),
                      top: (visibleCount - 1) * (cardHeight * 0.021),
                      child: Transform.translate(
                        offset: Offset(0, -(cardHeight * 0.28) * sin(_flipController.value * pi)),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 2))],
                            ),
                            child: _buildFlipCardImage(isBack, cardWidth, cardHeight),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        if (widget.showCountLabel)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('남은장: ${widget.remainingCards}', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}

// 카드더미의 실제 카드 위젯을 Overlay에서 애니메이션하는 클래스 (심플한 버전)
class _SimpleCardAnimation extends StatefulWidget {
  final GlobalKey cardKey;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback onComplete;

  const _SimpleCardAnimation({
    required this.cardKey,
    required this.startPosition,
    required this.endPosition,
    required this.onComplete,
  });

  @override
  State<_SimpleCardAnimation> createState() => _SimpleCardAnimationState();
}

class _SimpleCardAnimationState extends State<_SimpleCardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startAnimation();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600), // 더 빠른 애니메이션
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // 심플한 이징
    ));
  }

  Future<void> _startAnimation() async {
    if (_isDisposed) return;
    
    try {
      _controller.forward();
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (!_isDisposed && mounted) {
        widget.onComplete();
      }
    } catch (e) {
      print('⚠️ 심플 애니메이션 실행 오류: $e');
      if (!_isDisposed && mounted) {
        widget.onComplete();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 위젯이 유효한지 확인
    if (!mounted || _isDisposed) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 카드 위젯이 유효한지 확인
        final cardWidget = widget.cardKey.currentWidget;
        if (cardWidget == null) {
          print('⚠️ 카드 위젯이 null임');
          return const SizedBox.shrink();
        }
        
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: RepaintBoundary(
            child: cardWidget, // 실제 카드 위젯 그대로 사용
          ),
        );
      },
    );
  }
}