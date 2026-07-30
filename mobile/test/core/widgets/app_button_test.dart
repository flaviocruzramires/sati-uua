import 'package:chamados/core/widgets/actions/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AppButton primary renderiza rótulo', (tester) async {
    await tester.pumpWidget(
      _wrap(AppButton(label: 'Salvar', onPressed: () {})),
    );
    expect(find.text('Salvar'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('AppButton secondary usa OutlinedButton', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppButton(
          label: 'Cancelar',
          onPressed: () {},
          variant: AppButtonVariant.secondary,
        ),
      ),
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('AppButton ghost usa TextButton', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppButton(
          label: 'Fechar',
          onPressed: () {},
          variant: AppButtonVariant.ghost,
        ),
      ),
    );
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('AppButton loading mostra spinner e desabilita', (tester) async {
    await tester.pumpWidget(
      _wrap(AppButton(label: 'Salvar', onPressed: () {}, loading: true)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('AppButton block tem largura total', (tester) async {
    await tester.pumpWidget(
      _wrap(AppButton(label: 'Entrar', onPressed: () {}, block: true)),
    );
    final sized = tester.widget<SizedBox>(find.byType(SizedBox).first);
    expect(sized.width, double.infinity);
  });
}
