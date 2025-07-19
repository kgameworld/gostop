import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

enum Sfx {
  buttonClick,
  goStop,
  bonusCard,
  stealPi,
  winFanfare,
  cardFlip,
  cardOverlap,
  cardPlay,
}

class SoundManager {
  SoundManager._internal();
  static final SoundManager instance = SoundManager._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isBgmPlaying = false; // 현재 BGM 재생 여부
  // 테스트 기본값: BGM을 OFF 상태로 시작 (muted=true)
  bool _bgmMuted = true;
  double _bgmVolume = 0.5; // 마지막 설정된 볼륨을 기억
  bool _bgmLoopAttached = false; // loop listener once

  bool get isBgmPlaying => _isBgmPlaying;
  bool get isBgmMuted => _bgmMuted;

  void _log(String msg) {
    // ignore: avoid_print
    print('[SoundManager] $msg');
  }

  Future<void> play(Sfx sfx, {double volume = 0.8}) async {
    // base filename without extension
    final base = switch (sfx) {
      Sfx.buttonClick => 'button_click',
      Sfx.goStop => 'go_stop',
      Sfx.bonusCard => 'bonus_card',
      Sfx.stealPi => 'steal_pi',
      Sfx.winFanfare => 'win_fanfare',
      Sfx.cardFlip => 'card_flip',
      Sfx.cardOverlap => 'card_overlap',
      Sfx.cardPlay => 'card_play',
    };
    final filename = '$base.mp3';

    await _player.stop(); // 동일 채널에서 이전 사운드 중지
    await _player.setVolume(volume);
    await _player.play(AssetSource('sounds/$filename'));
  }

  Future<void> playBgm(String base, {double volume = 0.5}) async {
    _log('playBgm called with base=$base, volume=$volume, muted=$_bgmMuted, isPlaying=$_isBgmPlaying');
    final filename = '$base.mp3';
    _log('Attempting to load: sounds/$filename');
    
    // 파일 존재 여부 확인
    try {
      await rootBundle.load('assets/sounds/$filename');
      _log('File exists: assets/sounds/$filename');
    } catch (e) {
      _log('File NOT found: assets/sounds/$filename - Error: $e');
      return;
    }
    
    _bgmVolume = volume;
    await _bgmPlayer.stop();
    try {
      await _bgmPlayer.setSource(AssetSource('sounds/$filename'));
      _log('setSource completed successfully');
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      _log('setReleaseMode completed');
      // 수동 루프: 완료 이벤트에서 재시작 (한 번만 등록)
      if (!_bgmLoopAttached) {
        _bgmPlayer.onPlayerComplete.listen((event) async {
          _log('onPlayerComplete triggered');
          if (_isBgmPlaying && !_bgmMuted) {
            await _bgmPlayer.seek(Duration.zero);
            await _bgmPlayer.resume();
            _log('Loop resume called');
          }
        });
        _bgmLoopAttached = true;
        _log('Loop listener attached');
      }

      await _bgmPlayer.resume();
      _log('resume() completed');
      await _bgmPlayer.setVolume(_bgmMuted ? 0 : _bgmVolume);
      _log('setVolume(${_bgmMuted ? 0 : _bgmVolume}) completed');
      _isBgmPlaying = true;
      _log('BGM started successfully');
    } catch (e) {
      // 브라우저 자동재생 차단 등으로 실패할 수 있음
      _isBgmPlaying = false;
      _log('BGM play failed: $e');
      // 디버그 목적 로그 출력
      // ignore: avoid_print
      print(e);
    }
  }

  Future<void> stopBgm() async {
    _log('stopBgm called');
    _isBgmPlaying = false;
    await _bgmPlayer.stop();
  }

  Future<void> setBgmMuted(bool muted) async {
    _log('setBgmMuted: $muted');
    _bgmMuted = muted;
    await _bgmPlayer.setVolume(muted ? 0 : _bgmVolume);
  }
} 