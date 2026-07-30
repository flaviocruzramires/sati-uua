import 'package:chamados/core/widgets/modals/app_form_dialog.dart';
import 'package:chamados/core/widgets/modals/app_side_panel_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapDialog(Widget child) => MaterialApp(
  home: Scaffold(body: Builder(builder: (ctx) => child)),
);

Widget _wrapDesktop(Widget child) => MaterialApp(
  home: Scaffold(
    body: MediaQuery(
      data: const MediaQueryData(size: Size(1280, 800)),
      child: child,
    ),
  ),
);

Widget _wrapMobile(Widget child) => MaterialApp(
  home: Scaffold(
    body: MediaQuery(
      data: const MediaQueryData(size: Size(375, 812)),
      child: child,
    ),
  ),
);

void main() {
  group('AppFormDialog', () {
    testWidgets('renderiza título e campos', (tester) async {
      await tester.pumpWidget(
        _wrapDialog(
          AppFormDialog(
            title: 'Novo Setor',
            fields: const [Text('Campo 1'), Text('Campo 2')],
            onCancel: () {},
            onSave: () {},
          ),
        ),
      );
      expect(find.text('Novo Setor'), findsOneWidget);
      expect(find.text('Campo 1'), findsOneWidget);
      expect(find.text('Campo 2'), findsOneWidget);
    });

    testWidgets('botões Cancelar e Salvar presentes', (tester) async {
      await tester.pumpWidget(
        _wrapDialog(
          AppFormDialog(
            title: 'Teste',
            fields: const [],
            onCancel: () {},
            onSave: () {},
          ),
        ),
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets('saving=true mostra spinner no Salvar', (tester) async {
      await tester.pumpWidget(
        _wrapDialog(
          AppFormDialog(
            title: 'Teste',
            fields: const [],
            onCancel: () {},
            onSave: () {},
            saving: true,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('chama onCancel ao tocar em Cancelar', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        _wrapDialog(
          AppFormDialog(
            title: 'Teste',
            fields: const [],
            onCancel: () => cancelled = true,
            onSave: () {},
          ),
        ),
      );
      await tester.tap(find.text('Cancelar'));
      expect(cancelled, isTrue);
    });

    testWidgets('chama onSave ao tocar em Salvar', (tester) async {
      var saved = false;
      await tester.pumpWidget(
        _wrapDialog(
          AppFormDialog(
            title: 'Teste',
            fields: const [],
            onCancel: () {},
            onSave: () => saved = true,
          ),
        ),
      );
      await tester.tap(find.text('Salvar'));
      expect(saved, isTrue);
    });
  });

  group('AppSidePanelForm — desktop', () {
    testWidgets('renderiza painel lateral com título e campos', (tester) async {
      await tester.pumpWidget(
        _wrapDesktop(
          AppSidePanelForm(
            title: 'Editar Usuário',
            fields: const [Text('Nome'), Text('Email')],
            onCancel: () {},
            onSave: () {},
          ),
        ),
      );
      expect(find.text('Editar Usuário'), findsOneWidget);
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('não usa Scaffold próprio em desktop', (tester) async {
      await tester.pumpWidget(
        _wrapDesktop(
          AppSidePanelForm(
            title: 'Teste',
            fields: const [],
            onCancel: () {},
            onSave: () {},
          ),
        ),
      );
      // Em desktop o painel é um Container, não um Scaffold dentro de outro
      expect(find.byType(AppBar), findsNothing);
    });
  });

  group('AppSidePanelForm — mobile', () {
    testWidgets('renderiza como tela cheia com AppBar', (tester) async {
      await tester.pumpWidget(
        _wrapMobile(
          AppSidePanelForm(
            title: 'Editar Usuário',
            fields: const [Text('Nome')],
            onCancel: () {},
            onSave: () {},
          ),
        ),
      );
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Editar Usuário'), findsOneWidget);
    });

    testWidgets('saving desabilita botão Salvar no mobile', (tester) async {
      await tester.pumpWidget(
        _wrapMobile(
          AppSidePanelForm(
            title: 'Teste',
            fields: const [],
            onCancel: () {},
            onSave: () {},
            saving: true,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
