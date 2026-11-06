import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/services/modal_route_observer.dart';

void main() {
  testWidgets(
      'popup state follows nested modal routes and restores after closing',
      (tester) async {
    final observer = ModalRouteObserver();
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: key,
        navigatorObservers: [observer],
        home: const Scaffold(body: Text('Base'))));
    await tester.pumpAndSettle();
    expect(observer.popupVisible.value, false);
    showModalBottomSheet<void>(
        context: key.currentContext!, builder: (_) => const Text('Sheet'));
    await tester.pumpAndSettle();
    expect(observer.popupVisible.value, true);
    showDialog<void>(
        context: key.currentContext!,
        builder: (_) => const AlertDialog(content: Text('Dialog')));
    await tester.pumpAndSettle();
    expect(observer.popupVisible.value, true);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(observer.popupVisible.value, true);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(observer.popupVisible.value, false);
  });
}
