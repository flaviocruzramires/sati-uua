import 'package:chamados/core/widgets/surfaces/app_card.dart';
import 'package:chamados/core/widgets/surfaces/section_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AppCard renderiza filho', (tester) async {
    await tester.pumpWidget(_wrap(const AppCard(child: Text('Conteúdo'))));
    expect(find.text('Conteúdo'), findsOneWidget);
  });

  testWidgets('AppCard elevation none sem sombra', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppCard(elevation: AppCardElevation.none, child: SizedBox())),
    );
    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.boxShadow, isEmpty);
  });

  testWidgets('SectionDivider renderiza Divider com espessura 2', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SectionDivider()));
    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.thickness, 2);
  });
}
