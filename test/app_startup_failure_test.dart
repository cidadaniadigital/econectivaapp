import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/widgets/app_startup_failure.dart';

void main() {
  testWidgets('startup failure remains usable and prevents overlapping retries',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(AppStartupFailure(onRetry: () {
      calls++;
      return pending.future;
    }));
    expect(find.text('Não foi possível iniciar o app'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    pending.completeError(StateError('still unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('startup recovery keeps the requested clue route',
      (tester) async {
    await tester.pumpWidget(AppStartupFailure(
        routeName: '/living_clues/show?id=55', onRetry: () async {}));
    final context = tester.element(find.text('Não foi possível iniciar o app'));
    expect(ModalRoute.of(context)?.settings.name, '/living_clues/show?id=55');
    expect(tester.takeException(), isNull);
  });
}
