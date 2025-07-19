import 'package:flutter/material.dart';
import 'dart:math';

class Particle {
  Offset position;
  Offset velocity;
  double life;
  double maxLife;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
  });

  bool get isDead => life <= 0;
  
  void update(double deltaTime) {
    position += velocity * deltaTime;
    velocity *= 0.98; // 저항
    life -= deltaTime;
    rotation += rotationSpeed * deltaTime;
  }
}

class SparkleParticle extends StatefulWidget {
  final Offset position;
  final Color color;
  final int particleCount;
  final Duration duration;
  final VoidCallback? onComplete;

  const SparkleParticle({
    super.key,
    required this.position,
    this.color = Colors.yellow,
    this.particleCount = 20,
    this.duration = const Duration(milliseconds: 1000),
    this.onComplete,
  });

  @override
  State<SparkleParticle> createState() => _SparkleParticleState();
}

class _SparkleParticleState extends State<SparkleParticle>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particles = List.generate(widget.particleCount, (index) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 50 + _random.nextDouble() * 100;
      
      return Particle(
        position: widget.position,
        velocity: Offset(
          cos(angle) * speed,
          sin(angle) * speed,
        ),
        life: 1.0,
        maxLife: 1.0,
        color: widget.color,
        size: 2 + _random.nextDouble() * 4,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      );
    });

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: _particles
            .where((p) => !p.isDead)
            .map((particle) {
              final opacity = particle.life / particle.maxLife;
              return Positioned(
                left: particle.position.dx - particle.size / 2,
                top: particle.position.dy - particle.size / 2,
                child: Transform.rotate(
                  angle: particle.rotation,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: particle.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: particle.color.withOpacity(opacity * 0.5),
                            blurRadius: particle.size,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
}

class ScreenParticleEffect extends StatefulWidget {
  final String effectType;
  final Duration duration;
  final VoidCallback? onComplete;

  const ScreenParticleEffect({
    super.key,
    required this.effectType,
    this.duration = const Duration(milliseconds: 2000),
    this.onComplete,
  });

  @override
  State<ScreenParticleEffect> createState() => _ScreenParticleEffectState();
}

class _ScreenParticleEffectState extends State<ScreenParticleEffect>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particles = List.generate(50, (index) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      
      return Particle(
        position: Offset(
          _random.nextDouble() * screenWidth,
          _random.nextDouble() * screenHeight,
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 200,
          (_random.nextDouble() - 0.5) * 200,
        ),
        life: 1.0,
        maxLife: 1.0,
        color: _getEffectColor(),
        size: 3 + _random.nextDouble() * 6,
        rotationSpeed: (_random.nextDouble() - 0.5) * 15,
      );
    });

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  Color _getEffectColor() {
    switch (widget.effectType) {
      case 'ppeok':
        return Colors.red;
      case 'ttak':
        return Colors.orange;
      case 'bomb':
        return Colors.purple;
      case 'chok':
        return Colors.blue;
      case 'bonus':
        return Colors.green;
      default:
        return Colors.yellow;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: _particles
            .where((p) => !p.isDead)
            .map((particle) {
              final opacity = particle.life / particle.maxLife;
              return Positioned(
                left: particle.position.dx - particle.size / 2,
                top: particle.position.dy - particle.size / 2,
                child: Transform.rotate(
                  angle: particle.rotation,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: particle.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: particle.color.withOpacity(opacity * 0.7),
                            blurRadius: particle.size * 2,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
} 