import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_cover.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'catalog searches descriptions and paginates all matching records',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    Get.offAllNamed('/catalog', parameters: {'search': 'USP paginação'});
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.byType(ClueCover), findsNWidgets(24));
    await tester.ensureVisible(find.text('Carregar mais'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.byType(ClueCover), findsNWidgets(25));
    expect(find.text('Carregar mais'), findsNothing);
    await capture(tester, 'catalog-pagination');
    final search = find.byType(TextField).first;
    await tester.ensureVisible(search);
    await tester.pumpAndSettle();
    await tester.enterText(search, 'amostra-pagina-25');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.byType(ClueCover), findsOneWidget);
    expect(find.text('USP paginação 25'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planta USP validação').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Nenhum registro encontrado.'), findsOneWidget);
    expect(find.byType(ClueCover), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laboratório de integrações').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('USP paginação 25'), findsOneWidget);
    await capture(tester, 'catalog-description-filter');
    await tester.tap(find.text('USP paginação 25'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fixture fictícia descartável'), findsWidgets);
    expect(find.byTooltip('QR Code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
