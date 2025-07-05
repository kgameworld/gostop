import 'package:flutter/material.dart';

enum AnimationSpeed {
  slow, normal, fast, instant
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AnimationSpeed _animationSpeed = AnimationSpeed.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 설정'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[900]!,
              Colors.green[700]!,
              Colors.green[500]!,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: '애니메이션 설정',
              icon: Icons.animation,
              children: [
                const Text(
                  '애니메이션 속도',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...AnimationSpeed.values.map((speed) => RadioListTile<AnimationSpeed>(
                  title: Text(_getAnimationSpeedText(speed), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: Text(_getAnimationSpeedDescription(speed), style: const TextStyle(color: Colors.white70)),
                  value: speed,
                  groupValue: _animationSpeed,
                  onChanged: (value) {
                    setState(() { _animationSpeed = value!; });
                  },
                  activeColor: Colors.yellow,
                )),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '게임 정보',
              icon: Icons.info,
              children: [
                ListTile(
                  title: const Text('버전', style: TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: const Text('1.0.0', style: TextStyle(color: Colors.white70)),
                  leading: const Icon(Icons.app_settings_alt, color: Colors.white),
                ),
                ListTile(
                  title: const Text('개발자', style: TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: const Text('고스톱 게임 개발팀', style: TextStyle(color: Colors.white70)),
                  leading: const Icon(Icons.person, color: Colors.white),
                ),
                ListTile(
                  title: const Text('라이선스', style: TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: const Text('MIT License', style: TextStyle(color: Colors.white70)),
                  leading: const Icon(Icons.description, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.yellow, size: 24),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getAnimationSpeedText(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return '느리게';
      case AnimationSpeed.normal:
        return '보통';
      case AnimationSpeed.fast:
        return '빠르게';
      case AnimationSpeed.instant:
        return '즉시';
    }
  }

  String _getAnimationSpeedDescription(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return '애니메이션이 1.5배 느리게 재생됩니다';
      case AnimationSpeed.normal:
        return '기본 애니메이션 속도입니다';
      case AnimationSpeed.fast:
        return '애니메이션이 0.7배 빠르게 재생됩니다';
      case AnimationSpeed.instant:
        return '애니메이션 없이 즉시 결과를 표시합니다';
    }
  }
} 