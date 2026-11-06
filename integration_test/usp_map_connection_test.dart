import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('map creates a directed connection through marker and form UI',
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
    final category = (await CategoryWebclient().fetch())
        .firstWhere((c) => c.name == 'Laboratório de integrações');
    final client = LivingClueWebclient();
    final types = ConnectionTypeWebclient();
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final source = await client.create(LivingClueModel(
        id: 0,
        name: 'USP mapa origem $suffix',
        categoryId: category.id,
        latitude: -29.718,
        longitude: -51.150));
    final target = await client.create(LivingClueModel(
        id: 0,
        name: 'USP mapa destino $suffix',
        categoryId: category.id,
        latitude: -29.718,
        longitude: -51.136));
    final unlocated = await client.create(LivingClueModel(
        id: 0,
        name: 'USP mapa sem localização $suffix',
        categoryId: category.id));
    final type = await types
        .create(ConnectionTypeModel(id: 0, name: 'USP mapa relação $suffix'));
    try {
      Get.offAllNamed('/living_clues/map');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.byTooltip(unlocated.name), findsNothing);
      expect(find.byTooltip(source.name), findsOneWidget);
      expect(find.byTooltip(target.name), findsOneWidget);
      await tester.tap(find.byTooltip('Criar conexão no mapa'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(source.name));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(source.name));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/living_clues/map');
      await tester.tap(find.byTooltip(target.name));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/clue_connections/create');
      expect(find.text(source.name), findsWidgets);
      expect(find.text(target.name), findsWidgets);
      await tester.tap(find.text('Tipo de conexão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(type.name).last);
      await tester.pumpAndSettle();
      await capture(tester, 'map-connection-form');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(Get.currentRoute, '/living_clues/map');
      final links = await CollectionService().connections(source.id);
      expect(
          links
              .where((link) =>
                  link['source_clue_id'] == source.id &&
                  link['target_clue_id'] == target.id &&
                  link['connection_type_id'] == type.id)
              .length,
          1);
      await capture(tester, 'map-connection-saved');
    } finally {
      for (final link in await CollectionService().connections(source.id)) {
        if (link['source_clue_id'] == source.id)
          await ClueConnectionWebclient().delete(link['id']);
      }
      await client.delete(unlocated.id);
      await client.delete(target.id);
      await client.delete(source.id);
      await types.delete(type.id);
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
