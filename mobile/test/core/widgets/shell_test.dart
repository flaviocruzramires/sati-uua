import 'package:chamados/core/domain/enums.dart';
import 'package:chamados/core/widgets/shell/app_shell.dart';
import 'package:chamados/core/widgets/shell/back_icon_button.dart';
import 'package:chamados/core/widgets/shell/bottom_nav_bar.dart';
import 'package:chamados/core/widgets/shell/nav_item.dart';
import 'package:chamados/core/widgets/shell/user_footer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

Widget _shell({
  required Size size,
  String route = '/',
  PapelUsuario papel = PapelUsuario.admin,
}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: AppShell(
          currentRoute: route,
          nomeUsuario: 'João Silva',
          papelUsuario: papel,
          title: 'Dashboard',
          onNavigate: (_) {},
          onLogout: () {},
          child: const Text('Conteúdo'),
        ),
      ),
    );

const _desktop = Size(1280, 800);
const _mobile = Size(375, 812);

void main() {
  group('AppShell — desktop', () {
    testWidgets('renderiza sidebar e conteúdo', (tester) async {
      await tester.pumpWidget(_shell(size: _desktop));
      expect(find.text('SATI-UUA'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Conteúdo'), findsOneWidget);
    });

    testWidgets('topbar exibe título', (tester) async {
      await tester.pumpWidget(_shell(size: _desktop));
      expect(find.text('Dashboard'), findsWidgets);
    });

    testWidgets('não mostra BottomNavBar no desktop', (tester) async {
      await tester.pumpWidget(_shell(size: _desktop));
      expect(find.byType(AppBottomNavBar), findsNothing);
    });

    testWidgets('sidebar mostra UserFooterTile com nome e papel', (tester) async {
      await tester.pumpWidget(_shell(size: _desktop));
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('item ativo fica destacado (Dashboard na rota /)', (tester) async {
      await tester.pumpWidget(_shell(size: _desktop, route: '/'));
      // SidebarNavItem de Dashboard deve estar ativo
      final items = tester.widgetList<SidebarNavItem>(find.byType(SidebarNavItem));
      final dashboard = items.firstWhere((i) => i.label == 'Dashboard');
      expect(dashboard.active, isTrue);
    });

    testWidgets('SOLICITANTE não vê item Usuários na sidebar', (tester) async {
      await tester.pumpWidget(_shell(size: _desktop, papel: PapelUsuario.solicitante));
      await tester.pump();
      // Usuários é visível apenas para ADMIN
      final items = tester.widgetList<SidebarNavItem>(find.byType(SidebarNavItem));
      final usuarios = items.firstWhere((i) => i.label == 'Usuários');
      expect(usuarios._visible, isFalse);
    });
  });

  group('AppShell — mobile', () {
    testWidgets('renderiza AppBar e BottomNavBar', (tester) async {
      await tester.pumpWidget(_shell(size: _mobile));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('não renderiza sidebar', (tester) async {
      await tester.pumpWidget(_shell(size: _mobile));
      expect(find.text('SATI-UUA'), findsNothing);
    });
  });

  group('SidebarNavItem', () {
    testWidgets('item visível sem restrição de papel', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SidebarNavItem(
            icon: LucideIcons.layoutGrid,
            label: 'Dashboard',
            active: false,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('item invisível quando papel não autorizado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SidebarNavItem(
            icon: LucideIcons.users,
            label: 'Usuários',
            active: false,
            onTap: () {},
            visibleForPapeis: [PapelUsuario.admin],
            currentPapel: PapelUsuario.solicitante,
          ),
        ),
      ));
      expect(find.text('Usuários'), findsNothing);
    });

    testWidgets('chama onTap ao tocar', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SidebarNavItem(
            icon: LucideIcons.layoutGrid,
            label: 'Item',
            active: false,
            onTap: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });
  });

  group('UserFooterTile', () {
    testWidgets('exibe iniciais do nome', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UserFooterTile(
            nome: 'Maria Souza',
            papel: PapelUsuario.atendente,
            onLogout: () {},
          ),
        ),
      ));
      expect(find.text('MS'), findsOneWidget);
    });

    testWidgets('chama onLogout', (tester) async {
      var loggedOut = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UserFooterTile(
            nome: 'Teste',
            papel: PapelUsuario.solicitante,
            onLogout: () => loggedOut = true,
          ),
        ),
      ));
      await tester.tap(find.byType(IconButton));
      expect(loggedOut, isTrue);
    });
  });

  group('AppBottomNavBar', () {
    testWidgets('renderiza 4 itens', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppBottomNavBar(currentIndex: 0, onTap: (_) {}),
        ),
      ));
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Chamados'), findsOneWidget);
      expect(find.text('Cadastros'), findsOneWidget);
      expect(find.text('Mais'), findsOneWidget);
    });

    testWidgets('chama onTap com índice correto', (tester) async {
      int tapped = -1;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppBottomNavBar(
            currentIndex: 0,
            onTap: (i) => tapped = i,
          ),
        ),
      ));
      await tester.tap(find.text('Chamados'));
      expect(tapped, 1);
    });
  });

  group('BackIconButton', () {
    testWidgets('renderiza com ícone de seta', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BackIconButton(onPressed: () {}),
        ),
      ));
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
    });

    testWidgets('chama callback ao tocar', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BackIconButton(onPressed: () => tapped = true),
        ),
      ));
      await tester.tap(find.byType(OutlinedButton));
      expect(tapped, isTrue);
    });
  });
}

// Extensão para acessar _visible em teste
extension on SidebarNavItem {
  bool get _visible =>
      visibleForPapeis.isEmpty ||
      (currentPapel != null && visibleForPapeis.contains(currentPapel));
}
