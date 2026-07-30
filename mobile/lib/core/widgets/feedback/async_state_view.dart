import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_state.dart';
import 'loading_skeleton.dart';

class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.builder,
    this.empty,
    this.skeletonTipo = SkeletonTipo.lista,
    this.skeletonLinhas = 5,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget Function()? empty;
  final SkeletonTipo skeletonTipo;
  final int skeletonLinhas;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          LoadingSkeleton(tipo: skeletonTipo, linhas: skeletonLinhas),
      error: (e, _) => ErrorState(mensagem: e.toString(), onRetry: onRetry),
      data: (data) {
        if (empty != null && _isEmpty(data)) return empty!();
        return builder(data);
      },
    );
  }

  bool _isEmpty(T data) {
    if (data is List) return data.isEmpty;
    return false;
  }
}
