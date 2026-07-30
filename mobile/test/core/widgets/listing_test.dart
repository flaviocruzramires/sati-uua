import 'package:chamados/core/widgets/feedback/async_state_view.dart';
import 'package:chamados/core/widgets/feedback/empty_state.dart';
import 'package:chamados/core/widgets/feedback/error_state.dart';
import 'package:chamados/core/widgets/feedback/loading_skeleton.dart';
import 'package:chamados/core/widgets/listing/app_card_list_item.dart';
import 'package:chamados/core/widgets/listing/app_data_table.dart';
import 'package:chamados/core/widgets/listing/filter_bar.dart';
import 'package:chamados/core/widgets/listing/pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  group('EmptyState', () {
    testWidgets('mostra mensagem', (tester) async {
      await tester.pumpWidget(
          _wrap(const EmptyState(mensagem: 'Nenhum resultado encontrado')));
      expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
    });
  });

  group('ErrorState', () {
    testWidgets('mostra mensagem de erro e botão retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(_wrap(ErrorState(
        mensagem: 'Falha ao carregar',
        onRetry: () => retried = true,
      )));
      expect(find.text('Falha ao carregar'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      expect(retried, isTrue);
    });

    testWidgets('sem onRetry não mostra botão', (tester) async {
      await tester.pumpWidget(
          _wrap(const ErrorState(mensagem: 'Erro')));
      expect(find.text('Tentar novamente'), findsNothing);
    });
  });

  group('LoadingSkeleton', () {
    testWidgets('tipo tabela renderiza', (tester) async {
      await tester.pumpWidget(
          _wrap(const LoadingSkeleton(tipo: SkeletonTipo.tabela, linhas: 3)));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('tipo cards renderiza', (tester) async {
      await tester.pumpWidget(
          _wrap(const LoadingSkeleton(tipo: SkeletonTipo.cards, linhas: 3)));
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('AsyncStateView', () {
    testWidgets('loading mostra skeleton', (tester) async {
      await tester.pumpWidget(_wrap(AsyncStateView<String>(
        value: const AsyncValue.loading(),
        builder: (d) => Text(d),
      )));
      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });

    testWidgets('error mostra ErrorState', (tester) async {
      await tester.pumpWidget(_wrap(AsyncStateView<String>(
        value: AsyncValue.error('Ops', StackTrace.empty),
        builder: (d) => Text(d),
      )));
      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('data chama builder', (tester) async {
      await tester.pumpWidget(_wrap(AsyncStateView<String>(
        value: const AsyncValue.data('Olá'),
        builder: (d) => Text(d),
      )));
      expect(find.text('Olá'), findsOneWidget);
    });

    testWidgets('lista vazia chama empty()', (tester) async {
      await tester.pumpWidget(_wrap(AsyncStateView<List<String>>(
        value: const AsyncValue.data([]),
        builder: (d) => Text('${d.length}'),
        empty: () => const EmptyState(mensagem: 'Vazio'),
      )));
      expect(find.text('Vazio'), findsOneWidget);
    });
  });

  group('PaginationBar', () {
    testWidgets('mostra label de paginação', (tester) async {
      await tester.pumpWidget(_wrap(PaginationBar(
        page: 1,
        pageSize: 8,
        total: 20,
        onPageChanged: (_) {},
      )));
      expect(find.text('Mostrando 1–8 de 20'), findsOneWidget);
    });

    testWidgets('total 0 não renderiza nada', (tester) async {
      await tester.pumpWidget(_wrap(PaginationBar(
        page: 1,
        pageSize: 8,
        total: 0,
        onPageChanged: (_) {},
      )));
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('navega para próxima página', (tester) async {
      int currentPage = 1;
      await tester.pumpWidget(_wrap(StatefulBuilder(
        builder: (ctx, setState) => PaginationBar(
          page: currentPage,
          pageSize: 8,
          total: 40,
          onPageChanged: (p) => setState(() => currentPage = p),
        ),
      )));
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();
      expect(currentPage, 2);
    });
  });

  group('FilterBar', () {
    testWidgets('renderiza filtros filhos', (tester) async {
      await tester.pumpWidget(_wrap(FilterBar(
        filters: [const Text('Filtro A'), const Text('Filtro B')],
      )));
      expect(find.text('Filtro A'), findsOneWidget);
      expect(find.text('Filtro B'), findsOneWidget);
    });
  });

  group('AppDataTable', () {
    testWidgets('renderiza colunas e linhas', (tester) async {
      await tester.pumpWidget(_wrap(AppDataTable<String>(
        columns: const ['Nome', 'Status'],
        rows: const ['Alpha', 'Beta'],
        rowBuilder: (item) => [Text(item), const Text('Ativo')],
      )));
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('coluna Ações aparece quando actionsBuilder fornecido',
        (tester) async {
      await tester.pumpWidget(_wrap(AppDataTable<String>(
        columns: const ['Nome'],
        rows: const ['X'],
        rowBuilder: (item) => [Text(item)],
        actionsBuilder: (_) => [const Text('Edit')],
      )));
      expect(find.text('Ações'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });
  });

  group('AppCardListItem', () {
    testWidgets('renderiza título e meta', (tester) async {
      await tester.pumpWidget(_wrap(AppCardListItem(
        titulo: 'Chamado #42',
        metaLines: const ['Solicitante: João', '28/07/2026'],
        onTap: () {},
      )));
      expect(find.text('Chamado #42'), findsOneWidget);
      expect(find.text('Solicitante: João'), findsOneWidget);
    });

    testWidgets('chama onTap ao tocar', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(AppCardListItem(
        titulo: 'Item',
        onTap: () => tapped = true,
      )));
      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });
  });
}
