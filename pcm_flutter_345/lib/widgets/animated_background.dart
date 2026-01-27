import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatelessWidget {
  final Widget child;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: child,
    );
  }
}