import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/sound_manager.dart';
import '../l10n/app_localizations.dart';

class GoSelectionDialog extends StatefulWidget {
  final int currentGoCount;         // 현재 GO 횟수
  final int playerScore;           // 배수 포함 현재 내 점수
  final int opponentScore;         // 배수 포함 상대 점수
  final int coinChangeIfStop;      // 지금 STOP 시 코인 증감
  final Function(bool) onSelection;
  final bool isPlayerGwangBak;     // 플레이어 광박 상태
  final bool isPlayerPiBak;        // 플레이어 피박 상태
  final bool isOpponentGwangBak;   // 상대방 광박 상태
  final bool isOpponentPiBak;      // 상대방 피박 상태

  const GoSelectionDialog({
    super.key,
    required this.currentGoCount,
    required this.playerScore,
    required this.opponentScore,
    required this.coinChangeIfStop,
    required this.onSelection,
    required this.isPlayerGwangBak,
    required this.isPlayerPiBak,
    required this.isOpponentGwangBak,
    required this.isOpponentPiBak,
  });

  @override
  State<GoSelectionDialog> createState() => _GoSelectionDialogState();
}

class _GoSelectionDialogState extends State<GoSelectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
  }

  void _startAnimations() {
    _buttonController.forward();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Stack(
          children: [
            // 반투명 배경 (필드와 카드가 보이도록)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(_fadeAnimation.value * 0.3),
              ),
            ),
            
            // 필드와 내 카드 사이 중앙에 버튼 배치
            Positioned(
              bottom: screenSize.height * 0.25, // 내 카드 위쪽
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 점수 정보 (간결하게)
                      _buildScoreInfo(),
                      const SizedBox(height: 16),
                      // GO/STOP 버튼
                      _buildButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreInfo() {
    final nextGoBonus = _getNextGoBonus();

    // GO 시 점수 변화 문구 계산 (박 상태 포함)
    String goInfo;
    if (widget.currentGoCount >= 2) {
      // 3GO 이상일 때는 매 GO 마다 2배
      goInfo = "GO 선택 시 점수 ×2";
    } else {
      goInfo = "GO 선택 시 +${nextGoBonus.toInt()}점";
    }

    // STOP 시 코인 증감 문구
    final coinInfo = widget.coinChangeIfStop >= 0
        ? "+${widget.coinChangeIfStop} 코인"
        : "${widget.coinChangeIfStop} 코인";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 점수 정보 (박 상태 포함) ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildScoreWithBakStatus(widget.playerScore, true), // 플레이어 점수
              const SizedBox(width: 12),
              _buildScoreWithBakStatus(widget.opponentScore, false), // AI 점수
            ],
          ),
          const SizedBox(height: 6),
          // ── STOP / GO 보너스 정보 ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goInfo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "STOP 시 $coinInfo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 박 상태를 포함한 점수 표시 위젯
  Widget _buildScoreWithBakStatus(int score, bool isPlayer) {
    // 실제 박 상태 정보 사용
    bool hasGwangBak = isPlayer ? widget.isPlayerGwangBak : widget.isOpponentGwangBak;
    bool hasPiBak = isPlayer ? widget.isPlayerPiBak : widget.isOpponentPiBak;
    
    String scoreText = isPlayer 
        ? AppLocalizations.of(context)!.myScore(score)
        : AppLocalizations.of(context)!.aiScore(score);
    
    // 박 상태가 있으면 표시
    if (hasGwangBak || hasPiBak) {
      List<String> bakStatus = [];
      if (hasGwangBak) bakStatus.add('광박×2');
      if (hasPiBak) bakStatus.add('피박×2');
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scoreText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bakStatus.join(' '),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
    
    return Text(
      scoreText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(
          text: AppLocalizations.of(context)!.go, // GO 버튼
          icon: Icons.play_arrow,
          color: _getGoButtonColor(),
          onPressed: () => _onButtonPressed(true),
        ),
        const SizedBox(width: 20),
        _buildButton(
          text: AppLocalizations.of(context)!.stop, // STOP 버튼
          icon: Icons.stop,
          color: _getStopButtonColor(),
          onPressed: () => _onButtonPressed(false),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) => _buttonController.reverse(),
      onTapCancel: () => _buttonController.reverse(),
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          // 3D 효과와 하이라이트
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color,
              color.withOpacity(0.7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(25),
          // 최소한의 그림자
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          // 하이라이트 stroke
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () {
              HapticFeedback.mediumImpact();
              onPressed();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onButtonPressed(bool isGo) {
    // 버튼 클릭 효과음 재생
    HapticFeedback.heavyImpact();
    
    // GO/STOP 선택 사운드 재생
    if (isGo) {
      SoundManager.instance.play(Sfx.goStop);
    } else {
      SoundManager.instance.play(Sfx.buttonClick);
    }
    
    // 애니메이션과 함께 다이얼로그 닫기
    _buttonController.reverse().then((_) {
      widget.onSelection(isGo);
    });
  }

  Color _getGoButtonColor() {
    switch (widget.currentGoCount) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      case 6:
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  Color _getStopButtonColor() {
    switch (widget.currentGoCount) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.indigo;
      case 4:
        return Colors.deepPurple;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  double _getNextGoBonus() {
    switch (widget.currentGoCount) {
      case 1:
        return 2.0;
      case 2:
        return 3.0;
      case 3:
        return 4.0;
      case 4:
        return 5.0;
      case 5:
        return 6.0;
      case 6:
        return 7.0;
      default:
        return 2.0;
    }
  }
} 