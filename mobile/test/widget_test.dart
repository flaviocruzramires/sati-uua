import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chamados/main.dart';

void main() {
  testWidgets('app smoke test — renderiza sem erro', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChamadosApp()));
    await tester.pump();
    expect(find.text('SATI UUA'), findsOneWidget);
  });
}
