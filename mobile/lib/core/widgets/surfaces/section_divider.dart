import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(thickness: 2, color: AppColors.divider, height: 2);
  }
}
