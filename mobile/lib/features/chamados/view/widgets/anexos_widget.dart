import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../anexo_repository.dart';

class AnexosWidget extends ConsumerStatefulWidget {
  const AnexosWidget({
    super.key,
    required this.chamadoId,
    this.historicoId,
    required this.anexos,
    this.readOnly = false,
    this.onUploaded,
    this.onDeleted,
    required this.currentUserId,
    required this.isAtendente,
  });

  final int chamadoId;
  final int? historicoId;
  final List<AnexoDto> anexos;
  final bool readOnly;
  final void Function(AnexoDto)? onUploaded;
  final void Function(int id)? onDeleted;
  final int? currentUserId;
  final bool isAtendente;

  @override
  ConsumerState<AnexosWidget> createState() => _AnexosWidgetState();
}

class _AnexosWidgetState extends ConsumerState<AnexosWidget> {
  bool _uploading = false;
  String? _uploadError;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final mimeType = _guessMime(file.name);
    if (mimeType == null) {
      setState(() => _uploadError = 'Tipo não suportado. Use imagem ou PDF.');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadError = null;
    });

    try {
      final repo = ref.read(anexoRepositoryProvider);
      final anexo = await repo.upload(
        chamadoId: widget.chamadoId,
        historicoId: widget.historicoId,
        filePath: file.path!,
        fileName: file.name,
        mimeType: mimeType,
      );
      widget.onUploaded?.call(anexo);
    } catch (e) {
      setState(() => _uploadError = 'Falha no upload: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _abrirArquivo(AnexoDto anexo) async {
    final repo = ref.read(anexoRepositoryProvider);
    final url = Uri.parse(repo.urlArquivo(anexo.token));
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o arquivo')),
        );
      }
    }
  }

  Future<void> _deletar(AnexoDto anexo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover anexo'),
        content: Text('Remover "${anexo.nomeArquivo}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Remover', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final repo = ref.read(anexoRepositoryProvider);
      await repo.deletar(anexo.id);
      widget.onDeleted?.call(anexo.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final podeDeletar = widget.isAtendente;
    final repo = ref.read(anexoRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.anexos.isEmpty && widget.readOnly)
          Text(
            'Nenhum anexo',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          )
        else if (widget.anexos.isNotEmpty)
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: widget.anexos.map((a) {
              final podeRemover =
                  podeDeletar || a.usuarioId == widget.currentUserId;
              return _AnexoCard(
                anexo: a,
                fileUrl: repo.urlArquivo(a.token),
                podeRemover: podeRemover,
                onTap: () => _abrirArquivo(a),
                onDelete: () => _deletar(a),
              );
            }).toList(),
          ),
        if (!widget.readOnly) ...[
          if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s2),
              child: Text(_uploadError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: AppSpacing.s2),
          _uploading
              ? const Row(
                  children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: AppSpacing.s2),
                    Text('Enviando arquivo...',
                        style: TextStyle(fontSize: 12)),
                  ],
                )
              : OutlinedButton.icon(
                  onPressed: _pickAndUpload,
                  icon: const Icon(LucideIcons.paperclip, size: 15),
                  label: const Text('Anexar imagem ou PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
        ],
      ],
    );
  }

  String? _guessMime(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => null,
    };
  }
}

// ── Card de anexo ─────────────────────────────────────────────────────────────

class _AnexoCard extends StatelessWidget {
  const _AnexoCard({
    required this.anexo,
    required this.fileUrl,
    required this.podeRemover,
    required this.onTap,
    required this.onDelete,
  });

  final AnexoDto anexo;
  final String fileUrl;
  final bool podeRemover;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview
            SizedBox(
              height: 80,
              child: anexo.isImagem
                  ? Image.network(
                      fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconPreview(),
                    )
                  : _iconPreview(),
            ),
            // Nome + ações
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: AppSpacing.s1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      anexo.nomeArquivo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  if (podeRemover)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(LucideIcons.x,
                          size: 12, color: Colors.red),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPreview() {
    return Container(
      color: anexo.isPdf ? Colors.red.shade50 : AppColors.accent100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              anexo.isPdf ? LucideIcons.fileText : LucideIcons.image,
              size: 28,
              color: anexo.isPdf ? Colors.red.shade400 : AppColors.accent500,
            ),
            const SizedBox(height: 4),
            Text(
              anexo.isPdf ? 'PDF' : 'IMG',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: anexo.isPdf ? Colors.red.shade400 : AppColors.accent500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
