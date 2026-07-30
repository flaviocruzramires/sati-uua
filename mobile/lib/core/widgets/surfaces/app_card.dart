import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum AppCardElevation { none, sm, md }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.elevation = AppCardElevation.sm,
    this.background,
    this.padding = const EdgeInsets.all(AppSpacing.s4),
  });

  final Widget child;
  final AppCardElevation elevation;
  final Color? background;
  final EdgeInsetsGeometry padding;

  static const _shadows = {
    AppCardElevation.none: <BoxShadow>[],
    AppCardElevation.sm: [
      BoxShadow(color: Color(0x2423262D), blurRadius: 2, offset: Offset(0, 1))
    ],
    AppCardElevation.md: [
      BoxShadow(color: Color(0x2923262D), blurRadius: 10, offset: Offset(0, 3))
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.surface,
        boxShadow: _shadows[elevation]!,
      ),
      child: child,
    );
  }
}
