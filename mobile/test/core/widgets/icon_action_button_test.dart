import 'package:chamados/core/widgets/actions/icon_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('IconActionButton renderiza ícone e chama callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
        IconActionButton(icon: LucideIcons.pencil, onPressed: () => tapped = true)));
    expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));
    expect(tapped, isTrue);
  });

  testWidgets('IconActionButton com tooltip', (tester) async {
    await tester.pumpWidget(_wrap(IconActionButton(
        icon: LucideIcons.trash2, onPressed: () {}, tooltip: 'Excluir')));
    expect(find.byType(Tooltip), findsOneWidget);
  });
}
