import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('create, edit, cancel and reload clue through real forms',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    await PreferencesWebclient().setEditingEnabled(true);
    Get.offAllNamed('/home');
    await tester.pumpAndSettle();
    final categories = await CategoryWebclient().fetch();
    final category =
        categories.firstWhere((c) => c.name == 'Laboratório de integrações');
    final client = LivingClueWebclient();
    final name = 'USP formulário ${DateTime.now().microsecondsSinceEpoch}';
    int? id;
    try {
      Get.toNamed('/living_clues/create', arguments: {
        'categoryId': category.id,
        'categoryName': category.name,
        'metadataTags': category.metadataTags
      });
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), name);
      await tester.enterText(find.byType(TextFormField).at(2),
          'Descrição sintética do formulário.');
      await capture(tester, 'clue-create-form');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      final created = (await client.fetch(search: name)).single;
      id = created.id;
      expect(created.description, 'Descrição sintética do formulário.');
      expect(created.hasLocation, isFalse);
      const delta =
          '[{"insert":"Texto formatado\\n","attributes":{"bold":true}},{"insert":{"image":"https://example.test/embedded.png"}}]';
      created.metadata = {
        'typed': {'enabled': true, 'number': 0},
        'colecao_ordem_itens_v1': [4, 2]
      };
      created.descriptionDelta = delta;
      await client.update(created);
      Get.toNamed('/living_clues/update', parameters: {'id': '$id'});
      await tester.pumpAndSettle();
      expect(find.text('Colecao Ordem Itens V1'), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(0), '$name editada');
      await capture(tester, 'clue-edit-form');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      final changed = await client.fetchById(id);
      expect(changed.name, '$name editada');
      expect(changed.descriptionDelta, delta);
      expect(changed.metadata, created.metadata);
      Get.toNamed('/living_clues/update', parameters: {'id': '$id'});
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextFormField).at(0), 'Alteração cancelada');
      await tester.tap(find.byTooltip('Voltar').first);
      await tester.pumpAndSettle();
      expect((await client.fetchById(id)).name, '$name editada');
      Get.toNamed('/living_clues/show', parameters: {'id': '$id'});
      await tester.pumpAndSettle();
      expect(find.text('$name editada'), findsOneWidget);
    } finally {
      if (id != null) await client.delete(id);
    }
  });
}
