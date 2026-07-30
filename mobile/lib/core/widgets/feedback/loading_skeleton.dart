import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum SkeletonTipo { tabela, lista, cards }

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.tipo = SkeletonTipo.lista,
    this.linhas = 5,
  });

  final SkeletonTipo tipo;
  final int linhas;

  @override
  Widget build(BuildContext context) {
    return switch (tipo) {
      SkeletonTipo.tabela => _TabelaSkeleton(linhas: linhas),
      SkeletonTipo.lista => _ListaSkeleton(linhas: linhas),
      SkeletonTipo.cards => _CardsSkeleton(linhas: linhas),
    };
  }
}

class _TabelaSkeleton extends StatelessWidget {
  const _TabelaSkeleton({required this.linhas});
  final int linhas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonBar(height: 40, width: double.infinity),
        const SizedBox(height: 2),
        ...List.generate(
          linhas,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _SkeletonBar(height: 44, width: double.infinity),
          ),
        ),
      ],
    );
  }
}

class _ListaSkeleton extends StatelessWidget {
  const _ListaSkeleton({required this.linhas});
  final int linhas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        linhas,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
          child: Row(
            children: [
              _SkeletonBar(height: 14, width: 200),
              const Spacer(),
              _SkeletonBar(height: 14, width: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardsSkeleton extends StatelessWidget {
  const _CardsSkeleton({required this.linhas});
  final int linhas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        linhas,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
          child: _SkeletonBar(height: 72, width: double.infinity),
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.height, required this.width});
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.neutral200,
    );
  }
}
