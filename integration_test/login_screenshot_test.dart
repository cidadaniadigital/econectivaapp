import 'evidence_path.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

Future<void> saveScreen(WidgetTester tester, String path) async {
  final boundaries = find
      .byType(RepaintBoundary)
      .evaluate()
      .map((element) => element.renderObject)
      .whereType<RenderRepaintBoundary>()
      .where((item) =>
          item.hasSize && item.size.width > 300 && item.size.height > 300)
      .toList();
  expect(boundaries, isNotEmpty);
  final image = await boundaries.first.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  expect(data, isNotNull);
  final file = await evidenceFile(path.replaceFirst('docs/validation/', ''));
  file.parent.createSync(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
  image.dispose();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('login through form and open new connection with screenshot',
      (tester) async {
    expect({'127.0.0.1', 'localhost'},
        contains(Uri.parse(WebClient.apiBaseUrl).host));
    const email = String.fromEnvironment('E2E_EMAIL');
    const password = String.fromEnvironment('E2E_PASSWORD');
    expect(email, isNotEmpty);
    expect(password, isNotEmpty);
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Explore pistas e conexões'), findsOneWidget);
    await saveScreen(tester, 'docs/validation/screenshots/home.png');
    Get.toNamed('/management');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Conexões').first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.text('Conexões').first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(Get.currentRoute, '/clue_connections');
    await tester.tap(find.byTooltip('Nova conexão'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Nova conexão'), findsWidgets);
    expect(find.text('Pista origem'), findsWidgets);
    expect(find.text('Pista destino'), findsWidgets);
    expect(find.text('Tipo de conexão'), findsWidgets);
    await saveScreen(tester, 'docs/validation/screenshots/new-connection.png');
  });
}
