import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../domain/enums.dart';

enum AppTagVariant { accent, accent2, neutral, outline }

class AppTag extends StatelessWidget {
  const AppTag({super.key, required this.label, required this.variant});

  final String label;
  final AppTagVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      AppTagVariant.accent => (
        AppColors.accent100,
        AppColors.accent800,
        Colors.transparent,
      ),
      AppTagVariant.accent2 => (
        AppColors.green100,
        AppColors.green800,
        Colors.transparent,
      ),
      AppTagVariant.neutral => (
        AppColors.neutral100,
        AppColors.neutral800,
        Colors.transparent,
      ),
      AppTagVariant.outline => (
        Colors.transparent,
        AppColors.navy,
        AppColors.navy,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: border,
          width: border == Colors.transparent ? 0 : 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class StatusChamadoTag extends StatelessWidget {
  const StatusChamadoTag({super.key, required this.situacao});

  final SituacaoChamado situacao;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (situacao) {
      SituacaoChamado.aberto => ('Aberto', AppTagVariant.accent),
      SituacaoChamado.emAndamento => ('Em andamento', AppTagVariant.accent2),
      SituacaoChamado.aguardandoSolicitante => (
        'Aguardando solicitante',
        AppTagVariant.outline,
      ),
      SituacaoChamado.encerrado => ('Encerrado', AppTagVariant.neutral),
    };
    return AppTag(label: label, variant: variant);
  }
}

class PapelUsuarioTag extends StatelessWidget {
  const PapelUsuarioTag({super.key, required this.papel});

  final PapelUsuario papel;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (papel) {
      PapelUsuario.admin => ('Admin', AppTagVariant.accent),
      PapelUsuario.atendente => ('Atendente', AppTagVariant.accent2),
      PapelUsuario.gerencia => ('Gerência', AppTagVariant.accent2),
      PapelUsuario.solicitante => ('Solicitante', AppTagVariant.neutral),
    };
    return AppTag(label: label, variant: variant);
  }
}

class AtivoTag extends StatelessWidget {
  const AtivoTag({super.key, required this.status});

  final StatusAtivo status;

  @override
  Widget build(BuildContext context) {
    return AppTag(
      label: status == StatusAtivo.ativo ? 'Ativo' : 'Inativo',
      variant: status == StatusAtivo.ativo
          ? AppTagVariant.accent2
          : AppTagVariant.neutral,
    );
  }
}
