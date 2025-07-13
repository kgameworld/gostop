import 'package:flutter/material.dart';
import 'dart:collection';

class OverlayManager {
  static final OverlayManager _instance = OverlayManager._internal();
  factory OverlayManager() => _instance;
  OverlayManager._internal();

  final Queue<OverlayEntry> _toastQueue = Queue<OverlayEntry>();
  OverlayEntry? _currentToast;
  bool _isShowingToast = false;

  // 토스트 매니저
  static final ToastManager toastManager = ToastManager();

  // 토스트 표시
  static Future<void> showToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
  }) async {
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.viewPadding.top;
    
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 8, // SafeArea + 8px 여백
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    await toastManager.show(entry, duration);
  }

  // GO/STOP 배너 표시
  static Future<void> showGoStopBanner(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.orange,
  }) async {
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.viewPadding.top;
    
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 16, // SafeArea + 16px 여백
        left: 32,
        right: 32,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    await toastManager.show(entry, duration);
  }

  // Bust 배너 표시
  static Future<void> showBustBanner(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    Color backgroundColor = Colors.red,
  }) async {
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.viewPadding.top;
    
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 20, // SafeArea + 20px 여백
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await toastManager.show(entry, duration);
  }

  // Badge 표시
  static Future<void> showBadge(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color backgroundColor = Colors.blue,
  }) async {
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.viewPadding.top;
    
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 12, // SafeArea + 12px 여백
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    await toastManager.show(entry, duration);
  }
}

class ToastManager {
  static final ToastManager _instance = ToastManager._internal();
  factory ToastManager() => _instance;
  ToastManager._internal();

  final Queue<OverlayEntry> _queue = Queue<OverlayEntry>();
  OverlayEntry? _currentEntry;
  bool _isShowing = false;

  Future<void> show(OverlayEntry entry, Duration duration) async {
    _queue.add(entry);
    _processQueue();
    
    // 지정된 시간만큼 대기
    await Future.delayed(duration);
    
    // 큐에서 제거하고 다음 항목 처리
    if (_queue.contains(entry)) {
      _queue.remove(entry);
    }
    if (_currentEntry == entry) {
      _currentEntry?.remove();
      _currentEntry = null;
      _isShowing = false;
      _processQueue();
    }
  }

  void _processQueue() {
    if (_isShowing || _queue.isEmpty) return;
    
    _isShowing = true;
    _currentEntry = _queue.removeFirst();
    _currentEntry!.markNeedsBuild();
  }

  void dismiss() {
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
      _isShowing = false;
      _processQueue();
    }
  }

  void clear() {
    _queue.clear();
    dismiss();
  }
} 