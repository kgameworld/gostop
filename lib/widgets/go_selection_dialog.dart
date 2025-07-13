import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/sound_manager.dart';
import '../l10n/app_localizations.dart';

class GoSelectionDialog extends StatefulWidget {
  final int currentGoCount;
  final int playerScore;
  final int opponentScore;
  final Function(bool) onSelection;

  const GoSelectionDialog({
    super.key,
    required this.currentGoCount,
    required this.playerScore,
    required this.opponentScore,
    required this.onSelection,
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 내 점수
          Text(
            AppLocalizations.of(context)!.myScore(widget.playerScore), // 내 점수
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context)!.aiScore(widget.opponentScore), // AI 점수
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppLocalizations.of(context)!.goBonus(_getNextGoBonus()), // GO 보너스
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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