import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Uma entrada da [AppTimeline].
///
/// [header] é o conteúdo sempre visível (fica clicável quando há [body]); o
/// chevron de expandir é adicionado automaticamente pela timeline. [body] é o
/// conteúdo expansível — `null` torna a entrada não expansível.
class AppTimelineEntry {
  const AppTimelineEntry({
    required this.header,
    this.body,
    this.dotColor = AppColors.accent300,
    this.dotShape = BoxShape.rectangle,
    this.initiallyExpanded = false,
  });

  final Widget header;
  final Widget? body;
  final Color dotColor;
  final BoxShape dotShape;
  final bool initiallyExpanded;
}

/// Linha do tempo vertical genérica: desenha o trilho (ponto + linha conectora)
/// e renderiza itens expansíveis com animação (chevron girando + corpo
/// deslizando/fade). Sem dependência de pacote — só widgets nativos.
///
/// A cor/forma do ponto e o conteúdo de cada item vêm de [AppTimelineEntry],
/// então a mesma timeline serve para históricos de chamado, logs, auditoria, etc.
class AppTimeline extends StatelessWidget {
  const AppTimeline({
    super.key,
    required this.entries,
    this.lineColor = AppColors.divider,
    this.lineWidth = 2,
    this.dotSize = 10,
    this.railWidth = 20,
  });

  final List<AppTimelineEntry> entries;
  final Color lineColor;
  final double lineWidth;
  final double dotSize;

  /// Largura da "calha" à esquerda (ponto + linha).
  final double railWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(entries.length, (i) {
        return _AppTimelineTile(
          entry: entries[i],
          isLast: i == entries.length - 1,
          lineColor: lineColor,
          lineWidth: lineWidth,
          dotSize: dotSize,
          railWidth: railWidth,
        );
      }),
    );
  }
}

class _AppTimelineTile extends StatefulWidget {
  const _AppTimelineTile({
    required this.entry,
    required this.isLast,
    required this.lineColor,
    required this.lineWidth,
    required this.dotSize,
    required this.railWidth,
  });

  final AppTimelineEntry entry;
  final bool isLast;
  final Color lineColor;
  final double lineWidth;
  final double dotSize;
  final double railWidth;

  @override
  State<_AppTimelineTile> createState() => _AppTimelineTileState();
}

class _AppTimelineTileState extends State<_AppTimelineTile>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _expanded = widget.entry.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _expanded ? 1.0 : 0.0,
    );
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final expansivel = entry.body != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Trilho: ponto + linha conectora ────────────────────────────
          SizedBox(
            width: widget.railWidth,
            child: Column(
              children: [
                Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: entry.dotColor,
                    shape: entry.dotShape,
                  ),
                ),
                // IntrinsicHeight faz o Expanded esticar até o fim do conteúdo,
                // conectando este ponto ao próximo. Omitido no último item.
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: widget.lineWidth,
                      color: widget.lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          // ── Conteúdo: cabeçalho clicável + corpo expansível ────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: widget.isLast ? 0 : AppSpacing.s2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: expansivel ? _toggle : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: entry.header),
                          if (expansivel) ...[
                            const SizedBox(width: AppSpacing.s1),
                            RotationTransition(
                              turns: _rotate,
                              child: Icon(
                                LucideIcons.chevronDown,
                                size: 16,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (expansivel)
                    SizeTransition(
                      sizeFactor: _fade,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: _fade,
                        child: entry.body!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
