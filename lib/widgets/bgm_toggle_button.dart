import 'package:flutter/material.dart';
import '../utils/sound_manager.dart';

class BgmToggleButton extends StatefulWidget {
  final String bgmBase;
  final double volume;
  final double? size; // 반응형 크기 추가
  const BgmToggleButton({
    super.key, 
    required this.bgmBase, 
    this.volume = 0.6,
    this.size,
  });

  @override
  State<BgmToggleButton> createState() => _BgmToggleButtonState();
}

class _BgmToggleButtonState extends State<BgmToggleButton> {
  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.size ?? 40.0;
    final iconSize = (buttonSize * 0.6).clamp(16.0, 24.0);
    
    return GestureDetector(
      onTap: () async {
        final muted = SoundManager.instance.isBgmMuted;
        if (muted || !SoundManager.instance.isBgmPlaying) {
          await SoundManager.instance.setBgmMuted(false);
          await SoundManager.instance.playBgm(widget.bgmBase, volume: widget.volume);
        } else {
          await SoundManager.instance.setBgmMuted(true);
        }
        if (mounted) setState(() {});
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(
          SoundManager.instance.isBgmMuted ? Icons.music_off : Icons.music_note,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
} 