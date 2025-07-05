import 'package:flutter/material.dart';
import '../widgets/particle_system.dart';
import '../animations.dart';

class AnimationPool {
  static final AnimationPool _instance = AnimationPool._internal();
  factory AnimationPool() => _instance;
  AnimationPool._internal();

  final Map<String, List<Widget>> _pools = {};
  final int _maxPoolSize = 10;

  // 카드 뒤집기 애니메이션 풀
  Widget getCardFlipAnimation({
    required String backImage,
    required String frontImage,
    required VoidCallback onComplete,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    const key = 'card_flip';
    final pool = _pools[key] ?? [];
    
    if (pool.isNotEmpty) {
      final animation = pool.removeLast();
      // 기존 애니메이션 재사용 로직
      return animation;
    }
    
    return CardFlipAnimation(
      backImage: backImage,
      frontImage: frontImage,
      onComplete: () {
        onComplete();
        _returnToPool(key, CardFlipAnimation(
          backImage: backImage,
          frontImage: frontImage,
          onComplete: () {},
        ));
      },
      duration: duration,
    );
  }

  // 카드 이동 애니메이션 풀
  Widget getCardMoveAnimation({
    required String cardImage,
    required Offset startPosition,
    required Offset endPosition,
    required VoidCallback onComplete,
    Duration duration = const Duration(milliseconds: 600),
    bool withTrail = true,
  }) {
    const key = 'card_move';
    final pool = _pools[key] ?? [];
    
    if (pool.isNotEmpty) {
      final animation = pool.removeLast();
      return animation;
    }
    
    return CardMoveAnimation(
      cardImage: cardImage,
      startPosition: startPosition,
      endPosition: endPosition,
      onComplete: () {
        onComplete();
        _returnToPool(key, CardMoveAnimation(
          cardImage: cardImage,
          startPosition: startPosition,
          endPosition: endPosition,
          onComplete: () {},
        ));
      },
      duration: duration,
      withTrail: withTrail,
    );
  }

  // 특수 효과 애니메이션 풀
  Widget getSpecialEffectAnimation({
    required String effectType,
    required VoidCallback onComplete,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    const key = 'special_effect';
    final pool = _pools[key] ?? [];
    
    if (pool.isNotEmpty) {
      final animation = pool.removeLast();
      return animation;
    }
    
    return SpecialEffectAnimation(
      effectType: effectType,
      onComplete: () {
        onComplete();
        _returnToPool(key, SpecialEffectAnimation(
          effectType: effectType,
          onComplete: () {},
        ));
      },
      duration: duration,
    );
  }

  // 카드 획득 애니메이션 풀
  Widget getCardCaptureAnimation({
    required List<String> cardImages,
    required Offset startPosition,
    required Offset endPosition,
    required VoidCallback onComplete,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    const key = 'card_capture';
    final pool = _pools[key] ?? [];
    
    if (pool.isNotEmpty) {
      final animation = pool.removeLast();
      return animation;
    }
    
    return CardCaptureAnimation(
      cardImages: cardImages,
      startPosition: startPosition,
      endPosition: endPosition,
      onComplete: () {
        onComplete();
        _returnToPool(key, CardCaptureAnimation(
          cardImages: cardImages,
          startPosition: startPosition,
          endPosition: endPosition,
          onComplete: () {},
        ));
      },
      duration: duration,
    );
  }

  // 스파클 파티클 풀
  Widget getSparkleParticle({
    required Offset position,
    Color color = Colors.yellow,
    int particleCount = 20,
    Duration duration = const Duration(milliseconds: 1000),
    required VoidCallback onComplete,
  }) {
    const key = 'sparkle_particle';
    final pool = _pools[key] ?? [];
    
    if (pool.isNotEmpty) {
      final animation = pool.removeLast();
      return animation;
    }
    
    return SparkleParticle(
      position: position,
      color: color,
      particleCount: particleCount,
      onComplete: () {
        onComplete();
        _returnToPool(key, SparkleParticle(
          position: position,
          color: color,
          particleCount: particleCount,
          onComplete: () {},
        ));
      },
      duration: duration,
    );
  }

  // 화면 파티클 효과 풀
  Widget getScreenParticleEffect({
    required String effectType,
    Duration duration = const Duration(milliseconds: 2000),
    required VoidCallback onComplete,
  }) {
    const key = 'screen_particle';
    final pool = _pools[key] ?? [];
    
    if (pool.isNotEmpty) {
      final animation = pool.removeLast();
      return animation;
    }
    
    return ScreenParticleEffect(
      effectType: effectType,
      onComplete: () {
        onComplete();
        _returnToPool(key, ScreenParticleEffect(
          effectType: effectType,
          onComplete: () {},
        ));
      },
      duration: duration,
    );
  }

  // 풀에 애니메이션 반환
  void _returnToPool(String key, Widget animation) {
    if (!_pools.containsKey(key)) {
      _pools[key] = [];
    }
    
    final pool = _pools[key]!;
    if (pool.length < _maxPoolSize) {
      pool.add(animation);
    }
  }

  // 풀 정리
  void clearPool(String? key) {
    if (key != null) {
      _pools.remove(key);
    } else {
      _pools.clear();
    }
  }

  // 풀 상태 확인
  Map<String, int> getPoolStatus() {
    return _pools.map((key, value) => MapEntry(key, value.length));
  }
} 