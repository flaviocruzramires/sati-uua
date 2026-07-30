import 'package:chamados/core/widgets/forms/app_checkbox_row.dart';
import 'package:chamados/core/widgets/forms/app_date_field.dart';
import 'package:chamados/core/widgets/forms/app_select.dart';
import 'package:chamados/core/widgets/forms/app_segmented_control.dart';
import 'package:chamados/core/widgets/forms/app_text_field.dart';
import 'package:chamados/core/widgets/forms/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

void main() {
  group('AppTextField', () {
    testWidgets('renderiza label e campo', (tester) async {
      await tester.pumpWidget(_wrap(AppTextField(
        label: 'Nome',
        controller: TextEditingController(),
      )));
      expect(find.text('Nome'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('campo obrigatório mostra asterisco', (tester) async {
      await tester.pumpWidget(_wrap(AppTextField(
        label: 'Email',
        controller: TextEditingController(),
        obrigatorio: true,
      )));
      expect(find.textContaining('*'), findsOneWidget);
    });
  });

  group('AppTextArea', () {
    testWidgets('renderiza com label Descrição', (tester) async {
      await tester.pumpWidget(_wrap(AppTextArea(
        label: 'Descrição',
        controller: TextEditingController(),
        maxLines: 3,
      )));
      expect(find.text('Descrição'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });

  group('AppSelect', () {
    final items = [
      const ComboItem<int>(1, 'TI'),
      const ComboItem<int>(2, 'RH'),
    ];

    testWidgets('renderiza label e dropdown', (tester) async {
      await tester.pumpWidget(_wrap(AppSelect<int>(
        label: 'Setor',
        items: items,
        value: null,
        onChanged: (_) {},
        placeholder: 'Selecione',
      )));
      expect(find.text('Setor'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });

    testWidgets('loading mostra spinner', (tester) async {
      await tester.pumpWidget(_wrap(AppSelect<int>(
        label: 'Setor',
        items: const [],
        value: null,
        onChanged: (_) {},
        loading: true,
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppCheckboxRow', () {
    testWidgets('renderiza label e chama callback ao tocar', (tester) async {
      bool val = false;
      await tester.pumpWidget(_wrap(StatefulBuilder(
        builder: (ctx, setState) => AppCheckboxRow(
          label: 'Lembrar-me',
          value: val,
          onChanged: (v) => setState(() => val = v),
        ),
      )));
      expect(find.text('Lembrar-me'), findsOneWidget);
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(val, isTrue);
    });
  });

  group('AppSegmentedControl', () {
    final opts = [
      const SegmentedOption<String>('A', 'Opção A'),
      const SegmentedOption<String>('B', 'Opção B'),
    ];

    testWidgets('renderiza opções e chama onChanged', (tester) async {
      String selected = 'A';
      await tester.pumpWidget(_wrap(StatefulBuilder(
        builder: (ctx, setState) => AppSegmentedControl<String>(
          options: opts,
          value: selected,
          onChanged: (v) => setState(() => selected = v),
        ),
      )));
      expect(find.text('Opção A'), findsOneWidget);
      expect(find.text('Opção B'), findsOneWidget);
      await tester.tap(find.text('Opção B'));
      await tester.pump();
      expect(selected, 'B');
    });
  });

  group('AppDateField', () {
    testWidgets('renderiza label e exibe data formatada', (tester) async {
      final date = DateTime(2026, 7, 30);
      await tester.pumpWidget(_wrap(AppDateField(
        label: 'Data',
        value: date,
        onChanged: (_) {},
      )));
      expect(find.text('Data'), findsOneWidget);
      expect(find.text('30/07/2026'), findsOneWidget);
    });

    testWidgets('campo sem valor não mostra texto de data', (tester) async {
      await tester.pumpWidget(_wrap(AppDateField(
        label: 'Data',
        value: null,
        onChanged: (_) {},
      )));
      expect(find.text('30/07/2026'), findsNothing);
    });
  });

  group('AppDateTimeField', () {
    testWidgets('renderiza label e data+hora formatados', (tester) async {
      final dt = DateTime(2026, 7, 30, 14, 35);
      await tester.pumpWidget(_wrap(AppDateTimeField(
        label: 'Data e hora',
        value: dt,
        onChanged: (_) {},
      )));
      expect(find.text('Data e hora'), findsOneWidget);
      expect(find.text('30/07/2026 14:35'), findsOneWidget);
    });
  });

  group('SearchField', () {
    testWidgets('renderiza campo de busca com ícone', (tester) async {
      await tester.pumpWidget(_wrap(SearchField(onChanged: (_) {})));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('chama onChanged com debounce', (tester) async {
      String last = '';
      await tester.pumpWidget(_wrap(SearchField(
        onChanged: (v) => last = v,
        debounceDuration: Duration.zero,
      )));
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(Duration.zero);
      expect(last, 'abc');
    });
  });
}
