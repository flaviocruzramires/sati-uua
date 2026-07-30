import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chamados/main.dart';

void main() {
  testWidgets('app smoke test — renderiza sem erro', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChamadosApp()));
    // Permite que a árvore de widgets seja construída (sem esperar redirects async)
    await tester.pump(const Duration(milliseconds: 100));
    // O app pode estar em qualquer estado inicial — verifica apenas que renderizou
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
