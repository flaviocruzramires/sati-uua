import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../tags/app_tag.dart';

class UserFooterTile extends StatelessWidget {
  const UserFooterTile({
    super.key,
    required this.nome,
    required this.papel,
    required this.onLogout,
  });

  final String nome;
  final PapelUsuario? papel;
  final VoidCallback onLogout;

  String get _iniciais {
    final parts = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          // Avatar quadrado com iniciais
          Container(
            width: 34,
            height: 34,
            color: AppColors.accent200,
            alignment: Alignment.center,
            child: Text(
              _iniciais,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.accent800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                if (papel != null) ...[
                  const SizedBox(height: 2),
                  PapelUsuarioTag(papel: papel!),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 16),
            onPressed: onLogout,
            color: AppColors.neutral600,
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
