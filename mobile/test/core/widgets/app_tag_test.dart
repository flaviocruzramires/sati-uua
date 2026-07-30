import 'package:chamados/core/domain/enums.dart';
import 'package:chamados/core/widgets/tags/app_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AppTag renderiza rótulo', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppTag(label: 'Aberto', variant: AppTagVariant.accent)),
    );
    expect(find.text('Aberto'), findsOneWidget);
  });

  group('StatusChamadoTag', () {
    for (final (situacao, label) in [
      (SituacaoChamado.aberto, 'Aberto'),
      (SituacaoChamado.emAndamento, 'Em andamento'),
      (SituacaoChamado.aguardandoSolicitante, 'Aguardando solicitante'),
      (SituacaoChamado.encerrado, 'Encerrado'),
    ]) {
      testWidgets('$situacao → "$label"', (tester) async {
        await tester.pumpWidget(_wrap(StatusChamadoTag(situacao: situacao)));
        expect(find.text(label), findsOneWidget);
      });
    }
  });

  group('PapelUsuarioTag', () {
    for (final (papel, label) in [
      (PapelUsuario.admin, 'Admin'),
      (PapelUsuario.atendente, 'Atendente'),
      (PapelUsuario.solicitante, 'Solicitante'),
    ]) {
      testWidgets('$papel → "$label"', (tester) async {
        await tester.pumpWidget(_wrap(PapelUsuarioTag(papel: papel)));
        expect(find.text(label), findsOneWidget);
      });
    }
  });

  testWidgets('AtivoTag ativo', (tester) async {
    await tester.pumpWidget(_wrap(const AtivoTag(status: StatusAtivo.ativo)));
    expect(find.text('Ativo'), findsOneWidget);
  });

  testWidgets('AtivoTag inativo', (tester) async {
    await tester.pumpWidget(_wrap(const AtivoTag(status: StatusAtivo.inativo)));
    expect(find.text('Inativo'), findsOneWidget);
  });
}
