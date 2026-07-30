import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../forms/search_field.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    this.search,
    this.filters = const [],
    this.trailing,
  });

  final SearchField? search;
  final List<Widget> filters;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (search != null)
          SizedBox(width: 240, child: search),
        ...filters,
        if (trailing != null) trailing!,
      ],
    );
  }
}
