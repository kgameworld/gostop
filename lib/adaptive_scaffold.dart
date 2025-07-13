import 'package:flutter/material.dart';
import 'screen_size.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSizeType screenSize) builder;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.builder,
    this.backgroundColor,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ScreenSize.of(width);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: builder(context, screenSize),
      ),
    );
  }
} 