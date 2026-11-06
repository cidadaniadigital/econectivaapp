import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/preview/plant_layout_preview.dart';

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('plant proposal renders without overflow at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const PlantLayoutPreview());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('QR Code'));
      await tester.tap(find.text('QR Code'));
      await tester.pumpAndSettle();
      expect(find.text('QR Code da pista'), findsOneWidget);
      expect(find.textContaining('https://plataforma.atopos.spotec.app/'),
          findsOneWidget);
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Umidade do solo').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
