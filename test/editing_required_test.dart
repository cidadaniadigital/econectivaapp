import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/widgets/editing_required.dart';

void main() {
  testWidgets('consultation mode never constructs the write form',
      (tester) async {
    var enabled = false;
    var builds = 0;
    await tester.pumpWidget(MaterialApp(
        home: EditingRequired(
      builder: (_) {
        builds++;
        return const Text('Write form');
      },
      loadPreference: () async => enabled,
      onConfigure: () async {
        enabled = true;
      },
    )));
    await tester.pumpAndSettle();
    expect(builds, 0);
    expect(find.text('Criação e edição desativadas.'), findsOneWidget);
    await tester.tap(find.text('Meu perfil'));
    await tester.pumpAndSettle();
    expect(builds, greaterThan(0));
    expect(find.text('Write form'), findsOneWidget);
  });

  testWidgets('preference failure stays closed and retry rechecks the API',
      (tester) async {
    var fail = true;
    var builds = 0;
    await tester.pumpWidget(MaterialApp(
        home: EditingRequired(
      builder: (_) {
        builds++;
        return const Text('Write form');
      },
      loadPreference: () async {
        if (fail) throw StateError('unavailable');
        return true;
      },
      onConfigure: () async {},
    )));
    await tester.pumpAndSettle();
    expect(builds, 0);
    expect(find.text('Não foi possível verificar sua preferência de edição.'),
        findsOneWidget);
    fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Write form'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
