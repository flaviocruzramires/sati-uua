import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Buscar...',
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final Duration debounceDuration;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 16,
            color: AppColors.neutral500,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
      ),
    );
  }
}
