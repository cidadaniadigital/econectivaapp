import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/widgets/catalog_shelf.dart';

Finder button(String label) => find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == label);

void main() {
  Widget shelf(int count) => MaterialApp(
          home: Scaffold(
              body: CatalogShelf(
        title: 'Lugares',
        itemCount: count,
        itemBuilder: (_, index) => SizedBox(
            width: 240,
            child: TextButton(onPressed: () {}, child: Text('Pista $index'))),
      )));

  testWidgets('arrows reveal remaining cards and disable at boundaries',
      (tester) async {
    await tester.pumpWidget(shelf(8));
    await tester.pumpAndSettle();
    final previous = button('Pistas anteriores em Lugares');
    final next = button('Próximas pistas em Lugares');
    expect(tester.widget<IconButton>(previous).onPressed, isNull);
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);
    for (var i = 0; i < 5; i++) {
      if (tester.widget<IconButton>(next).onPressed == null) break;
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.text('Pista 7').hitTestable(), findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNull);
    expect(tester.widget<IconButton>(previous).onPressed, isNotNull);
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);
  });

  testWidgets('mouse can drag the catalog horizontally', (tester) async {
    await tester.pumpWidget(shelf(8));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(-400, 0),
        kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IconButton>(button('Pistas anteriores em Lugares'))
            .onPressed,
        isNotNull);
  });

  testWidgets('short rows disable controls and narrow layouts fit',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(shelf(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        tester
            .widget<IconButton>(button('Próximas pistas em Lugares'))
            .onPressed,
        isNull);
  });
}
