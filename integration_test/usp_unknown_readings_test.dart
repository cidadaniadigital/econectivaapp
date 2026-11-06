import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('unsupported readings remain readable without invented measures',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    const clueId = int.fromEnvironment('E2E_UNKNOWN_READING_ID');
    expect(clueId, greaterThan(0));
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    final clue = await LivingClueWebclient().fetchById(clueId);
    expect(clue.metadata?['lote'], 'usp-unknown-payload-20261027');
    Get.offAllNamed('/living_clues/show', parameters: {'id': '$clueId'});
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    final formats = find.text('Formato sem interpretação disponível');
    expect(formats, findsNWidgets(2));
    for (var index = 0; index < 2; index++) {
      await tester.ensureVisible(formats.at(index));
      await tester.tap(formats.at(index));
      await tester.pumpAndSettle();
    }
    final raw = find.byType(SelectableText);
    expect(raw, findsNWidgets(2));
    expect(tester.widgetList<SelectableText>(raw).map((w) => w.data).join(' '),
        contains('<medida>desconhecida</medida>'));
    expect(find.textContaining('Origem não informada'), findsNWidgets(2));
    expect(find.text('Temperatura: 123'), findsNothing);
    await tester.ensureVisible(raw.last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'unknown-reading');
  });
}
